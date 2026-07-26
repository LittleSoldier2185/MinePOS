import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

const _mdnsGroup = '224.0.0.251';
const _mdnsPort = 5353;
const _serviceType = '_minepos._tcp';

/// Broadcasts the MinePOS server as an mDNS service so Bonsoir-based
/// Flutter clients on the same LAN can discover it without manual
/// address entry.
///
/// Sends unsolicited PTR/SRV/TXT/A announcements on startup and every
/// 30 seconds.  Also responds to PTR queries for `_minepos._tcp.local.`.
class MdnsService {
  MdnsService._({
    required String serviceName,
    required int port,
    required String hostname,
    required List<InternetAddress> addresses,
  })  : _serviceName = serviceName,
        _port = port,
        _hostname = hostname,
        _addresses = addresses;

  final String _serviceName;
  final int _port;
  final String _hostname;
  final List<InternetAddress> _addresses;

  RawDatagramSocket? _socket;
  Timer? _timer;

  // Adapter names for VPN/virtual-networking software that commonly sits
  // alongside a real LAN connection (Radmin VPN, ZeroTier, Hamachi, TAP/TUN,
  // Windows' own Teredo tunnel). Their addresses are routable on the LAN in
  // name only — a device on the same physical Wi-Fi/Ethernet can't reach
  // them — so advertising one instead of the real adapter makes the shop
  // "discoverable" but unreachable. Matched against real machines that hit
  // this; extend the list if another VPN client shows up in the wild.
  static final _virtualAdapterPattern = RegExp(
    r'radmin|zerotier|zero tier|hamachi|tailscale|wireguard|openvpn|\btap\b|\btun\b|teredo|vethernet|virtualbox|vmware',
    caseSensitive: false,
  );

  static Future<MdnsService> create({
    required String serviceName,
    required int port,
  }) async {
    final hostname = Platform.localHostname.toLowerCase().replaceAll(' ', '-');
    final addresses = <InternetAddress>[];
    final virtualAddresses = <InternetAddress>[];
    for (final iface in await NetworkInterface.list()) {
      final isVirtual = _virtualAdapterPattern.hasMatch(iface.name);
      for (final addr in iface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          (isVirtual ? virtualAddresses : addresses).add(addr);
        }
      }
    }
    // Only fall back to a VPN/virtual adapter's address if there's truly
    // nothing else — still better than advertising no address at all.
    if (addresses.isEmpty) addresses.addAll(virtualAddresses);
    if (addresses.isEmpty) addresses.add(InternetAddress.loopbackIPv4);

    return MdnsService._(
      serviceName: serviceName,
      port: port,
      hostname: hostname,
      addresses: addresses,
    );
  }

  Future<void> start() async {
    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _mdnsPort,
        reuseAddress: true,
        ttl: 255,
      );
      _socket!.multicastLoopback = true;

      for (final iface in await NetworkInterface.list()) {
        try {
          _socket!.joinMulticast(InternetAddress(_mdnsGroup), iface);
        } catch (_) {}
      }

      _socket!.listen(_onData);
      _announce();
      _timer = Timer.periodic(const Duration(seconds: 30), (_) => _announce());

      final ip = _addresses.first.address;
      print('mDNS: advertising "$_serviceName" → $ip:$_port');
    } catch (e) {
      print('mDNS: could not start broadcaster ($e)');
      print('mDNS: use manual address entry in the app instead.');
    }
  }

  Future<void> stop() async {
    _timer?.cancel();
    if (_socket != null) {
      // Send goodbye (TTL=0) before closing.
      try {
        _socket!.send(_buildAnnouncement(ttl: 0), InternetAddress(_mdnsGroup), _mdnsPort);
      } catch (_) {}
      _socket!.close();
      _socket = null;
    }
  }

  // ── Incoming queries ────────────────────────────────────────────────────────

  void _onData(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final dg = _socket?.receive();
    if (dg == null) return;
    _handlePacket(dg.data);
  }

  void _handlePacket(Uint8List data) {
    if (data.length < 12) return;
    final flags = (data[2] << 8) | data[3];
    if ((flags & 0x8000) != 0) return; // ignore responses

    final qdcount = (data[4] << 8) | data[5];
    var offset = 12;

    for (var i = 0; i < qdcount && offset < data.length; i++) {
      final (name, next) = _readName(data, offset);
      offset = next;
      if (offset + 4 > data.length) break;
      final qtype = (data[offset] << 8) | data[offset + 1];
      offset += 4;

      // PTR query for our service type
      if (qtype == 12 &&
          (name == '$_serviceType.local' ||
              name == '$_serviceType.local.')) {
        _announce();
        return;
      }
    }
  }

  (String, int) _readName(Uint8List data, int offset) {
    final labels = <String>[];
    var pos = offset;
    while (pos < data.length) {
      final len = data[pos];
      if (len == 0) {
        pos++;
        break;
      }
      if ((len & 0xC0) == 0xC0) {
        if (pos + 1 >= data.length) break;
        final ptr = ((len & 0x3F) << 8) | data[pos + 1];
        final (pName, _) = _readName(data, ptr);
        labels.addAll(pName.split('.').where((s) => s.isNotEmpty));
        pos += 2;
        break;
      }
      pos++;
      if (pos + len > data.length) break;
      labels.add(String.fromCharCodes(data.sublist(pos, pos + len)));
      pos += len;
    }
    return (labels.join('.'), pos);
  }

  // ── Announcement builder ────────────────────────────────────────────────────

  void _announce() {
    if (_socket == null) return;
    try {
      _socket!.send(
        _buildAnnouncement(),
        InternetAddress(_mdnsGroup),
        _mdnsPort,
      );
    } catch (_) {}
  }

  Uint8List _buildAnnouncement({int ttl = 4500}) {
    final instanceFqdn = '$_serviceName.$_serviceType.local.';
    final serviceTypeFqdn = '$_serviceType.local.';
    final hostFqdn = '$_hostname.local.';

    // PTR answer
    final answers = [
      _record(_dnsName(serviceTypeFqdn), 12, 0x0001, ttl,
          _dnsName(instanceFqdn)),
    ];

    // SRV + TXT + A additional records
    final additional = <List<int>>[];

    final srvRdata = [0, 0, 0, 0, (_port >> 8) & 0xFF, _port & 0xFF, ..._dnsName(hostFqdn)];
    additional.add(_record(_dnsName(instanceFqdn), 33, 0x8001, ttl < 120 ? ttl : 120, srvRdata));

    const ver = 'version=1.0.0';
    additional.add(_record(_dnsName(instanceFqdn), 16, 0x8001, ttl, [ver.length, ...ver.codeUnits]));

    for (final addr in _addresses) {
      final parts = addr.address.split('.');
      if (parts.length == 4) {
        additional.add(_record(
            _dnsName(hostFqdn), 1, 0x8001, ttl < 120 ? ttl : 120,
            parts.map(int.parse).toList()));
      }
    }

    final an = answers.length;
    final ar = additional.length;

    return Uint8List.fromList([
      0x00, 0x00, 0x84, 0x00,
      0x00, 0x00,
      (an >> 8) & 0xFF, an & 0xFF,
      0x00, 0x00,
      (ar >> 8) & 0xFF, ar & 0xFF,
      for (final r in answers) ...r,
      for (final r in additional) ...r,
    ]);
  }

  List<int> _dnsName(String fqdn) {
    final out = <int>[];
    for (final label in fqdn.split('.')) {
      if (label.isEmpty) continue;
      out.add(label.length);
      out.addAll(label.codeUnits);
    }
    out.add(0);
    return out;
  }

  List<int> _record(
    List<int> name,
    int type,
    int cls,
    int ttl,
    List<int> rdata,
  ) {
    return [
      ...name,
      (type >> 8) & 0xFF, type & 0xFF,
      (cls >> 8) & 0xFF, cls & 0xFF,
      (ttl >> 24) & 0xFF, (ttl >> 16) & 0xFF, (ttl >> 8) & 0xFF, ttl & 0xFF,
      (rdata.length >> 8) & 0xFF, rdata.length & 0xFF,
      ...rdata,
    ];
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/discovered_host.dart';

/// The port a MinePOS server listens on unless `MINEPOS_PORT` overrides it
/// (rare) — the only port the sweep probes.
const _defaultPort = 8080;

Future<List<DiscoveredHost>> sweepLan({
  void Function(int done, int total)? onProgress,
}) async {
  final targets = await _lanTargets();
  final found = <DiscoveredHost>[];
  final client = http.Client();
  var done = 0;
  // Cap in-flight probes so a /24 (254 hosts) doesn't open 254 sockets at
  // once; unused addresses just time out, so this bounds the wall-clock cost
  // to ~ceil(254 / concurrency) * timeout.
  const concurrency = 48;
  try {
    for (var i = 0; i < targets.length; i += concurrency) {
      await Future.wait(targets.skip(i).take(concurrency).map((ip) async {
        final host = await _probe(client, ip);
        if (host != null) found.add(host);
        onProgress?.call(++done, targets.length);
      }));
    }
  } finally {
    client.close();
  }
  return found;
}

Future<DiscoveredHost?> _probe(http.Client client, String ip) async {
  try {
    final res = await client
        .get(Uri.parse('http://$ip:$_defaultPort/health'))
        .timeout(const Duration(milliseconds: 900));
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final name = (body['shopName'] as String?)?.trim();
    return DiscoveredHost(
      name: (name == null || name.isEmpty) ? ip : name,
      address: ip,
      port: _defaultPort,
    );
  } catch (_) {
    return null;
  }
}

/// Every address on the same /24 as each of this device's real IPv4
/// interfaces (skips loopback and link-local; the device's own address is
/// left in — a station that is also the host should still show up).
Future<List<String>> _lanTargets() async {
  final ips = <String>{};
  try {
    final ifaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    for (final iface in ifaces) {
      for (final addr in iface.addresses) {
        final p = addr.address.split('.');
        if (p.length != 4) continue;
        if (p[0] == '169' && p[1] == '254') continue; // link-local
        for (var h = 1; h <= 254; h++) {
          ips.add('${p[0]}.${p[1]}.${p[2]}.$h');
        }
      }
    }
  } catch (_) {
    // NetworkInterface.list can throw on a locked-down platform — nothing to
    // sweep then; mDNS / manual entry still apply.
  }
  return ips.toList();
}

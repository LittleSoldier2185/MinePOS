import '../models/discovered_host.dart';
import 'lan_scan_stub.dart' if (dart.library.io) 'lan_scan_io.dart' as impl;

/// Probes this device's local IPv4 /24 subnet(s) for a MinePOS `/health`
/// endpoint on the default port — a multicast-free alternative to the mDNS
/// "Wi-Fi" scan for when the OS firewall or the router drops mDNS but plain
/// TCP to the LAN works fine. Returns an empty list on web (no raw socket /
/// interface enumeration there). [onProgress] fires as probes finish.
Future<List<DiscoveredHost>> sweepLan({
  void Function(int done, int total)? onProgress,
}) =>
    impl.sweepLan(onProgress: onProgress);

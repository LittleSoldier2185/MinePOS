import '../models/discovered_host.dart';

/// Web (and any platform without `dart:io`): no LAN sweep possible.
Future<List<DiscoveredHost>> sweepLan({
  void Function(int done, int total)? onProgress,
}) async =>
    const [];

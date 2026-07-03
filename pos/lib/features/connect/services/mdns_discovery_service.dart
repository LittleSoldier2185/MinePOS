import 'dart:async';

import 'package:bonsoir/bonsoir.dart';

import '../models/discovered_host.dart';

/// The service type the future MinePOS host will broadcast under; this
/// wrapper only browses for it — nothing advertises it yet, so an empty
/// result list is expected until the host server exists.
const minePosServiceType = '_minepos._tcp';

class MdnsDiscoveryService {
  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _subscription;
  final _hosts = <String, DiscoveredHost>{};
  final _hostsController = StreamController<List<DiscoveredHost>>.broadcast();

  Stream<List<DiscoveredHost>> get hosts => _hostsController.stream;

  Future<void> start() async {
    await stop();

    final discovery = BonsoirDiscovery(type: minePosServiceType);
    _discovery = discovery;
    await discovery.ready;
    _subscription = discovery.eventStream?.listen(_onEvent);
    await discovery.start();
  }

  void _onEvent(BonsoirDiscoveryEvent event) {
    final service = event.service;
    if (service == null) return;

    switch (event.type) {
      case BonsoirDiscoveryEventType.discoveryServiceFound:
        service.resolve(_discovery!.serviceResolver);
      case BonsoirDiscoveryEventType.discoveryServiceResolved:
        if (service is ResolvedBonsoirService && service.host != null) {
          _hosts[service.name] = DiscoveredHost(
            name: service.name,
            address: service.host!,
            port: service.port,
          );
          _hostsController.add(_hosts.values.toList());
        }
      case BonsoirDiscoveryEventType.discoveryServiceLost:
        _hosts.remove(service.name);
        _hostsController.add(_hosts.values.toList());
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    await _discovery?.stop();
    _discovery = null;
    _hosts.clear();
  }

  void dispose() {
    unawaited(stop());
    _hostsController.close();
  }
}

class DiscoveredHost {
  const DiscoveredHost({required this.name, required this.address, required this.port});

  final String name;
  final String address;
  final int port;

  String get displayAddress => '$address:$port';
}

class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.available = true,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final bool available;
}

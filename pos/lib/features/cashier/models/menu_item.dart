class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.available = true,
    this.imageBase64,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final bool available;

  /// Base64-encoded thumbnail image, if one was set. Kept small by
  /// downscaling at pick time.
  final String? imageBase64;

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        price: (json['price'] as num).toDouble(),
        available: json['available'] as bool? ?? true,
        imageBase64: json['imageBase64'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'price': price,
        'available': available,
        'imageBase64': imageBase64,
      };
}

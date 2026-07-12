import 'dart:ui' show Locale;

class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.available = true,
    this.imageBase64,
    this.hasSweetness = false,
    this.nameTh,
  });

  final String id;

  /// English name — always required, the fallback whenever [nameTh] is
  /// unset or the active locale isn't Thai.
  final String name;
  final String category;
  final double price;
  final bool available;

  /// Base64-encoded thumbnail image, if one was set. Kept small by
  /// downscaling at pick time.
  final String? imageBase64;

  /// Whether ordering this item prompts for a Less/Normal/Sweet choice
  /// (drinks only — set per item in Menu Management, not inferred from
  /// category, since category names are free text).
  final bool hasSweetness;

  /// Optional Thai translation of [name], set per item in Menu Management.
  final String? nameTh;

  /// The name to show for the given [locale] — Thai when set and the
  /// locale is Thai, English otherwise.
  String displayName(Locale locale) =>
      locale.languageCode == 'th' && (nameTh?.isNotEmpty ?? false)
          ? nameTh!
          : name;

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        price: (json['price'] as num).toDouble(),
        available: json['available'] as bool? ?? true,
        imageBase64: json['imageBase64'] as String?,
        hasSweetness: json['hasSweetness'] as bool? ?? false,
        nameTh: json['nameTh'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'price': price,
        'available': available,
        'imageBase64': imageBase64,
        'hasSweetness': hasSweetness,
        'nameTh': nameTh,
      };
}

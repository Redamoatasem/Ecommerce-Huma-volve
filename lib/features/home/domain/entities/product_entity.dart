import 'category_entity.dart';

class ProductEntity {
  final String id;
  final int apiId;
  final String title;
  final double price;
  final String description;
  final List<String> images;
  final String imageUrl;
  final CategoryEntity? category;
  final List<String> sizes;
  final List<String> colors;

  const ProductEntity({
    required this.id,
    this.apiId = 0,
    required this.title,
    required this.price,
    required this.description,
    required this.images,
    required this.imageUrl,
    this.category,
    this.sizes = const [],
    this.colors = const [],
  });

  /// Convenience alias for title.
  String get name => title;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ProductEntity && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ProductEntity(id: $id, title: $title, price: $price)';
}

import '../../../core/constants/api_constants.dart';
import '../domain/entities/product_entity.dart';
import 'category_model.dart';

class ProductModel extends ProductEntity {
  ProductModel({
    required super.apiId,
    required super.title,
    required super.price,
    required super.description,
    required super.images,
    String? imageUrl,
    CategoryModel? category,
    super.sizes = const [],
    super.colors = const [],
  }) : super(
         id: apiId.toString(),
         imageUrl: (imageUrl != null && imageUrl.trim().isNotEmpty)
             ? imageUrl.trim()
             : (images.isNotEmpty
                   ? images.first
                   : ApiConstants.defaultProductImageUrl),
         category: category,
       );

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final idInt = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '0') ?? 0;
    final title = (json['title'] as String?)?.trim() ?? 'Untitled Product';
    final desc =
        (json['description'] as String?)?.trim() ?? 'No description available.';
    final rawPrice = json['price'];
    final priceDouble = (rawPrice is num)
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '0.0') ?? 0.0;

    final cleanedImages = _parseImages(json['images']);
    final categoryObj = json['category'] is Map<String, dynamic>
        ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
        : null;

    return ProductModel(
      apiId: idInt,
      title: title,
      price: priceDouble,
      description: desc,
      images: cleanedImages,
      category: categoryObj,
      sizes: const [],
      colors: const [],
    );
  }

  static List<String> _parseImages(dynamic rawImages) {
    if (rawImages == null || rawImages is! List) return const [];
    final list = <String>[];
    for (final item in rawImages) {
      if (item == null) continue;
      var str = item.toString().trim();
      // Handle EscuelaJS malformed formats such as '["https://..."]'
      str = str
          .replaceAll(RegExp(r'^\["?|"?\]$'), '')
          .replaceAll(r'\"', '')
          .replaceAll('"', '')
          .trim();
      if (str.isNotEmpty &&
          (str.startsWith('http://') || str.startsWith('https://'))) {
        list.add(str);
      }
    }
    return list;
  }

  Map<String, dynamic> toJson() => {
    'id': apiId,
    'title': title,
    'price': price,
    'description': description,
    'images': images,
    if (category != null && category is CategoryModel)
      'category': (category as CategoryModel).toJson(),
  };

  ProductEntity toEntity() => this;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ProductEntity && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ProductModel(id: $apiId, title: $title, price: $price)';
}

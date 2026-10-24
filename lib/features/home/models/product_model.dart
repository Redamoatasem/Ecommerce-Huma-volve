import '../../../core/constants/api_constants.dart';
import '../../../core/dummy_data.dart';
import 'category_model.dart';

class ProductModel extends Product {
  final int apiId;
  final String title;
  final CategoryModel? category;
  final List<String> images;

  ProductModel({
    required this.apiId,
    required this.title,
    required super.price,
    required super.description,
    required this.images,
    String? imageUrl,
    this.category,
    super.colors = const [],
    super.sizes = const [],
  }) : super(
         id: apiId.toString(),
         name: title,
         imageUrl: (imageUrl != null && imageUrl.trim().isNotEmpty)
             ? imageUrl.trim()
             : (images.isNotEmpty
                   ? images.first
                   : ApiConstants.defaultProductImageUrl),
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
      colors: const [],
      sizes: const [],
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
    if (category != null) 'category': category!.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModel &&
          runtimeType == other.runtimeType &&
          apiId == other.apiId;

  @override
  int get hashCode => apiId.hashCode;

  @override
  String toString() => 'ProductModel(id: $apiId, title: $title, price: $price)';
}

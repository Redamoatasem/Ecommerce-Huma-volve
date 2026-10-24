import '../entities/category_entity.dart';
import '../entities/product_entity.dart';

abstract class HomeRepository {
  /// Fetches all available categories.
  Future<List<CategoryEntity>> getCategories();

  /// Fetches products with optional category filtering and search term query.
  Future<List<ProductEntity>> getProducts({
    int? categoryId,
    String? searchTerm,
  });
}

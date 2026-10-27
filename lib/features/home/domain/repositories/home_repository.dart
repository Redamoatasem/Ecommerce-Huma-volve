import '../entities/category_entity.dart';
import '../entities/product_entity.dart';

abstract class HomeRepository {
  /// Fetches all available categories.
  Future<List<CategoryEntity>> getCategories();

  /// Fetches products with optional category filtering, title searching, and pagination.
  Future<List<ProductEntity>> getProducts({
    int? categoryId,
    String? searchTerm,
    int? offset,
    int? limit,
  });

  /// Fetches a single product by its unique integer identifier.
  Future<ProductEntity> getProductById(int id);
}

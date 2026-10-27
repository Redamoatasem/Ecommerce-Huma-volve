import '../../../core/network/api_client.dart';
import '../data/datasources/home_remote_data_source.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

/// Legacy service facade preserving backwards compatibility while delegating
/// to Clean Architecture data source and models.
class HomeService {
  final ApiClient apiClient;
  final HomeRemoteDataSource remoteDataSource;

  HomeService({ApiClient? apiClient, HomeRemoteDataSource? remoteDataSource})
    : apiClient = apiClient ?? ApiClient(),
      remoteDataSource =
          remoteDataSource ??
          HomeRemoteDataSourceImpl(apiClient: apiClient ?? ApiClient());

  /// Fetches the list of all categories from GET /categories.
  Future<List<CategoryModel>> getCategories() async {
    return remoteDataSource.getCategories();
  }

  /// Fetches products from GET /products.
  /// Supports optional category filtering (categoryId), title searching (searchTerm),
  /// and pagination parameters (offset, limit).
  Future<List<ProductModel>> getProducts({
    int? categoryId,
    String? searchTerm,
    int? offset,
    int? limit,
  }) async {
    return remoteDataSource.getProducts(
      categoryId: categoryId,
      searchTerm: searchTerm,
      offset: offset,
      limit: limit,
    );
  }
}

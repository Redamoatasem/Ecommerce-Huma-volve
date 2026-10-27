import '../entities/product_entity.dart';
import '../repositories/home_repository.dart';

class GetProductsUseCase {
  final HomeRepository repository;

  const GetProductsUseCase(this.repository);

  Future<List<ProductEntity>> call({
    int? categoryId,
    String? searchTerm,
    int? offset,
    int? limit,
  }) async {
    return repository.getProducts(
      categoryId: categoryId,
      searchTerm: searchTerm,
      offset: offset,
      limit: limit,
    );
  }
}

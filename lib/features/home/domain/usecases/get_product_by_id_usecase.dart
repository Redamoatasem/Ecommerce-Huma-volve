import '../entities/product_entity.dart';
import '../repositories/home_repository.dart';

/// Domain usecase to fetch an individual product by its ID.
class GetProductByIdUseCase {
  final HomeRepository repository;

  GetProductByIdUseCase(this.repository);

  Future<ProductEntity> call(int id) {
    return repository.getProductById(id);
  }
}


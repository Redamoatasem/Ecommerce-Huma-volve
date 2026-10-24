import '../entities/category_entity.dart';
import '../repositories/home_repository.dart';

class GetCategoriesUseCase {
  final HomeRepository repository;

  const GetCategoriesUseCase(this.repository);

  Future<List<CategoryEntity>> call() async {
    return repository.getCategories();
  }
}

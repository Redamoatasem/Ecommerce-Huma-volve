import '../../domain/entities/category_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;

  HomeRepositoryImpl({HomeRemoteDataSource? remoteDataSource})
    : remoteDataSource = remoteDataSource ?? HomeRemoteDataSourceImpl();

  @override
  Future<List<CategoryEntity>> getCategories() async {
    final models = await remoteDataSource.getCategories();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<ProductEntity>> getProducts({
    int? categoryId,
    String? searchTerm,
  }) async {
    final models = await remoteDataSource.getProducts(
      categoryId: categoryId,
      searchTerm: searchTerm,
    );
    return models.map((model) => model.toEntity()).toList();
  }
}

import 'package:ecommerce_app_huma_volve/features/home/data/datasources/home_remote_data_source.dart';
import 'package:ecommerce_app_huma_volve/features/home/data/repositories/home_repository_impl.dart';
import 'package:ecommerce_app_huma_volve/features/home/models/category_model.dart';
import 'package:ecommerce_app_huma_volve/features/home/models/product_model.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeHomeRemoteDataSource implements HomeRemoteDataSource {
  int? lastCategoryId;
  String? lastSearchTerm;
  int? lastOffset;
  int? lastLimit;

  final sampleCategories = [
    const CategoryModel(id: 1, name: 'Shoes', image: 'shoes.jpg'),
    const CategoryModel(id: 2, name: 'Clothes', image: 'clothes.jpg'),
  ];

  final sampleProducts = [
    ProductModel(
      apiId: 10,
      title: 'Sneakers',
      price: 50.0,
      description: 'Shoes',
      images: const ['https://picsum.photos/1'],
    ),
  ];

  @override
  Future<List<CategoryModel>> getCategories() async => sampleCategories;

  @override
  Future<List<ProductModel>> getProducts({
    int? categoryId,
    String? searchTerm,
    int? offset,
    int? limit,
  }) async {
    lastCategoryId = categoryId;
    lastSearchTerm = searchTerm;
    lastOffset = offset;
    lastLimit = limit;
    return sampleProducts;
  }
}

void main() {
  late FakeHomeRemoteDataSource remoteDataSource;
  late HomeRepositoryImpl repository;

  setUp(() {
    remoteDataSource = FakeHomeRemoteDataSource();
    repository = HomeRepositoryImpl(remoteDataSource: remoteDataSource);
  });

  group('HomeRepositoryImpl', () {
    test('getCategories maps CategoryModel to CategoryEntity', () async {
      final categories = await repository.getCategories();

      expect(categories.length, 2);
      expect(categories.first.id, 1);
      expect(categories.first.name, 'Shoes');
    });

    test('getProducts passes categoryId, searchTerm, offset, and limit and maps to ProductEntity', () async {
      final products = await repository.getProducts(
        categoryId: 3,
        searchTerm: 'Nike',
        offset: 20,
        limit: 10,
      );

      expect(remoteDataSource.lastCategoryId, 3);
      expect(remoteDataSource.lastSearchTerm, 'Nike');
      expect(remoteDataSource.lastOffset, 20);
      expect(remoteDataSource.lastLimit, 10);
      expect(products.length, 1);
      expect(products.first.id, '10');
      expect(products.first.title, 'Sneakers');
    });
  });
}

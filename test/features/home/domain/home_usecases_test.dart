import 'package:ecommerce_app_huma_volve/features/home/domain/entities/category_entity.dart';
import 'package:ecommerce_app_huma_volve/features/home/domain/entities/product_entity.dart';
import 'package:ecommerce_app_huma_volve/features/home/domain/repositories/home_repository.dart';
import 'package:ecommerce_app_huma_volve/features/home/domain/usecases/get_categories_usecase.dart';
import 'package:ecommerce_app_huma_volve/features/home/domain/usecases/get_products_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeHomeDomainRepository implements HomeRepository {
  int? lastCategoryId;
  String? lastSearchTerm;
  int? lastOffset;
  int? lastLimit;

  final sampleCategories = [
    const CategoryEntity(id: 1, name: 'Shoes', image: 'shoes.jpg'),
    const CategoryEntity(id: 2, name: 'Clothes', image: 'clothes.jpg'),
  ];

  final sampleProducts = [
    const ProductEntity(
      id: '1',
      apiId: 1,
      title: 'Sneakers',
      price: 99.0,
      description: 'Sport shoes',
      images: ['img1.jpg'],
      imageUrl: 'img1.jpg',
    ),
  ];

  @override
  Future<List<CategoryEntity>> getCategories() async {
    return sampleCategories;
  }

  @override
  Future<List<ProductEntity>> getProducts({
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
  late FakeHomeDomainRepository repository;

  setUp(() {
    repository = FakeHomeDomainRepository();
  });

  group('Home Domain Use Cases', () {
    test('GetCategoriesUseCase calls repository.getCategories()', () async {
      final useCase = GetCategoriesUseCase(repository);
      final categories = await useCase();

      expect(categories.length, 2);
      expect(categories[0].name, 'Shoes');
      expect(categories[1].name, 'Clothes');
    });

    test('GetProductsUseCase passes filters, search term, offset, and limit to repository', () async {
      final useCase = GetProductsUseCase(repository);
      final products = await useCase(
        categoryId: 5,
        searchTerm: 'Running',
        offset: 10,
        limit: 20,
      );

      expect(repository.lastCategoryId, 5);
      expect(repository.lastSearchTerm, 'Running');
      expect(repository.lastOffset, 10);
      expect(repository.lastLimit, 20);
      expect(products.length, 1);
      expect(products.first.title, 'Sneakers');
    });
  });
}

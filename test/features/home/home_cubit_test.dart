import 'package:ecommerce_app_huma_volve/features/home/cubit/home_cubit.dart';
import 'package:ecommerce_app_huma_volve/features/home/cubit/home_state.dart';
import 'package:ecommerce_app_huma_volve/features/home/models/category_model.dart';
import 'package:ecommerce_app_huma_volve/features/home/models/product_model.dart';
import 'package:ecommerce_app_huma_volve/features/home/services/home_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeHomeService implements HomeService {
  List<CategoryModel> categoriesToReturn = [];
  List<ProductModel> productsToReturn = [];
  bool shouldThrow = false;
  String errorMessage = 'Failed network call';

  int? lastCategoryIdRequested;
  String? lastSearchTermRequested;
  int? lastOffsetRequested;
  int? lastLimitRequested;
  int getProductsCallCount = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<CategoryModel>> getCategories() async {
    if (shouldThrow) throw Exception(errorMessage);
    return categoriesToReturn;
  }

  @override
  Future<List<ProductModel>> getProducts({
    int? categoryId,
    String? searchTerm,
    int? offset,
    int? limit,
  }) async {
    if (shouldThrow) throw Exception(errorMessage);
    getProductsCallCount++;
    lastCategoryIdRequested = categoryId;
    lastSearchTermRequested = searchTerm;
    lastOffsetRequested = offset;
    lastLimitRequested = limit;
    return productsToReturn;
  }
}

void main() {
  late FakeHomeService fakeService;
  late HomeCubit homeCubit;

  final sampleCategories = [
    const CategoryModel(id: 1, name: 'Shoes', image: ''),
    const CategoryModel(id: 2, name: 'Clothes', image: ''),
  ];

  final sampleProducts = [
    ProductModel(
      apiId: 10,
      title: 'Sneakers',
      price: 60.0,
      description: 'Shoes',
      images: const ['https://picsum.photos/1'],
    ),
    ProductModel(
      apiId: 20,
      title: 'Jacket',
      price: 120.0,
      description: 'Outerwear',
      images: const ['https://picsum.photos/2'],
    ),
  ];

  setUp(() {
    fakeService = FakeHomeService();
    fakeService.categoriesToReturn = sampleCategories;
    fakeService.productsToReturn = sampleProducts;
    homeCubit = HomeCubit(homeService: fakeService);
  });

  tearDown(() {
    homeCubit.close();
  });

  group('HomeCubit State Transitions', () {
    test('Initial state is HomeStatus.initial with CategoryModel.all', () {
      expect(homeCubit.state.status, HomeStatus.initial);
      expect(homeCubit.state.selectedCategory, CategoryModel.all);
      expect(homeCubit.state.products, isEmpty);
    });

    test(
      'loadHomeData emits loading then success with prepended All category',
      () async {
        final states = <HomeState>[];
        final subscription = homeCubit.stream.listen(states.add);

        await homeCubit.loadHomeData();
        await Future.delayed(Duration.zero);

        expect(states.length, 2);
        expect(states[0].status, HomeStatus.loading);
        expect(states[1].status, HomeStatus.success);
        expect(states[1].products.length, 2);
        // All category is at index 0
        expect(states[1].categories.first, CategoryModel.all);
        expect(states[1].categories.length, 3);

        await subscription.cancel();
      },
    );

    test(
      'selectCategory emits loading then success with filtered products',
      () async {
        await homeCubit.loadHomeData();

        fakeService.productsToReturn = [sampleProducts[0]];

        final states = <HomeState>[];
        final subscription = homeCubit.stream.listen(states.add);

        await homeCubit.selectCategory(sampleCategories[0]);
        await Future.delayed(Duration.zero);

        expect(states.length, 2);
        expect(states[0].status, HomeStatus.loading);
        expect(states[0].selectedCategory, sampleCategories[0]);
        expect(states[1].status, HomeStatus.success);
        expect(states[1].products.length, 1);
        expect(fakeService.lastCategoryIdRequested, 1);

        await subscription.cancel();
      },
    );

    test(
      'searchProducts emits loading then success with searched products',
      () async {
        await homeCubit.loadHomeData();

        fakeService.productsToReturn = [sampleProducts[1]];

        final states = <HomeState>[];
        final subscription = homeCubit.stream.listen(states.add);

        await homeCubit.searchProducts('Jacket');
        await Future.delayed(Duration.zero);

        expect(states.length, 2);
        expect(states[0].status, HomeStatus.loading);
        expect(states[0].searchQuery, 'Jacket');
        expect(states[1].status, HomeStatus.success);
        expect(states[1].products.length, 1);
        expect(fakeService.lastSearchTermRequested, 'Jacket');

        await subscription.cancel();
      },
    );

    test('Emits failure state when homeService throws an exception', () async {
      fakeService.shouldThrow = true;
      fakeService.errorMessage = 'Connection refused';

      final states = <HomeState>[];
      final subscription = homeCubit.stream.listen(states.add);

      await homeCubit.loadHomeData();
      await Future.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0].status, HomeStatus.loading);
      expect(states[1].status, HomeStatus.failure);
      expect(states[1].errorMessage, contains('Connection refused'));
      expect(states[1].isFailure, isTrue);

      await subscription.cancel();
    });

    test('Empty products list sets isEmpty to true', () async {
      fakeService.productsToReturn = [];

      await homeCubit.loadHomeData();

      expect(homeCubit.state.status, HomeStatus.success);
      expect(homeCubit.state.products, isEmpty);
      expect(homeCubit.state.isEmpty, isTrue);
    });

    test('refresh calls service with active filter', () async {
      await homeCubit.loadHomeData();
      await homeCubit.selectCategory(sampleCategories[1]);

      fakeService.lastCategoryIdRequested = null;
      await homeCubit.refresh();

      expect(fakeService.lastCategoryIdRequested, 2);
      expect(fakeService.lastOffsetRequested, 0);
      expect(fakeService.lastLimitRequested, 10);
      expect(homeCubit.state.status, HomeStatus.success);
    });
  });

  group('HomeCubit Pagination', () {
    List<ProductModel> generateProducts(int count, {int startId = 1}) {
      return List.generate(
        count,
        (index) => ProductModel(
          apiId: startId + index,
          title: 'Product ${startId + index}',
          price: 20.0 + index,
          description: 'Desc',
          images: ['https://picsum.photos/${startId + index}'],
        ),
      );
    }

    test(
      'Initial load passes offset 0, limit 10 and sets hasReachedMax',
      () async {
        final tenProducts = generateProducts(10);
        fakeService.productsToReturn = tenProducts;

        await homeCubit.loadHomeData();

        expect(fakeService.lastOffsetRequested, 0);
        expect(fakeService.lastLimitRequested, 10);
        expect(homeCubit.state.products.length, 10);
        expect(homeCubit.state.hasReachedMax, isFalse);
      },
    );

    test(
      'Initial load with fewer than pageSize items sets hasReachedMax to true',
      () async {
        fakeService.productsToReturn = generateProducts(5);

        await homeCubit.loadHomeData();

        expect(fakeService.lastOffsetRequested, 0);
        expect(fakeService.lastLimitRequested, 10);
        expect(homeCubit.state.products.length, 5);
        expect(homeCubit.state.hasReachedMax, isTrue);
      },
    );

    test(
      'loadMoreProducts appends items and calculates offset from product count',
      () async {
        fakeService.productsToReturn = generateProducts(10, startId: 1);
        await homeCubit.loadHomeData();
        expect(homeCubit.state.products.length, 10);
        expect(homeCubit.state.hasReachedMax, isFalse);

        fakeService.productsToReturn = generateProducts(5, startId: 11);
        await homeCubit.loadMoreProducts();

        expect(fakeService.lastOffsetRequested, 10);
        expect(fakeService.lastLimitRequested, 10);
        expect(homeCubit.state.products.length, 15);
        expect(homeCubit.state.hasReachedMax, isTrue);
        expect(homeCubit.state.isLoadingMore, isFalse);
        expect(homeCubit.state.paginationErrorMessage, isNull);
      },
    );

    test('loadMoreProducts deduplicates items by ID', () async {
      fakeService.productsToReturn = generateProducts(10, startId: 1);
      await homeCubit.loadHomeData();

      // Return overlapping items (id 10 already exists)
      fakeService.productsToReturn = [
        ...generateProducts(1, startId: 10),
        ...generateProducts(2, startId: 11),
      ];
      await homeCubit.loadMoreProducts();

      // Total should be 10 + 2 = 12 (id 10 was not duplicated)
      expect(homeCubit.state.products.length, 12);
    });

    test('loadMoreProducts does nothing when hasReachedMax is true', () async {
      fakeService.productsToReturn = generateProducts(5);
      await homeCubit.loadHomeData();
      expect(homeCubit.state.hasReachedMax, isTrue);

      final callsBefore = fakeService.getProductsCallCount;
      await homeCubit.loadMoreProducts();

      expect(fakeService.getProductsCallCount, callsBefore);
    });

    test('loadMoreProducts handles failure by setting paginationErrorMessage without wiping products', () async {
      fakeService.productsToReturn = generateProducts(10);
      await homeCubit.loadHomeData();
      expect(homeCubit.state.products.length, 10);

      fakeService.shouldThrow = true;
      fakeService.errorMessage = 'Network timeout on page 2';

      await homeCubit.loadMoreProducts();

      expect(homeCubit.state.status, HomeStatus.success);
      expect(homeCubit.state.products.length, 10);
      expect(homeCubit.state.isLoadingMore, isFalse);
      expect(
        homeCubit.state.paginationErrorMessage,
        contains('Network timeout on page 2'),
      );
    });

    test(
      'selectCategory resets offset to 0 and clears pagination error',
      () async {
        fakeService.productsToReturn = generateProducts(10);
        await homeCubit.loadHomeData();

        fakeService.productsToReturn = generateProducts(3, startId: 50);
        await homeCubit.selectCategory(sampleCategories[0]);

        expect(fakeService.lastOffsetRequested, 0);
        expect(fakeService.lastLimitRequested, 10);
        expect(fakeService.lastCategoryIdRequested, sampleCategories[0].id);
        expect(homeCubit.state.products.length, 3);
        expect(homeCubit.state.hasReachedMax, isTrue);
      },
    );

    test(
      'searchProducts resets offset to 0 and re-evaluates hasReachedMax',
      () async {
        fakeService.productsToReturn = generateProducts(10);
        await homeCubit.loadHomeData();

        fakeService.productsToReturn = generateProducts(10, startId: 100);
        await homeCubit.searchProducts('phone');

        expect(fakeService.lastOffsetRequested, 0);
        expect(fakeService.lastLimitRequested, 10);
        expect(fakeService.lastSearchTermRequested, 'phone');
        expect(homeCubit.state.products.length, 10);
        expect(homeCubit.state.hasReachedMax, isFalse);
      },
    );
  });
}

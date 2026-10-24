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
  }) async {
    if (shouldThrow) throw Exception(errorMessage);
    lastCategoryIdRequested = categoryId;
    lastSearchTermRequested = searchTerm;
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
      expect(homeCubit.state.status, HomeStatus.success);
    });
  });
}

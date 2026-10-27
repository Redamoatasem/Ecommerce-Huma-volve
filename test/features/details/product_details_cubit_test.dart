import 'package:ecommerce_app_huma_volve/features/details/cubit/product_details_cubit.dart';
import 'package:ecommerce_app_huma_volve/features/details/cubit/product_details_state.dart';
import 'package:ecommerce_app_huma_volve/features/home/domain/entities/product_entity.dart';
import 'package:ecommerce_app_huma_volve/features/home/domain/repositories/home_repository.dart';
import 'package:ecommerce_app_huma_volve/features/home/domain/usecases/get_product_by_id_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeHomeRepoForDetails implements HomeRepository {
  bool shouldThrow = false;
  String errorMessage = 'Product not found';

  final sampleProduct = const ProductEntity(
    id: '42',
    apiId: 42,
    title: 'Wireless Mouse',
    price: 39.99,
    description: 'Ergonomic optical mouse',
    images: ['https://picsum.photos/42'],
    imageUrl: 'https://picsum.photos/42',
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<ProductEntity> getProductById(int id) async {
    if (shouldThrow) throw Exception(errorMessage);
    return sampleProduct;
  }
}

void main() {
  late FakeHomeRepoForDetails fakeRepo;
  late GetProductByIdUseCase useCase;
  late ProductDetailsCubit cubit;

  setUp(() {
    fakeRepo = FakeHomeRepoForDetails();
    useCase = GetProductByIdUseCase(fakeRepo);
    cubit = ProductDetailsCubit(getProductByIdUseCase: useCase);
  });

  tearDown(() {
    cubit.close();
  });

  group('ProductDetailsCubit', () {
    test(
      'Initial state is ProductDetailsStatus.initial when no product passed',
      () {
        expect(cubit.state.status, ProductDetailsStatus.initial);
        expect(cubit.state.product, isNull);
      },
    );

    test('Initial state is ProductDetailsStatus.success when initialProduct is passed', () {
      final initialCubit = ProductDetailsCubit(
        initialProduct: fakeRepo.sampleProduct,
      );
      expect(initialCubit.state.status, ProductDetailsStatus.success);
      expect(initialCubit.state.product, fakeRepo.sampleProduct);
      initialCubit.close();
    });

    test('loadProduct with ID <= 0 emits failure immediately', () async {
      final states = <ProductDetailsState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.loadProduct(0);

      expect(states.length, 1);
      expect(states.first.status, ProductDetailsStatus.failure);
      expect(states.first.errorMessage, contains('Invalid product ID'));

      await subscription.cancel();
    });

    test('loadProduct with valid ID emits loading then success', () async {
      final states = <ProductDetailsState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.loadProduct(42);
      await Future.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0].status, ProductDetailsStatus.loading);
      expect(states[1].status, ProductDetailsStatus.success);
      expect(states[1].product, fakeRepo.sampleProduct);
      expect(states[1].isSuccess, isTrue);

      await subscription.cancel();
    });

    test('loadProduct emits loading then failure on error', () async {
      fakeRepo.shouldThrow = true;
      fakeRepo.errorMessage = 'Network timeout';

      final states = <ProductDetailsState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.loadProduct(42);
      await Future.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0].status, ProductDetailsStatus.loading);
      expect(states[1].status, ProductDetailsStatus.failure);
      expect(states[1].errorMessage, contains('Network timeout'));

      await subscription.cancel();
    });
  });
}

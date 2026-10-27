import 'dart:async';
import 'dart:io';

import 'package:ecommerce_app_huma_volve/features/details/cubit/product_details_cubit.dart';
import 'package:ecommerce_app_huma_volve/features/details/screens/product_details_screen.dart';
import 'package:ecommerce_app_huma_volve/features/home/domain/entities/product_entity.dart';
import 'package:ecommerce_app_huma_volve/features/home/domain/repositories/home_repository.dart';
import 'package:ecommerce_app_huma_volve/features/home/domain/usecases/get_product_by_id_usecase.dart';
import 'package:ecommerce_app_huma_volve/features/main_navigation/screens/main_navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const transparentImage = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];

class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => MockHttpClient();
}

class MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => MockHttpClientRequest();
}

class MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = MockHttpHeaders();
  @override
  Future<HttpClientResponse> close() async => MockHttpClientResponse();
}

class MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => transparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(transparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class FakeDetailsHomeRepo implements HomeRepository {
  bool shouldFail = false;
  Completer<ProductEntity>? fetchCompleter;
  int callCount = 0;

  final sampleProduct = const ProductEntity(
    id: '42',
    apiId: 42,
    title: 'Minimalist Desk Lamp',
    price: 49.99,
    description: 'Bright workspace lighting',
    images: ['https://placehold.co/600x400'],
    imageUrl: 'https://placehold.co/600x400',
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<ProductEntity> getProductById(int id) async {
    callCount++;
    if (shouldFail) throw Exception('Product not found (ID: $id).');
    if (fetchCompleter != null) return fetchCompleter!.future;
    return sampleProduct;
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  group('ProductDetailsScreen', () {
    testWidgets('renders directly when product object is provided', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeDetailsHomeRepo();
      final cubit = ProductDetailsCubit(
        getProductByIdUseCase: GetProductByIdUseCase(fakeRepo),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProductDetailsScreen(
            product: fakeRepo.sampleProduct,
            cubit: cubit,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Minimalist Desk Lamp'), findsOneWidget);
      expect(find.text('\$49.99'), findsOneWidget);
      expect(find.text('Bright workspace lighting'), findsOneWidget);
      expect(find.text('Add to Cart'), findsOneWidget);
      // Remote repository was not called because product was already available
      expect(fakeRepo.callCount, 0);

      cubit.close();
    });

    testWidgets('loads product details by ID and shows loading indicator', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final completer = Completer<ProductEntity>();
      final fakeRepo = FakeDetailsHomeRepo()..fetchCompleter = completer;
      final cubit = ProductDetailsCubit(
        getProductByIdUseCase: GetProductByIdUseCase(fakeRepo),
      );

      await tester.pumpWidget(
        MaterialApp(home: ProductDetailsScreen(productId: 42, cubit: cubit)),
      );
      await tester.pump();

      // Verify loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading product details...'), findsOneWidget);

      // Complete fetch
      completer.complete(fakeRepo.sampleProduct);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Minimalist Desk Lamp'), findsOneWidget);
      expect(find.text('\$49.99'), findsOneWidget);

      cubit.close();
    });

    testWidgets('displays error view with retry and back to home on failure', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = FakeDetailsHomeRepo()..shouldFail = true;
      final cubit = ProductDetailsCubit(
        getProductByIdUseCase: GetProductByIdUseCase(fakeRepo),
      );

      await tester.pumpWidget(
        MaterialApp(home: ProductDetailsScreen(productId: 999, cubit: cubit)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Unable to load product'), findsOneWidget);
      expect(find.text('Product not found (ID: 999).'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);

      // Tap Retry after fixing failure
      fakeRepo.shouldFail = false;
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Minimalist Desk Lamp'), findsOneWidget);

      cubit.close();
    });

    testWidgets(
      'Back to Home navigates to MainNavigationScreen when no prior history',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeRepo = FakeDetailsHomeRepo()..shouldFail = true;
        final cubit = ProductDetailsCubit(
          getProductByIdUseCase: GetProductByIdUseCase(fakeRepo),
        );

        await tester.pumpWidget(
          MaterialApp(home: ProductDetailsScreen(productId: 999, cubit: cubit)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Back to Home'), findsOneWidget);

        // Tap Back to Home
        await tester.tap(find.text('Back to Home'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Should have replaced with MainNavigationScreen
        expect(find.byType(MainNavigationScreen), findsOneWidget);

        cubit.close();
      },
    );

    testWidgets(
      'AppBar back button navigates to MainNavigationScreen on cold-start link',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeRepo = FakeDetailsHomeRepo();
        final cubit = ProductDetailsCubit(
          getProductByIdUseCase: GetProductByIdUseCase(fakeRepo),
        );

        await tester.pumpWidget(
          MaterialApp(home: ProductDetailsScreen(productId: 42, cubit: cubit)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Minimalist Desk Lamp'), findsOneWidget);

        // Tap back button in SliverAppBar
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Since canPop is false, navigates to MainNavigationScreen
        expect(find.byType(MainNavigationScreen), findsOneWidget);

        cubit.close();
      },
    );
  });
}

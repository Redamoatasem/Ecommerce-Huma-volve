import 'dart:async';
import 'dart:io';

import 'package:ecommerce_app_huma_volve/features/home/cubit/home_cubit.dart';
import 'package:ecommerce_app_huma_volve/features/home/models/category_model.dart';
import 'package:ecommerce_app_huma_volve/features/home/models/product_model.dart';
import 'package:ecommerce_app_huma_volve/features/home/screens/home_screen.dart';
import 'package:ecommerce_app_huma_volve/features/home/services/home_service.dart';
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
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient();
  }
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

class MockHomeServiceForScreen implements HomeService {
  List<CategoryModel> categories = [
    const CategoryModel(id: 1, name: 'Shoes', image: ''),
    const CategoryModel(id: 2, name: 'Clothes', image: ''),
  ];

  List<ProductModel> products = [
    ProductModel(
      apiId: 1,
      title: 'Cool Sneakers',
      price: 55.0,
      description: 'Nice shoes',
      images: const ['https://placehold.co/600x400'],
    ),
  ];

  bool shouldFail = false;
  Completer<List<ProductModel>>? loadMoreCompleter;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<CategoryModel>> getCategories() async {
    if (shouldFail) throw Exception('Category fetch error');
    return categories;
  }

  @override
  Future<List<ProductModel>> getProducts({
    int? categoryId,
    String? searchTerm,
    int? offset,
    int? limit,
  }) async {
    if (shouldFail) throw Exception('Product fetch error');
    if (offset != null && offset > 0 && loadMoreCompleter != null) {
      return loadMoreCompleter!.future;
    }
    return products;
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  testWidgets('HomeScreen renders products, category chips, and search field', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockService = MockHomeServiceForScreen();
    final cubit = HomeCubit(homeService: mockService);

    await tester.pumpWidget(MaterialApp(home: HomeScreen(homeCubit: cubit)));

    // Initial pump and settle
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify header and UI elements
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Best trendy collection!'), findsOneWidget);
    expect(find.text('Search clothes...'), findsOneWidget);

    // Verify categories (All, Shoes, Clothes)
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Shoes'), findsOneWidget);
    expect(find.text('Clothes'), findsOneWidget);

    // Verify product card
    expect(find.text('Cool Sneakers'), findsOneWidget);
    expect(find.text('\$55.00'), findsOneWidget);

    cubit.close();
  });

  testWidgets('HomeScreen renders error state with retry button on failure', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockService = MockHomeServiceForScreen()..shouldFail = true;
    final cubit = HomeCubit(homeService: mockService);

    await tester.pumpWidget(MaterialApp(home: HomeScreen(homeCubit: cubit)));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Failed to load products'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);

    cubit.close();
  });

  testWidgets('HomeScreen renders empty state when products list is empty', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockService = MockHomeServiceForScreen()..products = [];
    final cubit = HomeCubit(homeService: mockService);

    await tester.pumpWidget(MaterialApp(home: HomeScreen(homeCubit: cubit)));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('No products found'), findsOneWidget);

    cubit.close();
  });

  testWidgets(
    'HomeScreen renders pagination loading indicator when isLoadingMore is true',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final completer = Completer<List<ProductModel>>();
      final mockService = MockHomeServiceForScreen();
      mockService.products = List.generate(
        10,
        (index) => ProductModel(
          apiId: index + 1,
          title: 'Product $index',
          price: 50.0,
          description: 'Test',
          images: const ['https://placehold.co/600x400'],
        ),
      );
      mockService.loadMoreCompleter = completer;

      final cubit = HomeCubit(homeService: mockService);

      await tester.pumpWidget(MaterialApp(home: HomeScreen(homeCubit: cubit)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(cubit.state.hasReachedMax, isFalse);

      // Trigger loadMoreProducts while completer is uncompleted
      unawaited(cubit.loadMoreProducts());
      await tester.pump(const Duration(milliseconds: 10));

      expect(cubit.state.isLoadingMore, isTrue);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the future
      completer.complete([
        ProductModel(
          apiId: 50,
          title: 'Product 50',
          price: 50.0,
          description: 'New item',
          images: const ['https://placehold.co/600x400'],
        ),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(cubit.state.isLoadingMore, isFalse);
      expect(find.text('Product 50'), findsOneWidget);

      cubit.close();
    },
  );

  testWidgets('HomeScreen renders pagination error and retry button', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockService = MockHomeServiceForScreen();
    mockService.products = List.generate(
      10,
      (index) => ProductModel(
        apiId: index + 1,
        title: 'Product $index',
        price: 50.0,
        description: 'Test',
        images: const ['https://placehold.co/600x400'],
      ),
    );
    final cubit = HomeCubit(homeService: mockService);

    await tester.pumpWidget(MaterialApp(home: HomeScreen(homeCubit: cubit)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(cubit.state.hasReachedMax, isFalse);

    // Now fail subsequent page
    mockService.shouldFail = true;
    await cubit.loadMoreProducts();
    await tester.pump();

    expect(find.text('Could not load more products'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    // Tapping retry triggers loadMoreProducts
    mockService.shouldFail = false;
    mockService.products = [
      ProductModel(
        apiId: 99,
        title: 'Product 99',
        price: 99.0,
        description: 'New page item',
        images: const ['https://placehold.co/600x400'],
      ),
    ];
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Could not load more products'), findsNothing);
    expect(find.text('Product 99'), findsOneWidget);

    cubit.close();
  });

  testWidgets(
    'HomeScreen renders end-of-list message when hasReachedMax is true',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockService = MockHomeServiceForScreen();
      final cubit = HomeCubit(homeService: mockService);

      await tester.pumpWidget(MaterialApp(home: HomeScreen(homeCubit: cubit)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('All products loaded'), findsOneWidget);

      cubit.close();
    },
  );
}

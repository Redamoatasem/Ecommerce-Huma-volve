import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ecommerce_app_huma_volve/core/constants/api_constants.dart';
import 'package:ecommerce_app_huma_volve/core/constants/api_endpoints.dart';
import 'package:ecommerce_app_huma_volve/core/network/api_client.dart';
import 'package:ecommerce_app_huma_volve/features/auth/models/auth_exception.dart';
import 'package:ecommerce_app_huma_volve/features/home/services/home_service.dart';
import 'package:flutter_test/flutter_test.dart';

class MockHttpClientAdapter implements HttpClientAdapter {
  late Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}

  static ResponseBody jsonResponse(
    dynamic data, {
    int statusCode = 200,
    Map<String, List<String>>? headers,
  }) {
    final bodyString = jsonEncode(data);
    return ResponseBody.fromString(
      bodyString,
      statusCode,
      headers: {
        'content-type': ['application/json; charset=utf-8'],
        ...?headers,
      },
    );
  }
}

void main() {
  late MockHttpClientAdapter mockAdapter;
  late Dio dio;
  late ApiClient apiClient;
  late HomeService homeService;

  setUp(() {
    mockAdapter = MockHttpClientAdapter();
    dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
    dio.httpClientAdapter = mockAdapter;
    apiClient = ApiClient(customDio: dio);
    homeService = HomeService(apiClient: apiClient);
  });

  group('HomeService - Categories', () {
    test('1. Successful category parsing and listing', () async {
      mockAdapter.handler = (options) async {
        expect(options.path, ApiEndpoints.categories);
        expect(options.method, 'GET');

        return MockHttpClientAdapter.jsonResponse([
          {
            'id': 1,
            'name': 'Clothes',
            'image': 'https://placehold.co/600x400/png',
          },
          {
            'id': 2,
            'name': 'Electronics',
            'image': 'https://placehold.co/600x400/png',
          },
        ]);
      };

      final categories = await homeService.getCategories();

      expect(categories.length, 2);
      expect(categories[0].id, 1);
      expect(categories[0].name, 'Clothes');
      expect(categories[1].id, 2);
      expect(categories[1].name, 'Electronics');
    });

    test('2. Handles category request failure gracefully', () async {
      mockAdapter.handler = (options) async {
        throw DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 500,
            data: {'message': 'Internal Server Error'},
          ),
          type: DioExceptionType.badResponse,
        );
      };

      expect(() => homeService.getCategories(), throwsA(isA<AuthException>()));
    });
  });

  group('HomeService - Products', () {
    test('3. Successful product parsing and listing', () async {
      mockAdapter.handler = (options) async {
        expect(options.path, ApiEndpoints.products);
        expect(options.method, 'GET');
        expect(options.queryParameters, isEmpty);

        return MockHttpClientAdapter.jsonResponse([
          {
            'id': 101,
            'title': 'Classic Running Shoes',
            'price': 89.99,
            'description': 'Comfortable athletic shoes',
            'category': {
              'id': 3,
              'name': 'Shoes',
              'image': 'https://placehold.co/600x400/png',
            },
            'images': [
              'https://placehold.co/600x400/1.jpg',
              'https://placehold.co/600x400/2.jpg',
            ],
          },
        ]);
      };

      final products = await homeService.getProducts();

      expect(products.length, 1);
      final p = products.first;
      expect(p.apiId, 101);
      expect(p.id, '101');
      expect(p.title, 'Classic Running Shoes');
      expect(p.name, 'Classic Running Shoes');
      expect(p.price, 89.99);
      expect(p.description, 'Comfortable athletic shoes');
      expect(p.category?.name, 'Shoes');
      expect(p.imageUrl, 'https://placehold.co/600x400/1.jpg');
      expect(p.images.length, 2);
    });

    test(
      '4. Product filtering by categoryId sends correct query parameter',
      () async {
        mockAdapter.handler = (options) async {
          expect(options.path, ApiEndpoints.products);
          expect(options.queryParameters['categoryId'], 2);

          return MockHttpClientAdapter.jsonResponse([
            {
              'id': 202,
              'title': 'Smartphone',
              'price': 499.0,
              'description': 'Latest tech',
              'images': ['https://placehold.co/600x400/phone.jpg'],
            },
          ]);
        };

        final products = await homeService.getProducts(categoryId: 2);

        expect(products.length, 1);
        expect(products.first.apiId, 202);
        expect(products.first.title, 'Smartphone');
      },
    );

    test('5. Product search by title sends correct query parameter', () async {
      mockAdapter.handler = (options) async {
        expect(options.path, ApiEndpoints.products);
        expect(options.queryParameters['title'], 'Hoodie');

        return MockHttpClientAdapter.jsonResponse([
          {
            'id': 303,
            'title': 'Classic Red Hoodie',
            'price': 45.0,
            'description': 'Warm hoodie',
            'images': ['https://placehold.co/600x400/hoodie.jpg'],
          },
        ]);
      };

      final products = await homeService.getProducts(searchTerm: 'Hoodie');

      expect(products.length, 1);
      expect(products.first.title, 'Classic Red Hoodie');
    });

    test('6. Empty product response returns an empty list', () async {
      mockAdapter.handler = (options) async {
        return MockHttpClientAdapter.jsonResponse([]);
      };

      final products = await homeService.getProducts();

      expect(products, isEmpty);
    });

    test(
      '7. Missing, null, or malformed optional product fields parsed safely',
      () async {
        mockAdapter.handler = (options) async {
          return MockHttpClientAdapter.jsonResponse([
            {
              'id': '999', // string instead of int
              'title': null, // null title
              'price': 'invalid_num', // string instead of number
              'description': null, // null description
              'category': null, // null category
              'images': [
                '["https://placehold.co/escaped.jpg"]',
              ], // malformed JSON array inside string
            },
            {
              'id': 1000,
              'images': null, // null images
            },
          ]);
        };

        final products = await homeService.getProducts();

        expect(products.length, 2);

        final p1 = products[0];
        expect(p1.apiId, 999);
        expect(p1.title, 'Untitled Product');
        expect(p1.price, 0.0);
        expect(p1.description, 'No description available.');
        expect(p1.category, isNull);
        expect(p1.imageUrl, 'https://placehold.co/escaped.jpg');

        final p2 = products[1];
        expect(p2.apiId, 1000);
        expect(p2.images, isEmpty);
        // Fallback placeholder image used when images is null/empty
        expect(p2.imageUrl, ApiConstants.defaultProductImageUrl);
      },
    );
  });
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ecommerce_app_huma_volve/core/constants/api_constants.dart';
import 'package:ecommerce_app_huma_volve/core/constants/api_endpoints.dart';
import 'package:ecommerce_app_huma_volve/core/network/api_client.dart';
import 'package:ecommerce_app_huma_volve/features/auth/models/auth_exception.dart';
import 'package:ecommerce_app_huma_volve/features/home/data/datasources/home_remote_data_source.dart';
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

  static ResponseBody jsonResponse(dynamic data, {int statusCode = 200}) {
    return ResponseBody.fromString(
      jsonEncode(data),
      statusCode,
      headers: {
        'content-type': ['application/json; charset=utf-8'],
      },
    );
  }
}

void main() {
  late MockHttpClientAdapter mockAdapter;
  late Dio dio;
  late ApiClient apiClient;
  late HomeRemoteDataSourceImpl remoteDataSource;

  setUp(() {
    mockAdapter = MockHttpClientAdapter();
    dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
    dio.httpClientAdapter = mockAdapter;
    apiClient = ApiClient(customDio: dio);
    remoteDataSource = HomeRemoteDataSourceImpl(apiClient: apiClient);
  });

  group('HomeRemoteDataSourceImpl', () {
    test('getCategories fetches and parses category models', () async {
      mockAdapter.handler = (options) async {
        expect(options.path, ApiEndpoints.categories);
        return MockHttpClientAdapter.jsonResponse([
          {'id': 1, 'name': 'Clothes', 'image': 'https://placehold.co/1'},
          {'id': 2, 'name': 'Electronics', 'image': 'https://placehold.co/2'},
        ]);
      };

      final categories = await remoteDataSource.getCategories();
      expect(categories.length, 2);
      expect(categories[0].name, 'Clothes');
      expect(categories[1].name, 'Electronics');
    });

    test('getProducts with categoryId sends query parameters', () async {
      mockAdapter.handler = (options) async {
        expect(options.path, ApiEndpoints.products);
        expect(options.queryParameters['categoryId'], 2);
        return MockHttpClientAdapter.jsonResponse([
          {
            'id': 10,
            'title': 'Laptop',
            'price': 999.0,
            'description': 'Tech',
            'images': ['https://placehold.co/laptop.jpg'],
          },
        ]);
      };

      final products = await remoteDataSource.getProducts(categoryId: 2);
      expect(products.length, 1);
      expect(products.first.title, 'Laptop');
    });

    test('getProducts with searchTerm sends query parameters', () async {
      mockAdapter.handler = (options) async {
        expect(options.path, ApiEndpoints.products);
        expect(options.queryParameters['title'], 'shoes');
        return MockHttpClientAdapter.jsonResponse([
          {
            'id': 20,
            'title': 'Running shoes',
            'price': 49.0,
            'description': 'Shoes',
            'images': ['https://placehold.co/shoes.jpg'],
          },
        ]);
      };

      final products = await remoteDataSource.getProducts(searchTerm: 'shoes');
      expect(products.length, 1);
      expect(products.first.title, 'Running shoes');
    });

    test('getCategories throws AuthException on malformed response', () async {
      mockAdapter.handler = (options) async {
        return MockHttpClientAdapter.jsonResponse({'error': 'bad'});
      };

      expect(
        () => remoteDataSource.getCategories(),
        throwsA(isA<AuthException>()),
      );
    });
  });
}

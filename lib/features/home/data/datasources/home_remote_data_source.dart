import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/models/auth_exception.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';

abstract class HomeRemoteDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<List<ProductModel>> getProducts({int? categoryId, String? searchTerm});
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final ApiClient apiClient;

  HomeRemoteDataSourceImpl({ApiClient? apiClient})
    : apiClient = apiClient ?? ApiClient();

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await apiClient.dio.get(ApiEndpoints.categories);
      final data = response.data;

      if (data == null || data is! List) {
        throw const AuthException(
          'Malformed response received for categories.',
        );
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map((json) => CategoryModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw AuthException.fromDioException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to load categories: $e');
    }
  }

  @override
  Future<List<ProductModel>> getProducts({
    int? categoryId,
    String? searchTerm,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {};

      if (categoryId != null && categoryId > 0) {
        queryParameters['categoryId'] = categoryId;
      } else if (searchTerm != null && searchTerm.trim().isNotEmpty) {
        queryParameters['title'] = searchTerm.trim();
      }

      final response = await apiClient.dio.get(
        ApiEndpoints.products,
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );

      final data = response.data;
      if (data == null || data is! List) {
        throw const AuthException('Malformed response received for products.');
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map((json) => ProductModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw AuthException.fromDioException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to load products: $e');
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/home_repository_impl.dart';
import '../domain/entities/category_entity.dart';
import '../domain/entities/product_entity.dart';
import '../domain/repositories/home_repository.dart';
import '../domain/usecases/get_categories_usecase.dart';
import '../domain/usecases/get_products_usecase.dart';
import '../models/category_model.dart';
import '../services/home_service.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  static const int pageSize = 10;

  final GetCategoriesUseCase getCategoriesUseCase;
  final GetProductsUseCase getProductsUseCase;
  final HomeService? homeService;

  int _currentRequestId = 0;

  HomeCubit({
    GetCategoriesUseCase? getCategoriesUseCase,
    GetProductsUseCase? getProductsUseCase,
    HomeRepository? repository,
    HomeService? homeService,
  }) : homeService = homeService,
       getCategoriesUseCase =
           getCategoriesUseCase ??
           (homeService != null
               ? GetCategoriesUseCase(_LegacyHomeServiceAdapter(homeService))
               : GetCategoriesUseCase(repository ?? HomeRepositoryImpl())),
       getProductsUseCase =
           getProductsUseCase ??
           (homeService != null
               ? GetProductsUseCase(_LegacyHomeServiceAdapter(homeService))
               : GetProductsUseCase(repository ?? HomeRepositoryImpl())),
       super(const HomeState());

  /// Initial load: fetches both categories and products using domain use cases.
  Future<void> loadHomeData() async {
    final requestId = ++_currentRequestId;

    emit(
      state.copyWith(
        status: HomeStatus.loading,
        clearError: true,
        clearPaginationError: true,
        isLoadingMore: false,
        hasReachedMax: false,
      ),
    );

    try {
      final results = await Future.wait([
        getCategoriesUseCase(),
        getProductsUseCase(offset: 0, limit: pageSize),
      ]);

      if (requestId != _currentRequestId) return;

      final rawCategories = results[0] as List<CategoryEntity>;
      final products = results[1] as List<ProductEntity>;

      // Prepend virtual 'All' category for full collection view
      final allCategories = [
        CategoryModel.all,
        ...rawCategories.where((c) => c.id != 0),
      ];

      final reachedMax = products.length < pageSize;

      emit(
        state.copyWith(
          status: HomeStatus.success,
          categories: allCategories,
          products: products,
          selectedCategory: CategoryModel.all,
          searchQuery: '',
          clearError: true,
          clearPaginationError: true,
          isLoadingMore: false,
          hasReachedMax: reachedMax,
        ),
      );
    } catch (e) {
      if (requestId != _currentRequestId) return;
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: e.toString(),
          isLoadingMore: false,
        ),
      );
    }
  }

  /// Filters products by category using domain use case and resets pagination.
  Future<void> selectCategory(CategoryEntity category) async {
    if (category == state.selectedCategory &&
        state.searchQuery.isEmpty &&
        state.isSuccess) {
      return;
    }

    final requestId = ++_currentRequestId;

    emit(
      state.copyWith(
        selectedCategory: category,
        status: HomeStatus.loading,
        searchQuery: '',
        clearError: true,
        clearPaginationError: true,
        products: const [],
        isLoadingMore: false,
        hasReachedMax: false,
      ),
    );

    try {
      final products = await getProductsUseCase(
        categoryId: category.id > 0 ? category.id : null,
        offset: 0,
        limit: pageSize,
      );

      if (requestId != _currentRequestId) return;

      final reachedMax = products.length < pageSize;

      emit(
        state.copyWith(
          status: HomeStatus.success,
          products: products,
          clearError: true,
          clearPaginationError: true,
          isLoadingMore: false,
          hasReachedMax: reachedMax,
        ),
      );
    } catch (e) {
      if (requestId != _currentRequestId) return;
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: e.toString(),
          isLoadingMore: false,
        ),
      );
    }
  }

  /// Searches products by title using domain use case and resets pagination.
  Future<void> searchProducts(String query) async {
    final trimmedQuery = query.trim();
    final requestId = ++_currentRequestId;

    emit(
      state.copyWith(
        searchQuery: trimmedQuery,
        status: HomeStatus.loading,
        clearError: true,
        clearPaginationError: true,
        products: const [],
        isLoadingMore: false,
        hasReachedMax: false,
      ),
    );

    try {
      final products = trimmedQuery.isNotEmpty
          ? await getProductsUseCase(
              searchTerm: trimmedQuery,
              offset: 0,
              limit: pageSize,
            )
          : await getProductsUseCase(
              categoryId: state.selectedCategory.id > 0
                  ? state.selectedCategory.id
                  : null,
              offset: 0,
              limit: pageSize,
            );

      if (requestId != _currentRequestId) return;

      final reachedMax = products.length < pageSize;

      emit(
        state.copyWith(
          status: HomeStatus.success,
          products: products,
          clearError: true,
          clearPaginationError: true,
          isLoadingMore: false,
          hasReachedMax: reachedMax,
        ),
      );
    } catch (e) {
      if (requestId != _currentRequestId) return;
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: e.toString(),
          isLoadingMore: false,
        ),
      );
    }
  }

  /// Loads the next page of products without replacing the existing list.
  Future<void> loadMoreProducts() async {
    if (state.isLoadingMore ||
        state.isLoading ||
        state.hasReachedMax ||
        !state.isSuccess) {
      return;
    }

    final requestId = _currentRequestId;

    emit(state.copyWith(isLoadingMore: true, clearPaginationError: true));

    try {
      final currentOffset = state.products.length;

      final newProducts = state.searchQuery.isNotEmpty
          ? await getProductsUseCase(
              searchTerm: state.searchQuery,
              offset: currentOffset,
              limit: pageSize,
            )
          : await getProductsUseCase(
              categoryId: state.selectedCategory.id > 0
                  ? state.selectedCategory.id
                  : null,
              offset: currentOffset,
              limit: pageSize,
            );

      if (requestId != _currentRequestId) return;

      final existingIds = state.products.map((p) => p.id).toSet();
      final uniqueNewProducts = newProducts
          .where((p) => !existingIds.contains(p.id))
          .toList();

      final combinedProducts = [...state.products, ...uniqueNewProducts];
      final reachedMax = newProducts.length < pageSize || newProducts.isEmpty;

      emit(
        state.copyWith(
          products: combinedProducts,
          isLoadingMore: false,
          hasReachedMax: reachedMax,
          clearPaginationError: true,
        ),
      );
    } catch (e) {
      if (requestId != _currentRequestId) return;
      emit(
        state.copyWith(
          isLoadingMore: false,
          paginationErrorMessage: e.toString(),
        ),
      );
    }
  }

  /// Refreshes current product list using active filter or search context.
  Future<void> refresh() async {
    final requestId = ++_currentRequestId;

    try {
      final products = state.searchQuery.isNotEmpty
          ? await getProductsUseCase(
              searchTerm: state.searchQuery,
              offset: 0,
              limit: pageSize,
            )
          : await getProductsUseCase(
              categoryId: state.selectedCategory.id > 0
                  ? state.selectedCategory.id
                  : null,
              offset: 0,
              limit: pageSize,
            );

      if (requestId != _currentRequestId) return;

      final reachedMax = products.length < pageSize;

      emit(
        state.copyWith(
          status: HomeStatus.success,
          products: products,
          hasReachedMax: reachedMax,
          isLoadingMore: false,
          clearError: true,
          clearPaginationError: true,
        ),
      );
    } catch (e) {
      if (requestId != _currentRequestId) return;
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: e.toString(),
          isLoadingMore: false,
        ),
      );
    }
  }
}

/// Private adapter wrapping legacy [HomeService] into a domain [HomeRepository].
class _LegacyHomeServiceAdapter implements HomeRepository {
  final HomeService _service;

  _LegacyHomeServiceAdapter(this._service);

  @override
  Future<List<CategoryEntity>> getCategories() async {
    return _service.getCategories();
  }

  @override
  Future<List<ProductEntity>> getProducts({
    int? categoryId,
    String? searchTerm,
    int? offset,
    int? limit,
  }) async {
    return _service.getProducts(
      categoryId: categoryId,
      searchTerm: searchTerm,
      offset: offset,
      limit: limit,
    );
  }
}

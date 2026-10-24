import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/home_repository_impl.dart';
import '../domain/entities/category_entity.dart';
import '../domain/entities/product_entity.dart';
import '../models/category_model.dart';
import '../domain/repositories/home_repository.dart';
import '../domain/usecases/get_categories_usecase.dart';
import '../domain/usecases/get_products_usecase.dart';
import '../services/home_service.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final GetCategoriesUseCase getCategoriesUseCase;
  final GetProductsUseCase getProductsUseCase;
  final HomeService? homeService;

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
    emit(state.copyWith(status: HomeStatus.loading, clearError: true));

    try {
      final results = await Future.wait([
        getCategoriesUseCase(),
        getProductsUseCase(),
      ]);

      final rawCategories = results[0] as List<CategoryEntity>;
      final products = results[1] as List;

      // Prepend virtual 'All' category for full collection view
      final allCategories = [
        CategoryModel.all,
        ...rawCategories.where((c) => c.id != 0),
      ];

      emit(
        state.copyWith(
          status: HomeStatus.success,
          categories: allCategories,
          products: products.cast(),
          selectedCategory: CategoryModel.all,
          searchQuery: '',
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: HomeStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  /// Filters products by category using domain use case.
  Future<void> selectCategory(CategoryEntity category) async {
    if (category == state.selectedCategory &&
        state.searchQuery.isEmpty &&
        state.isSuccess) {
      return;
    }

    emit(
      state.copyWith(
        selectedCategory: category,
        status: HomeStatus.loading,
        searchQuery: '',
        clearError: true,
      ),
    );

    try {
      final products = await getProductsUseCase(
        categoryId: category.id > 0 ? category.id : null,
      );

      emit(
        state.copyWith(
          status: HomeStatus.success,
          products: products,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: HomeStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  /// Searches products by title using domain use case.
  Future<void> searchProducts(String query) async {
    final trimmedQuery = query.trim();

    emit(
      state.copyWith(
        searchQuery: trimmedQuery,
        status: HomeStatus.loading,
        clearError: true,
      ),
    );

    try {
      final products = trimmedQuery.isNotEmpty
          ? await getProductsUseCase(searchTerm: trimmedQuery)
          : await getProductsUseCase(
              categoryId: state.selectedCategory.id > 0
                  ? state.selectedCategory.id
                  : null,
            );

      emit(
        state.copyWith(
          status: HomeStatus.success,
          products: products,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: HomeStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  /// Refreshes current product list using active filter or search context.
  Future<void> refresh() async {
    try {
      if (state.searchQuery.isNotEmpty) {
        final products = await getProductsUseCase(
          searchTerm: state.searchQuery,
        );
        emit(state.copyWith(status: HomeStatus.success, products: products));
      } else {
        final products = await getProductsUseCase(
          categoryId: state.selectedCategory.id > 0
              ? state.selectedCategory.id
              : null,
        );
        emit(state.copyWith(status: HomeStatus.success, products: products));
      }
    } catch (e) {
      emit(
        state.copyWith(status: HomeStatus.failure, errorMessage: e.toString()),
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
  }) async {
    return _service.getProducts(categoryId: categoryId, searchTerm: searchTerm);
  }
}

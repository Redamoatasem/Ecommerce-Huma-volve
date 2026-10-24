import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/category_model.dart';
import '../services/home_service.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeService homeService;

  HomeCubit({HomeService? homeService})
    : homeService = homeService ?? HomeService(),
      super(const HomeState());

  /// Initial load: fetches both categories and products.
  Future<void> loadHomeData() async {
    emit(state.copyWith(status: HomeStatus.loading, clearError: true));

    try {
      final results = await Future.wait([
        homeService.getCategories(),
        homeService.getProducts(),
      ]);

      final rawCategories = results[0] as List<CategoryModel>;
      final products = results[1] as List;

      // Prepend the virtual 'All' category for full collection view
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

  /// Filters products when a category chip is tapped.
  Future<void> selectCategory(CategoryModel category) async {
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
      final products = await homeService.getProducts(
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

  /// Searches products by title.
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
          ? await homeService.getProducts(searchTerm: trimmedQuery)
          : await homeService.getProducts(
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

  /// Refreshes the current product list (e.g. for pull-to-refresh).
  Future<void> refresh() async {
    try {
      if (state.searchQuery.isNotEmpty) {
        final products = await homeService.getProducts(
          searchTerm: state.searchQuery,
        );
        emit(state.copyWith(status: HomeStatus.success, products: products));
      } else {
        final products = await homeService.getProducts(
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

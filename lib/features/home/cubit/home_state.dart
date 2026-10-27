import '../domain/entities/category_entity.dart';
import '../domain/entities/product_entity.dart';
import '../models/category_model.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState {
  final HomeStatus status;
  final List<ProductEntity> products;
  final List<CategoryEntity> categories;
  final CategoryEntity selectedCategory;
  final String searchQuery;
  final String? errorMessage;
  final bool isLoadingMore;
  final bool hasReachedMax;
  final String? paginationErrorMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.products = const [],
    this.categories = const [CategoryModel.all],
    this.selectedCategory = CategoryModel.all,
    this.searchQuery = '',
    this.errorMessage,
    this.isLoadingMore = false,
    this.hasReachedMax = false,
    this.paginationErrorMessage,
  });

  bool get isLoading => status == HomeStatus.loading;
  bool get isSuccess => status == HomeStatus.success;
  bool get isFailure => status == HomeStatus.failure;
  bool get isEmpty => isSuccess && products.isEmpty;

  HomeState copyWith({
    HomeStatus? status,
    List<ProductEntity>? products,
    List<CategoryEntity>? categories,
    CategoryEntity? selectedCategory,
    String? searchQuery,
    String? errorMessage,
    bool clearError = false,
    bool? isLoadingMore,
    bool? hasReachedMax,
    String? paginationErrorMessage,
    bool clearPaginationError = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      paginationErrorMessage: clearPaginationError
          ? null
          : (paginationErrorMessage ?? this.paginationErrorMessage),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          selectedCategory == other.selectedCategory &&
          searchQuery == other.searchQuery &&
          errorMessage == other.errorMessage &&
          isLoadingMore == other.isLoadingMore &&
          hasReachedMax == other.hasReachedMax &&
          paginationErrorMessage == other.paginationErrorMessage &&
          products.length == other.products.length &&
          categories.length == other.categories.length;

  @override
  int get hashCode => Object.hash(
    status,
    selectedCategory,
    searchQuery,
    errorMessage,
    isLoadingMore,
    hasReachedMax,
    paginationErrorMessage,
    products.length,
    categories.length,
  );
}

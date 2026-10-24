import '../models/category_model.dart';
import '../models/product_model.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState {
  final HomeStatus status;
  final List<ProductModel> products;
  final List<CategoryModel> categories;
  final CategoryModel selectedCategory;
  final String searchQuery;
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.products = const [],
    this.categories = const [CategoryModel.all],
    this.selectedCategory = CategoryModel.all,
    this.searchQuery = '',
    this.errorMessage,
  });

  bool get isLoading => status == HomeStatus.loading;
  bool get isSuccess => status == HomeStatus.success;
  bool get isFailure => status == HomeStatus.failure;
  bool get isEmpty => isSuccess && products.isEmpty;

  HomeState copyWith({
    HomeStatus? status,
    List<ProductModel>? products,
    List<CategoryModel>? categories,
    CategoryModel? selectedCategory,
    String? searchQuery,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HomeState(
      status: status ?? this.status,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
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
          products.length == other.products.length &&
          categories.length == other.categories.length;

  @override
  int get hashCode => Object.hash(
    status,
    selectedCategory,
    searchQuery,
    errorMessage,
    products.length,
    categories.length,
  );
}

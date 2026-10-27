enum ProductDetailsStatus { initial, loading, success, failure }

class ProductDetailsState {
  final ProductDetailsStatus status;
  final dynamic product;
  final String? errorMessage;

  const ProductDetailsState({
    required this.status,
    this.product,
    this.errorMessage,
  });

  factory ProductDetailsState.initial() =>
      const ProductDetailsState(status: ProductDetailsStatus.initial);

  factory ProductDetailsState.loading() =>
      const ProductDetailsState(status: ProductDetailsStatus.loading);

  factory ProductDetailsState.success(dynamic product) => ProductDetailsState(
    status: ProductDetailsStatus.success,
    product: product,
  );

  factory ProductDetailsState.failure(String message) => ProductDetailsState(
    status: ProductDetailsStatus.failure,
    errorMessage: message,
  );

  bool get isLoading => status == ProductDetailsStatus.loading;
  bool get isSuccess =>
      status == ProductDetailsStatus.success && product != null;
  bool get isFailure => status == ProductDetailsStatus.failure;

  ProductDetailsState copyWith({
    ProductDetailsStatus? status,
    dynamic product,
    String? errorMessage,
  }) {
    return ProductDetailsState(
      status: status ?? this.status,
      product: product ?? this.product,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductDetailsState &&
          status == other.status &&
          product == other.product &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(status, product, errorMessage);

  @override
  String toString() =>
      'ProductDetailsState(status: $status, product: $product, errorMessage: $errorMessage)';
}

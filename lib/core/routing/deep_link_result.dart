enum DeepLinkStatus { product, invalid, unhandled }

class DeepLinkResult {
  final DeepLinkStatus status;
  final int? productId;
  final String? rawInput;
  final String? errorMessage;

  const DeepLinkResult._({
    required this.status,
    this.productId,
    this.rawInput,
    this.errorMessage,
  });

  factory DeepLinkResult.product(int id, {String? rawInput}) =>
      DeepLinkResult._(
        status: DeepLinkStatus.product,
        productId: id,
        rawInput: rawInput,
      );

  factory DeepLinkResult.invalid(String message, {String? rawInput}) =>
      DeepLinkResult._(
        status: DeepLinkStatus.invalid,
        rawInput: rawInput,
        errorMessage: message,
      );

  factory DeepLinkResult.unhandled({String? rawInput}) =>
      DeepLinkResult._(status: DeepLinkStatus.unhandled, rawInput: rawInput);

  bool get isProduct => status == DeepLinkStatus.product;
  bool get isInvalid => status == DeepLinkStatus.invalid;
  bool get isUnhandled => status == DeepLinkStatus.unhandled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeepLinkResult &&
          status == other.status &&
          productId == other.productId &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(status, productId, errorMessage);

  @override
  String toString() =>
      'DeepLinkResult(status: $status, productId: $productId, error: $errorMessage)';
}

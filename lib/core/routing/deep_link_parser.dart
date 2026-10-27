import 'deep_link_result.dart';

/// Deterministic parser and validator for application deep links.
class DeepLinkParser {
  const DeepLinkParser._();

  /// Parses a raw URL string or internal route string into a [DeepLinkResult].
  static DeepLinkResult parse(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      return DeepLinkResult.unhandled(rawInput: rawUrl);
    }

    final trimmed = rawUrl.trim();
    Uri? uri;

    try {
      if (!trimmed.contains('://') && !trimmed.startsWith('/')) {
        uri = Uri.parse('/$trimmed');
      } else {
        uri = Uri.parse(trimmed);
      }
    } catch (_) {
      return DeepLinkResult.invalid(
        'Malformed URL format: $trimmed',
        rawInput: rawUrl,
      );
    }

    return parseUri(uri, rawInput: rawUrl);
  }

  /// Parses a [Uri] into a [DeepLinkResult].
  static DeepLinkResult parseUri(Uri? uri, {String? rawInput}) {
    if (uri == null) {
      return DeepLinkResult.unhandled(rawInput: rawInput);
    }

    final input = rawInput ?? uri.toString();
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    // Check if the URL targets the products resource
    final isProductsHost = uri.host.toLowerCase() == 'products';
    final hasProductsSegment =
        segments.isNotEmpty && segments.first.toLowerCase() == 'products';

    if (!isProductsHost && !hasProductsSegment) {
      return DeepLinkResult.unhandled(rawInput: input);
    }

    // Attempt to extract product ID from path segments
    String? rawId;

    if (isProductsHost) {
      // e.g. ecommerce://products/42 -> host is 'products', path is '/42'
      if (segments.isNotEmpty) {
        rawId = segments.first;
      }
    } else if (hasProductsSegment) {
      // e.g. https://example.com/products/42 or /products/42
      if (segments.length >= 2) {
        rawId = segments[1];
      }
    }

    // Fallback: check query parameters if not present in path
    if (rawId == null || rawId.isEmpty) {
      rawId = uri.queryParameters['id'] ?? uri.queryParameters['productId'];
    }

    if (rawId == null || rawId.trim().isEmpty) {
      return DeepLinkResult.invalid(
        'Missing product ID in URL.',
        rawInput: input,
      );
    }

    final parsedId = int.tryParse(rawId.trim());
    if (parsedId == null) {
      return DeepLinkResult.invalid(
        "Invalid product ID: '$rawId'. Expected a positive integer.",
        rawInput: input,
      );
    }

    if (parsedId <= 0) {
      return DeepLinkResult.invalid(
        'Product ID must be greater than zero. Received: $parsedId.',
        rawInput: input,
      );
    }

    return DeepLinkResult.product(parsedId, rawInput: input);
  }
}


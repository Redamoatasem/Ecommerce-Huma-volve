import 'package:ecommerce_app_huma_volve/core/routing/deep_link_parser.dart';
import 'package:ecommerce_app_huma_volve/core/routing/deep_link_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeepLinkParser', () {
    test('parses valid HTTPS URL', () {
      final result = DeepLinkParser.parse('https://example.com/products/42');
      expect(result.status, DeepLinkStatus.product);
      expect(result.productId, 42);
      expect(result.isProduct, isTrue);
    });

    test('parses valid HTTP URL', () {
      final result = DeepLinkParser.parse('http://example.com/products/100');
      expect(result.status, DeepLinkStatus.product);
      expect(result.productId, 100);
    });

    test('parses custom scheme ecommerce://products/42', () {
      final result = DeepLinkParser.parse('ecommerce://products/42');
      expect(result.status, DeepLinkStatus.product);
      expect(result.productId, 42);
    });

    test(
      'parses custom scheme with domain ecommerce://example.com/products/42',
      () {
        final result = DeepLinkParser.parse(
          'ecommerce://example.com/products/42',
        );
        expect(result.status, DeepLinkStatus.product);
        expect(result.productId, 42);
      },
    );

    test('parses internal route string /products/42', () {
      final result = DeepLinkParser.parse('/products/42');
      expect(result.status, DeepLinkStatus.product);
      expect(result.productId, 42);
    });

    test('parses relative route string products/42', () {
      final result = DeepLinkParser.parse('products/42');
      expect(result.status, DeepLinkStatus.product);
      expect(result.productId, 42);
    });

    test('handles trailing slashes /products/42/', () {
      final result = DeepLinkParser.parse('https://example.com/products/42/');
      expect(result.status, DeepLinkStatus.product);
      expect(result.productId, 42);
    });

    test('extracts product ID from query parameter ?id=42', () {
      final result = DeepLinkParser.parse('https://example.com/products?id=42');
      expect(result.status, DeepLinkStatus.product);
      expect(result.productId, 42);
    });

    test('extracts product ID from query parameter ?productId=42', () {
      final result = DeepLinkParser.parse('ecommerce://products?productId=42');
      expect(result.status, DeepLinkStatus.product);
      expect(result.productId, 42);
    });

    test('returns invalid result when ID is non-integer', () {
      final result = DeepLinkParser.parse('https://example.com/products/abc');
      expect(result.status, DeepLinkStatus.invalid);
      expect(result.isInvalid, isTrue);
      expect(result.errorMessage, contains("Invalid product ID: 'abc'"));
    });

    test('returns invalid result when ID is negative', () {
      final result = DeepLinkParser.parse('https://example.com/products/-5');
      expect(result.status, DeepLinkStatus.invalid);
      expect(result.errorMessage, contains('greater than zero'));
    });

    test('returns invalid result when ID is zero', () {
      final result = DeepLinkParser.parse('https://example.com/products/0');
      expect(result.status, DeepLinkStatus.invalid);
      expect(result.errorMessage, contains('greater than zero'));
    });

    test('returns invalid result when product path has no ID', () {
      final result = DeepLinkParser.parse('https://example.com/products');
      expect(result.status, DeepLinkStatus.invalid);
      expect(result.errorMessage, contains('Missing product ID'));
    });

    test('returns unhandled result for unrelated paths', () {
      expect(DeepLinkParser.parse('/home').isUnhandled, isTrue);
      expect(DeepLinkParser.parse('/login').isUnhandled, isTrue);
      expect(
        DeepLinkParser.parse('https://example.com/categories/1').isUnhandled,
        isTrue,
      );
      expect(DeepLinkParser.parse('/').isUnhandled, isTrue);
    });

    test('returns unhandled result for null or empty input', () {
      expect(DeepLinkParser.parse(null).isUnhandled, isTrue);
      expect(DeepLinkParser.parse('').isUnhandled, isTrue);
      expect(DeepLinkParser.parse('   ').isUnhandled, isTrue);
    });
  });
}

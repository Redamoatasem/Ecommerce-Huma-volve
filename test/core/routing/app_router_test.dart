import 'package:ecommerce_app_huma_volve/core/routing/app_router.dart';
import 'package:ecommerce_app_huma_volve/features/details/screens/product_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppRouter onGenerateRoute', () {
    test('routes null or empty or / to SplashScreen', () {
      final routeNull = AppRouter.onGenerateRoute(
        const RouteSettings(name: null),
      );
      expect(routeNull, isA<MaterialPageRoute>());

      final routeSlash = AppRouter.onGenerateRoute(
        const RouteSettings(name: '/'),
      );
      expect(routeSlash, isA<MaterialPageRoute>());
    });

    test('routes valid product deep link to ProductDetailsScreen', () {
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: 'https://example.com/products/42'),
      );
      expect(route, isA<MaterialPageRoute>());
      final materialRoute = route as MaterialPageRoute;
      final widget = materialRoute.builder(_FakeBuildContext());
      expect(widget, isA<ProductDetailsScreen>());
      final screen = widget as ProductDetailsScreen;
      expect(screen.productId, 42);
    });

    test(
      'routes invalid product deep link to ProductDetailsScreen with error',
      () {
        final route = AppRouter.onGenerateRoute(
          const RouteSettings(name: 'https://example.com/products/abc'),
        );
        expect(route, isA<MaterialPageRoute>());
        final materialRoute = route as MaterialPageRoute;
        final widget = materialRoute.builder(_FakeBuildContext());
        expect(widget, isA<ProductDetailsScreen>());
        final screen = widget as ProductDetailsScreen;
        expect(screen.productId, isNull);
        expect(
          screen.initialErrorMessage,
          contains("Invalid product ID: 'abc'"),
        );
      },
    );
  });

  group('AppRouter handleUri while app is running', () {
    testWidgets(
      'handleUri pushes ProductDetailsScreen onto running navigator',
      (tester) async {
        final navKey = GlobalKey<NavigatorState>();

        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navKey,
            home: const Scaffold(body: Text('Current Screen')),
          ),
        );
        await tester.pump();

        expect(find.text('Current Screen'), findsOneWidget);

        final handled = AppRouter.handleUri(
          Uri.parse('ecommerce://products/99'),
          navKey: navKey,
        );
        expect(handled, isTrue);

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(ProductDetailsScreen), findsOneWidget);
      },
    );

    testWidgets('handleUri ignores unhandled URIs', (tester) async {
      final navKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: const Scaffold(body: Text('Current Screen')),
        ),
      );
      await tester.pump();

      final handled = AppRouter.handleUri(
        Uri.parse('https://example.com/about'),
        navKey: navKey,
      );
      expect(handled, isFalse);
    });
  });
}

class _FakeBuildContext extends Fake implements BuildContext {}

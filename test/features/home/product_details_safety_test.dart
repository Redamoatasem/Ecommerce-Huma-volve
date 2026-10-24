import 'package:ecommerce_app_huma_volve/core/dummy_data.dart';
import 'package:ecommerce_app_huma_volve/features/details/screens/product_details_screen.dart';
import 'package:ecommerce_app_huma_volve/features/home/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'ProductDetailsScreen renders safely without crashing when colors and sizes are empty',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Product with zero colors and zero sizes (typical EscuelaJS API item)
      final apiProduct = ProductModel(
        apiId: 42,
        title: 'Minimalist Desk Lamp',
        price: 29.99,
        description: 'Bright LED lamp for workspace',
        images: const ['https://placehold.co/600x400'],
        colors: const [],
        sizes: const [],
      );

      await tester.pumpWidget(
        MaterialApp(home: ProductDetailsScreen(product: apiProduct)),
      );

      // Verify it renders the details without throwing StateError on .first
      expect(find.text('Minimalist Desk Lamp'), findsOneWidget);
      expect(find.text('\$29.99'), findsOneWidget);
      expect(find.text('Bright LED lamp for workspace'), findsOneWidget);

      // Verify fallback labels
      expect(find.text('Standard color / Not specified'), findsOneWidget);
      expect(find.text('One size fits all'), findsOneWidget);

      // Verify Add to Cart button is present
      expect(find.text('Add to Cart'), findsOneWidget);
    },
  );

  testWidgets(
    'ProductDetailsScreen renders color and size selectors when options are provided',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Product with color and size options
      final dummyItem = Product(
        id: '99',
        name: 'Custom T-Shirt',
        description: 'Cotton shirt',
        price: 19.99,
        imageUrl: 'https://placehold.co/600x400',
        colors: const [Colors.red, Colors.blue],
        sizes: const ['M', 'L'],
      );

      await tester.pumpWidget(
        MaterialApp(home: ProductDetailsScreen(product: dummyItem)),
      );

      expect(find.text('Custom T-Shirt'), findsOneWidget);
      expect(find.text('M'), findsOneWidget);
      expect(find.text('L'), findsOneWidget);
    },
  );
}

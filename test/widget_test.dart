import 'package:ecommerce_app_huma_volve/core/network/api_client.dart';
import 'package:ecommerce_app_huma_volve/core/storage/token_storage.dart';
import 'package:ecommerce_app_huma_volve/features/auth/login/screens/login_screen.dart';
import 'package:ecommerce_app_huma_volve/features/auth/services/auth_service.dart';
import 'package:ecommerce_app_huma_volve/features/auth/sign_up/screens/sign_up_screen.dart';
import 'package:ecommerce_app_huma_volve/features/splash/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SplashScreen renders title and tagline', (WidgetTester tester) async {
    final mockAuth = AuthService(
      apiClient: ApiClient(),
      tokenStorage: InMemoryTokenStorage(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(authService: mockAuth),
      ),
    );

    // Verify SplashScreen visual identity
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Huma-volve'), findsOneWidget);
    expect(find.text('Your Ultimate E-Commerce App'), findsOneWidget);

    // Fast-forward pending 2-second timer to avoid pending timer error
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });

  testWidgets('LoginScreen displays required fields and executes form validation',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockAuth = AuthService(
      apiClient: ApiClient(),
      tokenStorage: InMemoryTokenStorage(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(authService: mockAuth),
      ),
    );

    // Verify initial layout
    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text('Login to continue your shopping'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    // Trigger validation with empty inputs
    await tester.tap(find.text('Login'));
    await tester.pump();

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);

    // Enter invalid email format
    await tester.enterText(find.byType(TextFormField).first, 'invalidemail');
    await tester.tap(find.text('Login'));
    await tester.pump();

    expect(find.text('Please enter a valid email'), findsOneWidget);

    // Enter short password
    await tester.enterText(find.byType(TextFormField).last, '12345');
    await tester.tap(find.text('Login'));
    await tester.pump();

    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
  });

  testWidgets('SignUpScreen displays required fields and executes form validation',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockAuth = AuthService(
      apiClient: ApiClient(),
      tokenStorage: InMemoryTokenStorage(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SignUpScreen(authService: mockAuth),
      ),
    );

    // Verify initial layout
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Sign up to get started'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    // Trigger validation with empty inputs
    await tester.tap(find.text('Sign Up'));
    await tester.pump();

    expect(find.text('Please enter your full name'), findsOneWidget);
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });
}

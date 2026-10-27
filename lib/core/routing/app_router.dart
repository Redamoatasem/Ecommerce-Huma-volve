import 'package:flutter/material.dart';

import '../../features/auth/login/screens/login_screen.dart';
import '../../features/details/screens/product_details_screen.dart';
import '../../features/main_navigation/screens/main_navigation_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import 'deep_link_parser.dart';

/// Centralized application router and deep link dispatcher.
class AppRouter {
  const AppRouter._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Handles route generation for initial launch (cold start) and named navigation.
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name;

    if (routeName == null ||
        routeName.isEmpty ||
        routeName == '/' ||
        routeName == '/splash') {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const SplashScreen(),
      );
    }

    if (routeName == '/home' || routeName == '/main') {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const MainNavigationScreen(),
      );
    }

    if (routeName == '/login') {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const LoginScreen(),
      );
    }

    final result = DeepLinkParser.parse(routeName);

    if (result.isProduct) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => ProductDetailsScreen(productId: result.productId),
      );
    }

    if (result.isInvalid) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => ProductDetailsScreen(
          productId: null,
          initialErrorMessage: result.errorMessage,
        ),
      );
    }

    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const SplashScreen(),
    );
  }

  /// Handles incoming URIs when the application is already running in background or foreground.
  static bool handleUri(Uri uri, {GlobalKey<NavigatorState>? navKey}) {
    final key = navKey ?? navigatorKey;
    final state = key.currentState;
    if (state == null) return false;

    final result = DeepLinkParser.parseUri(uri);

    if (result.isProduct) {
      state.push(
        MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(productId: result.productId),
        ),
      );
      return true;
    }

    if (result.isInvalid) {
      state.push(
        MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(
            productId: null,
            initialErrorMessage: result.errorMessage,
          ),
        ),
      );
      return true;
    }

    return false;
  }
}


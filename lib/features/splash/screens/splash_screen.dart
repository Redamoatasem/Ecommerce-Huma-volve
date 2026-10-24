import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../auth/data/repositories/auth_repository_impl.dart';
import '../../auth/domain/usecases/check_session_usecase.dart';
import '../../auth/login/screens/login_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../main_navigation/screens/main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  final CheckSessionUseCase? checkSessionUseCase;
  final AuthService? authService;

  const SplashScreen({super.key, this.checkSessionUseCase, this.authService});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final CheckSessionUseCase _checkSessionUseCase;

  @override
  void initState() {
    super.initState();
    _checkSessionUseCase =
        widget.checkSessionUseCase ??
        (widget.authService?.checkSessionUseCase ??
            CheckSessionUseCase(AuthRepositoryImpl()));
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Retain minimum display delay for smooth UX transition
    await Future.delayed(const Duration(seconds: 2));

    final hasValidSession = await _checkSessionUseCase();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => hasValidSession
            ? const MainNavigationScreen()
            : const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag, size: 120, color: AppTheme.primary),
            const SizedBox(height: 24),
            Text(
              'Huma-volve',
              style: Theme.of(context).textTheme.displayLarge
                  ?.copyWith(fontSize: 40, color: AppTheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Ultimate E-Commerce App',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}

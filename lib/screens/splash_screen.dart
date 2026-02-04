import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:ismart_shop/providers/auth_provider.dart';
import 'package:ismart_shop/utils/ios_theme.dart';
import 'onboarding_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToScreen();
  }

  Future<void> _navigateToScreen() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    // Check if already authenticated (demo mode or Firebase user)
    if (authProvider.isAuthenticated) {
      // In demo mode, userModel is already set
      // In Firebase mode, authStateChanges should have loaded user data
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (_) => const MainScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IOSColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(IOSBorderRadius.xxxl),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.store,
                size: 64,
                color: IOSColors.primary,
              ),
            ),
            const SizedBox(height: IOSSpacing.xl),
            // App Name
            const Text(
              'iSmart Shop',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: IOSSpacing.sm),
            // Tagline
            const Text(
              'Your Intelligent Shop Assistant',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: IOSSpacing.xxxl),
            // Loading indicator
            const CupertinoActivityIndicator(
              color: Colors.white,
              radius: 20,
            ),
          ],
        ),
      ),
    );
  }
}

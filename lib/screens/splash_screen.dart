import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:ismart_shop/providers/auth_provider.dart';
import 'package:ismart_shop/utils/ios_theme.dart';
import 'onboarding_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showFirebaseWarning = false;

  @override
  void initState() {
    super.initState();
    _navigateToScreen();
  }

  Future<void> _navigateToScreen() async {
    // Wait briefly for Firebase to initialize and check auth state
    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    // Check if Firebase failed to initialize
    if (!authProvider.isFirebaseReady) {
      debugPrint('Firebase not initialized - showing warning');
      if (mounted) {
        setState(() {
          _showFirebaseWarning = true;
        });
      }
    }

    if (!mounted) return;

    // Check if user is already signed in (from previous session)
    // This keeps user logged in even after app refresh
    if (authProvider.isSignedIn) {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (_) => const HomeScreen()),
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
            // Firebase Warning
            if (_showFirebaseWarning)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: IOSSpacing.xl),
                padding: const EdgeInsets.all(IOSSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(IOSBorderRadius.large),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber, color: Colors.white, size: 20),
                    SizedBox(width: IOSSpacing.sm),
                    Flexible(
                      child: Text(
                        'Firebase not configured - App will run in demo mode',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
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

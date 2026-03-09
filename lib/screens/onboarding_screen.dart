import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:ismart_shop/providers/language_provider.dart';
import 'package:ismart_shop/utils/ios_theme.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate responsive dimensions
    final illustrationHeight = screenHeight * 0.22;
    final iconSize = screenWidth * 0.15;
    final buttonHeight = screenHeight * 0.07;
    final featureIconSize = screenWidth * 0.12;

    // Ensure minimum and maximum values
    final clampedIllustrationHeight = illustrationHeight.clamp(140.0, 220.0);
    final clampedIconSize = iconSize.clamp(60.0, 100.0);
    final clampedButtonHeight = buttonHeight.clamp(48.0, 64.0);
    final clampedFeatureIconSize = featureIconSize.clamp(40.0, 50.0);

    final languageProvider = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: IOSColors.systemBackground,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.06,
            vertical: screenHeight * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Language Selection at top right
              Align(
                alignment: Alignment.topRight,
                child: CupertinoButton(
                  onPressed: () {
                    _showLanguagePicker(context, languageProvider);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.globe,
                        color: IOSColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        languageProvider.getLanguageName(
                          languageProvider.currentLanguage,
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: IOSColors.primary,
                        ),
                      ),
                      const Icon(
                        CupertinoIcons.chevron_down,
                        color: IOSColors.primary,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              // Illustration
              Container(
                height: clampedIllustrationHeight,
                decoration: BoxDecoration(
                  color: IOSColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(IOSBorderRadius.xxxl),
                ),
                child: Center(
                  child: Container(
                    width: clampedIconSize,
                    height: clampedIconSize,
                    decoration: BoxDecoration(
                      color: IOSColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(IOSBorderRadius.xxxl),
                    ),
                    child: Icon(
                      Icons.store,
                      size: clampedIconSize * 0.5,
                      color: IOSColors.primary,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.03),
              // Welcome text
              const Text(
                'Welcome to iSmart Shop',
                style: IOSTextStyles.title1,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.008),
              const Text(
                'Your intelligent assistant for managing shop transactions',
                style: IOSTextStyles.subheadline,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.03),
              // Features list
              _buildFeatureTile(
                CupertinoIcons.mic_fill,
                'Record transactions by voice',
                'Speak naturally in English or Luganda',
                clampedFeatureIconSize,
              ),
              SizedBox(height: screenHeight * 0.015),
              _buildFeatureTile(
                CupertinoIcons.pencil,
                'Enter transactions manually',
                'Quick and easy text entry',
                clampedFeatureIconSize,
              ),
              SizedBox(height: screenHeight * 0.015),
              _buildFeatureTile(
                CupertinoIcons.chart_bar,
                'View sales reports & analytics',
                'Track your business performance',
                clampedFeatureIconSize,
              ),
              SizedBox(height: screenHeight * 0.015),
              _buildFeatureTile(
                CupertinoIcons.lock_shield_fill,
                'Secure & private',
                'Your data is always protected',
                clampedFeatureIconSize,
              ),
              const Spacer(),
              // Get Started button
              SizedBox(
                height: clampedButtonHeight,
                child: CupertinoButton.filled(
                  onPressed: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile(
      IconData icon, String title, String subtitle, double iconSize) {
    return Container(
      padding: const EdgeInsets.all(IOSSpacing.md),
      decoration: BoxDecoration(
        color: IOSColors.secondarySystemBackground,
        borderRadius: BorderRadius.circular(IOSBorderRadius.large),
        border: Border.all(
          color: IOSColors.labelQuaternary.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(iconSize * 0.15),
            decoration: BoxDecoration(
              color: IOSColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
            ),
            child: Icon(icon, color: IOSColors.primary, size: iconSize * 0.5),
          ),
          const SizedBox(width: IOSSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: IOSColors.labelPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: IOSColors.labelSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(
    BuildContext context,
    LanguageProvider languageProvider,
  ) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => Container(
        height: 200,
        decoration: const BoxDecoration(
          color: IOSColors.systemBackground,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(IOSBorderRadius.large),
          ),
        ),
        child: CupertinoPicker(
          itemExtent: 44,
          onSelectedItemChanged: (index) {
            final languages = ['en', 'lg'];
            if (index < languages.length) {
              languageProvider.setLanguage(languages[index]);
            }
          },
          children: [
            Center(
              child: Text(
                'English',
                style: TextStyle(
                  fontSize: 17,
                  color: languageProvider.currentLanguage == 'en'
                      ? IOSColors.labelPrimary
                      : IOSColors.labelTertiary,
                ),
              ),
            ),
            Center(
              child: Text(
                'Luganda',
                style: TextStyle(
                  fontSize: 17,
                  color: languageProvider.currentLanguage == 'lg'
                      ? IOSColors.labelPrimary
                      : IOSColors.labelTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

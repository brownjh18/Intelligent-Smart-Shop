import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:ismart_shop/providers/auth_provider.dart';
import 'package:ismart_shop/providers/transaction_provider.dart';
import 'package:ismart_shop/providers/language_provider.dart';
import 'package:ismart_shop/services/speech_service.dart';
import 'package:ismart_shop/services/nlp_service.dart';
import 'package:ismart_shop/services/translation_service.dart';
import 'package:ismart_shop/utils/ios_theme.dart';
import 'package:ismart_shop/widgets/ios_app_bar.dart';
import 'transaction_review_screen.dart';
import 'home_screen.dart';

class VoiceRecordingScreen extends StatefulWidget {
  const VoiceRecordingScreen({super.key});

  @override
  State<VoiceRecordingScreen> createState() => _VoiceRecordingScreenState();
}

class _VoiceRecordingScreenState extends State<VoiceRecordingScreen> {
  final SpeechService _speechService = SpeechService();
  String _transcribedText = '';
  bool _isInitialized = false;
  String _statusMessage = 'Tap to start recording';

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    await _speechService.initialize();
    setState(() {
      _isInitialized = _speechService.isAvailable;
      if (!_isInitialized) {
        _statusMessage = 'Speech recognition not available';
      }
    });
  }

  Future<void> _toggleRecording() async {
    if (_speechService.isListening) {
      await _speechService.stopListening();
      setState(() {
        _statusMessage = 'Processing...';
      });
      _navigateToReview();
    } else {
      final languageProvider = context.read<LanguageProvider>();
      final localeId =
          languageProvider.currentLanguage == 'lg' ? 'lg' : 'en_US';
      await _speechService.startListening(localeId: localeId);
      setState(() {
        _statusMessage = 'Listening...';
      });
    }
  }

  void _navigateToReview() {
    final processedText = TranslationService.processText(
      _transcribedText,
      context.read<LanguageProvider>().currentLanguage,
    );

    final intent = NLPService.parseTransaction(processedText);

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => TransactionReviewScreen(
          transcribedText: _transcribedText,
          transactionIntent: intent,
        ),
      ),
    );
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        backgroundColor: IOSColors.secondarySystemBackground,
        appBar: IOSLargeTitleNavigationBar(
          title: 'Record Transaction',
          onBackPressed: _navigateToHome,
        ),
        body: Padding(
          padding: const EdgeInsets.all(IOSSpacing.xl),
          child: Column(
            children: [
              const Spacer(),
              // Recording status and microphone button
              Center(
                child: Column(
                  children: [
                    // Microphone button
                    GestureDetector(
                      onTap: _isInitialized ? _toggleRecording : null,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _speechService.isListening
                                ? [IOSColors.primary, IOSColors.primaryDark]
                                : [
                                    IOSColors.primary.withOpacity(0.8),
                                    IOSColors.primary.withOpacity(0.6)
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(80),
                          boxShadow: [
                            BoxShadow(
                              color: _speechService.isListening
                                  ? IOSColors.primary.withOpacity(0.5)
                                  : IOSColors.primary.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            _speechService.isListening
                                ? CupertinoIcons.stop_fill
                                : CupertinoIcons.mic_fill,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: IOSSpacing.xl),
                    // Status message
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: IOSSpacing.xl,
                        vertical: IOSSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: IOSColors.systemBackground,
                        borderRadius:
                            BorderRadius.circular(IOSBorderRadius.large),
                        border: Border.all(
                          color: IOSColors.labelQuaternary.withOpacity(0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        _statusMessage,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: IOSColors.labelPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: IOSSpacing.md),
                    // Language indicator
                    Consumer<LanguageProvider>(
                      builder: (context, languageProvider, _) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: IOSSpacing.md,
                            vertical: IOSSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: IOSColors.primary.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(IOSBorderRadius.circular),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                CupertinoIcons.globe,
                                color: IOSColors.primary,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                languageProvider.getLanguageName(
                                  languageProvider.currentLanguage,
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: IOSColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Transcribed text preview
              if (_transcribedText.isNotEmpty) ...[
                IOSCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            CupertinoIcons.textformat,
                            color: IOSColors.primary,
                            size: 18,
                          ),
                          SizedBox(width: IOSSpacing.sm),
                          Text(
                            'Transcribed Text:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: IOSColors.labelSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: IOSSpacing.sm),
                      Text(
                        '"$_transcribedText"',
                        style: const TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: IOSColors.labelPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: IOSSpacing.md),
              ],
              // Instructions
              IOSCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          CupertinoIcons.lightbulb_fill,
                          color: IOSColors.warning,
                          size: 18,
                        ),
                        SizedBox(width: IOSSpacing.sm),
                        Text(
                          'Example phrases:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: IOSColors.labelPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: IOSSpacing.sm),
                    _buildExample('"Sold bread for 5000 shillings"'),
                    _buildExample('"Spent 20000 on transport"'),
                    _buildExample('"Sold milk to customer for 3000"'),
                  ],
                ),
              ),
              const SizedBox(height: IOSSpacing.xl),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          height: 80,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: IOSColors.systemBackground.withOpacity(0.95),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, CupertinoIcons.house, 'Home'),
                _buildNavItem(1, CupertinoIcons.list_bullet, 'Transactions'),
                _buildNavItem(2, CupertinoIcons.chart_bar, 'Reports'),
                _buildNavItem(3, CupertinoIcons.settings, 'Settings'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExample(String example) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: IOSSpacing.xs),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.chevron_right,
            size: 12,
            color: IOSColors.labelTertiary,
          ),
          const SizedBox(width: IOSSpacing.xs),
          Text(
            example,
            style: const TextStyle(
              color: IOSColors.labelSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        _navigateToHome();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: index == 0
              ? IOSColors.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: index == 0 ? 24 : 22,
              color: index == 0 ? IOSColors.primary : IOSColors.labelTertiary,
            ),
            if (index == 0) const SizedBox(width: 8),
            if (index == 0)
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: IOSColors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

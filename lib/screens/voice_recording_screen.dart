import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
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

class _VoiceRecordingScreenState extends State<VoiceRecordingScreen>
    with TickerProviderStateMixin {
  final SpeechService _speechService = SpeechService();
  String _transcribedText = '';
  bool _isInitialized = false;
  bool _isListening = false;
  String _statusMessage = 'Tap the microphone to start';
  bool _isInitializing = false;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeSpeech();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reinitialize speech if needed when screen becomes visible
    if (!_isInitializing && !_isInitialized) {
      _initializeSpeech();
    }
  }

  void _initializeAnimations() {
    // Pulse animation for the recording button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Wave animation for sound visualization
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _speechService.stopListening();
    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    // Prevent multiple simultaneous initializations
    if (_isInitializing) return;

    _isInitializing = true;
    try {
      // Reset speech service state first
      _speechService.reset();

      final success = await _speechService.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = success;
          if (!_isInitialized) {
            _statusMessage = 'Voice not available. Try on physical device.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _statusMessage = 'Voice initialization failed. Try again.';
        });
      }
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _startRecording() async {
    // If already listening, stop first
    if (_isListening) {
      await _stopRecording();
      return;
    }

    // Attempt real speech recognition first - try to initialize if not done
    if (!_isInitialized) {
      await _initializeSpeech();
      if (!_isInitialized) {
        _showErrorDialog(
            'Speech recognition is not available. Please use a physical device with microphone and internet connection, or check app permissions.');
        return;
      }
    }

    final languageProvider = context.read<LanguageProvider>();
    final localeId = languageProvider.currentLanguage == 'lg' ? 'lg' : 'en_US';

    final success = await _speechService.startListening(localeId: localeId);

    if (success) {
      setState(() {
        _isListening = true;
        _transcribedText = '';
        _statusMessage = 'Listening... Speak now';
      });
      _pulseController.repeat(reverse: true);
      _waveController.repeat();
    } else {
      // Show more detailed error information
      final errorMsg = _speechService.lastError.isNotEmpty
          ? _speechService.lastError
          : 'Unknown error';
      final statusMsg = _speechService.lastStatus.isNotEmpty
          ? _speechService.lastStatus
          : 'No status';

      // Provide more helpful error messages
      String helpfulMessage;
      if (errorMsg.contains('not available') ||
          errorMsg.contains('unavailable')) {
        helpfulMessage =
            'Speech recognition is not available on this device.\n\nPlease ensure:\n• You are using a physical device\n• Microphone permission is granted\n• Internet connection is available';
      } else if (errorMsg.contains('timeout')) {
        helpfulMessage =
            'No speech detected. Please speak clearly and try again.';
      } else {
        helpfulMessage =
            'Failed to start recording.\n\nError: $errorMsg\nStatus: $statusMsg';
      }

      _showErrorDialog(helpfulMessage);

      // Reset state on error
      setState(() {
        _statusMessage = 'Tap the microphone to try again';
      });
    }
  }

  Future<void> _stopRecording() async {
    // Stop listening if active
    if (_isListening) {
      try {
        await _speechService.stopListening();
      } catch (e) {
        debugPrint('Error stopping speech: $e');
      }
    }

    _pulseController.stop();
    _waveController.stop();

    if (!mounted) return;

    setState(() {
      _isListening = false;
    });

    // Wait a moment for final results
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final text = _speechService.text;
    debugPrint('Transcribed text: "$text"');

    if (text.isNotEmpty) {
      setState(() {
        _transcribedText = text;
        _statusMessage = 'Processing...';
      });
      _navigateToReview();
    } else {
      setState(() {
        _statusMessage = 'No speech detected. Try again.';
      });
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Voice Recording'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToReview() {
    if (_transcribedText.isEmpty) return;

    final processedText = TranslationService.processText(
      _transcribedText,
      context.read<LanguageProvider>().currentLanguage,
    );

    final intent = NLPService.parseTransaction(processedText);

    // Debug: Log the parsing results
    debugPrint('=== Voice Recording - NLP Results ===');
    debugPrint('Original text: $_transcribedText');
    debugPrint('Processed text: $processedText');
    debugPrint(
        'Parsed - Type: ${intent.type}, Amount: ${intent.amount}, Item: ${intent.itemName}, Category: ${intent.category}');

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => TransactionReviewScreen(
          transcribedText: _transcribedText,
          transactionIntent: intent,
        ),
      ),
    ).then((_) {
      // Reset state when returning
      setState(() {
        _transcribedText = '';
        _statusMessage = 'Tap the microphone to start';
      });
    });
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IOSColors.secondarySystemBackground,
      appBar: IOSNavigationBar(
        title: 'Record Transaction',
        automaticallyImplyLeading: false,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _navigateToHome,
          child: const Icon(
            CupertinoIcons.back,
            color: IOSColors.primary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(IOSSpacing.md),
        child: Column(
          children: [
            const SizedBox(height: IOSSpacing.xl),

            // Main recording button area
            _buildRecordingSection(),

            const SizedBox(height: IOSSpacing.xl),

            // Status indicator
            _buildStatusSection(),

            const SizedBox(height: IOSSpacing.xl),

            // Transcribed text preview (when available)
            if (_transcribedText.isNotEmpty) _buildTranscribedPreview(),

            // Tips section
            _buildTipsSection(),

            const SizedBox(height: IOSSpacing.xl),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildRecordingSection() {
    return Center(
      child: Column(
        children: [
          // Animated recording button
          AnimatedBuilder(
            animation: Listenable.merge([_pulseAnimation, _waveAnimation]),
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Outer pulsing circle (only when listening)
                  if (_isListening) ...[
                    // Wave rings
                    for (int i = 0; i < 3; i++)
                      Container(
                        width: 160 + (_waveAnimation.value * 60) + (i * 30),
                        height: 160 + (_waveAnimation.value * 60) + (i * 30),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                IOSColors.primary.withOpacity(0.2 - (i * 0.05)),
                            width: 2,
                          ),
                        ),
                      ),
                  ],

                  // Main button
                  Transform.scale(
                    scale: _isListening ? _pulseAnimation.value : 1.0,
                    child: GestureDetector(
                      onTap: () {
                        if (_isListening) {
                          _stopRecording();
                        } else {
                          _startRecording();
                        }
                      },
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _isListening
                                ? [
                                    IOSColors.error,
                                    IOSColors.error.withOpacity(0.8)
                                  ]
                                : [IOSColors.primary, IOSColors.primaryDark],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (_isListening
                                      ? IOSColors.error
                                      : IOSColors.primary)
                                  .withOpacity(0.4),
                              blurRadius: _isListening ? 40 : 25,
                              spreadRadius: _isListening ? 10 : 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              _isListening
                                  ? CupertinoIcons.stop_fill
                                  : CupertinoIcons.mic_fill,
                              key: ValueKey(_isListening),
                              size: 56,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: IOSSpacing.lg),

          // Instruction text
          Text(
            _isListening ? 'Tap to stop recording' : 'Tap to start recording',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _isListening ? IOSColors.error : IOSColors.labelSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: IOSSpacing.lg,
        vertical: IOSSpacing.md,
      ),
      decoration: BoxDecoration(
        color: _isListening
            ? IOSColors.error.withOpacity(0.1)
            : IOSColors.systemBackground,
        borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
        border: Border.all(
          color: _isListening
              ? IOSColors.error.withOpacity(0.3)
              : IOSColors.labelQuaternary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isListening) ...[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: IOSColors.error,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: IOSSpacing.sm),
          ],
          Flexible(
            child: Text(
              _statusMessage,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _isListening ? IOSColors.error : IOSColors.labelPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscribedPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: IOSSpacing.lg),
      padding: const EdgeInsets.all(IOSSpacing.md),
      decoration: BoxDecoration(
        color: IOSColors.systemBackground,
        borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
        border: Border.all(color: IOSColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.text_quote,
                color: IOSColors.primary,
                size: 18,
              ),
              const SizedBox(width: IOSSpacing.sm),
              Text(
                'Captured Speech:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: IOSColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: IOSSpacing.sm),
          Text(
            '"$_transcribedText"',
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: IOSColors.labelPrimary,
            ),
          ),
          const SizedBox(height: IOSSpacing.md),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: IOSColors.primary,
              padding: const EdgeInsets.symmetric(vertical: IOSSpacing.sm),
              borderRadius: BorderRadius.circular(IOSBorderRadius.small),
              onPressed: _navigateToReview,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.arrow_right, size: 18),
                  SizedBox(width: IOSSpacing.sm),
                  Text(
                    'Review Transaction',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      padding: const EdgeInsets.all(IOSSpacing.md),
      decoration: BoxDecoration(
        color: IOSColors.systemBackground,
        borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.lightbulb_fill,
                color: IOSColors.warning,
                size: 18,
              ),
              const SizedBox(width: IOSSpacing.sm),
              Text(
                'Tips for best results:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: IOSColors.labelPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: IOSSpacing.sm),
          _buildTip('• Speak clearly and at a normal pace'),
          _buildTip('• Mention the amount and item name'),
          _buildTip('• Example: "Sold bread for 5000 shillings"'),
          _buildTip('• Example: "Spent 20000 on transport"'),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: IOSColors.labelSecondary,
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
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
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = index == 0;
    return GestureDetector(
      onTap: _navigateToHome,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? IOSColors.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isSelected ? 24 : 22,
              color: isSelected ? IOSColors.primary : IOSColors.labelTertiary,
            ),
            if (isSelected) const SizedBox(width: 8),
            if (isSelected)
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

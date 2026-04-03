import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:ismart_shop/providers/language_provider.dart';
import 'package:ismart_shop/services/speech_service.dart';
import 'package:ismart_shop/utils/ios_theme.dart';

/// A reusable voice recording button widget with clean state management
class VoiceButton extends StatefulWidget {
  final Function(String text)? onTextRecognized;
  final VoidCallback? onRecordingStarted;
  final VoidCallback? onRecordingStopped;
  final double size;
  final Color? primaryColor;
  final Color? errorColor;
  final bool enabled;

  const VoiceButton({
    super.key,
    this.onTextRecognized,
    this.onRecordingStarted,
    this.onRecordingStopped,
    this.size = 56,
    this.primaryColor,
    this.errorColor,
    this.enabled = true,
  });

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton>
    with SingleTickerProviderStateMixin {
  SpeechService? _speechService;
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isInitialized = false;
  String _recognizedText = '';
  String _statusMessage = '';

  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeSpeechService();
    _setupAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reinitialize speech service when returning to this page
    // This ensures the voice button works after leaving and returning
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _reinitializeIfNeeded();
      }
    });
  }

  /// Reinitialize if needed - called when page becomes visible again
  Future<void> _reinitializeIfNeeded() async {
    // If the speech service is not initialized or not available, reinitialize
    if (!_isInitialized || _speechService == null) {
      await _initializeSpeechService();
    } else {
      // Force reinitialize to ensure clean state
      try {
        await _speechService!.forceReinitialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _isListening = false;
            _statusMessage = 'Tap to speak';
          });
        }
      } catch (e) {
        debugPrint('Error reinitializing: $e');
      }
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeSpeechService() async {
    _speechService = SpeechService();
    // Use forceReinitialize to ensure clean state
    final success = await _speechService!.forceReinitialize();
    if (mounted) {
      setState(() {
        _isInitialized = success;
        _statusMessage = success ? 'Tap to speak' : 'Voice unavailable';
      });
    }
  }

  Future<void> _handleButtonPressed() async {
    if (_isProcessing || !widget.enabled) return;

    if (_isListening) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    // Check microphone permission
    final micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) {
        _updateStatus('Microphone permission required');
        return;
      }
    }

    // Ensure speech service is initialized
    if (!_isInitialized || _speechService == null) {
      await _initializeSpeechService();
      if (!_isInitialized) {
        _updateStatus('Voice recognition unavailable');
        return;
      }
    } else {
      // Reinitialize to ensure clean state
      try {
        await _speechService!.forceReinitialize();
      } catch (e) {
        debugPrint('Error reinitializing speech service: $e');
      }
    }

    // Get best locale for the user's language - use default if provider not available
    String localeId = 'en_US';
    try {
      final languageProvider = context.read<LanguageProvider>();
      localeId = await _getBestLocale(languageProvider.currentLanguage);
    } catch (e) {
      debugPrint('Could not get language provider, using default locale');
    }

    try {
      _updateStatus('Listening...');
      setState(() => _isProcessing = true);

      final success = await _speechService!.startListening(localeId: localeId);

      if (success && mounted) {
        setState(() {
          _isListening = true;
          _isProcessing = false;
          _recognizedText = '';
        });
        _animationController.repeat(reverse: true);
        widget.onRecordingStarted?.call();
      } else if (mounted) {
        _updateStatus('Failed to start. Tap to try again.');
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
      _updateStatus('Error starting recording');
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _stopRecording() async {
    if (_speechService == null) return;

    try {
      await _speechService!.stopListening();
      _animationController.stop();

      if (mounted) {
        setState(() => _isListening = false);

        // Give a moment for final results
        await Future.delayed(const Duration(milliseconds: 300));

        final text = _speechService!.text;
        if (text.isNotEmpty) {
          _recognizedText = text;
          _updateStatus('Tap to speak');
          widget.onTextRecognized?.call(text);
        } else {
          _updateStatus('No speech detected');
        }

        widget.onRecordingStopped?.call();
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      if (mounted) {
        setState(() => _isListening = false);
        _updateStatus('Error stopping recording');
      }
    }
  }

  Future<String> _getBestLocale(String userLanguage) async {
    try {
      final locales = await _speechService?.getLocales();
      if (locales != null && locales.isNotEmpty) {
        if (userLanguage == 'lg') {
          try {
            final lugandaLocale = locales.firstWhere(
              (l) =>
                  l.localeId.startsWith('lg') ||
                  l.name.toLowerCase().contains('luganda'),
              orElse: () => locales.first,
            );
            return lugandaLocale.localeId;
          } catch (_) {
            return locales.first.localeId;
          }
        } else {
          try {
            final englishLocale = locales.firstWhere(
              (l) =>
                  l.localeId.startsWith('en') &&
                  (l.localeId.contains('US') || l.localeId.contains('GB')),
              orElse: () => locales.firstWhere(
                (l) => l.localeId.startsWith('en'),
                orElse: () => locales.first,
              ),
            );
            return englishLocale.localeId;
          } catch (_) {
            return locales.first.localeId;
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting best locale: $e');
    }
    return 'en_US';
  }

  void _updateStatus(String message) {
    if (mounted) {
      setState(() => _statusMessage = message);
    }
  }

  @override
  void dispose() {
    _speechService?.stopListening();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = widget.primaryColor ??
        (isDarkMode ? IOSDarkColors.primary : IOSColors.primary);
    final errorColor = widget.errorColor ??
        (isDarkMode ? IOSDarkColors.error : IOSColors.error);

    final isDisabled = _isProcessing || !widget.enabled;
    final buttonColor = _isListening
        ? errorColor
        : isDisabled
            ? Colors.grey
            : primaryColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isListening ? _pulseAnimation.value : 1.0,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: isDisabled ? null : _handleButtonPressed,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: buttonColor,
                    borderRadius: BorderRadius.circular(widget.size / 2),
                    boxShadow: [
                      BoxShadow(
                        color: buttonColor.withOpacity(0.4),
                        blurRadius: _isListening ? 20 : 10,
                        spreadRadius: _isListening ? 5 : 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening
                        ? CupertinoIcons.stop_fill
                        : CupertinoIcons.mic_fill,
                    color: Colors.white,
                    size: widget.size * 0.5,
                  ),
                ),
              ),
            );
          },
        ),
        if (_statusMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _statusMessage,
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode
                    ? IOSDarkColors.labelSecondary
                    : IOSColors.labelSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

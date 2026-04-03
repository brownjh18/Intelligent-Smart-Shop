import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;
  String _text = '';
  double _confidence = 0;
  String _lastStatus = '';
  String _lastError = '';
  bool _hasStartedListening = false;
  String _currentLocaleId = '';
  bool _isInitialized = false;

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get text => _text;
  double get confidence => _confidence;
  String get lastStatus => _lastStatus;
  String get lastError => _lastError;

  /// Check if speech recognition is available on this device
  Future<bool> initialize() async {
    debugPrint('SpeechService: Initializing speech recognition...');

    // If already initialized, just return the current state
    if (_isInitialized && _isAvailable) {
      debugPrint('SpeechService: Already initialized, returning current state');
      return _isAvailable;
    }

    try {
      _isAvailable = await _speechToText.initialize(
        onStatus: (status) {
          _lastStatus = status;
          debugPrint('Speech status: $status');

          if (status == 'listening') {
            _isListening = true;
            _hasStartedListening = true;
          } else if (status == 'done' ||
              status == 'notListening' ||
              status == 'statusNotStarted') {
            _isListening = false;
          }
        },
        onError: (error) {
          _lastError = error.errorMsg;
          debugPrint('Speech error: ${error.errorMsg}');
          _isListening = false;
        },
        debugLogging: false,
      );

      _isInitialized = true;
      debugPrint('SpeechService: Initialization result: $_isAvailable');

      // Log available locales
      if (!_isAvailable) {
        try {
          final locales = await _speechToText.locales();
          debugPrint('SpeechService: Available locales: ${locales.length}');
          for (var locale in locales.take(5)) {
            debugPrint('  - ${locale.name} (${locale.localeId})');
          }
        } catch (e) {
          debugPrint('SpeechService: Could not get locales: $e');
        }
      }

      return _isAvailable;
    } catch (e) {
      debugPrint('SpeechService: Initialization exception: $e');
      _isAvailable = false;
      _isInitialized = true;
      return false;
    }
  }

  Future<List<LocaleName>> getLocales() async {
    if (!_isAvailable) {
      await initialize();
    }

    if (_isAvailable) {
      try {
        return await _speechToText.locales();
      } catch (e) {
        debugPrint('Error getting locales: $e');
        return [];
      }
    }
    return [];
  }

  Future<bool> startListening({required String localeId}) async {
    debugPrint(
        'SpeechService: Starting listening with requested locale: $localeId');
    _currentLocaleId = localeId;

    // Try to initialize if not available
    if (!_isAvailable || !_isInitialized) {
      debugPrint('SpeechService: Not available, attempting to initialize...');
      final initialized = await initialize();
      if (!initialized) {
        debugPrint('SpeechService: Failed to initialize speech - $_lastError');
        _lastError = 'Speech recognition not available on this device';
        return false;
      }
    }

    // If still not available after initialization attempt
    if (!_isAvailable) {
      debugPrint('SpeechService: Not available after initialization');
      _lastError = 'Speech recognition is not available';
      return false;
    }

    // Try to get the best available locale
    String actualLocaleId = localeId;

    // If the requested locale is 'lg' (Luganda) or 'en_US', try to find a matching one
    if (localeId == 'lg' || localeId == 'en_US') {
      try {
        final locales = await _speechToText.locales();

        // For Luganda, try to find Luganda locale
        if (localeId == 'lg') {
          final lugandaLocale = locales.firstWhere(
            (l) =>
                l.localeId.startsWith('lg') ||
                l.name.toLowerCase().contains('luganda'),
            orElse: () => locales.first,
          );
          actualLocaleId = lugandaLocale.localeId;
          debugPrint('SpeechService: Using Luganda locale: $actualLocaleId');
        }
        // For English, try to find en-US or en-GB
        else if (localeId == 'en_US') {
          final englishLocale = locales.firstWhere(
            (l) =>
                l.localeId.startsWith('en') &&
                (l.localeId.contains('US') || l.localeId.contains('GB')),
            orElse: () => locales.firstWhere(
              (l) => l.localeId.startsWith('en'),
              orElse: () => locales.first,
            ),
          );
          actualLocaleId = englishLocale.localeId;
          debugPrint('SpeechService: Using English locale: $actualLocaleId');
        }
      } catch (e) {
        debugPrint('SpeechService: Error getting locales: $e');
      }
    }

    if (_isAvailable) {
      try {
        _text = '';
        _confidence = 0;
        _lastStatus = 'starting';
        _hasStartedListening = false;
        _lastError = '';

        // Use the new SpeechListenOptions API
        final listenOptions = SpeechListenOptions(
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
        );

        debugPrint(
            'SpeechService: Attempting to start listening with locale: $actualLocaleId');

        // Start listening with localeId parameter
        await _speechToText.listen(
          onResult: (SpeechRecognitionResult result) {
            debugPrint(
                'SpeechService: Got result - "${result.recognizedWords}", final: ${result.finalResult}');
            _text =
                result.recognizedWords.isNotEmpty ? result.recognizedWords : '';
            _confidence = result.confidence;

            if (result.finalResult) {
              _isListening = false;
              _lastStatus = 'done';
              debugPrint('SpeechService: Final result received, stopping');
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          localeId: actualLocaleId,
          listenOptions: listenOptions,
        );

        debugPrint('SpeechService: listen() called successfully');

        // Wait for the listening to start and check status
        // Give it time to initialize and check the status callback
        for (int i = 0; i < 10; i++) {
          await Future.delayed(const Duration(milliseconds: 300));

          debugPrint(
              'SpeechService: Check attempt $i - status: $_lastStatus, isListening: $_isListening, hasStarted: $_hasStartedListening');

          // If we've received the listening status, consider it a success
          if (_hasStartedListening ||
              _lastStatus == 'listening' ||
              _isListening) {
            debugPrint(
                'SpeechService: Actually started listening (status: $_lastStatus)');
            _isListening = true;
            return true;
          }
        }

        // If status shows listening but we didn't detect it, check once more
        if (_lastStatus == 'listening') {
          _isListening = true;
          _hasStartedListening = true;
          debugPrint('SpeechService: Detected listening via status check');
          return true;
        }

        // If we still haven't started, report failure but don't give up - try again
        debugPrint('SpeechService: First attempt failed, retrying...');

        // Stop and try again
        try {
          await _speechToText.stop();
        } catch (e) {
          debugPrint('SpeechService: Error on stop: $e');
        }

        await Future.delayed(const Duration(milliseconds: 500));

        // Second attempt
        _lastStatus = 'starting';
        _hasStartedListening = false;

        await _speechToText.listen(
          onResult: (SpeechRecognitionResult result) {
            _text =
                result.recognizedWords.isNotEmpty ? result.recognizedWords : '';
            _confidence = result.confidence;
            if (result.finalResult) {
              _isListening = false;
              _lastStatus = 'done';
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          localeId: actualLocaleId,
          listenOptions: listenOptions,
        );

        for (int i = 0; i < 5; i++) {
          await Future.delayed(const Duration(milliseconds: 300));
          if (_hasStartedListening ||
              _lastStatus == 'listening' ||
              _isListening) {
            _isListening = true;
            return true;
          }
        }

        // If still failing, report failure
        debugPrint(
            'SpeechService: Failed to start listening - status: $_lastStatus');
        return false;
      } catch (e) {
        debugPrint('SpeechService: Exception during listen: $e');
        _lastError = 'Error: $e';
        _isListening = false;
        return false;
      }
    } else {
      debugPrint('SpeechService: Not available after initialization');
      _lastError = 'Speech recognition is not available';
      return false;
    }
  }

  Future<void> stopListening() async {
    debugPrint('SpeechService: Stopping listening');
    try {
      await _speechToText.stop();
      _isListening = false;
      _lastStatus = 'stopped';
    } catch (e) {
      debugPrint('SpeechService: Error stopping: $e');
    }
  }

  void reset() {
    _text = '';
    _confidence = 0;
    _lastStatus = '';
    _lastError = '';
    _hasStartedListening = false;
    _isListening = false;
  }

  /// Force reinitialize the speech service - useful when returning to the page
  /// or when starting a new recording session
  Future<bool> forceReinitialize() async {
    debugPrint('SpeechService: Force reinitializing...');

    // Stop any ongoing operation first
    try {
      await _speechToText.stop();
    } catch (e) {
      debugPrint('SpeechService: Error stopping before reinit: $e');
    }

    // Reset our tracking state completely
    _isListening = false;
    _text = '';
    _confidence = 0;
    _lastStatus = '';
    _lastError = '';
    _hasStartedListening = false;
    _isInitialized = false;
    _isAvailable = false;

    // Wait a bit for any pending operations to complete
    await Future.delayed(const Duration(milliseconds: 500));

    // Now initialize fresh
    return await initialize();
  }

  /// Stop any ongoing listening and reset to a clean state
  Future<void> stopAndReset() async {
    debugPrint('SpeechService: Stopping and resetting...');
    try {
      await _speechToText.stop();
    } catch (e) {
      debugPrint('SpeechService: Error on stop: $e');
    }

    // Reset all state
    _isListening = false;
    _text = '';
    _confidence = 0;
    _lastStatus = '';
    _lastError = '';
    _hasStartedListening = false;
  }

  static String get englishLocale => 'en_US';

  /// Get the best available locale for speech recognition
  static Future<String> getBestLocale(String preferredLocale) async {
    try {
      final speechToText = SpeechToText();
      final isAvailable = await speechToText.initialize();

      if (isAvailable) {
        final locales = await speechToText.locales();

        // Try to find a matching locale
        if (preferredLocale == 'lg') {
          // Try to find Luganda
          final lugandaLocale = locales.firstWhere(
            (l) =>
                l.localeId.startsWith('lg') ||
                l.name.toLowerCase().contains('luganda'),
            orElse: () => locales.first,
          );
          await speechToText.stop();
          return lugandaLocale.localeId;
        } else if (preferredLocale == 'en_US') {
          // Try to find English (US or GB)
          final englishLocale = locales.firstWhere(
            (l) =>
                l.localeId.startsWith('en') &&
                (l.localeId.contains('US') || l.localeId.contains('GB')),
            orElse: () => locales.firstWhere(
              (l) => l.localeId.startsWith('en'),
              orElse: () => locales.first,
            ),
          );
          await speechToText.stop();
          return englishLocale.localeId;
        }

        await speechToText.stop();
        return locales.first.localeId;
      }
    } catch (e) {
      debugPrint('SpeechService: Error getting best locale: $e');
    }

    // Return default based on preference
    return preferredLocale == 'lg' ? 'en_US' : preferredLocale;
  }
}

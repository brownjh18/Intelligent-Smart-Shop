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

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get text => _text;
  double get confidence => _confidence;
  String get lastStatus => _lastStatus;
  String get lastError => _lastError;

  Future<bool> initialize() async {
    debugPrint('SpeechService: Initializing speech recognition...');

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
        debugLogging: true,
      );

      debugPrint('SpeechService: Initialization result: $_isAvailable');

      // Log more details about why initialization might have failed
      if (!_isAvailable) {
        debugPrint('SpeechService: Available locales would be checked');
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
    debugPrint('SpeechService: Starting listening with locale: $localeId');

    // Try to initialize if not available
    if (!_isAvailable) {
      debugPrint('SpeechService: Not available, attempting to initialize...');
      final initialized = await initialize();
      if (!initialized) {
        debugPrint('SpeechService: Failed to initialize speech - $_lastError');
        _lastError = 'Speech recognition not available on this device';
        return false;
      }
    }

    if (_isAvailable) {
      try {
        _text = '';
        _confidence = 0;
        _lastStatus = 'starting';
        _hasStartedListening = false;
        _lastError = '';

        // Try listening - use default locale if specific locale fails
        bool success = false;
        bool attemptedWithLocale = false;

        try {
          debugPrint(
              'SpeechService: Attempting to start listening with locale: $localeId');

          // First try with the specified locale
          success = await _speechToText.listen(
            onResult: (SpeechRecognitionResult result) {
              debugPrint(
                  'SpeechService: Got result - "${result.recognizedWords}", final: ${result.finalResult}');
              _text = result.recognizedWords.isNotEmpty
                  ? result.recognizedWords
                  : '';
              _confidence = result.confidence;

              if (result.finalResult) {
                _isListening = false;
                _lastStatus = 'done';
              }
            },
            localeId: localeId,
            listenFor: const Duration(seconds: 30),
            pauseFor: const Duration(seconds: 3),
            partialResults: true,
            cancelOnError: false,
            listenMode: ListenMode.dictation,
          );

          debugPrint('SpeechService: listen() with locale returned: $success');
          attemptedWithLocale = true;
        } catch (e) {
          debugPrint('SpeechService: First listen attempt error: $e');
        }

        // If first attempt failed or returned false, try with default locale
        if (!success || !attemptedWithLocale) {
          try {
            debugPrint('SpeechService: Trying with default locale...');
            success = await _speechToText.listen(
              onResult: (SpeechRecognitionResult result) {
                debugPrint(
                    'SpeechService: Got result - "${result.recognizedWords}", final: ${result.finalResult}');
                _text = result.recognizedWords.isNotEmpty
                    ? result.recognizedWords
                    : '';
                _confidence = result.confidence;

                if (result.finalResult) {
                  _isListening = false;
                  _lastStatus = 'done';
                }
              },
              listenFor: const Duration(seconds: 30),
              pauseFor: const Duration(seconds: 3),
              partialResults: true,
              cancelOnError: false,
              listenMode: ListenMode.dictation,
            );
            debugPrint('SpeechService: Second listen() returned: $success');
          } catch (e2) {
            debugPrint('SpeechService: Second listen attempt error: $e2');
          }
        }

        // Check if listening actually started (even if listen() returned false)
        // Give it a moment to start and check the status
        // We need to wait a bit longer and also handle the case where callbacks fire after we check
        for (int i = 0; i < 3; i++) {
          await Future.delayed(const Duration(milliseconds: 300));

          debugPrint(
              'SpeechService: Check attempt $i - status: $_lastStatus, isListening: $_isListening, hasStarted: $_hasStartedListening');

          if (_hasStartedListening ||
              _lastStatus == 'listening' ||
              _isListening) {
            debugPrint(
                'SpeechService: Actually started listening (status: $_lastStatus)');
            _isListening = true;
            return true;
          }
        }

        // If we still haven't started, report failure
        debugPrint(
            'SpeechService: Failed to start listening - status: $_lastStatus');

        // Provide more helpful error messages
        if (_lastStatus == 'starting' || _lastStatus.isEmpty) {
          _lastError = 'Speech recognition failed to start. Please try again.';
        } else if (_lastError.isEmpty) {
          _lastError =
              'Failed to start speech recognition. Status: $_lastStatus';
        }
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

  static String get lugandaLocale => 'lg';
  static String get englishLocale => 'en_US';
}

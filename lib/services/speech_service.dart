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
          _isListening = status == 'listening' || status == 'done';

          if (status == 'done' || status == 'notListening') {
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

        // Try listening without specifying locale first (let system use default)
        bool success = false;

        // Try with locale ID
        try {
          debugPrint(
              'SpeechService: Attempting to start listening with locale: $localeId');
          success = await _speechToText.listen(
            onResult: (SpeechRecognitionResult result) {
              debugPrint(
                  'SpeechService: Got result - "${result.recognizedWords}", final: ${result.finalResult}');
              _text = result.recognizedWords;
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

          debugPrint('SpeechService: listen() returned: $success');
        } catch (e) {
          debugPrint('SpeechService: First listen attempt error: $e');

          // Try again with default locale
          try {
            debugPrint('SpeechService: Trying with default locale...');
            success = await _speechToText.listen(
              onResult: (SpeechRecognitionResult result) {
                debugPrint(
                    'SpeechService: Got result - "${result.recognizedWords}", final: ${result.finalResult}');
                _text = result.recognizedWords;
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

        if (success) {
          _isListening = true;
          debugPrint('SpeechService: Listening started successfully');
          return true;
        } else {
          // Even if listen returns false, the speech might still be working
          // Let's check the status
          debugPrint(
              'SpeechService: listen() returned false, but checking if it started...');

          // Give it a moment to start
          await Future.delayed(const Duration(milliseconds: 500));

          if (_lastStatus == 'listening' || _isListening) {
            debugPrint(
                'SpeechService: Actually started listening (status: $_lastStatus)');
            return true;
          }

          debugPrint(
              'SpeechService: Failed to start listening - status: $_lastStatus');
          _lastError =
              'Failed to start speech recognition. Status: $_lastStatus';
          return false;
        }
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
  }

  static String get lugandaLocale => 'lg';
  static String get englishLocale => 'en_US';
}

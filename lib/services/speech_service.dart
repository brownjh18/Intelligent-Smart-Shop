import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// A reliable speech recognition service
class SpeechService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;
  String _text = '';
  double _confidence = 0;
  String _lastStatus = '';
  String _lastError = '';
  bool _hasStartedListening = false;
  String _currentLocaleId = '';
  bool _isInitialized = false;

  Function(bool isListening)? onListeningStateChanged;
  Function(String text)? onPartialResult;
  Function(String text)? onFinalResult;
  Function(String error)? onError;

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get text => _text;
  String get lastStatus => _lastStatus;
  String get lastError => _lastError;
  double get confidence => _confidence;

  Future<bool> initialize() async {
    debugPrint('SpeechService: Initializing...');
    if (_isInitialized && _isAvailable) return _isAvailable;

    try {
      _isAvailable = await _speechToText.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
        debugLogging: false,
      );
      _isInitialized = true;
      debugPrint('SpeechService: Initialized, available: $_isAvailable');
      return _isAvailable;
    } catch (e) {
      debugPrint('SpeechService: Initialization failed: $e');
      _isAvailable = false;
      _isInitialized = true;
      return false;
    }
  }

  void _handleStatus(String status) {
    _lastStatus = status;
    debugPrint('SpeechService: Status: $status');
    if (status == 'listening') {
      _isListening = true;
      _hasStartedListening = true;
      onListeningStateChanged?.call(true);
    } else if (status == 'done' ||
        status == 'notListening' ||
        status == 'statusNotStarted') {
      _isListening = false;
      onListeningStateChanged?.call(false);
    }
  }

  void _handleError(dynamic error) {
    _lastError = error.errorMsg;
    _isListening = false;
    debugPrint('SpeechService: Error: ${error.errorMsg}');
    onListeningStateChanged?.call(false);
    onError?.call(error.errorMsg);
  }

  Future<List<stt.LocaleName>> getLocales() async {
    if (!_isAvailable) await initialize();
    if (_isAvailable) {
      try {
        return await _speechToText.locales();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  Future<String> _getBestLocaleId(String requestedLocale) async {
    if (requestedLocale == 'lg') {
      try {
        final locales = await getLocales();
        final locale = locales.firstWhere(
          (l) =>
              l.localeId.startsWith('lg') ||
              l.name.toLowerCase().contains('luganda'),
          orElse: () => locales.firstWhere((l) => l.localeId.startsWith('en'),
              orElse: () => locales.first),
        );
        return locale.localeId;
      } catch (e) {
        return 'en_US';
      }
    }
    if (requestedLocale == 'en_US') {
      try {
        final locales = await getLocales();
        final locale = locales.firstWhere(
          (l) =>
              l.localeId.startsWith('en') &&
              (l.localeId.contains('US') || l.localeId.contains('GB')),
          orElse: () => locales.firstWhere((l) => l.localeId.startsWith('en'),
              orElse: () => locales.first),
        );
        return locale.localeId;
      } catch (e) {
        return 'en_US';
      }
    }
    return requestedLocale;
  }

  Future<bool> startListening({required String localeId}) async {
    debugPrint('SpeechService: Starting listening for locale: $localeId');
    _currentLocaleId = localeId;

    if (!_isAvailable || !_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        _lastError = 'Speech recognition not available';
        return false;
      }
    }

    _text = '';
    _confidence = 0;
    _lastError = '';
    _hasStartedListening = false;
    _isListening = false;
    _lastStatus = 'starting';

    final actualLocaleId = await _getBestLocaleId(localeId);

    try {
      final listenOptions = stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: false,
      );

      debugPrint(
          'SpeechService: Calling listen() with locale: $actualLocaleId');

      await _speechToText.listen(
        onResult: _handleResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: actualLocaleId,
        listenOptions: listenOptions,
      );

      debugPrint('SpeechService: listen() call completed');

      // Wait a short time for status callback
      await Future.delayed(const Duration(milliseconds: 100));

      // If we got an error, report it
      if (_lastError.isNotEmpty) {
        debugPrint('SpeechService: Failed - error: $_lastError');
        return false;
      }

      // If status is 'listening', we're good
      if (_lastStatus == 'listening' || _isListening) {
        debugPrint('SpeechService: Successfully started listening');
        return true;
      }

      // If status is 'starting', wait a bit more
      if (_lastStatus == 'starting') {
        await Future.delayed(const Duration(milliseconds: 500));
        if (_lastStatus == 'listening' || _isListening) {
          debugPrint('SpeechService: Started after waiting');
          return true;
        }
      }

      // If we see 'done' or 'notListening', the recognition ran but stopped
      // This is actually OK - it means the listen() call worked, even if no speech was captured
      if (_lastStatus == 'done' || _lastStatus == 'notListening') {
        debugPrint(
            'SpeechService: Recognition completed (status: $_lastStatus)');
        // Return true because listen() was called successfully
        // The actual results will be available via _text
        return true;
      }

      debugPrint('SpeechService: Assuming started (status: $_lastStatus)');
      return true;
    } catch (e) {
      debugPrint('SpeechService: Exception: $e');
      _lastError = 'Error: $e';
      _isListening = false;
      return false;
    }
  }

  void _handleResult(dynamic result) {
    _text = result.recognizedWords;
    _confidence = result.confidence;
    if (result.finalResult) {
      debugPrint('SpeechService: Final result: "$_text"');
      onFinalResult?.call(_text);
    } else if (result.recognizedWords.isNotEmpty) {
      debugPrint('SpeechService: Partial result: "$_text"');
      onPartialResult?.call(_text);
    }
  }

  Future<void> stopListening() async {
    debugPrint('SpeechService: Stopping');
    try {
      await _speechToText.stop();
      _isListening = false;
      _lastStatus = 'stopped';
    } catch (e) {
      debugPrint('SpeechService: Error stopping: $e');
    }
  }

  Future<void> cancel() async {
    debugPrint('SpeechService: Cancelling');
    try {
      await _speechToText.cancel();
      _isListening = false;
      _lastStatus = 'cancelled';
    } catch (e) {
      debugPrint('SpeechService: Error cancelling: $e');
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

  Future<bool> forceReinitialize() async {
    debugPrint('SpeechService: Force reinitializing...');
    try {
      await _speechToText.stop();
    } catch (_) {}
    _isListening = false;
    _text = '';
    _confidence = 0;
    _lastStatus = '';
    _lastError = '';
    _hasStartedListening = false;
    _isInitialized = false;
    _isAvailable = false;
    await Future.delayed(const Duration(milliseconds: 300));
    return await initialize();
  }

  Future<void> stopAndReset() async {
    debugPrint('SpeechService: Stop and reset');
    try {
      await _speechToText.stop();
    } catch (_) {}
    reset();
  }

  static String get englishLocale => 'en_US';

  static Future<String> getBestLocale(String preferredLocale) async {
    try {
      final st = stt.SpeechToText();
      final isAvailable = await st.initialize();
      if (isAvailable) {
        final locales = await st.locales();
        if (preferredLocale == 'lg') {
          final locale = locales.firstWhere(
            (l) =>
                l.localeId.startsWith('lg') ||
                l.name.toLowerCase().contains('luganda'),
            orElse: () => locales.first,
          );
          await st.stop();
          return locale.localeId;
        }
        if (preferredLocale == 'en_US') {
          final locale = locales.firstWhere(
            (l) =>
                l.localeId.startsWith('en') &&
                (l.localeId.contains('US') || l.localeId.contains('GB')),
            orElse: () => locales.firstWhere((l) => l.localeId.startsWith('en'),
                orElse: () => locales.first),
          );
          await st.stop();
          return locale.localeId;
        }
        await st.stop();
        return locales.first.localeId;
      }
    } catch (e) {
      debugPrint('SpeechService: Error getting best locale: $e');
    }
    return preferredLocale == 'lg' ? 'en_US' : preferredLocale;
  }
}

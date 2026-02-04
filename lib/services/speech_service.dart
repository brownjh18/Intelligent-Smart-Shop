import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;
  String _text = '';
  double _confidence = 0;

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get text => _text;
  double get confidence => _confidence;

  Future<void> initialize() async {
    _isAvailable = await _speechToText.initialize(
      onStatus: (status) {
        debugPrint('Speech status: $status');
        _isListening = status == 'listening';
      },
      onError: (error) {
        debugPrint('Speech error: $error');
        _isListening = false;
      },
    );
  }

  Future<void> startListening({required String localeId}) async {
    if (!_isAvailable) {
      await initialize();
    }

    if (_isAvailable) {
      _text = '';
      _confidence = 0;
      await _speechToText.listen(
        onResult: (result) {
          _text = result.recognizedWords;
          _confidence = result.confidence;
        },
        localeId: localeId,
        cancelOnError: false,
        listenMode: ListenMode.confirmation,
      );
      _isListening = true;
    }
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    _isListening = false;
  }

  void reset() {
    _text = '';
    _confidence = 0;
  }

  // Luganda locale ID
  static String get lugandaLocale => 'lg';

  // English locale ID
  static String get englishLocale => 'en_US';
}

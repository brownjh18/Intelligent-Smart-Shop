import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for speech-to-text using OpenAI Whisper API
class WhisperService {
  static String _apiKey = '';
  static const String _apiUrl =
      'https://api.openai.com/v1/audio/transcriptions';
  static const String _apiKeyPref = 'whisper_api_key';
  static const String _defaultModel = 'whisper-1';
  static const String _defaultLanguage = 'lg'; // Luganda

  /// Initialize the service and load API key from storage
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString(_apiKeyPref);
      if (savedKey != null && savedKey.isNotEmpty) {
        _apiKey = savedKey;
        debugPrint('WhisperService: API key loaded from storage');
      }
    } catch (e) {
      debugPrint('WhisperService: Error loading API key - $e');
    }
  }

  /// Save API key to storage
  static Future<bool> saveApiKey(String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_apiKeyPref, apiKey);
      _apiKey = apiKey;
      debugPrint('WhisperService: API key saved');
      return true;
    } catch (e) {
      debugPrint('WhisperService: Error saving API key - $e');
      return false;
    }
  }

  /// Get current API key
  static String get apiKey => _apiKey;

  /// Check if API key is configured
  static bool get isApiKeyConfigured => _apiKey.isNotEmpty;

  /// Get configuration status message
  static String get configurationStatus {
    if (_apiKey.isEmpty) {
      return 'Whisper API key is empty. Please configure your Whisper API key.';
    }
    return 'Whisper API key configured. Speech recognition is ready!';
  }

  /// Transcribe audio file to text
  /// [audioFilePath] - Path to the audio file
  /// [language] - Language code (default: 'lg' for Luganda)
  /// [model] - Whisper model to use (default: 'whisper-1')
  /// Returns transcribed text or null if failed
  static Future<String?> transcribeAudio(
    String audioFilePath, {
    String language = _defaultLanguage,
    String model = _defaultModel,
  }) async {
    if (!isApiKeyConfigured) {
      debugPrint('WhisperService: No API key configured');
      return null;
    }

    if (audioFilePath.isEmpty) {
      debugPrint('WhisperService: Audio file path is empty');
      return null;
    }

    try {
      final file = File(audioFilePath);
      if (!await file.exists()) {
        debugPrint('WhisperService: Audio file does not exist: $audioFilePath');
        return null;
      }

      debugPrint('WhisperService: Transcribing audio file: $audioFilePath');
      debugPrint('WhisperService: Language: $language, Model: $model');

      final request = http.MultipartRequest('POST', Uri.parse(_apiUrl))
        ..headers['Authorization'] = 'Bearer $_apiKey'
        ..fields['model'] = model
        ..fields['language'] = language
        ..files.add(await http.MultipartFile.fromPath('file', audioFilePath));

      final response =
          await request.send().timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);
        final transcribedText = data['text'] as String?;

        if (transcribedText != null && transcribedText.isNotEmpty) {
          debugPrint(
              'WhisperService: Successfully transcribed: "$transcribedText"');
          return transcribedText.trim();
        } else {
          debugPrint('WhisperService: Empty transcription result');
          return null;
        }
      } else if (response.statusCode == 401) {
        debugPrint('WhisperService: Unauthorized - Invalid API key');
        return null;
      } else if (response.statusCode == 429) {
        debugPrint('WhisperService: Rate limit exceeded');
        return null;
      } else {
        debugPrint('WhisperService: API error - ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('WhisperService: Exception during transcription - $e');
      if (e.toString().contains('TimeoutException')) {
        debugPrint('WhisperService: Request timed out');
      }
      return null;
    }
  }

  /// Transcribe audio bytes to text
  /// [audioBytes] - Audio file bytes
  /// [language] - Language code (default: 'lg' for Luganda)
  /// [model] - Whisper model to use (default: 'whisper-1')
  /// Returns transcribed text or null if failed
  static Future<String?> transcribeAudioBytes(
    List<int> audioBytes, {
    String language = _defaultLanguage,
    String model = _defaultModel,
  }) async {
    if (!isApiKeyConfigured) {
      debugPrint('WhisperService: No API key configured');
      return null;
    }

    if (audioBytes.isEmpty) {
      debugPrint('WhisperService: Audio bytes are empty');
      return null;
    }

    try {
      debugPrint(
          'WhisperService: Transcribing audio bytes (${audioBytes.length} bytes)');
      debugPrint('WhisperService: Language: $language, Model: $model');

      final request = http.MultipartRequest('POST', Uri.parse(_apiUrl))
        ..headers['Authorization'] = 'Bearer $_apiKey'
        ..fields['model'] = model
        ..fields['language'] = language
        ..files.add(http.MultipartFile.fromBytes('file', audioBytes,
            filename: 'audio.wav'));

      final response =
          await request.send().timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);
        final transcribedText = data['text'] as String?;

        if (transcribedText != null && transcribedText.isNotEmpty) {
          debugPrint(
              'WhisperService: Successfully transcribed: "$transcribedText"');
          return transcribedText.trim();
        } else {
          debugPrint('WhisperService: Empty transcription result');
          return null;
        }
      } else if (response.statusCode == 401) {
        debugPrint('WhisperService: Unauthorized - Invalid API key');
        return null;
      } else if (response.statusCode == 429) {
        debugPrint('WhisperService: Rate limit exceeded');
        return null;
      } else {
        debugPrint('WhisperService: API error - ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('WhisperService: Exception during transcription - $e');
      if (e.toString().contains('TimeoutException')) {
        debugPrint('WhisperService: Request timed out');
      }
      return null;
    }
  }

  /// Get supported languages
  static Map<String, String> get supportedLanguages => {
        'lg': 'Luganda',
        'en': 'English',
        'sw': 'Swahili',
        'fr': 'French',
        'es': 'Spanish',
        'de': 'German',
        'it': 'Italian',
        'pt': 'Portuguese',
        'nl': 'Dutch',
        'ru': 'Russian',
        'zh': 'Chinese',
        'ja': 'Japanese',
        'ko': 'Korean',
        'ar': 'Arabic',
        'hi': 'Hindi',
      };

  /// Get language name from code
  static String getLanguageName(String code) {
    return supportedLanguages[code] ?? code;
  }

  /// Check if language is supported
  static bool isLanguageSupported(String code) {
    return supportedLanguages.containsKey(code);
  }
}

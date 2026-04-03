import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ismart_shop/services/nlp_service.dart';

/// Service for parsing transaction text using OpenAI GPT API
/// This is the fallback service when Gemini is unavailable or fails
class OpenAIParserService {
  // API key configured - used as fallback when Gemini fails
  // IMPORTANT: Set your API key via the app settings or environment variables
  // Never commit real API keys to version control
  static String _apiKey = '';
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _apiKeyPref = 'openai_api_key';

  // Fallback to local NLP if API fails
  static bool _useLocalNLP = true;

  /// Initialize the service and load API key from storage
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString(_apiKeyPref);
      if (savedKey != null && savedKey.isNotEmpty) {
        _apiKey = savedKey;
        debugPrint('OpenAIParserService: API key loaded from storage');
      }
    } catch (e) {
      debugPrint('OpenAIParserService: Error loading API key - $e');
    }
  }

  /// Save API key to storage
  static Future<bool> saveApiKey(String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_apiKeyPref, apiKey);
      _apiKey = apiKey;
      debugPrint('OpenAIParserService: API key saved');
      return true;
    } catch (e) {
      debugPrint('OpenAIParserService: Error saving API key - $e');
      return false;
    }
  }

  /// Get current API key
  static String get apiKey => _apiKey;

  /// Check if API key is configured
  static bool get isApiKeyConfigured =>
      _apiKey.isNotEmpty && _apiKey != 'YOUR_OPENAI_API_KEY';

  /// Get configuration status message
  static String get configurationStatus {
    if (_apiKey.isEmpty) {
      return 'API key is empty. Please configure your OpenAI API key.';
    }
    if (_apiKey == 'YOUR_OPENAI_API_KEY') {
      return 'API key not configured. Using local NLP (limited functionality).';
    }
    return 'API key configured. AI assistant is ready!';
  }

  /// Get setup instructions
  static String get setupInstructions {
    return '''To enable full AI capabilities:

1. Get an OpenAI API key from https://platform.openai.com/api-keys
2. Add credits to your account at https://platform.openai.com/account/billing
3. Save the API key in the app settings
4. Restart the app

Without API key: Limited to local NLP (fixed responses)
With API key: Dynamic, intelligent responses about your business''';
  }

  /// Parse transaction text using OpenAI GPT
  /// Returns a map with parsed transaction data or null if failed
  static Future<Map<String, dynamic>?> parseTransaction(String text) async {
    if (text.isEmpty) return null;

    // If API key is not set, use local NLP
    if (!isApiKeyConfigured) {
      debugPrint('OpenAIParserService: No API key configured, using local NLP');
      return _parseTransactionWithLocalNLP(text);
    }

    try {
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': 'gpt-4o-mini', // Using the cheapest model
              'messages': [
                {
                  'role': 'system',
                  'content':
                      '''You are a transaction parser for a small shop in Uganda.
Parse the following text and return a JSON object with these fields:
- type: "sale", "expense", or "purchase"
- item: the item name or "Unknown"
- quantity: number (default 1)
- unit: unit of measure (default "pcs")
- unitPrice: price per unit (0 if not specified)
- total: total amount
- category: one of "Food & Beverages", "Household", "Transport", "Communication", "Utilities", "Medical", "Clothing", "Personal Care", "Other"

Example inputs and outputs:
"I sold bread 3 pieces at 5000" → {"type":"sale","item":"bread","quantity":3,"unit":"pcs","unitPrice":5000,"total":15000,"category":"Food & Beverages"}
"spent transport 5000" → {"type":"expense","item":"transport","quantity":1,"unit":"pcs","unitPrice":0,"total":5000,"category":"Transport"}
"bought sugar 2 packets at 3000" → {"type":"purchase","item":"sugar","quantity":2,"unit":"packets","unitPrice":3000,"total":6000,"category":"Food & Beverages"}

Return ONLY the JSON object, no explanation.''',
                },
                {
                  'role': 'user',
                  'content': text,
                }
              ],
              'temperature': 0.1,
              'max_tokens': 200,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;

        // Parse the JSON response
        final parsed = _parseJSONResponse(content);
        if (parsed != null) {
          debugPrint('OpenAIParserService: Successfully parsed using OpenAI');
          return parsed;
        }
      } else {
        debugPrint('OpenAIParserService: API error - ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('OpenAIParserService: Exception - $e');
    }

    // Fallback to local NLP if OpenAI fails
    debugPrint('OpenAIParserService: Falling back to local NLP');
    return _parseTransactionWithLocalNLP(text);
  }

  /// Parse JSON response from OpenAI
  static Map<String, dynamic>? _parseJSONResponse(String content) {
    try {
      // Try to find JSON in the response (may have markdown code blocks)
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

        // Validate and normalize the response
        return {
          'type': _normalizeType(decoded['type']?.toString() ?? 'sale'),
          'item': decoded['item']?.toString() ?? 'Unknown',
          'quantity': _parseInt(decoded['quantity'] ?? 1),
          'unit': _normalizeUnit(decoded['unit']?.toString() ?? 'pcs'),
          'unitPrice': _parseDouble(decoded['unitPrice'] ?? 0),
          'total': _parseDouble(decoded['total'] ?? 0),
          'category':
              _normalizeCategory(decoded['category']?.toString() ?? 'Other'),
        };
      }
    } catch (e) {
      debugPrint('OpenAIParserService: JSON parse error - $e');
    }
    return null;
  }

  static String _normalizeType(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('expense') || lower.contains('spent')) {
      return 'expense';
    }
    if (lower.contains('purchase') ||
        lower.contains('bought') ||
        lower.contains('stock')) {
      return 'purchase';
    }
    return 'sale';
  }

  static String _normalizeUnit(String unit) {
    final lower = unit.toLowerCase();
    if (lower.startsWith('pc')) return 'pcs';
    if (lower.startsWith('kg')) return 'kgs';
    if (lower.startsWith('gram')) return 'g';
    if (lower.startsWith('liter') || lower == 'l') return 'L';
    if (lower.startsWith('milliliter') || lower == 'ml') return 'ml';
    if (lower.startsWith('packet')) return 'packets';
    if (lower.startsWith('box')) return 'boxes';
    if (lower.startsWith('bag')) return 'bags';
    if (lower.startsWith('bundle')) return 'bundles';
    if (lower.startsWith('bottle')) return 'bottles';
    if (lower.startsWith('dozen')) return 'dozen';
    return lower.isEmpty ? 'pcs' : lower;
  }

  static String _normalizeCategory(String category) {
    final validCategories = [
      'Food & Beverages',
      'Household',
      'Transport',
      'Communication',
      'Utilities',
      'Medical',
      'Clothing',
      'Personal Care',
      'Other',
    ];

    for (final valid in validCategories) {
      if (category.toLowerCase().contains(valid.toLowerCase().split(' ')[0])) {
        return valid;
      }
    }
    return 'Other';
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 1;
    return 1;
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '')) ?? 0;
    return 0;
  }

  /// Enable/disable local NLP fallback
  static void setUseLocalNLP(bool useLocal) {
    _useLocalNLP = useLocal;
  }

  static bool get useLocalNLP => _useLocalNLP;

  /// Parse transaction using local NLP service
  static Map<String, dynamic>? _parseTransactionWithLocalNLP(String text) {
    try {
      final intent = NLPService.parseTransaction(text);
      return {
        'type': intent.type.name,
        'item': intent.itemName,
        'quantity': intent.quantity,
        'unit': intent.unit,
        'unitPrice': intent.unitPrice,
        'total': intent.amount,
        'category': intent.category,
      };
    } catch (e) {
      debugPrint('OpenAIParserService: Local NLP error - $e');
      return null;
    }
  }

  /// Parse product using local NLP service
  static Map<String, dynamic>? _parseProductWithLocalNLP(String text) {
    try {
      final intent = NLPService.parseTransaction(text);
      return {
        'name': intent.itemName,
        'category': intent.category,
        'price': intent.unitPrice,
        'quantity': intent.quantity,
        'unit': intent.unit,
      };
    } catch (e) {
      debugPrint('OpenAIParserService: Local NLP product error - $e');
      return null;
    }
  }

  /// Parse supplier using local NLP service
  static Map<String, dynamic>? _parseSupplierWithLocalNLP(String text) {
    try {
      // Extract supplier name from text
      final words = text.split(' ');
      String name = 'Unknown Supplier';
      String phone = '';
      String email = '';
      String address = '';

      // Simple extraction logic
      for (int i = 0; i < words.length; i++) {
        final word = words[i].toLowerCase();
        if (word.contains('phone') ||
            word.contains('tel') ||
            word.contains('number')) {
          if (i + 1 < words.length) {
            phone = words[i + 1].replaceAll(RegExp(r'[^\d+]'), '');
          }
        } else if (word.contains('email') || word.contains('mail')) {
          if (i + 1 < words.length) {
            email = words[i + 1];
          }
        } else if (word.contains('address') || word.contains('location')) {
          if (i + 1 < words.length) {
            address = words.sublist(i + 1).join(' ');
          }
        }
      }

      // Extract name (first few words before contact info)
      final nameMatch = RegExp(
              r'(?:add|create|new|register)\s+supplier\s+([^,]+)',
              caseSensitive: false)
          .firstMatch(text);
      if (nameMatch != null) {
        name = nameMatch.group(1)?.trim() ?? 'Unknown Supplier';
      }

      return {
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
      };
    } catch (e) {
      debugPrint('OpenAIParserService: Local NLP supplier error - $e');
      return null;
    }
  }

  /// Parse customer using local NLP service
  static Map<String, dynamic>? _parseCustomerWithLocalNLP(String text) {
    try {
      // Extract customer name from text
      final words = text.split(' ');
      String name = 'Unknown Customer';
      String phone = '';
      String email = '';
      String address = '';

      // Simple extraction logic
      for (int i = 0; i < words.length; i++) {
        final word = words[i].toLowerCase();
        if (word.contains('phone') ||
            word.contains('tel') ||
            word.contains('number')) {
          if (i + 1 < words.length) {
            phone = words[i + 1].replaceAll(RegExp(r'[^\d+]'), '');
          }
        } else if (word.contains('email') || word.contains('mail')) {
          if (i + 1 < words.length) {
            email = words[i + 1];
          }
        } else if (word.contains('address') || word.contains('location')) {
          if (i + 1 < words.length) {
            address = words.sublist(i + 1).join(' ');
          }
        }
      }

      // Extract name (first few words before contact info)
      final nameMatch = RegExp(
              r'(?:add|create|new|register)\s+customer\s+([^,]+)',
              caseSensitive: false)
          .firstMatch(text);
      if (nameMatch != null) {
        name = nameMatch.group(1)?.trim() ?? 'Unknown Customer';
      }

      return {
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
      };
    } catch (e) {
      debugPrint('OpenAIParserService: Local NLP customer error - $e');
      return null;
    }
  }

  /// Parse category using local NLP service
  static Map<String, dynamic>? _parseCategoryWithLocalNLP(String text) {
    try {
      // Extract category name from text
      String name = 'Unknown Category';
      String description = '';

      final nameMatch = RegExp(
              r'(?:add|create|new|register)\s+category\s+([^,]+)',
              caseSensitive: false)
          .firstMatch(text);
      if (nameMatch != null) {
        name = nameMatch.group(1)?.trim() ?? 'Unknown Category';
      }

      final descMatch = RegExp(r'description\s+([^,]+)', caseSensitive: false)
          .firstMatch(text);
      if (descMatch != null) {
        description = descMatch.group(1)?.trim() ?? '';
      }

      return {
        'name': name,
        'description': description,
      };
    } catch (e) {
      debugPrint('OpenAIParserService: Local NLP category error - $e');
      return null;
    }
  }

  /// Answer general queries about shop data using OpenAI GPT
  /// Returns a natural language response or null if failed
  static Future<String?> answerQuery(String query, String contextData) async {
    if (query.isEmpty) return null;

    // If API key is not set, return null with helpful message
    if (!isApiKeyConfigured) {
      debugPrint('OpenAIParserService: No API key configured for query');
      return null; // Caller will handle fallback
    }

    try {
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': 'gpt-4o-mini',
              'messages': [
                {
                  'role': 'system',
                  'content':
                      '''You are iSmart AI, a friendly and knowledgeable business assistant for a small shop in Uganda. You help the shop owner understand their business performance, track sales, expenses, and make better decisions.

Your personality:
- Warm, encouraging, and professional
- Use simple, clear language
- Be proactive in offering insights and suggestions
- Celebrate successes and offer constructive advice for challenges
- Use emojis occasionally to make responses more engaging

Your capabilities:
- Answer questions about sales, expenses, purchases, profits
- Provide insights on business performance
- Suggest ways to improve profitability
- Help track inventory and customer data
- Offer tips for small business management

Guidelines:
- Always respond in English
- Format numbers with commas (e.g., 15,000 not 15000)
- Currency is UGX (Ugandan Shillings)
- Be concise but informative (2-4 sentences typically)
- If you don't have enough data, suggest what information would help
- Offer actionable advice when appropriate
- Use a friendly, conversational tone

Context Data (Today's and recent business data):
$contextData''',
                },
                {
                  'role': 'user',
                  'content': query,
                }
              ],
              'temperature': 0.8,
              'max_tokens': 500,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        debugPrint('OpenAIParserService: Successfully answered query');
        return content.trim();
      } else if (response.statusCode == 401) {
        debugPrint('OpenAIParserService: Unauthorized - Invalid API key');
        return '⚠️ API key is invalid. Please check your OpenAI API key configuration.';
      } else if (response.statusCode == 429) {
        debugPrint('OpenAIParserService: Rate limit exceeded');
        return '⚠️ Rate limit exceeded. Please wait a moment and try again.';
      } else if (response.statusCode == 500) {
        debugPrint('OpenAIParserService: OpenAI server error');
        return '⚠️ OpenAI service is temporarily unavailable. Please try again later.';
      } else {
        debugPrint('OpenAIParserService: API error - ${response.statusCode}');
        return '⚠️ Unable to process your query. Please try again.';
      }
    } catch (e) {
      debugPrint('OpenAIParserService: Query exception - $e');
      if (e.toString().contains('TimeoutException')) {
        return '⚠️ Request timed out. Please check your internet connection and try again.';
      }
      return '⚠️ An error occurred. Please try again.';
    }

    return null;
  }

  /// Parse product text using OpenAI GPT
  /// Returns a map with parsed product data or null if failed
  static Future<Map<String, dynamic>?> parseProduct(String text) async {
    if (text.isEmpty) return null;

    // If API key is not set, use local NLP
    if (!isApiKeyConfigured) {
      debugPrint(
          'OpenAIParserService: No API key configured for product parsing, using local NLP');
      return _parseProductWithLocalNLP(text);
    }

    try {
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': 'gpt-4o-mini',
              'messages': [
                {
                  'role': 'system',
                  'content':
                      '''You are a product parser for a small shop in Uganda.
Parse the following text and return a JSON object with these fields:
- name: the product name
- category: one of "Food & Beverages", "Household", "Transport", "Communication", "Utilities", "Medical", "Clothing", "Personal Care", "Other"
- price: price per unit (0 if not specified)
- quantity: number (default 0)
- unit: unit of measure (default "pcs")

Example inputs and outputs:
"Add product Bread, category Food, price 5000, quantity 100 pieces" → {"name":"Bread","category":"Food & Beverages","price":5000,"quantity":100,"unit":"pcs"}
"New item Sugar 2kg at 3000" → {"name":"Sugar","category":"Food & Beverages","price":3000,"quantity":2,"unit":"kgs"}

Return ONLY the JSON object, no explanation.''',
                },
                {
                  'role': 'user',
                  'content': text,
                }
              ],
              'temperature': 0.1,
              'max_tokens': 200,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;

        // Parse the JSON response
        final parsed = _parseProductJSONResponse(content);
        if (parsed != null) {
          debugPrint(
              'OpenAIParserService: Successfully parsed product using OpenAI');
          return parsed;
        }
      } else {
        debugPrint('OpenAIParserService: API error - ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('OpenAIParserService: Product parse exception - $e');
    }

    // Fallback to local NLP if OpenAI fails
    debugPrint(
        'OpenAIParserService: Falling back to local NLP for product parsing');
    return _parseProductWithLocalNLP(text);
  }

  /// Parse product JSON response from OpenAI
  static Map<String, dynamic>? _parseProductJSONResponse(String content) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

        return {
          'name': decoded['name']?.toString() ?? 'Unknown',
          'category':
              _normalizeCategory(decoded['category']?.toString() ?? 'Other'),
          'price': _parseDouble(decoded['price'] ?? 0),
          'quantity': _parseInt(decoded['quantity'] ?? 0),
          'unit': _normalizeUnit(decoded['unit']?.toString() ?? 'pcs'),
        };
      }
    } catch (e) {
      debugPrint('OpenAIParserService: Product JSON parse error - $e');
    }
    return null;
  }

  /// Parse supplier text using OpenAI GPT
  /// Returns a map with parsed supplier data or null if failed
  static Future<Map<String, dynamic>?> parseSupplier(String text) async {
    if (text.isEmpty) return null;

    // If API key is not set, use local NLP
    if (!isApiKeyConfigured) {
      debugPrint(
          'OpenAIParserService: No API key configured for supplier parsing, using local NLP');
      return _parseSupplierWithLocalNLP(text);
    }

    try {
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': 'gpt-4o-mini',
              'messages': [
                {
                  'role': 'system',
                  'content':
                      '''You are a supplier parser for a small shop in Uganda.
Parse the following text and return a JSON object with these fields:
- name: the supplier name
- phone: phone number (empty string if not specified)
- email: email address (empty string if not specified)
- address: physical address (empty string if not specified)

Example inputs and outputs:
"Add supplier ABC Distributors, phone 0700123456" → {"name":"ABC Distributors","phone":"0700123456","email":"","address":""}
"New vendor XYZ Company, email xyz@example.com, address Kampala" → {"name":"XYZ Company","phone":"","email":"xyz@example.com","address":"Kampala"}

Return ONLY the JSON object, no explanation.''',
                },
                {
                  'role': 'user',
                  'content': text,
                }
              ],
              'temperature': 0.1,
              'max_tokens': 200,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;

        // Parse the JSON response
        final parsed = _parseSupplierJSONResponse(content);
        if (parsed != null) {
          debugPrint(
              'OpenAIParserService: Successfully parsed supplier using OpenAI');
          return parsed;
        }
      } else {
        debugPrint('OpenAIParserService: API error - ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('OpenAIParserService: Supplier parse exception - $e');
    }

    // Fallback to local NLP if OpenAI fails
    debugPrint(
        'OpenAIParserService: Falling back to local NLP for supplier parsing');
    return _parseSupplierWithLocalNLP(text);
  }

  /// Parse supplier JSON response from OpenAI
  static Map<String, dynamic>? _parseSupplierJSONResponse(String content) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

        return {
          'name': decoded['name']?.toString() ?? 'Unknown',
          'phone': decoded['phone']?.toString() ?? '',
          'email': decoded['email']?.toString() ?? '',
          'address': decoded['address']?.toString() ?? '',
        };
      }
    } catch (e) {
      debugPrint('OpenAIParserService: Supplier JSON parse error - $e');
    }
    return null;
  }

  /// Parse customer text using OpenAI GPT
  /// Returns a map with parsed customer data or null if failed
  static Future<Map<String, dynamic>?> parseCustomer(String text) async {
    if (text.isEmpty) return null;

    // If API key is not set, use local NLP
    if (!isApiKeyConfigured) {
      debugPrint(
          'OpenAIParserService: No API key configured for customer parsing, using local NLP');
      return _parseCustomerWithLocalNLP(text);
    }

    try {
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': 'gpt-4o-mini',
              'messages': [
                {
                  'role': 'system',
                  'content':
                      '''You are a customer parser for a small shop in Uganda.
Parse the following text and return a JSON object with these fields:
- name: the customer name
- phone: phone number (empty string if not specified)
- email: email address (empty string if not specified)
- address: physical address (empty string if not specified)

Example inputs and outputs:
"Add customer John Doe, phone 0700123456" → {"name":"John Doe","phone":"0700123456","email":"","address":""}
"New client Mary, email mary@example.com, address Kampala" → {"name":"Mary","phone":"","email":"mary@example.com","address":"Kampala"}

Return ONLY the JSON object, no explanation.''',
                },
                {
                  'role': 'user',
                  'content': text,
                }
              ],
              'temperature': 0.1,
              'max_tokens': 200,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;

        // Parse the JSON response
        final parsed = _parseCustomerJSONResponse(content);
        if (parsed != null) {
          debugPrint(
              'OpenAIParserService: Successfully parsed customer using OpenAI');
          return parsed;
        }
      } else {
        debugPrint('OpenAIParserService: API error - ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('OpenAIParserService: Customer parse exception - $e');
    }

    // Fallback to local NLP if OpenAI fails
    debugPrint(
        'OpenAIParserService: Falling back to local NLP for customer parsing');
    return _parseCustomerWithLocalNLP(text);
  }

  /// Parse customer JSON response from OpenAI
  static Map<String, dynamic>? _parseCustomerJSONResponse(String content) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

        return {
          'name': decoded['name']?.toString() ?? 'Unknown',
          'phone': decoded['phone']?.toString() ?? '',
          'email': decoded['email']?.toString() ?? '',
          'address': decoded['address']?.toString() ?? '',
        };
      }
    } catch (e) {
      debugPrint('OpenAIParserService: Customer JSON parse error - $e');
    }
    return null;
  }

  /// Parse category text using OpenAI GPT
  /// Returns a map with parsed category data or null if failed
  static Future<Map<String, dynamic>?> parseCategory(String text) async {
    if (text.isEmpty) return null;

    // If API key is not set, use local NLP
    if (!isApiKeyConfigured) {
      debugPrint(
          'OpenAIParserService: No API key configured for category parsing, using local NLP');
      return _parseCategoryWithLocalNLP(text);
    }

    try {
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': 'gpt-4o-mini',
              'messages': [
                {
                  'role': 'system',
                  'content':
                      '''You are a category parser for a small shop in Uganda.
Parse the following text and return a JSON object with these fields:
- name: the category name
- description: category description (empty string if not specified)

Example inputs and outputs:
"Add category Food, description for edible products" → {"name":"Food","description":"for edible products"}
"New type Electronics" → {"name":"Electronics","description":""}

Return ONLY the JSON object, no explanation.''',
                },
                {
                  'role': 'user',
                  'content': text,
                }
              ],
              'temperature': 0.1,
              'max_tokens': 200,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;

        // Parse the JSON response
        final parsed = _parseCategoryJSONResponse(content);
        if (parsed != null) {
          debugPrint(
              'OpenAIParserService: Successfully parsed category using OpenAI');
          return parsed;
        }
      } else {
        debugPrint('OpenAIParserService: API error - ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('OpenAIParserService: Category parse exception - $e');
    }

    // Fallback to local NLP if OpenAI fails
    debugPrint(
        'OpenAIParserService: Falling back to local NLP for category parsing');
    return _parseCategoryWithLocalNLP(text);
  }

  /// Parse category JSON response from OpenAI
  static Map<String, dynamic>? _parseCategoryJSONResponse(String content) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

        return {
          'name': decoded['name']?.toString() ?? 'Unknown',
          'description': decoded['description']?.toString() ?? '',
        };
      }
    } catch (e) {
      debugPrint('OpenAIParserService: Category JSON parse error - $e');
    }
    return null;
  }
}

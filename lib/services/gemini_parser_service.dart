import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:ismart_shop/services/nlp_service.dart';

/// Service for parsing transaction text using Google Gemini API
class GeminiParserService {
  // API key configured - Gemini is the primary AI service
  // Note: API key should be saved via saveApiKey() method for persistence
  static String _apiKey = 'AIzaSyAyrQHJACANyTpnECptXD7f6p3_vU2Tk-w';
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  static const String _apiKeyPref = 'gemini_api_key';

  // Fallback to local NLP if API fails
  static bool _useLocalNLP = true;

  /// Initialize the service and load API key from storage
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString(_apiKeyPref);
      if (savedKey != null && savedKey.isNotEmpty) {
        _apiKey = savedKey;
        debugPrint('GeminiParserService: API key loaded from storage');
      } else if (_apiKey.isNotEmpty) {
        // If there's a hardcoded API key, save it for future use
        await prefs.setString(_apiKeyPref, _apiKey);
        debugPrint('GeminiParserService: Hardcoded API key saved to storage');
      }

      debugPrint(
          'GeminiParserService: API key configured: $isApiKeyConfigured');
    } catch (e) {
      debugPrint('GeminiParserService: Error loading API key - $e');
    }
  }

  /// Save API key to storage
  static Future<bool> saveApiKey(String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_apiKeyPref, apiKey);
      _apiKey = apiKey;
      debugPrint('GeminiParserService: API key saved');
      return true;
    } catch (e) {
      debugPrint('GeminiParserService: Error saving API key - $e');
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
      return '⚠️ Gemini API key is empty. Please configure your Gemini API key in settings.';
    }
    return '✅ Gemini API key configured. AI assistant is ready! 🤖';
  }

  /// Get setup instructions
  static String get setupInstructions {
    return '''To enable full AI capabilities:

1. Get a Gemini API key from https://makersuite.google.com/app/apikey
2. Save the API key in the app settings
3. Restart the app

Without API key: Limited to local NLP (fixed responses)
With API key: Dynamic, intelligent responses about your business''';
  }

  /// Parse transaction text using Gemini
  /// Returns a map with parsed transaction data or null if failed
  static Future<Map<String, dynamic>?> parseTransaction(String text) async {
    if (text.isEmpty) return null;

    // If API key is not set, use local NLP
    if (!isApiKeyConfigured) {
      debugPrint('GeminiParserService: No API key configured, using local NLP');
      return _parseTransactionWithLocalNLP(text);
    }

    try {
      final prompt = '''You are a transaction parser for a small shop in Uganda.
Parse the following text and return a JSON object with these fields:
- type: "sale", "expense", or "purchase"
- item: the item name or "Unknown" - ONLY the product name, NEVER include quantity or numbers in the item name
- quantity: number (default 1) - ALWAYS convert word numbers to numeric values: "one"=1, "two"=2, "three"=3, "four"=4, "five"=5, "six"=6, "seven"=7, "eight"=8, "nine"=9, "ten"=10, "a"=1, "an"=1
- unit: unit of measure (default "pcs")
- unitPrice: price per unit (0 if not specified)
- total: total amount
- category: one of "Food & Beverages", "Household", "Transport", "Communication", "Utilities", "Medical", "Clothing", "Personal Care", "Other"

CRITICAL RULES - FOLLOW THESE EXACTLY:
1. ALWAYS extract the quantity as a NUMBER. If text says "three bread", quantity MUST be 3, NOT "three"
2. The item field must be ONLY the product name. "three bread" → item: "bread", quantity: 3
3. NEVER put quantity words in the item field. "five milk" → item: "milk", quantity: 5 (NOT item: "five milk")
4. Word numbers must be converted: one/two/three/four/five/six/seven/eight/nine/ten/a/an = 1/2/3/4/5/6/7/8/9/10/1/1
5. When you see patterns like "three bread at 2000" or "three breads each at 2000", extract: item="bread", quantity=3, unitPrice=2000
6. The word "each" or "at" before the price indicates per-unit price

Example inputs and outputs:
"I sold bread 3 pieces at 5000" → {"type":"sale","item":"bread","quantity":3,"unit":"pcs","unitPrice":5000,"total":15000,"category":"Food & Beverages"}
"I sold three bread at 2000" → {"type":"sale","item":"bread","quantity":3,"unit":"pcs","unitPrice":2000,"total":6000,"category":"Food & Beverages"}
"sold three breads each at 2000" → {"type":"sale","item":"breads","quantity":3,"unit":"pcs","unitPrice":2000,"total":6000,"category":"Food & Beverages"}
"sold five milk at 1500" → {"type":"sale","item":"milk","quantity":5,"unit":"pcs","unitPrice":1500,"total":7500,"category":"Food & Beverages"}
"sold two soap at 3000" → {"type":"sale","item":"soap","quantity":2,"unit":"pcs","unitPrice":3000,"total":6000,"category":"Personal Care"}
"sold a cake at 5000" → {"type":"sale","item":"cake","quantity":1,"unit":"pcs","unitPrice":5000,"total":5000,"category":"Food & Beverages"}
"sold ten phones at 50000" → {"type":"sale","item":"phones","quantity":10,"unit":"pcs","unitPrice":50000,"total":500000,"category":"Communication"}
"spent transport 5000" → {"type":"expense","item":"transport","quantity":1,"unit":"pcs","unitPrice":0,"total":5000,"category":"Transport"}
"bought sugar 2 packets at 3000" → {"type":"purchase","item":"sugar","quantity":2,"unit":"packets","unitPrice":3000,"total":6000,"category":"Food & Beverages"}
"bought ten rice at 25000" → {"type":"purchase","item":"rice","quantity":10,"unit":"pcs","unitPrice":2500,"total":25000,"category":"Food & Beverages"}

Return ONLY the JSON object, no explanation.

Text to parse: $text''';

      final response = await http
          .post(
            Uri.parse('$_apiUrl?key=$_apiKey'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.1,
                'maxOutputTokens': 200,
              }
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content =
            data['candidates'][0]['content']['parts'][0]['text'] as String;

        // Parse the JSON response
        final parsed = _parseJSONResponse(content);
        if (parsed != null) {
          debugPrint('GeminiParserService: Successfully parsed using Gemini');
          return parsed;
        }
      } else if (response.statusCode == 401) {
        debugPrint('GeminiParserService: Unauthorized - Invalid API key');
      } else if (response.statusCode == 429) {
        debugPrint('GeminiParserService: Rate limit exceeded');
      } else {
        debugPrint('GeminiParserService: API error - ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('GeminiParserService: Exception - $e');
    }

    // Fallback to local NLP if Gemini fails
    debugPrint('GeminiParserService: Falling back to local NLP');
    return _parseTransactionWithLocalNLP(text);
  }

  /// Parse JSON response from Gemini
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
      debugPrint('GeminiParserService: JSON parse error - $e');
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
      debugPrint('GeminiParserService: Local NLP error - $e');
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
      debugPrint('GeminiParserService: Local NLP product error - $e');
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
      debugPrint('GeminiParserService: Local NLP supplier error - $e');
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
      debugPrint('GeminiParserService: Local NLP customer error - $e');
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
      debugPrint('GeminiParserService: Local NLP category error - $e');
      return null;
    }
  }

  /// Answer general queries about shop data using Gemini
  /// Returns a natural language response or null if failed
  static Future<String?> answerQuery(String query, String contextData) async {
    if (query.isEmpty) return null;

    // If API key is not set, try to use a simpler local fallback with the context data
    if (!isApiKeyConfigured) {
      debugPrint('GeminiParserService: No API key configured for query');
      // Generate a conversational response from the context data directly
      return _generateLocalQueryResponse(query, contextData);
    }

    try {
      // Build a more comprehensive and dynamic prompt based on query type
      final queryLower = query.toLowerCase();
      String queryTypeHint = '';
      String responseStyle = '';

      // Add specific hints based on query type to get better responses
      if (queryLower.contains('profit') ||
          queryLower.contains('earn') ||
          queryLower.contains('loss')) {
        queryTypeHint =
            'The user is asking about PROFIT or EARNINGS. Provide specific profit numbers with calculations, compare with previous periods, and offer insights about how to improve profit.';
        responseStyle =
            'Be encouraging about profits. Calculate profit margins and suggest ways to increase profitability.';
      } else if (queryLower.contains('sale') ||
          queryLower.contains('sold') ||
          queryLower.contains('revenue') ||
          queryLower.contains('income')) {
        queryTypeHint =
            'The user is asking about SALES or REVENUE. Provide specific sales figures from the context data, analyze trends, and identify patterns.';
        responseStyle =
            'Celebrate good sales performance and suggest ways to increase sales. Use actual numbers from the context.';
      } else if (queryLower.contains('expense') ||
          queryLower.contains('spent') ||
          queryLower.contains('cost')) {
        queryTypeHint =
            'The user is asking about EXPENSES. Provide specific expense breakdowns from the context and suggest cost-saving tips.';
        responseStyle =
            'Help identify areas where expenses can be reduced. Use actual expense numbers.';
      } else if (queryLower.contains('inventory') ||
          queryLower.contains('stock') ||
          queryLower.contains('product')) {
        queryTypeHint =
            'The user is asking about INVENTORY or PRODUCTS. Use the top selling products from the context to provide insights.';
        responseStyle =
            'Suggest which products to restock based on sales data and which are popular. Use the product data provided.';
      } else if (queryLower.contains('customer') ||
          queryLower.contains('client')) {
        queryTypeHint =
            'The user is asking about CUSTOMERS. Provide insights based on available transaction data.';
        responseStyle =
            'Suggest ways to attract and retain customers based on transaction patterns.';
      } else if (queryLower.contains('supplier') ||
          queryLower.contains('vendor')) {
        queryTypeHint =
            'The user is asking about SUPPLIERS. Provide supplier-related information from transactions.';
        responseStyle =
            'Suggest ways to improve supplier relationships and manage purchases.';
      } else if (queryLower.contains('report') ||
          queryLower.contains('summary') ||
          queryLower.contains('overview')) {
        queryTypeHint =
            'The user is asking for a REPORT or SUMMARY. Provide comprehensive business overview using ALL the numerical data.';
        responseStyle =
            'Make the report easy to understand with clear insights. Always include actual numbers.';
      } else if (queryLower.contains('how much') ||
          queryLower.contains('total') ||
          queryLower.contains('amount')) {
        queryTypeHint =
            'The user is asking for AMOUNTS/TOTALS. Provide specific numerical values with currency (UGX) from the context data.';
        responseStyle =
            'Give clear, specific numbers with explanations. Always include the exact values.';
      } else if (queryLower.contains('how many') ||
          queryLower.contains('count') ||
          queryLower.contains('number')) {
        queryTypeHint =
            'The user is asking for COUNTS/NUMBERS. Provide specific counts from the context data.';
        responseStyle =
            'Be precise with numbers. Use transaction counts and product counts.';
      } else if (queryLower.contains('compare') ||
          queryLower.contains('vs') ||
          queryLower.contains('versus')) {
        queryTypeHint =
            'The user is asking for a COMPARISON. Compare different metrics or time periods using the data provided.';
        responseStyle =
            'Use comparison with clear numbers. Show today vs week vs month.';
      } else if (queryLower.contains('best') ||
          queryLower.contains('top') ||
          queryLower.contains('popular')) {
        queryTypeHint =
            'The user is asking about TOP/BEST performers. Use the top products and categories from the context data.';
        responseStyle =
            'Highlight success stories from the product data and suggest how to build on them.';
      } else if (queryLower.contains('recommend') ||
          queryLower.contains('suggest') ||
          queryLower.contains('advice')) {
        queryTypeHint =
            'The user is asking for RECOMMENDATIONS. Provide actionable business advice based on the actual data.';
        responseStyle =
            'Give practical, actionable suggestions the shop owner can implement immediately.';
      } else if (queryLower.contains('trend') ||
          queryLower.contains('growth') ||
          queryLower.contains('increase') ||
          queryLower.contains('decrease')) {
        queryTypeHint =
            'The user is asking about TRENDS. Analyze the comparative data to explain growth or decline patterns.';
        responseStyle =
            'Explain what the trends mean for the business and suggest responses based on the numbers.';
      } else if (queryLower.contains('hello') ||
          queryLower.contains('hi') ||
          queryLower.contains('hey')) {
        queryTypeHint =
            'The user is GREETING you. Give a warm, friendly response and briefly mention what you can help with.';
        responseStyle =
            'Be warm and conversational. Use emojis to make it friendly but not overwhelming.';
      } else if (queryLower.contains('thank')) {
        queryTypeHint =
            'The user is EXPRESSING THANKS. Respond warmly and offer further assistance.';
        responseStyle =
            'Be gracious and friendly. Offer to help with more questions about their business.';
      } else {
        // Generic query - provide helpful response
        queryTypeHint =
            'The user is asking a general business question. Provide a helpful, informative response based on their data.';
        responseStyle =
            'Be conversational and helpful. ALWAYS use the numbers from the context data.';
      }

      final prompt =
          '''You are iSmart AI, a friendly and knowledgeable business assistant for a small shop owner in Uganda. Your role is to help the owner understand their business better and make smart decisions.

Your Personality:
- Warm, encouraging, and genuinely helpful
- Use conversational language (like talking to a friend)
- Be specific with numbers - ALWAYS include actual figures from the provided context data
- Provide insights that help the owner make better decisions
- Celebrate wins and offer constructive solutions for challenges
- Use emojis naturally to make responses engaging but not overwhelming
- Keep responses concise but packed with useful information
- IMPORTANT: NEVER use template placeholders like [NUMBER] - always use the actual numbers from the data

CRITICAL - Response Style:
$responseStyle

IMPORTANT - Query Analysis:
$queryTypeHint

CRITICAL INSTRUCTIONS FOR YOUR RESPONSE:
1. ALWAYS respond in English
2. ALWAYS include specific numbers from the context data - NEVER give vague answers without numbers
3. Format money with commas (e.g., 15,000 not 15000)
4. Currency is UGX (Ugandan Shillings)
5. If the data shows 0 or no transactions, encourage the owner to start recording
6. If there is enough data for a specific answer, provide it with exact numbers
7. NEVER just repeat the numbers - explain what they MEAN for the business
8. Offer at least one actionable suggestion when relevant
9. Use the top products and categories data when answering questions about popular items
10. Reference the time periods (today, this week, this month) in your analysis
11. NEVER use brackets or placeholders like [X] - always use actual values or say "no data" if unavailable

Context Data (Your shop's actual business data - YOU MUST USE THIS DATA):
$contextData

User Question: $query

Remember: Your response should make the owner feel supported and informed. Be specific with actual numbers, be helpful, and make their data work for them!''';

      final response = await http
          .post(
            Uri.parse('$_apiUrl?key=$_apiKey'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.9,
                'maxOutputTokens': 800,
                'topP': 0.95,
                'topK': 40,
              }
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content =
            data['candidates'][0]['content']['parts'][0]['text'] as String;

        debugPrint('GeminiParserService: Successfully answered query');
        debugPrint('Query: $query');
        debugPrint('Response: $content');
        return content.trim();
      } else if (response.statusCode == 401) {
        debugPrint('GeminiParserService: Unauthorized - Invalid API key');
        return '⚠️ Your Gemini API key appears to be invalid. Please check your settings.';
      } else if (response.statusCode == 429) {
        debugPrint('GeminiParserService: Rate limit exceeded');
        return '⏳ Too many requests. Please wait a moment and try again.';
      } else if (response.statusCode == 500) {
        debugPrint('GeminiParserService: Gemini server error');
        return '🔧 Gemini service is temporarily unavailable. Please try again later.';
      } else {
        debugPrint('GeminiParserService: API error - ${response.statusCode}');
        return '❓ I couldn\'t process your request right now. Please try again.';
      }
    } catch (e) {
      debugPrint('GeminiParserService: Query exception - $e');
      if (e.toString().contains('TimeoutException')) {
        return '⏱️ Request timed out. Please check your internet connection and try again.';
      }
      return '🤔 Something went wrong. Please try again.';
    }
  }

  /// Generate a conversational response when API key is not configured
  static String? _generateLocalQueryResponse(String query, String contextData) {
    try {
      final queryLower = query.toLowerCase();

      // Parse context data to extract key numbers
      final todaySales = _extractValue(contextData, "Today's Sales:");
      final todayExpenses = _extractValue(contextData, "Today's Expenses:");
      final todayProfit = _extractValue(contextData, "Today's Profit:");
      final weekSales = _extractValue(contextData, "This Week's Sales:");
      final weekProfit = _extractValue(contextData, "This Week's Profit:");
      final monthSales = _extractValue(contextData, "This Month's Sales:");
      final monthProfit = _extractValue(contextData, "This Month's Profit:");
      final totalTransactions =
          _extractValue(contextData, "Total Transactions:");

      // Handle greetings
      if (queryLower.contains('hello') ||
          queryLower.contains('hi') ||
          queryLower.contains('hey')) {
        return '👋 Hey there! I\'m iSmart AI, your business assistant! 📊\n\n'
            'I can help you track sales, expenses, and answer questions about your shop.\n\n'
            'Currently you have ${totalTransactions.toInt()} transactions recorded. '
            '${todaySales > 0 ? "Today's sales are looking good at UGX ${_formatNumber(todaySales)}!" : "Start recording to see your numbers!"}\n\n'
            'Just ask me anything like "How much did I sell today?" or "What\'s my profit this week?" 🚀';
      }

      // Handle profit queries
      if (queryLower.contains('profit') ||
          queryLower.contains('earn') ||
          queryLower.contains('loss')) {
        final profit = todayProfit > 0
            ? todayProfit
            : weekProfit > 0
                ? weekProfit
                : monthProfit;
        if (profit > 0) {
          return '📈 Great news on profits! 🎉\n\n'
              'Today\'s profit: UGX ${_formatNumber(todayProfit)}\n'
              'This week: UGX ${_formatNumber(weekProfit)}\n'
              'This month: UGX ${_formatNumber(monthProfit)}\n\n'
              'Your profit margin is looking healthy! Keep up the good work. 💪\n\n'
              '${totalTransactions > 0 ? "You've completed ${totalTransactions.toInt()} transactions this month." : "Start recording to track your profit!"}';
        } else if (profit == 0 && todaySales > 0) {
          return '📊 Profit Update\n\n'
              'Today\'s profit: UGX ${_formatNumber(todayProfit)}\n'
              'This week: UGX ${_formatNumber(weekProfit)}\n\n'
              'You\'re breaking even today! Here\'s a tip: try to reduce small expenses to increase your profit margin. 💡';
        } else {
          return '📈 Starting Your Profit Journey! 🚀\n\n'
              'I don\'t see any profit data yet, but don\'t worry - every big business started somewhere!\n\n'
              'Tips to boost profit:\n'
              '• Track all your sales and expenses\n'
              '• Focus on high-margin items\n'
              '• Reduce unnecessary costs\n\n'
              'Start recording transactions and I\'ll help you track your progress! 📝';
        }
      }

      // Handle sales queries
      if (queryLower.contains('sale') ||
          queryLower.contains('sold') ||
          queryLower.contains('revenue') ||
          queryLower.contains('income')) {
        if (todaySales > 0) {
          return '🛒 Your Sales Update 📊\n\n'
              '📅 Today: UGX ${_formatNumber(todaySales)}\n'
              '📆 This week: UGX ${_formatNumber(weekSales)}\n'
              '📆 This month: UGX ${_formatNumber(monthSales)}\n\n'
              '${todaySales >= weekSales / 7 ? "You're doing great today - above your daily average! 🌟" : "Keep pushing! Every sale counts. 💪"}\n\n'
              'Want to see more details? Just ask! 😊';
        } else {
          return '🛒 No Sales Recorded Yet 📝\n\n'
              'Today\'s sales: UGX 0\n\n'
              'Every big sale starts with a first step! Record your first transaction and I\'ll help you track your progress.\n\n'
              'Try saying: "I sold 3 bread at 2000" or "Sold 2 milk at 1500" 🎯';
        }
      }

      // Handle expense queries
      if (queryLower.contains('expense') ||
          queryLower.contains('spent') ||
          queryLower.contains('cost')) {
        if (todayExpenses > 0) {
          return '💸 Your Expenses Summary\n\n'
              '📅 Today: UGX ${_formatNumber(todayExpenses)}\n\n'
              'Tip: Keep an eye on daily expenses to maximize your profit! 💡';
        } else {
          return '💸 Great Job! 💪\n\n'
              'No expenses recorded today - that\'s how you maximize profit!\n\n'
              'Remember to track expenses by saying "Spent 5000 on transport" or "Paid 10000 for rent" 📝';
        }
      }

      // Handle "how much" / totals
      if (queryLower.contains('how much') ||
          queryLower.contains('total') ||
          queryLower.contains('amount')) {
        return '📊 Your Business Summary 📈\n\n'
            "Today's Sales: UGX ${_formatNumber(todaySales)}\n"
            "Today's Expenses: UGX ${_formatNumber(todayExpenses)}\n"
            "Today's Profit: UGX ${_formatNumber(todayProfit)}\n\n"
            'This Week: UGX ${_formatNumber(weekSales)} in sales\n'
            'This Month: UGX ${_formatNumber(monthSales)} in sales\n\n'
            '${totalTransactions > 0 ? "Total ${totalTransactions.toInt()} transactions recorded!" : "Start recording to see your numbers!"}\n\n'
            'Need more details? Just ask! 😊';
      }

      // Handle inventory/product queries
      if (queryLower.contains('inventory') ||
          queryLower.contains('stock') ||
          queryLower.contains('product')) {
        return '📦 Inventory & Products\n\n'
            '${totalTransactions > 0 ? "You have ${totalTransactions.toInt()} transactions recorded." : "No transactions yet."}\n\n'
            'To add products to your inventory:\n'
            '1. Go to the Inventory screen\n'
            '2. Tap "Add Product" button\n'
            '3. Enter product details\n\n'
            'Or ask me: "Add product Sugar, price 5000, quantity 20" 📝';
      }

      // Handle customer queries
      if (queryLower.contains('customer') || queryLower.contains('client')) {
        return '👤 Customer Management\n\n'
            'I can help you track customers and their purchases!\n\n'
            'To add customers:\n'
            '1. Go to the Customers screen\n'
            '2. Tap "Add Customer" button\n\n'
            'Or say: "Add customer John, phone 0772123456" 📝';
      }

      // Handle thank you
      if (queryLower.contains('thank')) {
        return '😊 You\'re so welcome! 😊\n\n'
            'Happy to help you grow your business! 💪\n\n'
            'Feel free to ask me anything - sales, expenses, profits, or just chat! 🎯';
      }

      // Generic fallback with actual data
      if (todaySales > 0 || todayExpenses > 0) {
        return '📊 Here\'s your quick overview:\n\n'
            'Today\'s Sales: UGX ${_formatNumber(todaySales)}\n'
            'Today\'s Expenses: UGX ${_formatNumber(todayExpenses)}\n'
            'Today\'s Profit: UGX ${_formatNumber(todayProfit)}\n'
            'Total Transactions: ${totalTransactions.toInt()}\n\n'
            'Ask me about:\n'
            '• "How much did I sell?"\n'
            '• "What\'s my profit?"\n'
            '• "Show my expenses"\n\n'
            'I\'m here to help! 🎯';
      }

      // Default welcome for new users
      return '👋 Hello! I\'m iSmart AI! 🚀\n\n'
          'I\'m here to help you manage your shop. Here\'s what I can do:\n\n'
          '📝 Record transactions:\n'
          '• "Sold 5 bread at 2000"\n'
          '• "Spent 10000 on transport"\n\n'
          '💰 Answer questions:\n'
          '• "How much did I sell today?"\n'
          '• "What\'s my profit?"\n\n'
          '📦 Add products, customers, suppliers\n\n'
          'Start recording your first transaction and watch your business grow! 📈';
    } catch (e) {
      debugPrint('Error generating local query response: $e');
      return null;
    }
  }

  static double _extractValue(String data, String key) {
    try {
      final regex = RegExp('$key\\s*UGX\\s*([\\d,.]+)');
      final match = regex.firstMatch(data);
      if (match != null) {
        final valueStr = match.group(1)?.replaceAll(',', '') ?? '0';
        return double.tryParse(valueStr) ?? 0;
      }
    } catch (e) {
      debugPrint('Error extracting value for $key: $e');
    }
    return 0;
  }

  static String _formatNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return NumberFormat('#,###').format(value);
    }
    return value.toStringAsFixed(0);
  }

  /// Parse product text using Gemini
  /// Returns a map with parsed product data or null if failed
  static Future<Map<String, dynamic>?> parseProduct(String text) async {
    if (text.isEmpty) return null;

    // If API key is not set, use local NLP
    if (!isApiKeyConfigured) {
      debugPrint(
          'GeminiParserService: No API key configured for product parsing, using local NLP');
      return _parseProductWithLocalNLP(text);
    }

    try {
      final prompt = '''You are a product parser for a small shop in Uganda.
Parse the following text and return a JSON object with these fields:
- name: the product name
- category: one of "Food & Beverages", "Household", "Transport", "Communication", "Utilities", "Medical", "Clothing", "Personal Care", "Other"
- price: price per unit (0 if not specified)
- quantity: number (default 0)
- unit: unit of measure (default "pcs")

Example inputs and outputs:
"Add product Bread, category Food, price 5000, quantity 100 pieces" → {"name":"Bread","category":"Food & Beverages","price":5000,"quantity":100,"unit":"pcs"}
"New item Sugar 2kg at 3000" → {"name":"Sugar","category":"Food & Beverages","price":3000,"quantity":2,"unit":"kgs"}

Return ONLY the JSON object, no explanation.

Text to parse: $text''';

      final response = await http
          .post(
            Uri.parse('$_apiUrl?key=$_apiKey'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.1,
                'maxOutputTokens': 200,
              }
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content =
            data['candidates'][0]['content']['parts'][0]['text'] as String;

        // Parse the JSON response
        final parsed = _parseProductJSONResponse(content);
        if (parsed != null) {
          debugPrint(
              'GeminiParserService: Successfully parsed product using Gemini');
          return parsed;
        }
      } else {
        debugPrint('GeminiParserService: API error - ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('GeminiParserService: Product parse exception - $e');
    }

    // Fallback to local NLP if Gemini fails
    debugPrint(
        'GeminiParserService: Falling back to local NLP for product parsing');
    return _parseProductWithLocalNLP(text);
  }

  /// Parse product JSON response from Gemini
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
      debugPrint('GeminiParserService: Product JSON parse error - $e');
    }
    return null;
  }

  /// Parse supplier text using Gemini
  /// Returns a map with parsed supplier data or null if failed
  static Future<Map<String, dynamic>?> parseSupplier(String text) async {
    if (text.isEmpty) return null;

    // If API key is not set, use local NLP
    if (!isApiKeyConfigured) {
      debugPrint(
          'GeminiParserService: No API key configured for supplier parsing, using local NLP');
      return _parseSupplierWithLocalNLP(text);
    }

    try {
      final prompt = '''You are a supplier parser for a small shop in Uganda.
Parse the following text and return a JSON object with these fields:
- name: the supplier name
- phone: phone number (empty string if not specified)
- email: email address (empty string if not specified)
- address: physical address (empty string if not specified)

Example inputs and outputs:
"Add supplier ABC Distributors, phone 0700123456" → {"name":"ABC Distributors","phone":"0700123456","email":"","address":""}
"New vendor XYZ Company, email xyz@example.com, address Kampala" → {"name":"XYZ Company","phone":"","email":"xyz@example.com","address":"Kampala"}

Return ONLY the JSON object, no explanation.

Text to parse: $text''';

      final response = await http
          .post(
            Uri.parse('$_apiUrl?key=$_apiKey'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.1,
                'maxOutputTokens': 200,
              }
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content =
            data['candidates'][0]['content']['parts'][0]['text'] as String;

        // Parse the JSON response
        final parsed = _parseSupplierJSONResponse(content);
        if (parsed != null) {
          debugPrint(
              'GeminiParserService: Successfully parsed supplier using Gemini');
          return parsed;
        }
      } else {
        debugPrint('GeminiParserService: API error - ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('GeminiParserService: Supplier parse exception - $e');
    }

    // Fallback to local NLP if Gemini fails
    debugPrint(
        'GeminiParserService: Falling back to local NLP for supplier parsing');
    return _parseSupplierWithLocalNLP(text);
  }

  /// Parse supplier JSON response from Gemini
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
      debugPrint('GeminiParserService: Supplier JSON parse error - $e');
    }
    return null;
  }

  /// Parse customer text using Gemini
  /// Returns a map with parsed customer data or null if failed
  static Future<Map<String, dynamic>?> parseCustomer(String text) async {
    if (text.isEmpty) return null;

    // If API key is not set, use local NLP
    if (!isApiKeyConfigured) {
      debugPrint(
          'GeminiParserService: No API key configured for customer parsing, using local NLP');
      return _parseCustomerWithLocalNLP(text);
    }

    try {
      final prompt = '''You are a customer parser for a small shop in Uganda.
Parse the following text and return a JSON object with these fields:
- name: the customer name
- phone: phone number (empty string if not specified)
- email: email address (empty string if not specified)
- address: physical address (empty string if not specified)

Example inputs and outputs:
"Add customer John Doe, phone 0700123456" → {"name":"John Doe","phone":"0700123456","email":"","address":""}
"New client Mary, email mary@example.com, address Kampala" → {"name":"Mary","phone":"","email":"mary@example.com","address":"Kampala"}

Return ONLY the JSON object, no explanation.

Text to parse: $text''';

      final response = await http
          .post(
            Uri.parse('$_apiUrl?key=$_apiKey'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.1,
                'maxOutputTokens': 200,
              }
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content =
            data['candidates'][0]['content']['parts'][0]['text'] as String;

        // Parse the JSON response
        final parsed = _parseCustomerJSONResponse(content);
        if (parsed != null) {
          debugPrint(
              'GeminiParserService: Successfully parsed customer using Gemini');
          return parsed;
        }
      } else {
        debugPrint('GeminiParserService: API error - ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('GeminiParserService: Customer parse exception - $e');
    }

    // Fallback to local NLP if Gemini fails
    debugPrint(
        'GeminiParserService: Falling back to local NLP for customer parsing');
    return _parseCustomerWithLocalNLP(text);
  }

  /// Parse customer JSON response from Gemini
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
      debugPrint('GeminiParserService: Customer JSON parse error - $e');
    }
    return null;
  }

  /// Parse category text using Gemini
  /// Returns a map with parsed category data or null if failed
  static Future<Map<String, dynamic>?> parseCategory(String text) async {
    if (text.isEmpty) return null;

    // If API key is not set, use local NLP
    if (!isApiKeyConfigured) {
      debugPrint(
          'GeminiParserService: No API key configured for category parsing, using local NLP');
      return _parseCategoryWithLocalNLP(text);
    }

    try {
      final prompt = '''You are a category parser for a small shop in Uganda.
Parse the following text and return a JSON object with these fields:
- name: the category name
- description: category description (empty string if not specified)

Example inputs and outputs:
"Add category Food, description for edible products" → {"name":"Food","description":"for edible products"}
"New type Electronics" → {"name":"Electronics","description":""}

Return ONLY the JSON object, no explanation.

Text to parse: $text''';

      final response = await http
          .post(
            Uri.parse('$_apiUrl?key=$_apiKey'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.1,
                'maxOutputTokens': 200,
              }
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content =
            data['candidates'][0]['content']['parts'][0]['text'] as String;

        // Parse the JSON response
        final parsed = _parseCategoryJSONResponse(content);
        if (parsed != null) {
          debugPrint(
              'GeminiParserService: Successfully parsed category using Gemini');
          return parsed;
        }
      } else {
        debugPrint('GeminiParserService: API error - ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('GeminiParserService: Category parse exception - $e');
    }

    // Fallback to local NLP if Gemini fails
    debugPrint(
        'GeminiParserService: Falling back to local NLP for category parsing');
    return _parseCategoryWithLocalNLP(text);
  }

  /// Parse category JSON response from Gemini
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
      debugPrint('GeminiParserService: Category JSON parse error - $e');
    }
    return null;
  }
}

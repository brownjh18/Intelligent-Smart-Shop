import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:ismart_shop/models/transaction.dart';
import 'package:ismart_shop/models/transaction_item.dart';
import 'package:ismart_shop/providers/auth_provider.dart';
import 'package:ismart_shop/providers/language_provider.dart';
import 'package:ismart_shop/providers/transaction_provider.dart';
import 'package:ismart_shop/services/speech_service.dart';
import 'package:ismart_shop/services/nlp_service.dart';
import 'package:ismart_shop/services/whisper_service.dart';
import 'package:ismart_shop/services/gemini_parser_service.dart';
import 'package:ismart_shop/services/translation_service.dart';
import 'package:ismart_shop/services/local_database_service.dart';
import 'package:ismart_shop/utils/ios_theme.dart';
import 'package:ismart_shop/widgets/ios_app_bar.dart';
import 'package:ismart_shop/widgets/app_bottom_nav.dart';
import 'package:ismart_shop/widgets/voice_button.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'categories_screen.dart';
import 'customers_screen.dart';
import 'home_screen.dart';
import 'inventory_screen.dart';
import 'receipts_screen.dart';
import 'reports_screen.dart';
import 'suppliers_screen.dart';
import 'transactions_list_screen.dart';

// Chat message model
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final ChatMessageType type;
  final Map<String, dynamic>? data;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.type = ChatMessageType.text,
    this.data,
  });
}

enum ChatMessageType {
  text,
  query,
  transaction,
  profit,
  receipt,
  inventory,
  supplier,
  customer,
  category,
  error,
}

class VoiceRecordingScreen extends StatefulWidget {
  const VoiceRecordingScreen({super.key});

  @override
  State<VoiceRecordingScreen> createState() => _VoiceRecordingScreenState();
}

class _VoiceRecordingScreenState extends State<VoiceRecordingScreen>
    with TickerProviderStateMixin {
  SpeechService? _speechService;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  String _transcribedText = '';
  // State variables
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isProcessing = false;
  String _statusMessage = 'Tap the microphone or type your query';
  bool _isInitializing = false;

  // Recording duration tracking
  int _recordingDuration = 0;
  Timer? _recordingTimer;
  static const int _maxRecordingDuration = 30;

  // Chat history
  final List<ChatMessage> _chatMessages = [];

  // Transaction review state
  bool _showTransactionReview = false;
  TransactionIntent? _currentTransactionIntent;
  late TransactionType _transactionType;
  late String _transactionDescription;
  late String _transactionCategory;
  late int _transactionQuantity;
  late String _transactionUnit;
  late double _transactionUnitPrice;
  late String _transactionCustomerName;
  late String _transactionNotes;

  // Inline editing state
  bool _isEditingQuantity = false;
  bool _isEditingUnitPrice = false;

  // Controllers for editing transaction
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Controllers for inline editing
  final TextEditingController _inlineQuantityController =
      TextEditingController();
  final TextEditingController _inlineUnitPriceController =
      TextEditingController();

  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _addWelcomeMessage();
    // Initialize AI services - Whisper for speech and Gemini for AI understanding
    WhisperService.initialize();
    GeminiParserService.initialize();
    // Initialize speech service
    _initializeSpeechService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reinitialize speech service when returning to this page
    // This ensures the voice button works after leaving and returning
    // Use a post-frame callback to ensure widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _resetVoiceState();
      }
    });
  }

  /// Reset voice-related state when returning to the page
  void _resetVoiceState() {
    debugPrint('=== VoiceRecordingScreen: Resetting voice state ===');

    // Stop any ongoing speech service
    if (_speechService != null) {
      try {
        _speechService!.stopListening();
      } catch (e) {
        debugPrint('Error stopping speech service: $e');
      }
    }

    // Cancel any recording timer
    _recordingTimer?.cancel();
    _recordingTimer = null;

    // Stop animations safely
    if (_pulseController.isAnimating) {
      _pulseController.stop();
    }
    if (_waveController.isAnimating) {
      _waveController.stop();
    }

    // Only update state and reinitialize if widget is still active
    if (!mounted) {
      debugPrint(
          '=== VoiceRecordingScreen: Widget not mounted, skipping reset ===');
      return;
    }

    // Reset all voice-related state
    setState(() {
      _isListening = false;
      _isProcessing = false;
      _isInitialized = false;
      _statusMessage = 'Tap the microphone or type your query';
      _recordingDuration = 0;
    });

    // Reinitialize the speech service
    _initializeSpeechService();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
  }

  void _addWelcomeMessage() {
    _chatMessages.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: 'Hello! I\'m your iSmart AI assistant. I can help you with:\n\n'
          '📝 **Transactions:**\n'
          '• Record sales, expenses, and purchases\n'
          '• "Sold 5 bread at 2000"\n'
          '• "Spent 10000 on transport"\n'
          '• "Bought 10 packets sugar at 5000"\n'
          '• "Sold 2 bread and 3 milk at 2000 each" (multiple items)\n\n'
          '🖨️ **Printing:**\n'
          '• Print receipts, invoices, and reports\n'
          '• "Print my last receipt"\n'
          '• "Print my daily report"\n'
          '• "Print invoice for John"\n\n'
          '📦 **Entity Management:**\n'
          '• Add products, suppliers, and customers\n'
          '• "Add product Bread, price 5000"\n\n'
          '💰 **Business Queries:**\n'
          '• Check profits, sales, and expenses\n'
          '• "How much did I sell today?"\n\n'
          '⚡ **After Transaction Review:**\n'
          '• Say "Yes" or "Save" to confirm\n'
          '• Say "No" or "Cancel" to cancel\n'
          '• Say "Edit" to modify\n'
          '• Say "Print" to print receipt\n\n'
          'Just speak or type your request!',
      isUser: false,
      timestamp: DateTime.now(),
      type: ChatMessageType.text,
    ));
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _speechService?.stopListening();
    _pulseController.stop();
    _waveController.stop();
    _pulseController.dispose();
    _waveController.dispose();
    _textController.dispose();
    _chatScrollController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _customerNameController.dispose();
    _notesController.dispose();
    _inlineQuantityController.dispose();
    _inlineUnitPriceController.dispose();
    super.dispose();
  }

  // Create a fresh speech service instance
  Future<void> _initializeSpeechService() async {
    debugPrint('=== VoiceRecordingScreen: Initializing speech service ===');

    // Stop any previous speech service first
    if (_speechService != null) {
      try {
        // Use the new stopAndReset method for clean state
        await _speechService!.stopAndReset();
      } catch (e) {
        debugPrint('Error stopping previous speech service: $e');
      }
    }

    // Create a new speech service instance each time to avoid state issues
    _speechService = SpeechService();

    // Reset state
    _isInitialized = false;
    _isListening = false;
    _statusMessage = 'Initializing voice recognition...';

    if (mounted) {
      setState(() {});
    }

    // Force reinitialize the speech service for a clean start
    final success = await _speechService!.forceReinitialize();

    if (mounted) {
      setState(() {
        _isInitialized = success;
        if (!_isInitialized) {
          _statusMessage = 'Voice unavailable. Type your query.';
        } else {
          _statusMessage = 'Tap the microphone or type your query';
        }
      });
      debugPrint(
          '=== VoiceRecordingScreen: Speech service initialized: $success ===');
    }
  }

  Future<void> _initializeSpeech() async {
    if (_isInitializing) {
      // Wait for existing initialization to complete
      int attempts = 0;
      while (_isInitializing && attempts < 20) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      return;
    }

    _isInitializing = true;
    try {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        if (mounted) {
          setState(() {
            _isInitialized = false;
            _statusMessage = 'Microphone permission denied. Type instead.';
          });
        }
        return;
      }

      _speechService!.reset();
      final success = await _speechService!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = success;
          if (!_isInitialized) {
            _statusMessage = 'Voice unavailable. Type your query.';
          }
        });
      }
    } catch (e) {
      debugPrint('Error initializing speech: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _statusMessage = 'Voice unavailable. Type your query.';
        });
      }
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _startRecording() async {
    debugPrint('=== VoiceRecordingScreen: _startRecording called ===');
    debugPrint(
        'State: _isListening=$_isListening, _isInitialized=$_isInitialized, _isProcessing=$_isProcessing');

    // If already listening, stop first
    if (_isListening) {
      debugPrint('Already listening, stopping first');
      await _stopRecording();
      // Small delay to ensure clean state before starting again
      await Future.delayed(const Duration(milliseconds: 500));
      debugPrint('After stop, state: _isListening=$_isListening');
    }

    // Always reset processing state before starting new recording
    // This ensures the button works even if _isProcessing was stuck
    if (_isProcessing) {
      debugPrint('Resetting stuck processing state');
      setState(() {
        _isProcessing = false;
      });
    }

    // Check microphone permission
    final micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      final result = await Permission.microphone.request();
      if (!result.isGranted) {
        _showErrorDialog(
            'Microphone permission is required for voice recording.');
        return;
      }
    }

    // Get the locale for speech recognition
    final languageProvider = context.read<LanguageProvider>();
    final localeId =
        await _getBestLocaleForSpeech(languageProvider.currentLanguage);

    debugPrint('=== VoiceRecordingScreen: Starting speech recognition ===');

    try {
      // Create a fresh speech service instance for each recording attempt
      // This ensures clean state and avoids issues from previous sessions
      debugPrint('Creating new speech service instance for fresh recording');
      _speechService = SpeechService();

      // Initialize the speech service
      setState(() {
        _statusMessage = 'Initializing voice recognition...';
      });

      final initSuccess = await _speechService!.initialize();

      if (!initSuccess) {
        debugPrint('Speech service initialization failed');
        setState(() {
          _isInitialized = false;
          _statusMessage = 'Voice unavailable. Type your query.';
        });
        return;
      }

      setState(() {
        _isInitialized = true;
      });

      // Start listening
      debugPrint('Starting speech recognition with locale: $localeId');
      final success = await _speechService!.startListening(localeId: localeId);

      if (success) {
        // Give a small delay to ensure the status callback has time to fire
        await Future.delayed(const Duration(milliseconds: 300));

        // Check if we're actually listening - if not, force the state
        if (!_speechService!.isListening) {
          debugPrint(
              'Speech service reports not listening, but trying to force state');
        }

        setState(() {
          _isListening = true;
          _transcribedText = '';
          _recordingDuration = 0;
          _statusMessage = 'Listening... Speak now (0s)';
        });

        // Start animations
        _pulseController.repeat(reverse: true);
        _waveController.repeat();

        // Start the recording timer
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted && _isListening) {
            setState(() {
              _recordingDuration++;
              _statusMessage =
                  'Listening... Speak now (${_recordingDuration}s)';
            });

            if (_recordingDuration >= _maxRecordingDuration) {
              _stopRecording();
              _showErrorDialog(
                  'Recording stopped. Maximum duration of $_maxRecordingDuration seconds reached.');
            }
          }
        });

        debugPrint(
            'Recording started successfully - isListening should be true');
      } else {
        debugPrint('Failed to start speech recognition');
        setState(() {
          _statusMessage = 'Voice unavailable. Type your query.';
          _isInitialized = false;
        });
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
      setState(() {
        _statusMessage = 'Error starting recording. Please try again.';
      });
    }
  }

  Future<void> _stopRecording() async {
    debugPrint('=== VoiceRecordingScreen: _stopRecording called ===');
    debugPrint('State before stop: _isListening=$_isListening');
    String text = '';

    // Note: Whisper API requires an audio file for transcription.
    // The current SpeechService uses on-device recognition which doesn't save audio files.
    // For full Whisper integration, audio recording to file would need to be implemented.
    // For now, we use on-device speech recognition which works well for English and basic Luganda.

    // Use on-device speech recognition
    if (_isListening) {
      try {
        await _speechService?.stopListening();
      } catch (e) {
        debugPrint('Error stopping speech: $e');
      }
    }

    _recordingTimer?.cancel();
    _pulseController.stop();
    _waveController.stop();

    if (!mounted) return;

    setState(() {
      _isListening = false;
    });

    // Give speech service time to finalize recognition
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    text = _speechService!.text;
    debugPrint('Transcribed text: "$text"');

    if (text.isNotEmpty) {
      setState(() {
        _transcribedText = text;
        _textController.text = text;
        _statusMessage = 'Voice captured! Processing with AI...';
      });
      _processWithAI(text);
    } else {
      setState(() {
        _statusMessage = 'No speech detected. Type your query.';
      });
    }
  }

  Future<void> _retrySpeechRecognition() async {
    setState(() {
      _statusMessage = 'Retrying speech recognition...';
    });

    await _initializeSpeech();

    if (_isInitialized) {
      setState(() {
        _statusMessage = 'Speech recognition ready. Tap microphone to start.';
      });
    } else {
      setState(() {
        _statusMessage =
            'Speech recognition still unavailable. Please type your query.';
      });
    }
  }

  Future<void> _cancelRecording() async {
    if (_isListening) {
      try {
        await _speechService!.stopListening();
      } catch (e) {
        debugPrint('Error stopping speech: $e');
      }
    }

    _recordingTimer?.cancel();
    _pulseController.stop();
    _waveController.stop();

    if (!mounted) return;

    setState(() {
      _isListening = false;
      _recordingDuration = 0;
      _statusMessage = 'Recording cancelled. Tap microphone to try again.';
    });
  }

  /// Get the best available locale for speech recognition based on user preference
  Future<String> _getBestLocaleForSpeech(String userLanguage) async {
    // Try to get the best available locale from SpeechService
    try {
      final locales = await _speechService?.getLocales();

      if (locales != null && locales.isNotEmpty) {
        // If user wants Luganda, try to find it, otherwise use English
        if (userLanguage == 'lg') {
          try {
            final lugandaLocale = locales.firstWhere(
              (l) =>
                  l.localeId.startsWith('lg') ||
                  l.name.toLowerCase().contains('luganda'),
              orElse: () => locales.firstWhere(
                (l) => l.localeId.startsWith('en'),
                orElse: () => locales.first,
              ),
            );
            debugPrint('Using locale: ${lugandaLocale.localeId}');
            return lugandaLocale.localeId;
          } catch (e) {
            debugPrint('Could not find Luganda locale, using first available');
            return locales.first.localeId;
          }
        } else {
          // For English, try to find en_US or en_GB
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
            debugPrint('Using locale: ${englishLocale.localeId}');
            return englishLocale.localeId;
          } catch (e) {
            debugPrint('Could not find English locale, using first available');
            return locales.first.localeId;
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting best locale: $e');
    }

    // Fallback to default
    return userLanguage == 'lg' ? 'en_US' : 'en_US';
  }

  void _processTextInput() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showErrorDialog('Please enter a query or transaction.');
      return;
    }

    // Check if there's an active transaction review awaiting confirmation
    if (_showTransactionReview && _currentTransactionIntent != null) {
      final lowerText = text.toLowerCase();

      // Check for confirmation keywords
      if (_isConfirmation(lowerText)) {
        _saveTransaction();
        _textController.clear();
        return;
      } else if (_isRejection(lowerText)) {
        _cancelTransaction();
        _textController.clear();
        return;
      } else if (_isEditRequest(lowerText)) {
        _showEditDialog();
        _textController.clear();
        return;
      } else if (lowerText.contains('print')) {
        // Handle print request during transaction review
        _handlePrintDuringReview();
        _textController.clear();
        return;
      }
      // If there's a transaction review but response doesn't match any action,
      // show helpful message
      _addChatMessage(
        'I\'m waiting for your confirmation.\n\n'
        '• Say "Yes" or "Save" to save the transaction\n'
        '• Say "No" or "Cancel" to cancel\n'
        '• Say "Edit" to modify the details\n'
        '• Say "Print" to print a receipt',
        isUser: false,
        type: ChatMessageType.query,
      );
      _textController.clear();
      return;
    }

    setState(() {
      _transcribedText = text;
      _statusMessage = 'Processing with AI...';
      _isProcessing = true;
    });

    _processWithAI(text);
  }

  bool _isConfirmation(String text) {
    final confirmKeywords = [
      'yes',
      'yeah',
      'yep',
      'sure',
      'ok',
      'okay',
      'correct',
      'confirm',
      'save',
      'store',
      'record',
      'go ahead',
      'proceed',
      'do it',
      'please save',
      'yes please',
      'yup',
      'ya'
    ];
    return confirmKeywords.any((keyword) => text.contains(keyword));
  }

  bool _isRejection(String text) {
    final rejectKeywords = [
      'no',
      'nope',
      'cancel',
      'not',
      'don\'t',
      'do not',
      'stop',
      'wait',
      'wrong',
      'incorrect',
      'change my mind',
      'never mind',
      'forget it',
      'maybe not',
      'abort'
    ];
    return rejectKeywords.any((keyword) => text.contains(keyword));
  }

  bool _isEditRequest(String text) {
    final editKeywords = [
      'edit',
      'change',
      'modify',
      'update',
      'fix',
      'correct',
      'alter',
      'adjust',
      'revise',
      'amend'
    ];
    return editKeywords.any((keyword) => text.contains(keyword));
  }

  void _cancelTransaction() {
    setState(() {
      _showTransactionReview = false;
      _currentTransactionIntent = null;
      _transcribedText = '';
      _statusMessage = 'Transaction cancelled. What else can I help you with?';
    });
    _addChatMessage(
      'Transaction cancelled. What else can I help you with?',
      isUser: false,
      type: ChatMessageType.text,
    );
  }

  Future<void> _handlePrintDuringReview() async {
    if (_currentTransactionIntent != null) {
      // Create a temporary transaction from the current intent for printing
      final authProvider = context.read<AuthProvider>();

      // Build transaction items
      List<TransactionItem> items = [];
      final quantityUnit = _getQuantityUnit();

      final mainItem = TransactionItem.create(
        itemName: _currentTransactionIntent!.itemName,
        quantity: _transactionQuantity.toDouble(),
        unit: quantityUnit,
        pricePerUnit: _transactionUnitPrice,
      );
      items.add(mainItem);

      if (_currentTransactionIntent!.hasMultipleItems &&
          _currentTransactionIntent!.additionalItems != null) {
        for (var itemData in _currentTransactionIntent!.additionalItems!) {
          final itemName = itemData['item']?.toString() ?? 'Unknown';
          final itemQty = (itemData['quantity'] as num?)?.toDouble() ?? 1.0;
          final itemPrice = (itemData['unitPrice'] as num?)?.toDouble() ?? 0.0;

          items.add(TransactionItem.create(
            itemName: itemName,
            quantity: itemQty,
            unit: quantityUnit,
            pricePerUnit: itemPrice,
          ));
        }
      }

      final transaction = Transaction.create(
        type: _transactionType,
        items: items,
        userId: authProvider.userModel?.id ?? '',
        description: _transactionDescription,
        category: _transactionCategory.isNotEmpty ? _transactionCategory : null,
        customerName: _transactionCustomerName.isNotEmpty
            ? _transactionCustomerName
            : null,
        notes: _transactionNotes.isNotEmpty ? _transactionNotes : null,
      );

      await _printReceipt(transaction);

      _addChatMessage(
        '🧾 Receipt printed successfully!\n\n'
        'Would you like to save this transaction?',
        isUser: false,
        type: ChatMessageType.receipt,
      );
    }
  }

  QuantityUnit _getQuantityUnit() {
    String unitLower = _transactionUnit.toLowerCase();
    if (unitLower.startsWith('kg') ||
        unitLower == 'kilo' ||
        unitLower == 'kilos') {
      return QuantityUnit.kgs;
    } else if (unitLower.startsWith('gram') ||
        unitLower == 'g' ||
        unitLower == 'gr') {
      return QuantityUnit.grams;
    } else if (unitLower == 'l' || unitLower.startsWith('liter')) {
      return QuantityUnit.liters;
    } else if (unitLower == 'ml' || unitLower.startsWith('milliliter')) {
      return QuantityUnit.ml;
    } else if (unitLower.startsWith('dozen')) {
      return QuantityUnit.dozens;
    } else if (unitLower.startsWith('box')) {
      return QuantityUnit.boxes;
    } else if (unitLower.startsWith('bag')) {
      return QuantityUnit.bags;
    } else if (unitLower.startsWith('sack')) {
      return QuantityUnit.sacks;
    } else if (unitLower.startsWith('piece') ||
        unitLower.startsWith('pcs') ||
        unitLower == 'pc') {
      return QuantityUnit.pieces;
    }
    return QuantityUnit.pcs;
  }

  Future<void> _processWithAI(String text) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Processing with AI...';
    });

    // Add user message to chat
    _addChatMessage(text, isUser: true);

    try {
      final processedText = TranslationService.processText(
        text,
        context.read<LanguageProvider>().currentLanguage,
      );

      // Check for entity addition intents first
      final entityResult = await _handleEntityAddition(processedText);
      if (entityResult != null) {
        _addChatMessage(
          entityResult,
          isUser: false,
          type: _getEntityType(processedText),
        );
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Tap the microphone or type your query';
        });
        _textController.clear();
        return;
      }

      // Determine if this is a query or a transaction
      final isQuery = _isQuery(processedText.toLowerCase());

      if (isQuery) {
        // This is a query - try to get AI response
        final queryResult = await _handleAIQuery(processedText);

        if (queryResult != null) {
          // AI answered the query
          _addChatMessage(
            queryResult,
            isUser: false,
            type: ChatMessageType.query,
          );
        } else {
          // AI couldn't answer - provide helpful guidance
          _addChatMessage(
            _getQueryFallbackResponse(processedText),
            isUser: false,
            type: ChatMessageType.query,
          );
        }
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Tap the microphone or type your query';
        });
      } else {
        // This is a transaction - parse and show review using Gemini
        final intent = await _parseTransactionWithGemini(processedText);
        if (!mounted) return;

        // Check if parsing failed - if item name is Unknown, parsing failed
        // ALWAYS check this first - even if it has some values, Unknown means failed
        if (intent.itemName == 'Unknown' || intent.itemName.isEmpty) {
          debugPrint('Transaction parsing failed - item is Unknown');
          // Parsing failed - provide helpful response instead
          _addChatMessage(
            _getTransactionHelpResponse(processedText),
            isUser: false,
            type: ChatMessageType.query,
          );
          setState(() {
            _isProcessing = false;
            _statusMessage = 'Tap the microphone or type your query';
          });
          _textController.clear();
          return;
        }

        _initializeTransactionReview(intent);
      }
    } catch (e) {
      debugPrint('Error processing with AI: $e');
      _addChatMessage(
        'Sorry, I encountered an error processing your request. Please try again.',
        isUser: false,
        type: ChatMessageType.error,
      );
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Error processing. Please try again.';
      });
    }

    _textController.clear();
  }

  ChatMessageType _getEntityType(String text) {
    final lowerText = text.toLowerCase();
    if (lowerText.contains('product') || lowerText.contains('item')) {
      return ChatMessageType.inventory;
    } else if (lowerText.contains('supplier') || lowerText.contains('vendor')) {
      return ChatMessageType.supplier;
    } else if (lowerText.contains('customer') || lowerText.contains('client')) {
      return ChatMessageType.customer;
    } else if (lowerText.contains('category') || lowerText.contains('type')) {
      return ChatMessageType.category;
    }
    return ChatMessageType.text;
  }

  Future<String?> _handleEntityAddition(String text) async {
    final lowerText = text.toLowerCase();

    // Check for product addition - use Gemini directly
    if (_isProductAddition(lowerText)) {
      final result = await _handleProductAddition(text);
      // Return the result regardless - it will show parsed data or error message
      return result;
    }

    // Check for supplier addition - use Gemini directly
    if (_isSupplierAddition(lowerText)) {
      final result = await _handleSupplierAddition(text);
      return result;
    }

    // Check for customer addition - use Gemini directly
    if (_isCustomerAddition(lowerText)) {
      final result = await _handleCustomerAddition(text);
      return result;
    }

    // Check for category addition - use Gemini directly
    if (_isCategoryAddition(lowerText)) {
      final result = await _handleCategoryAddition(text);
      return result;
    }

    return null;
  }

  String _getLocalProductAdditionHelp(String text) {
    // Extract what the user might have mentioned
    final lowerText = text.toLowerCase();
    String hint = '';
    String productName = '';

    // Try to extract product name from the input
    final nameMatch = RegExp(
            r'(?:add|create|new|register)\s+(?:product|item)\s+([a-zA-Z\s]+?)(?:,|$)',
            caseSensitive: false)
        .firstMatch(text);
    if (nameMatch != null) {
      productName = nameMatch.group(1)?.trim() ?? '';
    }

    // Generate contextual hints based on what user said
    if (lowerText.contains('bread') || lowerText.contains('food')) {
      hint =
          '\n💡 It sounds like you want to add a food item. Try: "Add product Bread, category Food, price 5000, quantity 100 pieces"';
    } else if (lowerText.contains('soap') || lowerText.contains('household')) {
      hint =
          '\n💡 It sounds like you want to add a household item. Try: "Add product Soap, category Household, price 2000, quantity 50 pieces"';
    } else if (lowerText.contains('medicine') ||
        lowerText.contains('medical')) {
      hint =
          '\n💡 It sounds like you want to add a medical item. Try: "Add product Panadol, category Medical, price 1000, quantity 20 pieces"';
    } else if (productName.isNotEmpty) {
      hint =
          '\n💡 I detected "$productName". Try: "Add product $productName, category Food, price 5000, quantity 100 pieces"';
    }

    return '📦 Product Addition\n\n'
        'I can help you add a new product. Please provide:\n\n'
        '• Product name\n'
        '• Category\n'
        '• Price\n'
        '• Quantity\n'
        '• Unit (e.g., pcs, kg, liters)$hint\n\n'
        'Example: "Add product Bread, category Food, price 5000, quantity 100 pieces"';
  }

  String _getLocalSupplierAdditionHelp(String text) {
    final lowerText = text.toLowerCase();
    String hint = '';
    String supplierName = '';

    // Try to extract supplier name from the input
    final nameMatch = RegExp(
            r'(?:add|create|new|register)\s+supplier\s+([a-zA-Z\s]+?)(?:,|$)',
            caseSensitive: false)
        .firstMatch(text);
    if (nameMatch != null) {
      supplierName = nameMatch.group(1)?.trim() ?? '';
    }

    // Generate contextual hints
    if (lowerText.contains('distributor') || lowerText.contains('wholesale')) {
      hint =
          '\n💡 It sounds like you want to add a distributor. Try: "Add supplier ABC Distributors, phone 0700123456, email abc@example.com"';
    } else if (lowerText.contains('vendor') || lowerText.contains('seller')) {
      hint =
          '\n💡 It sounds like you want to add a vendor. Try: "Add supplier XYZ Vendor, phone 0700123456"';
    } else if (supplierName.isNotEmpty) {
      hint =
          '\n💡 I detected "$supplierName". Try: "Add supplier $supplierName, phone 0700123456"';
    }

    return '👥 Supplier Addition\n\n'
        'I can help you add a new supplier. Please provide:\n\n'
        '• Supplier name\n'
        '• Phone number\n'
        '• Email (optional)\n'
        '• Address (optional)$hint\n\n'
        'Example: "Add supplier ABC Distributors, phone 0700123456"';
  }

  String _getLocalCustomerAdditionHelp(String text) {
    final lowerText = text.toLowerCase();
    String hint = '';
    String customerName = '';

    // Try to extract customer name from the input
    final nameMatch = RegExp(
            r'(?:add|create|new|register)\s+customer\s+([a-zA-Z\s]+?)(?:,|$)',
            caseSensitive: false)
        .firstMatch(text);
    if (nameMatch != null) {
      customerName = nameMatch.group(1)?.trim() ?? '';
    }

    // Generate contextual hints
    if (lowerText.contains('client') || lowerText.contains('buyer')) {
      hint =
          '\n💡 It sounds like you want to add a client. Try: "Add customer John Doe, phone 0700123456, email john@example.com"';
    } else if (lowerText.contains('shop') || lowerText.contains('store')) {
      hint =
          '\n💡 It sounds like you want to add a shop customer. Try: "Add customer ABC Shop, phone 0700123456"';
    } else if (customerName.isNotEmpty) {
      hint =
          '\n💡 I detected "$customerName". Try: "Add customer $customerName, phone 0700123456"';
    }

    return '👤 Customer Addition\n\n'
        'I can help you add a new customer. Please provide:\n\n'
        '• Customer name\n'
        '• Phone number\n'
        '• Email (optional)\n'
        '• Address (optional)$hint\n\n'
        'Example: "Add customer John Doe, phone 0700123456"';
  }

  String _getLocalCategoryAdditionHelp(String text) {
    final lowerText = text.toLowerCase();
    String hint = '';
    String categoryName = '';

    // Try to extract category name from the input
    final nameMatch = RegExp(
            r'(?:add|create|new|register)\s+category\s+([a-zA-Z\s]+?)(?:,|$)',
            caseSensitive: false)
        .firstMatch(text);
    if (nameMatch != null) {
      categoryName = nameMatch.group(1)?.trim() ?? '';
    }

    // Generate contextual hints
    if (lowerText.contains('food') || lowerText.contains('beverage')) {
      hint =
          '\n💡 It sounds like you want to add a food category. Try: "Add category Beverages, description for drinks and liquids"';
    } else if (lowerText.contains('electronics') ||
        lowerText.contains('gadget')) {
      hint =
          '\n💡 It sounds like you want to add an electronics category. Try: "Add category Electronics, description for electronic devices"';
    } else if (lowerText.contains('clothing') ||
        lowerText.contains('fashion')) {
      hint =
          '\n💡 It sounds like you want to add a clothing category. Try: "Add category Clothing, description for apparel and fashion"';
    } else if (categoryName.isNotEmpty) {
      hint =
          '\n💡 I detected "$categoryName". Try: "Add category $categoryName, description for your products"';
    }

    return '🏷️ Category Addition\n\n'
        'I can help you add a new category. Please provide:\n\n'
        '• Category name\n'
        '• Description (optional)$hint\n\n'
        'Example: "Add category Food, description for edible products"';
  }

  bool _isProductAddition(String text) {
    final keywords = [
      'add product',
      'add item',
      'new product',
      'new item',
      'create product',
      'create item',
      'register product',
      'register item',
    ];
    return keywords.any((keyword) => text.contains(keyword));
  }

  bool _isSupplierAddition(String text) {
    final keywords = [
      'add supplier',
      'new supplier',
      'create supplier',
      'register supplier',
      'add vendor',
      'new vendor',
    ];
    return keywords.any((keyword) => text.contains(keyword));
  }

  bool _isCustomerAddition(String text) {
    final keywords = [
      'add customer',
      'new customer',
      'create customer',
      'register customer',
      'add client',
      'new client',
    ];
    return keywords.any((keyword) => text.contains(keyword));
  }

  bool _isCategoryAddition(String text) {
    final keywords = [
      'add category',
      'new category',
      'create category',
      'register category',
      'add type',
      'new type',
    ];
    return keywords.any((keyword) => text.contains(keyword));
  }

  Future<String> _handleProductAddition(String text) async {
    // Use Gemini directly for product parsing - no fallback
    var parsed = await GeminiParserService.parseProduct(text);

    if (parsed != null) {
      final name = parsed['name'] ?? 'Unknown';
      final category = parsed['category'] ?? 'Other';
      final price = parsed['price'] ?? 0;
      final quantity = parsed['quantity'] ?? 0;
      final unit = parsed['unit'] ?? 'pcs';

      return '📦 Product Addition Request\n\n'
          'I\'ve parsed your product details:\n\n'
          '• Name: $name\n'
          '• Category: $category\n'
          '• Price: UGX ${price.toStringAsFixed(0)}\n'
          '• Quantity: $quantity $unit\n\n'
          'To add this product, please go to the Inventory screen and use the "Add Product" button. '
          'I can help you record transactions involving this product!';
    }

    return '📦 Product Addition\n\n'
        'I couldn\'t parse the product details. Please provide:\n\n'
        '• Product name\n'
        '• Category\n'
        '• Price\n'
        '• Quantity\n'
        '• Unit (e.g., pcs, kg, liters)\n\n'
        'Example: "Add product Bread, category Food, price 5000, quantity 100 pieces"';
  }

  Future<String> _handleSupplierAddition(String text) async {
    // Use Gemini directly for supplier parsing - no fallback
    var parsed = await GeminiParserService.parseSupplier(text);

    if (parsed != null) {
      final name = parsed['name'] ?? 'Unknown';
      final phone = parsed['phone'] ?? '';
      final email = parsed['email'] ?? '';
      final address = parsed['address'] ?? '';

      return '👥 Supplier Addition Request\n\n'
          'I\'ve parsed your supplier details:\n\n'
          '• Name: $name\n'
          '${phone.isNotEmpty ? '• Phone: $phone\n' : ''}'
          '${email.isNotEmpty ? '• Email: $email\n' : ''}'
          '${address.isNotEmpty ? '• Address: $address\n' : ''}\n'
          'To add this supplier, please go to the Suppliers screen and use the "Add Supplier" button. '
          'I can help you record purchases from this supplier!';
    }

    return '👥 Supplier Addition\n\n'
        'I couldn\'t parse the supplier details. Please provide:\n\n'
        '• Supplier name\n'
        '• Phone number\n'
        '• Email (optional)\n'
        '• Address (optional)\n\n'
        'Example: "Add supplier ABC Distributors, phone 0700123456"';
  }

  Future<String> _handleCustomerAddition(String text) async {
    // Use Gemini directly for customer parsing - no fallback
    var parsed = await GeminiParserService.parseCustomer(text);

    if (parsed != null) {
      final name = parsed['name'] ?? 'Unknown';
      final phone = parsed['phone'] ?? '';
      final email = parsed['email'] ?? '';
      final address = parsed['address'] ?? '';

      return '👤 Customer Addition Request\n\n'
          'I\'ve parsed your customer details:\n\n'
          '• Name: $name\n'
          '${phone.isNotEmpty ? '• Phone: $phone\n' : ''}'
          '${email.isNotEmpty ? '• Email: $email\n' : ''}'
          '${address.isNotEmpty ? '• Address: $address\n' : ''}\n'
          'To add this customer, please go to the Customers screen and use the "Add Customer" button. '
          'I can help you record sales to this customer!';
    }

    return '👤 Customer Addition\n\n'
        'I couldn\'t parse the customer details. Please provide:\n\n'
        '• Customer name\n'
        '• Phone number\n'
        '• Email (optional)\n'
        '• Address (optional)\n\n'
        'Example: "Add customer John Doe, phone 0700123456"';
  }

  Future<String> _handleCategoryAddition(String text) async {
    // Use Gemini directly for category parsing - no fallback
    var parsed = await GeminiParserService.parseCategory(text);

    if (parsed != null) {
      final name = parsed['name'] ?? 'Unknown';
      final description = parsed['description'] ?? '';

      return '🏷️ Category Addition Request\n\n'
          'I\'ve parsed your category details:\n\n'
          '• Name: $name\n'
          '${description.isNotEmpty ? '• Description: $description\n' : ''}\n'
          'To add this category, please go to the Categories screen and use the "Add Category" button. '
          'I can help you organize your products with this category!';
    }

    return '🏷️ Category Addition\n\n'
        'I couldn\'t parse the category details. Please provide:\n\n'
        '• Category name\n'
        '• Description (optional)\n\n'
        'Example: "Add category Food, description for edible products"';
  }

  void _addChatMessage(String text,
      {required bool isUser,
      ChatMessageType type = ChatMessageType.text,
      Map<String, dynamic>? data}) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
      type: type,
      data: data,
    );

    setState(() {
      _chatMessages.add(message);
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _initializeTransactionReview(TransactionIntent intent) {
    _currentTransactionIntent = intent;
    _transactionType = intent.type;
    _transactionDescription = _transcribedText;
    _transactionCategory = intent.category;
    _transactionQuantity = intent.quantity;
    _transactionUnit = intent.unit;
    _transactionUnitPrice =
        intent.unitPrice > 0 ? intent.unitPrice : intent.amount;
    _transactionCustomerName = intent.customerName;
    _transactionNotes = intent.notes;

    _categoryController.text = _transactionCategory;
    _quantityController.text = _transactionQuantity.toString();
    _unitPriceController.text = _transactionUnitPrice.toStringAsFixed(0);
    _customerNameController.text = _transactionCustomerName;
    _notesController.text = _transactionNotes;

    // Build the transaction review message based on items
    String typeLabel;
    ChatMessageType chatType;
    switch (_transactionType) {
      case TransactionType.sale:
        typeLabel = 'Sale';
        chatType = ChatMessageType.transaction;
        break;
      case TransactionType.expense:
        typeLabel = 'Expense';
        chatType = ChatMessageType.transaction;
        break;
      case TransactionType.purchase:
        typeLabel = 'Purchase';
        chatType = ChatMessageType.transaction;
        break;
      case TransactionType.cashReceipt:
        typeLabel = 'Cash Receipt';
        chatType = ChatMessageType.receipt;
        break;
    }

    // Build the item details
    String itemsText = '';
    final itemCount = intent.totalItemsCount;

    if (intent.hasMultipleItems) {
      // Multiple items detected
      final itemNames = _parseMultipleItemNames(intent.itemName);
      itemsText = '\n📋 Items in this transaction ($itemCount):\n';

      // Add the main item
      itemsText +=
          '1. ${intent.itemName} - $_transactionQuantity ${_getUnitDisplay()} @ UGX ${_transactionUnitPrice.toStringAsFixed(0)} each\n';

      // Add additional items
      if (intent.additionalItems != null) {
        for (var i = 0; i < intent.additionalItems!.length; i++) {
          final item = intent.additionalItems![i];
          final itemName = item['item'] ?? 'Unknown';
          final qty = item['quantity'] ?? 1;
          final price = item['unitPrice'] ?? 0;
          itemsText +=
              '${i + 2}. $itemName - $qty @ UGX ${NumberFormat('#,###').format(price)} each\n';
        }
      }
    } else {
      // Single item
      itemsText = '• Item: ${intent.itemName}\n'
          '• Quantity: $_transactionQuantity ${_getUnitDisplay()}\n'
          '• Unit Price: UGX ${_transactionUnitPrice.toStringAsFixed(0)}\n';
    }

    _addChatMessage(
      'I\'ve parsed your $typeLabel transaction ($itemCount item${itemCount > 1 ? 's' : ''}):\n\n'
      '$itemsText\n'
      '• Total: UGX ${_totalAmount.toStringAsFixed(0)}\n'
      '• Category: ${_transactionCategory.isEmpty ? 'Not specified' : _transactionCategory}\n'
      '${_transactionCustomerName.isNotEmpty ? '• Customer: $_transactionCustomerName\n' : ''}'
      '${_transactionNotes.isNotEmpty ? '• Notes: $_transactionNotes\n' : ''}\n'
      'Would you like to save this transaction?',
      isUser: false,
      type: chatType,
      data: {
        'type': _transactionType.toString(),
        'item': _currentTransactionIntent!.itemName,
        'quantity': _transactionQuantity,
        'unitPrice': _transactionUnitPrice,
        'total': _totalAmount,
        'category': _transactionCategory,
        'customer': _transactionCustomerName,
        'notes': _transactionNotes,
        'hasMultipleItems': intent.hasMultipleItems,
        'additionalItems': intent.additionalItems,
      },
    );

    setState(() {
      _showTransactionReview = true;
      _isProcessing = false;
      _statusMessage = 'Tap the microphone or type your query';
    });
  }

  /// Parse multiple item names from comma or 'and' separated string
  List<String> _parseMultipleItemNames(String itemName) {
    if (itemName.contains(',') || itemName.contains(' and ')) {
      return itemName
          .split(RegExp(r'[, ]+and[, ]+|,'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [itemName];
  }

  double get _totalAmount => _transactionUnitPrice * _transactionQuantity;

  void _saveTransaction() {
    if (_currentTransactionIntent == null) return;

    int quantity =
        int.tryParse(_quantityController.text) ?? _transactionQuantity;
    double unitPrice =
        double.tryParse(_unitPriceController.text) ?? _transactionUnitPrice;

    final authProvider = context.read<AuthProvider>();
    final transactionProvider = context.read<TransactionProvider>();

    debugPrint('=== AI Assistant - Saving Transaction ===');
    debugPrint('Type: $_transactionType');
    debugPrint('Total Amount: ${unitPrice * quantity}');
    debugPrint('Quantity: $quantity');
    debugPrint('Unit Price: $unitPrice');
    debugPrint('Item Name: ${_currentTransactionIntent!.itemName}');
    debugPrint('Category: $_transactionCategory');
    debugPrint('Unit: $_transactionUnit');
    debugPrint(
        'Has multiple items: ${_currentTransactionIntent!.hasMultipleItems}');

    // Determine quantity unit
    QuantityUnit quantityUnit = QuantityUnit.pcs;
    String unitLower = _transactionUnit.toLowerCase();
    if (unitLower.startsWith('kg') ||
        unitLower == 'kilo' ||
        unitLower == 'kilos') {
      quantityUnit = QuantityUnit.kgs;
    } else if (unitLower.startsWith('gram') ||
        unitLower == 'g' ||
        unitLower == 'gr') {
      quantityUnit = QuantityUnit.grams;
    } else if (unitLower == 'l' || unitLower.startsWith('liter')) {
      quantityUnit = QuantityUnit.liters;
    } else if (unitLower == 'ml' || unitLower.startsWith('milliliter')) {
      quantityUnit = QuantityUnit.ml;
    } else if (unitLower.startsWith('dozen')) {
      quantityUnit = QuantityUnit.dozens;
    } else if (unitLower.startsWith('box')) {
      quantityUnit = QuantityUnit.boxes;
    } else if (unitLower.startsWith('bag')) {
      quantityUnit = QuantityUnit.bags;
    } else if (unitLower.startsWith('sack')) {
      quantityUnit = QuantityUnit.sacks;
    } else if (unitLower.startsWith('piece') ||
        unitLower.startsWith('pcs') ||
        unitLower == 'pc') {
      quantityUnit = QuantityUnit.pieces;
    }

    // Build transaction items list
    List<TransactionItem> items = [];

    // Add the main item
    final mainItem = TransactionItem.create(
      itemName: _currentTransactionIntent!.itemName,
      quantity: quantity.toDouble(),
      unit: quantityUnit,
      pricePerUnit: unitPrice,
      description: _transactionNotes.isNotEmpty ? _transactionNotes : null,
    );
    items.add(mainItem);

    debugPrint(
        'Created main item - quantity: ${mainItem.quantity}, unit: ${mainItem.unit}, pricePerUnit: ${mainItem.pricePerUnit}, amount: ${mainItem.amount}');

    // Add additional items if present
    if (_currentTransactionIntent!.hasMultipleItems &&
        _currentTransactionIntent!.additionalItems != null) {
      for (var itemData in _currentTransactionIntent!.additionalItems!) {
        final itemName = itemData['item']?.toString() ?? 'Unknown';
        final itemQty = (itemData['quantity'] as num?)?.toDouble() ?? 1.0;
        final itemPrice = (itemData['unitPrice'] as num?)?.toDouble() ?? 0.0;

        final additionalItem = TransactionItem.create(
          itemName: itemName,
          quantity: itemQty,
          unit: quantityUnit,
          pricePerUnit: itemPrice,
        );
        items.add(additionalItem);
        debugPrint(
            'Created additional item: $itemName - qty: $itemQty, price: $itemPrice');
      }
    }

    final transaction = Transaction.create(
      type: _transactionType,
      items: items,
      userId: authProvider.userModel?.id ?? '',
      description: _transactionDescription,
      category: _transactionCategory.isNotEmpty ? _transactionCategory : null,
      customerName:
          _transactionCustomerName.isNotEmpty ? _transactionCustomerName : null,
      notes: _transactionNotes.isNotEmpty ? _transactionNotes : null,
    );

    debugPrint(
        'Created transaction - totalAmount: ${transaction.totalAmount}, items: ${items.length}');

    transactionProvider.addTransaction(transaction);

    // Add success message to chat
    String typeLabel;
    switch (_transactionType) {
      case TransactionType.sale:
        typeLabel = 'Sale';
        break;
      case TransactionType.expense:
        typeLabel = 'Expense';
        break;
      case TransactionType.purchase:
        typeLabel = 'Purchase';
        break;
      case TransactionType.cashReceipt:
        typeLabel = 'Cash Receipt';
        break;
    }

    final itemCount = items.length;
    _addChatMessage(
      '✅ $typeLabel transaction saved successfully!\n\n'
      '• Items: $itemCount\n'
      '• Total Amount: UGX ${_totalAmount.toStringAsFixed(0)}\n'
      '• Category: ${_transactionCategory.isEmpty ? 'Not specified' : _transactionCategory}',
      isUser: false,
      type: ChatMessageType.transaction,
    );

    setState(() {
      _showTransactionReview = false;
      _currentTransactionIntent = null;
      _transcribedText = '';
      _statusMessage = 'Transaction saved! What else can I help you with?';
    });
  }

  void _startEditingQuantity() {
    _inlineQuantityController.text = _transactionQuantity.toString();
    setState(() {
      _isEditingQuantity = true;
      _isEditingUnitPrice = false;
    });
  }

  void _startEditingUnitPrice() {
    _inlineUnitPriceController.text = _transactionUnitPrice.toStringAsFixed(0);
    setState(() {
      _isEditingQuantity = false;
      _isEditingUnitPrice = true;
    });
  }

  void _saveInlineQuantity() {
    final newQty = int.tryParse(_inlineQuantityController.text);
    if (newQty != null && newQty > 0) {
      setState(() {
        _transactionQuantity = newQty;
        _quantityController.text = newQty.toString();
        _isEditingQuantity = false;
      });
      // Update the chat message with new values
      _updateTransactionReviewMessage();
    } else {
      setState(() {
        _isEditingQuantity = false;
      });
    }
  }

  void _saveInlineUnitPrice() {
    final newPrice = double.tryParse(_inlineUnitPriceController.text);
    if (newPrice != null && newPrice >= 0) {
      setState(() {
        _transactionUnitPrice = newPrice;
        _unitPriceController.text = newPrice.toStringAsFixed(0);
        _isEditingUnitPrice = false;
      });
      // Update the chat message with new values
      _updateTransactionReviewMessage();
    } else {
      setState(() {
        _isEditingUnitPrice = false;
      });
    }
  }

  void _cancelInlineEdit() {
    setState(() {
      _isEditingQuantity = false;
      _isEditingUnitPrice = false;
    });
  }

  void _updateTransactionReviewMessage() {
    if (_currentTransactionIntent == null) return;

    // Find and update the last transaction message
    for (int i = _chatMessages.length - 1; i >= 0; i--) {
      if (_chatMessages[i].type == ChatMessageType.transaction ||
          _chatMessages[i].type == ChatMessageType.receipt) {
        final itemCount = _currentTransactionIntent!.totalItemsCount;
        String itemsText;
        if (_currentTransactionIntent!.hasMultipleItems) {
          itemsText = '\n📋 Items in this transaction ($itemCount):\n';
          itemsText +=
              '1. ${_currentTransactionIntent!.itemName} - $_transactionQuantity ${_getUnitDisplay()} @ UGX ${_transactionUnitPrice.toStringAsFixed(0)} each\n';
          if (_currentTransactionIntent!.additionalItems != null) {
            for (var j = 0;
                j < _currentTransactionIntent!.additionalItems!.length;
                j++) {
              final item = _currentTransactionIntent!.additionalItems![j];
              final itemName = item['item'] ?? 'Unknown';
              final qty = item['quantity'] ?? 1;
              final price = item['unitPrice'] ?? 0;
              itemsText +=
                  '${j + 2}. $itemName - $qty @ UGX ${NumberFormat('#,###').format(price)} each\n';
            }
          }
        } else {
          itemsText = '• Item: ${_currentTransactionIntent!.itemName}\n'
              '• Quantity: $_transactionQuantity ${_getUnitDisplay()}\n'
              '• Unit Price: UGX ${_transactionUnitPrice.toStringAsFixed(0)}\n';
        }

        String typeLabel;
        switch (_transactionType) {
          case TransactionType.sale:
            typeLabel = 'Sale';
            break;
          case TransactionType.expense:
            typeLabel = 'Expense';
            break;
          case TransactionType.purchase:
            typeLabel = 'Purchase';
            break;
          case TransactionType.cashReceipt:
            typeLabel = 'Cash Receipt';
            break;
        }

        final newText =
            'I\'ve parsed your $typeLabel transaction ($itemCount item${itemCount > 1 ? 's' : ''}):\n\n'
            '$itemsText\n'
            '• Total: UGX ${_totalAmount.toStringAsFixed(0)}\n'
            '• Category: ${_transactionCategory.isEmpty ? 'Not specified' : _transactionCategory}\n'
            '${_transactionCustomerName.isNotEmpty ? '• Customer: $_transactionCustomerName\n' : ''}'
            '${_transactionNotes.isNotEmpty ? '• Notes: $_transactionNotes\n' : ''}\n'
            'Would you like to save this transaction?';

        setState(() {
          _chatMessages[i] = ChatMessage(
            id: _chatMessages[i].id,
            text: newText,
            isUser: false,
            timestamp: _chatMessages[i].timestamp,
            type: _chatMessages[i].type,
            data: {
              'type': _transactionType.toString(),
              'item': _currentTransactionIntent!.itemName,
              'quantity': _transactionQuantity,
              'unitPrice': _transactionUnitPrice,
              'total': _totalAmount,
              'category': _transactionCategory,
              'customer': _transactionCustomerName,
              'notes': _transactionNotes,
              'hasMultipleItems': _currentTransactionIntent!.hasMultipleItems,
              'additionalItems': _currentTransactionIntent!.additionalItems,
            },
          );
        });
        break;
      }
    }
  }

  void _showEditDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final systemBg = isDarkMode
        ? IOSDarkColors.systemBackground
        : IOSColors.systemBackground;
    final labelPrimary =
        isDarkMode ? IOSDarkColors.labelPrimary : IOSColors.labelPrimary;
    final labelQuaternary = isDarkMode
        ? IOSDarkColors.labelQuaternary
        : IOSDarkColors.labelQuaternary;
    final secondarySystemBg = isDarkMode
        ? IOSDarkColors.secondarySystemBackground
        : IOSColors.secondarySystemBackground;
    final labelSecondary =
        isDarkMode ? IOSDarkColors.labelSecondary : IOSColors.labelSecondary;
    final primaryColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;

    final quantityController =
        TextEditingController(text: _quantityController.text);
    final unitPriceController =
        TextEditingController(text: _unitPriceController.text);
    final categoryController =
        TextEditingController(text: _categoryController.text);
    final customerNameController =
        TextEditingController(text: _customerNameController.text);
    final notesController = TextEditingController(text: _notesController.text);

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 550,
        decoration: BoxDecoration(
          color: systemBg,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(IOSBorderRadius.large),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(IOSSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: labelQuaternary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: IOSSpacing.lg),
              Text(
                'Edit Transaction',
                style: IOSTextStyles.title2.copyWith(color: labelPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: IOSSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: IOSSpacing.md),
                decoration: BoxDecoration(
                  color: secondarySystemBg,
                  borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
                ),
                child: DropdownButtonFormField<TransactionType>(
                  initialValue: _transactionType,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    labelStyle: TextStyle(color: labelSecondary),
                    border: InputBorder.none,
                  ),
                  dropdownColor: secondarySystemBg,
                  items: TransactionType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(
                        type.name.toUpperCase(),
                        style: TextStyle(color: labelPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _transactionType = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: IOSSpacing.md),
              Text('Quantity',
                  style: TextStyle(color: labelSecondary, fontSize: 12)),
              const SizedBox(height: IOSSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: IOSSpacing.md),
                decoration: BoxDecoration(
                  color: secondarySystemBg,
                  borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
                ),
                child: CupertinoTextField(
                  controller: quantityController,
                  placeholder: 'Quantity',
                  keyboardType: TextInputType.number,
                  decoration: null,
                  style: TextStyle(color: labelPrimary),
                ),
              ),
              const SizedBox(height: IOSSpacing.md),
              Text('Unit Price (UGX)',
                  style: TextStyle(color: labelSecondary, fontSize: 12)),
              const SizedBox(height: IOSSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: IOSSpacing.md),
                decoration: BoxDecoration(
                  color: secondarySystemBg,
                  borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
                ),
                child: CupertinoTextField(
                  controller: unitPriceController,
                  placeholder: 'Unit Price',
                  keyboardType: TextInputType.number,
                  decoration: null,
                  style: TextStyle(color: labelPrimary),
                ),
              ),
              const SizedBox(height: IOSSpacing.md),
              Text('Category',
                  style: TextStyle(color: labelSecondary, fontSize: 12)),
              const SizedBox(height: IOSSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: IOSSpacing.md),
                decoration: BoxDecoration(
                  color: secondarySystemBg,
                  borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
                ),
                child: CupertinoTextField(
                  controller: categoryController,
                  placeholder: 'Category',
                  decoration: null,
                  style: TextStyle(color: labelPrimary),
                ),
              ),
              const SizedBox(height: IOSSpacing.md),
              Text('Customer Name',
                  style: TextStyle(color: labelSecondary, fontSize: 12)),
              const SizedBox(height: IOSSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: IOSSpacing.md),
                decoration: BoxDecoration(
                  color: secondarySystemBg,
                  borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
                ),
                child: CupertinoTextField(
                  controller: customerNameController,
                  placeholder: 'Customer Name (optional)',
                  decoration: null,
                  style: TextStyle(color: labelPrimary),
                ),
              ),
              const SizedBox(height: IOSSpacing.md),
              Text('Notes',
                  style: TextStyle(color: labelSecondary, fontSize: 12)),
              const SizedBox(height: IOSSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: IOSSpacing.md),
                decoration: BoxDecoration(
                  color: secondarySystemBg,
                  borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
                ),
                child: CupertinoTextField(
                  controller: notesController,
                  placeholder: 'Notes (optional)',
                  maxLines: 2,
                  decoration: null,
                  style: TextStyle(color: labelPrimary),
                ),
              ),
              const SizedBox(height: IOSSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      onPressed: () => Navigator.pop(ctx),
                      color: secondarySystemBg,
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: labelPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: IOSSpacing.md),
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: () {
                        setState(() {
                          _transactionQuantity =
                              int.tryParse(quantityController.text) ??
                                  _transactionQuantity;
                          _transactionUnitPrice =
                              double.tryParse(unitPriceController.text) ??
                                  _transactionUnitPrice;
                          _transactionCategory = categoryController.text;
                          _transactionCustomerName =
                              customerNameController.text;
                          _transactionNotes = notesController.text;
                        });
                        _quantityController.text =
                            _transactionQuantity.toString();
                        _unitPriceController.text =
                            _transactionUnitPrice.toStringAsFixed(0);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getUnitDisplay() {
    String unitLower = _transactionUnit.toLowerCase();
    if (unitLower.startsWith('kg')) return 'KGs';
    if (unitLower.startsWith('gram')) return 'Grams';
    if (unitLower == 'l' || unitLower.startsWith('liter')) return 'Liters';
    if (unitLower == 'ml') return 'ML';
    if (unitLower.startsWith('dozen')) return 'Dozen';
    if (unitLower.startsWith('box')) return 'Boxes';
    if (unitLower.startsWith('bag')) return 'Bags';
    if (unitLower.startsWith('sack')) return 'Sacks';
    if (unitLower.startsWith('bundle')) return 'Bundles';
    if (unitLower.startsWith('bottle')) return 'Bottles';
    if (unitLower.startsWith('can')) return 'Cans';
    if (unitLower.startsWith('cup')) return 'Cups';
    if (unitLower.startsWith('plate')) return 'Plates';
    if (unitLower.startsWith('roll')) return 'Rolls';
    if (unitLower.startsWith('sheet')) return 'Sheets';
    if (unitLower.startsWith('ream')) return 'Reams';
    if (unitLower.startsWith('pair')) return 'Pairs';
    if (unitLower.startsWith('jar')) return 'Jars';
    if (unitLower.startsWith('carton')) return 'Cartons';
    if (unitLower.startsWith('crate')) return 'Crates';
    if (unitLower.startsWith('head')) return 'Heads';
    if (unitLower.startsWith('bunch')) return 'Bunches';
    if (unitLower.startsWith('set')) return 'Sets';
    return 'PCS';
  }

  Future<String?> _handleAIQuery(String text) async {
    final transactionProvider = context.read<TransactionProvider>();
    final transactions = transactionProvider.transactions;
    final lowerText = text.toLowerCase();

    // Build detailed context based on query type
    final contextData = _buildDetailedDataContext(transactions, lowerText);

    debugPrint('Processing query: $text');
    debugPrint('Context data: $contextData');

    // Check for print requests first - these should be handled immediately
    if (lowerText.contains('print') ||
        lowerText.contains('print receipt') ||
        lowerText.contains('print invoice') ||
        lowerText.contains('print report')) {
      final printResult = await _handlePrintRequest(lowerText, transactions);
      if (printResult != null) {
        return printResult;
      }
    }

    // Use Gemini directly - no fallback to OpenAI
    // This ensures responses come directly from Gemini AI
    String? response;
    try {
      debugPrint('Calling Gemini directly for query...');
      response = await GeminiParserService.answerQuery(text, contextData);

      // Check if response is valid
      if (response != null && response.isNotEmpty) {
        // Check for error indicators
        if (response.contains('⚠️') ||
            response.contains('api key') ||
            response.contains('invalid') ||
            response.contains('error')) {
          debugPrint('Gemini returned error response: $response');
          // Return the error message directly so user knows what's wrong
          return response;
        }
        debugPrint('Gemini succeeded with direct response');
        return response;
      } else {
        debugPrint('Gemini returned empty response');
        // Return a message indicating the query couldn't be processed
        return 'I received your query but need more specific information. '
            'Try asking about:\n'
            '• Sales or expenses\n'
            '• Profit or revenue\n'
            '• Recent transactions\n'
            '• Your business performance';
      }
    } catch (e) {
      debugPrint('Gemini exception: $e');
      // Return a direct error message instead of falling back
      return 'Sorry, I couldn\'t process your query right now. '
          'Please try again or rephrase your question.';
    }
    // NO FALLBACK - responses come directly from Gemini AI
  }

  /// Handle print requests from the user
  Future<String?> _handlePrintRequest(
      String lowerText, List<dynamic> transactions) async {
    final transactionProvider = context.read<TransactionProvider>();
    final allTransactions = transactionProvider.transactions;

    // Handle receipt printing
    if (lowerText.contains('receipt') ||
        (lowerText.contains('print') &&
            !lowerText.contains('invoice') &&
            !lowerText.contains('report'))) {
      if (allTransactions.isEmpty) {
        _showPrintError('No transactions found to print a receipt.');
        return '🧾 No transactions found to print a receipt.\n\nPlease record a sale first, then ask me to print the receipt!';
      }

      // Get the last transaction
      final lastTransaction = allTransactions.first;
      await _printReceipt(lastTransaction);

      return '🧾 I\'ve prepared your receipt for printing!\n\n'
          'Receipt Details:\n'
          '• Type: ${lastTransaction.type.name}\n'
          '• Amount: UGX ${NumberFormat('#,###').format(lastTransaction.totalAmount)}\n'
          '• Date: ${DateFormat('dd MMM yyyy HH:mm').format(lastTransaction.createdAt)}\n\n'
          'The print dialog should open automatically. 📄🖨️';
    }

    // Handle invoice printing
    if (lowerText.contains('invoice')) {
      if (allTransactions.isEmpty) {
        _showPrintError('No transactions found to print an invoice.');
        return '📄 No transactions found to print an invoice.\n\nPlease record a sale first, then ask me to print an invoice!';
      }

      // Get the last transaction
      final lastTransaction = allTransactions.first;

      // Try to extract customer name from the request
      String? customerName;
      final customerMatch = RegExp(r'(?:for|to)\s+([a-zA-Z\s]+?)(?:\s|$|\?)',
              caseSensitive: false)
          .firstMatch(lowerText);
      if (customerMatch != null) {
        customerName = customerMatch.group(1)?.trim();
      }

      await _printInvoice(lastTransaction, customerName: customerName);

      return '📄 I\'ve prepared your invoice for printing!\n\n'
          'Invoice Details:\n'
          '• Amount: UGX ${NumberFormat('#,###').format(lastTransaction.totalAmount)}\n'
          '• Date: ${DateFormat('dd MMM yyyy').format(lastTransaction.createdAt)}\n'
          '${customerName != null ? '• Customer: $customerName\n' : ''}\n'
          'The print dialog should open automatically. 📄🖨️';
    }

    // Handle report printing
    if (lowerText.contains('report')) {
      if (allTransactions.isEmpty) {
        _showPrintError('No transactions found to print a report.');
        return '📊 No transactions found to print a report.\n\nPlease record some transactions first, then ask me to print a report!';
      }

      String reportType = 'daily';
      if (lowerText.contains('weekly') || lowerText.contains('week')) {
        reportType = 'weekly';
      } else if (lowerText.contains('monthly') || lowerText.contains('month')) {
        reportType = 'monthly';
      } else if (lowerText.contains('profit') ||
          lowerText.contains('summary')) {
        reportType = 'profit';
      }

      await _printReport(allTransactions.cast<Transaction>(), reportType);

      String reportName = 'Daily Report';
      if (reportType == 'weekly') reportName = 'Weekly Report';
      if (reportType == 'monthly') reportName = 'Monthly Report';
      if (reportType == 'profit') reportName = 'Profit Summary';

      return '📊 I\'ve prepared your $reportName for printing!\n\n'
          'The report includes all your transaction data.\n'
          'Total Transactions: ${allTransactions.length}\n\n'
          'The print dialog should open automatically. 📊🖨️';
    }

    return null;
  }

  void _showPrintError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isQuery(String text) {
    // First check: if text has explicit transaction patterns with item/price info, it's NOT a query
    // Look for patterns like "sold 5 bread at 2000" or "bought 10 sugar" or "sold three bread at 2000"
    final transactionWithDetails = RegExp(
            r'(?:sold|bought|spent|paid|buy|sell)\s+\d+\s+\w+.*(?:at|for|price)',
            caseSensitive: false)
        .hasMatch(text);

    if (transactionWithDetails) {
      return false; // It's definitely a transaction
    }

    // Check for transaction with word numbers (e.g., "sold three bread at 2000")
    final transactionWithWordNumbers = RegExp(
            r'(?:sold|bought|spent|paid|buy|sell)\s+(?:one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|a|an)\s+\w+.*(?:at|for|price)',
            caseSensitive: false)
        .hasMatch(text);

    if (transactionWithWordNumbers) {
      return false; // It's definitely a transaction with word number
    }

    // Second check: check for transaction keywords with digit numbers
    final hasTransactionKeyword = RegExp(
            r'(?:sold|bought|spent|paid|buy|sell|purchase|expense)\s+\d+',
            caseSensitive: false)
        .hasMatch(text);

    if (hasTransactionKeyword) {
      return false; // It's likely a transaction
    }

    // Check for transaction keywords with word numbers
    final hasTransactionWordKeyword = RegExp(
            r'(?:sold|bought|spent|paid|buy|sell|purchase|expense)\s+(?:one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|thirteen|fourteen|fifteen|sixteen|seventeen|eighteen|nineteen|twenty|a|an)',
            caseSensitive: false)
        .hasMatch(text);

    if (hasTransactionWordKeyword) {
      return false; // It's likely a transaction with word number
    }

    // Third check: question words and query patterns - these indicate queries
    final queryPatterns = [
      // Question words
      'how much', 'how many', 'how long', 'how often', 'how do', 'how can',
      'how should', 'how is', 'how are',
      'what is', 'what are', 'what was', 'what were', 'what does', 'what did',
      'what do', 'what can', 'what will', 'what\'s',
      'where is', 'where are', 'where did', 'where do',
      'when did', 'when was', 'when will', 'when is',
      'who is', 'who are', 'who did', 'who does',
      'why is', 'why did', 'why do',
      'which is', 'which are', 'which did',
      // Common query phrases
      'show me', 'tell me', 'give me', 'find', 'search', 'list', 'count',
      'number of', 'total', 'sum', 'all', 'every',
      // Time-based queries
      'today', 'yesterday', 'tomorrow', 'this week', 'this month', 'this year',
      'last week', 'last month', 'last day',
      // Business query keywords
      'profit', 'revenue', 'income', 'sales', 'expense', 'expenses',
      'cost', 'costs', 'balance',
      'report', 'reports', 'summary', 'overview', 'statistics', 'stats',
      'calculate', 'compute', 'check', 'get', 'retrieve', 'view', 'see',
      // Greetings and general queries
      'hello', 'hi', 'hey', 'how are you', 'what can you do', 'help',
      'who are you', 'capabilities', 'features',
      'inventory', 'stock', 'products', 'items in stock',
      'customer', 'client', 'buyer', 'supplier', 'vendor', 'distributor',
      'category', 'type', 'group', 'receipt', 'receipts',
      'thank', 'thanks', 'bye', 'goodbye',
      '?', 'any', 'anyone', 'anything',
    ];

    for (var pattern in queryPatterns) {
      if (text.contains(pattern)) {
        return true; // It's a query
      }
    }

    // Check if starts with question words
    final firstWord = text.split(' ').first.trim().toLowerCase();
    final questionStarters = [
      'who',
      'what',
      'where',
      'when',
      'why',
      'how',
      'is',
      'are',
      'can',
      'do',
      'does',
      'did',
      'will',
      'would',
      'should',
      'could'
    ];

    if (questionStarters.contains(firstWord)) {
      return true;
    }

    // Default: treat as query if short, otherwise as transaction attempt
    if (text.length < 30) {
      return true;
    }

    return false;
  }

  String _getQueryFallbackResponse(String query) {
    final lowerQuery = query.toLowerCase();
    final transactionProvider = context.read<TransactionProvider>();
    final transactions = transactionProvider.transactions;

    // Calculate actual data for dynamic responses
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    double todaySales = 0;
    double todayExpenses = 0;
    double todayPurchases = 0;
    double weekSales = 0;
    double weekExpenses = 0;
    double monthSales = 0;
    double monthExpenses = 0;
    int todayTransactionCount = 0;
    int weekTransactionCount = 0;
    int monthTransactionCount = 0;

    for (var t in transactions) {
      final createdAt = t.createdAt;
      if (createdAt.isAfter(todayStart)) {
        todayTransactionCount++;
        if (t.type == TransactionType.sale) todaySales += t.totalAmount;
        if (t.type == TransactionType.expense) todayExpenses += t.totalAmount;
        if (t.type == TransactionType.purchase) todayPurchases += t.totalAmount;
      }
      if (createdAt.isAfter(weekStart)) {
        weekTransactionCount++;
        if (t.type == TransactionType.sale) weekSales += t.totalAmount;
        if (t.type == TransactionType.expense) weekExpenses += t.totalAmount;
      }
      if (createdAt.isAfter(monthStart)) {
        monthTransactionCount++;
        if (t.type == TransactionType.sale) monthSales += t.totalAmount;
        if (t.type == TransactionType.expense) monthExpenses += t.totalAmount;
      }
    }

    final todayProfit = todaySales - todayExpenses;
    final weekProfit = weekSales - weekExpenses;
    final monthProfit = monthSales - monthExpenses;

    // Handle greeting queries
    if (lowerQuery.contains('hello') ||
        lowerQuery.contains('hi') ||
        lowerQuery.contains('hey') ||
        lowerQuery.contains('how are you')) {
      return '👋 Hello! I\'m your iSmart AI assistant!\n\n'
          'I can help you:\n'
          '• Record sales, expenses, and purchases\n'
          '• Check your profits and sales\n'
          '• Add products, customers, and suppliers\n'
          '• Answer questions about your business\n\n'
          'Just type or speak what you need! 🚀';
    }

    // Handle "what can you do" queries
    if (lowerQuery.contains('what can you do') ||
        lowerQuery.contains('help') ||
        lowerQuery.contains('capabilities')) {
      return '🎯 I can help you with:\n\n'
          '📝 **Transactions:**\n'
          '• "I sold 5 bread at 2000"\n'
          '• "Spent 10000 on transport"\n'
          '• "Bought 10 packets sugar"\n\n'
          '💰 **Business Queries:**\n'
          '• "How much did I sell today?"\n'
          '• "What is my profit this week?"\n'
          '• "Show me my expenses"\n\n'
          '📦 **Entity Management:**\n'
          '• "Add product Bread, price 5000"\n'
          '• "Add customer John, phone 0772"\n'
          '• "Add supplier ABC Distributors"';
    }

    // Handle "who are you" queries
    if (lowerQuery.contains('who are you') ||
        lowerQuery.contains('what are you')) {
      return '🤖 I\'m iSmart AI, your business assistant!\n\n'
          'I\'m designed to help small shop owners in Uganda manage their business more easily.\n\n'
          'I can understand your voice or text input, '
          'parse transactions, and answer questions about your business.\n\n'
          'Try saying: "How much did I sell today?"';
    }

    // Handle inventory queries
    if (lowerQuery.contains('inventory') ||
        lowerQuery.contains('stock') ||
        lowerQuery.contains('products')) {
      return '📦 Inventory Overview\n\n'
          '${transactions.isNotEmpty ? 'You have ${transactions.length} transactions recorded.\n\n'
              'To see your actual inventory, go to the Inventory screen.\n\n'
              'Try: "What products sell best?"' : 'No transactions recorded yet.\n\n'
              'Start recording sales to track your inventory!\n\n'
              'Try: "I sold 3 bread at 2000 each"'}';
    }

    // Handle customer queries
    if (lowerQuery.contains('customer') || lowerQuery.contains('client')) {
      return '👤 Customer Management\n\n'
          'I can help you add and track customers.\n\n'
          'To manage customers, go to the Customers screen.\n\n'
          'Try: "Add customer John, phone 0772123456"';
    }

    // Handle supplier queries
    if (lowerQuery.contains('supplier') || lowerQuery.contains('vendor')) {
      return '🏭 Supplier Management\n\n'
          'I can help you manage your suppliers.\n\n'
          'To view suppliers, go to the Suppliers screen.\n\n'
          'Try: "Add supplier ABC Company, phone 0772123456"';
    }

    // Handle category queries
    if (lowerQuery.contains('category')) {
      return '🏷️ Categories\n\n'
          'Your shop can use these categories:\n'
          '• Food & Beverages\n'
          '• Household\n'
          '• Transport\n'
          '• Communication\n'
          '• Medical\n'
          '• Clothing\n'
          '• Personal Care\n'
          '• Other\n\n'
          'I auto-detect categories from your transactions!';
    }

    // Handle print/receipt/invoice/report queries
    if (lowerQuery.contains('print') ||
        lowerQuery.contains('receipt') ||
        lowerQuery.contains('invoice') ||
        lowerQuery.contains('generate receipt') ||
        lowerQuery.contains('create receipt')) {
      return '🧾 Receipt & Printing\n\n'
          'I can help you print receipts, invoices, and reports!\n\n'
          'Just say things like:\n'
          '• "Print my last receipt"\n'
          '• "Print an invoice for my customer"\n'
          '• "Print my daily report"\n'
          '• "Generate and print a profit report"\n\n'
          '🖨️ What would you like to print?';
    }

    // Handle report queries
    if (lowerQuery.contains('report') ||
        lowerQuery.contains('generate report') ||
        lowerQuery.contains('create report') ||
        lowerQuery.contains('daily report') ||
        lowerQuery.contains('weekly report') ||
        lowerQuery.contains('monthly report')) {
      return '📊 Reports\n\n'
          'I can help you generate reports! Here\'s how:\n\n'
          '1. Go to the Reports screen for detailed analytics\n'
          '2. Or ask me specific questions like:\n'
          '   - "How much did I sell this week?"\n'
          '   - "What is my profit this month?"\n'
          '   - "Show my expenses breakdown"\n\n'
          'Available reports:\n'
          '• Daily Sales Report\n'
          '• Weekly Profit Summary\n'
          '• Monthly Expense Breakdown\n'
          '• Product Performance\n\n'
          'What specific report would you like? 📈';
    }

    // Handle invoice queries
    if (lowerQuery.contains('invoice')) {
      return '📄 Invoice Generation\n\n'
          'To create an invoice, go to the Receipts screen.\n\n'
          'From there you can:\n'
          '• Generate new invoices\n'
          '• View past invoices\n'
          '• Print or share invoices\n\n'
          'Try: "Go to receipts" to navigate there! 📋';
    }

    // Handle "thank you" queries
    if (lowerQuery.contains('thank')) {
      return '😊 You\'re welcome!\n\n'
          'Is there anything else I can help with?';
    }

    // Handle "goodbye" queries
    if (lowerQuery.contains('bye') || lowerQuery.contains('goodbye')) {
      return '👋 Goodbye!\n\n'
          'Thank you for using iSmart AI!\n'
          'Feel free to come back anytime. 🌟';
    }

    // Handle purchase queries
    if (lowerQuery.contains('purchase') ||
        lowerQuery.contains('bought') ||
        lowerQuery.contains('restock')) {
      if (todayPurchases > 0) {
        return '🛒 Your Purchases:\n\n'
            '📅 Today: UGX ${todayPurchases.toStringAsFixed(0)}\n'
            'Track purchases to manage your inventory!';
      } else {
        return '🛒 No purchases recorded today.\n\n'
            'Track stock purchases by saying:\n'
            '"Bought 10 packets sugar at 3000"';
      }
    }

    // Provide dynamic, data-driven responses based on query type
    if (lowerQuery.contains('how much') ||
        lowerQuery.contains('total') ||
        lowerQuery.contains('amount')) {
      return '📊 Here\'s your sales summary:\n\n'
          '📅 Today:\n'
          '• Sales: UGX ${todaySales.toStringAsFixed(0)}\n'
          '• Expenses: UGX ${todayExpenses.toStringAsFixed(0)}\n'
          '• Purchases: UGX ${todayPurchases.toStringAsFixed(0)}\n'
          '• Profit: UGX ${todayProfit.toStringAsFixed(0)}\n'
          '• Transactions: $todayTransactionCount\n\n'
          '📆 This Week:\n'
          '• Sales: UGX ${weekSales.toStringAsFixed(0)}\n'
          '• Profit: UGX ${weekProfit.toStringAsFixed(0)}\n\n'
          '📆 This Month:\n'
          '• Sales: UGX ${monthSales.toStringAsFixed(0)}\n'
          '• Profit: UGX ${monthProfit.toStringAsFixed(0)}';
    }

    if (lowerQuery.contains('profit') ||
        lowerQuery.contains('earn') ||
        lowerQuery.contains('loss')) {
      if (transactions.isNotEmpty) {
        return '📈 Your Profit Overview:\n\n'
            '• Today: UGX ${todayProfit.toStringAsFixed(0)}\n'
            '• This Week: UGX ${weekProfit.toStringAsFixed(0)}\n'
            '• This Month: UGX ${monthProfit.toStringAsFixed(0)}\n\n'
            '${todayProfit > 0 ? "Great job! You're making profit today! 🎉" : "Keep tracking to improve your profit! 💪"}\n\n'
            'Total transactions: $monthTransactionCount this month';
      } else {
        return '📈 No transactions recorded yet.\n\n'
            'Start recording your sales and expenses to track your profit!\n\n'
            'Try saying: "I sold 10 items at 5000 each"';
      }
    }

    if (lowerQuery.contains('sales') ||
        lowerQuery.contains('sold') ||
        lowerQuery.contains('revenue') ||
        lowerQuery.contains('income')) {
      if (todaySales > 0) {
        return '🛒 Your Sales Summary:\n\n'
            '📅 Today: UGX ${todaySales.toStringAsFixed(0)}\n'
            '📅 This Week: UGX ${weekSales.toStringAsFixed(0)}\n'
            '📅 This Month: UGX ${monthSales.toStringAsFixed(0)}\n\n'
            'You\'ve made $todayTransactionCount transaction${todayTransactionCount > 1 ? 's' : ''} today!\n\n'
            'Want more details? Try: "Show me my sales this week"';
      } else {
        return '🛒 No sales recorded today.\n\n'
            'Start recording your first sale to start tracking!\n\n'
            'Try saying: "I sold 3 bread at 2000 each"';
      }
    }

    if (lowerQuery.contains('expense') ||
        lowerQuery.contains('spent') ||
        lowerQuery.contains('cost')) {
      if (todayExpenses > 0) {
        return '💸 Your Expenses Summary:\n\n'
            '📅 Today: UGX ${todayExpenses.toStringAsFixed(0)}\n'
            '📅 This Week: UGX ${weekExpenses.toStringAsFixed(0)}\n'
            '📅 This Month: UGX ${monthExpenses.toStringAsFixed(0)}\n\n'
            'Expense transactions: $todayTransactionCount today';
      } else {
        return '💸 No expenses recorded today.\n\n'
            'Good job keeping expenses low!\n\n'
            'Track expenses by saying: "I spent 10000 on transport"';
      }
    }

    if (lowerQuery.contains('list') ||
        lowerQuery.contains('show') ||
        lowerQuery.contains('recent') ||
        lowerQuery.contains('last')) {
      if (transactions.isNotEmpty) {
        // Get recent transactions
        final recentList = transactions.take(5).map((t) {
          final typeLabel = t.type == TransactionType.sale
              ? 'Sale'
              : t.type == TransactionType.expense
                  ? 'Expense'
                  : t.type == TransactionType.purchase
                      ? 'Purchase'
                      : 'Other';
          return '• $typeLabel: UGX ${t.totalAmount.toStringAsFixed(0)} - ${t.description ?? "No description"}';
        }).join('\n');

        return '📋 Recent Transactions:\n\n$recentList\n\n'
            'Total: ${transactions.length} transactions\n\n'
            'Want to see more? Try asking: "Show me all transactions today"';
      } else {
        return '📋 No transactions recorded yet.\n\n'
            'Start recording to see your activity here!\n\n'
            'Try saying: "I sold 5 bread at 2000 each"';
      }
    }

    // Generic fallback with actual data
    if (transactions.isNotEmpty) {
      return '🤖 I\'m your iSmart AI assistant!\n\n'
          '📊 Quick Stats:\n'
          '• Today\'s Sales: UGX ${todaySales.toStringAsFixed(0)}\n'
          '• Today\'s Expenses: UGX ${todayExpenses.toStringAsFixed(0)}\n'
          '• Today\'s Profit: UGX ${todayProfit.toStringAsFixed(0)}\n'
          '• Total Transactions: ${transactions.length}\n\n'
          'You can ask me about:\n'
          '• "How much did I sell today?"\n'
          '• "What is my profit this week?"\n'
          '• "Show me my expenses"\n'
          '• "List my recent transactions"';
    } else {
      return '🤖 I\'m your iSmart AI assistant!\n\n'
          'I can help you track your business. Start by recording transactions:\n\n'
          '• "I sold 5 bread at 2000 each"\n'
          '• "I spent 10000 on transport"\n'
          '• "I bought sugar 2 packets at 3000"\n\n'
          'Once you have data, I can answer questions like:\n'
          '• "How much did I sell today?"\n'
          '• "What is my profit this week?"';
    }
  }

  String _getTransactionHelpResponse(String userInput) {
    final lowerInput = userInput.toLowerCase();

    // Try to understand what the user is trying to do
    if (lowerInput.contains('sold') ||
        lowerInput.contains('sell') ||
        lowerInput.contains('buy') ||
        lowerInput.contains('purchase') ||
        lowerInput.contains('bought') ||
        lowerInput.contains('spent') ||
        lowerInput.contains('expense')) {
      // The user wants to record a transaction
      return '💡 I understand you want to record a transaction, but I couldn\'t parse the details.\n\n'
          'For sales, try this format:\n'
          '• "Sold [quantity] [item] at [price]"\n'
          '  Example: "Sold 5 bread at 2000"\n\n'
          'For expenses, try:\n'
          '• "Spent [amount] on [item]"\n'
          '  Example: "Spent 10000 on transport"\n\n'
          'For purchases, try:\n'
          '• "Bought [quantity] [item] at [price]"\n'
          '  Example: "Bought 10 packets sugar at 3000"';
    }

    // If it doesn't look like a transaction, treat it as a query
    return _getQueryFallbackResponse(userInput);
  }

  String _buildDataContext(List<dynamic> transactions) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    double todaySales = 0;
    double todayExpenses = 0;
    double todayPurchases = 0;
    double weekSales = 0;
    double weekExpenses = 0;
    double monthSales = 0;
    double monthExpenses = 0;
    int totalTransactions = transactions.length;

    for (var t in transactions) {
      final createdAt = t.createdAt;
      if (createdAt.isAfter(todayStart)) {
        if (t.type == TransactionType.sale) todaySales += t.totalAmount;
        if (t.type == TransactionType.expense) todayExpenses += t.totalAmount;
        if (t.type == TransactionType.purchase) todayPurchases += t.totalAmount;
      }
      if (createdAt.isAfter(weekStart)) {
        if (t.type == TransactionType.sale) weekSales += t.totalAmount;
        if (t.type == TransactionType.expense) weekExpenses += t.totalAmount;
      }
      if (createdAt.isAfter(monthStart)) {
        if (t.type == TransactionType.sale) monthSales += t.totalAmount;
        if (t.type == TransactionType.expense) monthExpenses += t.totalAmount;
      }
    }

    return '''
Shop Data Context:
- Today's Sales: UGX ${todaySales.toStringAsFixed(0)}
- Today's Expenses: UGX ${todayExpenses.toStringAsFixed(0)}
- Today's Purchases: UGX ${todayPurchases.toStringAsFixed(0)}
- This Week's Sales: UGX ${weekSales.toStringAsFixed(0)}
- This Week's Expenses: UGX ${weekExpenses.toStringAsFixed(0)}
- This Month's Sales: UGX ${monthSales.toStringAsFixed(0)}
- This Month's Expenses: UGX ${monthExpenses.toStringAsFixed(0)}
- Total Transactions: $totalTransactions
- Today's Profit: UGX ${(todaySales - todayExpenses).toStringAsFixed(0)}
- This Week's Profit: UGX ${(weekSales - weekExpenses).toStringAsFixed(0)}
- This Month's Profit: UGX ${(monthSales - monthExpenses).toStringAsFixed(0)}
''';
  }

  String _buildDetailedDataContext(
      List<dynamic> transactions, String queryType) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    double todaySales = 0;
    double todayExpenses = 0;
    double todayPurchases = 0;
    double weekSales = 0;
    double weekExpenses = 0;
    double monthSales = 0;
    double monthExpenses = 0;
    int totalTransactions = transactions.length;

    // Track recent transactions for context
    List<Map<String, dynamic>> recentTransactions = [];
    List<String> topProducts = [];
    Map<String, int> productCounts = {};
    Map<String, double> categorySales = {};
    Map<String, int> categoryCounts = {};

    for (var t in transactions) {
      final createdAt = t.createdAt;

      // Count products
      if (t.items != null) {
        for (var item in t.items!) {
          final productName = item.itemName ?? 'Unknown';
          productCounts[productName] = (productCounts[productName] ?? 0) + 1;

          // Track category sales for sales transactions
          if (t.type == TransactionType.sale) {
            final category = t.category ?? 'Other';
            categorySales[category] =
                (categorySales[category] ?? 0) + t.totalAmount;
            categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
          }
        }
      }

      if (createdAt.isAfter(todayStart)) {
        if (t.type == TransactionType.sale) todaySales += t.totalAmount;
        if (t.type == TransactionType.expense) todayExpenses += t.totalAmount;
        if (t.type == TransactionType.purchase) todayPurchases += t.totalAmount;
      }
      if (createdAt.isAfter(weekStart)) {
        if (t.type == TransactionType.sale) weekSales += t.totalAmount;
        if (t.type == TransactionType.expense) weekExpenses += t.totalAmount;
      }
      if (createdAt.isAfter(monthStart)) {
        if (t.type == TransactionType.sale) monthSales += t.totalAmount;
        if (t.type == TransactionType.expense) monthExpenses += t.totalAmount;
      }

      // Keep last 10 transactions for context
      if (recentTransactions.length < 10) {
        recentTransactions.add({
          'type': t.type.toString().split('.').last,
          'amount': t.totalAmount,
          'description': t.description ?? 'No description',
          'date': createdAt.toString().substring(0, 16),
          'category': t.category ?? 'Other',
        });
      }
    }

    // Get top 5 products
    final sortedProducts = productCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    topProducts = sortedProducts.take(5).map((e) => e.key).toList();

    // Get top categories sorted by sales
    final sortedCategories = categorySales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(3).map((e) => e.key).toList();

    final todayProfit = todaySales - todayExpenses;
    final weekProfit = weekSales - weekExpenses;
    final monthProfit = monthSales - monthExpenses;
    final todayProfitMargin =
        todaySales > 0 ? (todayProfit / todaySales * 100) : 0.0;
    final weekProfitMargin =
        weekSales > 0 ? (weekProfit / weekSales * 100) : 0.0;
    final monthProfitMargin =
        monthSales > 0 ? (monthProfit / monthSales * 100) : 0.0;

    // Build comprehensive context with emojis and better formatting
    String context = '''
SHOP BUSINESS DATA OVERVIEW - Use these actual numbers in your response:

SALES AND REVENUE:
Today's Sales: UGX ${todaySales.toStringAsFixed(0)}
This Week's Sales: UGX ${weekSales.toStringAsFixed(0)}
This Month's Sales: UGX ${monthSales.toStringAsFixed(0)}

EXPENSES:
Today's Expenses: UGX ${todayExpenses.toStringAsFixed(0)}
This Week's Expenses: UGX ${weekExpenses.toStringAsFixed(0)}
This Month's Expenses: UGX ${monthExpenses.toStringAsFixed(0)}

PURCHASES RESTOCK:
Today's Purchases: UGX ${todayPurchases.toStringAsFixed(0)}

PROFIT ANALYSIS:
Today's Profit: UGX ${todayProfit.toStringAsFixed(0)} (${todayProfitMargin.toStringAsFixed(1)}% margin)
This Week's Profit: UGX ${weekProfit.toStringAsFixed(0)} (${weekProfitMargin.toStringAsFixed(1)}% margin)
This Month's Profit: UGX ${monthProfit.toStringAsFixed(0)} (${monthProfitMargin.toStringAsFixed(1)}% margin)

ACTIVITY:
Total Transactions: $totalTransactions
Transactions Today: ${transactions.where((t) => t.createdAt.isAfter(todayStart)).length}
''';

    // Add top products if available
    if (topProducts.isNotEmpty) {
      context += '\nTOP SELLING PRODUCTS:\n';
      for (var i = 0; i < topProducts.length; i++) {
        final count = productCounts[topProducts[i]] ?? 0;
        context += '${i + 1}. ${topProducts[i]} - $count sales\n';
      }
    }

    // Add top categories
    if (topCategories.isNotEmpty) {
      context += '\nTOP SELLING CATEGORIES by revenue:\n';
      for (var i = 0; i < topCategories.length; i++) {
        final amount = categorySales[topCategories[i]] ?? 0;
        final count = categoryCounts[topCategories[i]] ?? 0;
        context +=
            '${i + 1}. ${topCategories[i]} - UGX ${amount.toStringAsFixed(0)} ($count transactions)\n';
      }
    }

    // Add recent transactions for queries about recent activity
    if (queryType.contains('recent') ||
        queryType.contains('last') ||
        queryType.contains('latest') ||
        queryType.contains('show') ||
        queryType.contains('list')) {
      context += '\nRECENT TRANSACTIONS Last 10:\n';
      for (var t in recentTransactions) {
        context +=
            '- ${t['type']}: UGX ${t['amount']} - ${t['description']} (${t['date']}) - ${t['category']}\n';
      }
    }

    // Add comparative analysis
    context += '\nCOMPARATIVE ANALYSIS:\n';
    if (weekSales > 0) {
      context +=
          'Average Daily Sales: UGX ${(weekSales / 7).toStringAsFixed(0)}\n';
    }
    if (weekExpenses > 0) {
      context +=
          'Average Daily Expenses: UGX ${(weekExpenses / 7).toStringAsFixed(0)}\n';
    }
    if (todaySales > 0 && weekSales > 0) {
      final dailyAvg = weekSales / 7;
      final todayVsAvg = (todaySales / dailyAvg * 100).toStringAsFixed(0);
      context += "Today's performance vs weekly average: $todayVsAvg%\n";
    }
    if (monthSales > 0 && weekSales > 0) {
      final weeklyAvg = weekSales;
      final monthlyDailyAvg = monthSales / 30;
      final growth = monthlyDailyAvg > weeklyAvg ? 'increasing' : 'stable';
      context += 'Sales trend: $growth\n';
    }

    context +=
        '\nIMPORTANT: Always include specific numbers from this data in your response. Provide actionable insights.';

    return context;
  }

  Future<TransactionIntent> _parseTransactionWithGemini(String text) async {
    // Use Gemini directly - no fallback to OpenAI
    // This ensures transactions are parsed directly by Gemini AI
    var geminiResult = await GeminiParserService.parseTransaction(text);

    // If Gemini returns a valid result with actual item name, use it
    if (geminiResult != null &&
        geminiResult['item'] != null &&
        geminiResult['item'].toString() != 'Unknown' &&
        geminiResult['item'].toString().isNotEmpty) {
      debugPrint('Gemini transaction parsing succeeded');
      return _convertGeminiResult(geminiResult);
    }

    // Gemini parsing failed - return a failed intent to trigger help response
    debugPrint('Gemini transaction parsing failed - no fallback');
    return TransactionIntent(
      type: TransactionType.sale,
      amount: 0,
      itemName: 'Unknown',
      description: text,
      category: 'Other',
      quantity: 1,
      unit: 'pcs',
      unitPrice: 0,
      customerName: '',
      notes: '',
      transactionDate: DateTime.now(),
    );
  }

  TransactionIntent _convertGeminiResult(Map<String, dynamic> geminiResult) {
    TransactionType type;
    final typeStr = geminiResult['type']?.toString().toLowerCase() ?? 'sale';
    if (typeStr.contains('expense')) {
      type = TransactionType.expense;
    } else if (typeStr.contains('purchase')) {
      type = TransactionType.purchase;
    } else {
      type = TransactionType.sale;
    }

    // Check for multiple items (items can be passed as array)
    List<Map<String, dynamic>>? additionalItems;
    final itemsArray = geminiResult['items'];
    if (itemsArray is List) {
      additionalItems = itemsArray.cast<Map<String, dynamic>>();
    }

    return TransactionIntent(
      type: type,
      amount: (geminiResult['total'] as num?)?.toDouble() ?? 0,
      itemName: geminiResult['item']?.toString() ?? 'Unknown',
      description: _transcribedText,
      category: geminiResult['category']?.toString() ?? 'Other',
      quantity: (geminiResult['quantity'] as num?)?.toInt() ?? 1,
      unit: geminiResult['unit']?.toString() ?? 'pcs',
      unitPrice: (geminiResult['unitPrice'] as num?)?.toDouble() ?? 0,
      customerName: '',
      notes: '',
      transactionDate: DateTime.now(),
      additionalItems: additionalItems,
    );
  }

  TransactionIntent _convertOpenAIResult(Map<String, dynamic> openAIResult) {
    TransactionType type;
    final typeStr = openAIResult['type']?.toString().toLowerCase() ?? 'sale';
    if (typeStr.contains('expense')) {
      type = TransactionType.expense;
    } else if (typeStr.contains('purchase')) {
      type = TransactionType.purchase;
    } else {
      type = TransactionType.sale;
    }

    return TransactionIntent(
      type: type,
      amount: (openAIResult['total'] as num?)?.toDouble() ?? 0,
      itemName: openAIResult['item']?.toString() ?? 'Unknown',
      description: _transcribedText,
      category: openAIResult['category']?.toString() ?? 'Other',
      quantity: (openAIResult['quantity'] as num?)?.toInt() ?? 1,
      unit: openAIResult['unit']?.toString() ?? 'pcs',
      unitPrice: (openAIResult['unitPrice'] as num?)?.toDouble() ?? 0,
      customerName: '',
      notes: '',
      transactionDate: DateTime.now(),
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('AI Assistant'),
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

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;
    final errorColor = isDarkMode ? IOSDarkColors.error : IOSColors.error;
    final labelPrimary =
        isDarkMode ? IOSDarkColors.labelPrimary : IOSColors.labelPrimary;
    final labelSecondary =
        isDarkMode ? IOSDarkColors.labelSecondary : IOSColors.labelSecondary;
    final systemBg = isDarkMode
        ? IOSDarkColors.systemBackground
        : IOSColors.systemBackground;
    final secondarySystemBg = isDarkMode
        ? IOSDarkColors.secondarySystemBackground
        : IOSColors.secondarySystemBackground;

    return Scaffold(
      backgroundColor: secondarySystemBg,
      appBar: IOSNavigationBar(
        title: 'AI Assistant',
        automaticallyImplyLeading: false,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _navigateToHome,
          child: Icon(CupertinoIcons.back, color: primaryColor),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat messages area
            Expanded(
              child: ListView.builder(
                controller: _chatScrollController,
                padding: const EdgeInsets.all(IOSSpacing.md),
                itemCount: _chatMessages.length,
                itemBuilder: (context, index) {
                  final message = _chatMessages[index];
                  return _buildChatBubble(message, isDarkMode, primaryColor,
                      labelPrimary, labelSecondary, systemBg);
                },
              ),
            ),

            // Processing indicator
            if (_isProcessing)
              Container(
                padding: const EdgeInsets.all(IOSSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CupertinoActivityIndicator(),
                    const SizedBox(width: IOSSpacing.sm),
                    Text(
                      'Processing...',
                      style: TextStyle(
                        color: labelSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

            // Transaction review (if active)
            if (_showTransactionReview)
              _buildTransactionReviewActions(
                  isDarkMode, primaryColor, labelPrimary, labelSecondary),

            // Fixed bottom input area
            _buildBottomInputArea(
                isDarkMode, primaryColor, errorColor, labelPrimary, systemBg),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onNavigate: (index) {
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(
              builder: (_) => HomeScreen(initialTabIndex: index),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatBubble(
      ChatMessage message,
      bool isDarkMode,
      Color primaryColor,
      Color labelPrimary,
      Color labelSecondary,
      Color systemBg) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: IOSSpacing.md),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                CupertinoIcons.sparkles,
                color: primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: IOSSpacing.sm),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showChatBubbleOptions(context, message),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.all(IOSSpacing.md),
                decoration: BoxDecoration(
                  color: isUser ? primaryColor : systemBg,
                  borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
                  border: isUser
                      ? null
                      : Border.all(
                          color: _getBadgeColor(message.type, isDarkMode)
                              .withOpacity(0.3),
                        ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge for non-user messages
                    if (!isUser && message.type != ChatMessageType.text)
                      _buildMessageBadge(message.type, isDarkMode),
                    if (!isUser && message.type != ChatMessageType.text)
                      const SizedBox(height: IOSSpacing.sm),
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isUser ? Colors.white : labelPrimary,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: IOSSpacing.sm),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                CupertinoIcons.person_fill,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageBadge(ChatMessageType type, bool isDarkMode) {
    String label;
    IconData icon;
    Color color;

    switch (type) {
      case ChatMessageType.query:
        label = 'Query Result';
        icon = CupertinoIcons.search;
        color = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;
        break;
      case ChatMessageType.transaction:
        label = 'Transaction';
        icon = CupertinoIcons.arrow_right_arrow_left;
        color = isDarkMode ? IOSDarkColors.saleColor : IOSColors.saleColor;
        break;
      case ChatMessageType.profit:
        label = 'Profit';
        icon = CupertinoIcons.money_dollar_circle_fill;
        color = Colors.green;
        break;
      case ChatMessageType.receipt:
        label = 'Receipt';
        icon = CupertinoIcons.doc_text_fill;
        color = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;
        break;
      case ChatMessageType.inventory:
        label = 'Inventory';
        icon = CupertinoIcons.cube_box_fill;
        color = Colors.orange;
        break;
      case ChatMessageType.supplier:
        label = 'Supplier';
        icon = CupertinoIcons.person_2_fill;
        color = Colors.purple;
        break;
      case ChatMessageType.customer:
        label = 'Customer';
        icon = CupertinoIcons.person_fill;
        color = Colors.blue;
        break;
      case ChatMessageType.category:
        label = 'Category';
        icon = CupertinoIcons.tag_fill;
        color = Colors.teal;
        break;
      case ChatMessageType.error:
        label = 'Error';
        icon = CupertinoIcons.exclamationmark_circle_fill;
        color = isDarkMode ? IOSDarkColors.error : IOSColors.error;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBadgeColor(ChatMessageType type, bool isDarkMode) {
    switch (type) {
      case ChatMessageType.query:
        return isDarkMode ? IOSDarkColors.primary : IOSColors.primary;
      case ChatMessageType.transaction:
        return isDarkMode ? IOSDarkColors.saleColor : IOSColors.saleColor;
      case ChatMessageType.profit:
        return Colors.green;
      case ChatMessageType.receipt:
        return isDarkMode ? IOSDarkColors.primary : IOSColors.primary;
      case ChatMessageType.inventory:
        return Colors.orange;
      case ChatMessageType.supplier:
        return Colors.purple;
      case ChatMessageType.customer:
        return Colors.blue;
      case ChatMessageType.category:
        return Colors.teal;
      case ChatMessageType.error:
        return isDarkMode ? IOSDarkColors.error : IOSColors.error;
      default:
        return isDarkMode ? IOSDarkColors.primary : IOSColors.primary;
    }
  }

  Widget _buildTransactionReviewActions(bool isDarkMode, Color primaryColor,
      Color labelPrimary, Color labelSecondary) {
    final systemBg = isDarkMode
        ? IOSDarkColors.systemBackground
        : IOSColors.systemBackground;

    return Container(
      padding: const EdgeInsets.all(IOSSpacing.md),
      decoration: BoxDecoration(
        color: isDarkMode
            ? IOSDarkColors.secondarySystemBackground
            : IOSColors.secondarySystemBackground,
        border: Border(
          top: BorderSide(
            color: primaryColor.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Inline editing section for Quantity and Unit Price
          if (_showTransactionReview)
            _buildInlineEditSection(isDarkMode, labelPrimary, labelSecondary),
          const SizedBox(height: IOSSpacing.md),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: IOSSpacing.sm),
                  color: systemBg,
                  borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
                  onPressed: () {
                    setState(() {
                      _showTransactionReview = false;
                      _currentTransactionIntent = null;
                    });
                    _addChatMessage(
                      'Transaction cancelled. What else can I help you with?',
                      isUser: false,
                      type: ChatMessageType.text,
                    );
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: labelPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: IOSSpacing.sm),
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: IOSSpacing.sm),
                  color: systemBg,
                  borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
                  onPressed: _showEditDialog,
                  child: Text(
                    'Edit',
                    style: TextStyle(
                      color: labelPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: IOSSpacing.sm),
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: IOSSpacing.sm),
                  color: systemBg,
                  borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
                  onPressed: () async {
                    await _handlePrintDuringReview();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.printer,
                          size: 18, color: labelPrimary),
                      const SizedBox(width: IOSSpacing.xs),
                      Text(
                        'Print',
                        style: TextStyle(
                          color: labelPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: IOSSpacing.sm),
              Expanded(
                child: CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(vertical: IOSSpacing.sm),
                  borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
                  onPressed: _saveTransaction,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.checkmark_circle_fill,
                          size: 18, color: Colors.white),
                      SizedBox(width: IOSSpacing.xs),
                      Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInlineEditSection(
      bool isDarkMode, Color labelPrimary, Color labelSecondary) {
    final systemBg = isDarkMode
        ? IOSDarkColors.systemBackground
        : IOSColors.systemBackground;
    final secondarySystemBg = isDarkMode
        ? IOSDarkColors.secondarySystemBackground
        : IOSColors.secondarySystemBackground;
    final primaryColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;

    return Container(
      padding: const EdgeInsets.all(IOSSpacing.md),
      decoration: BoxDecoration(
        color: secondarySystemBg,
        borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✏️ Edit Transaction Details',
            style: TextStyle(
              color: labelPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: IOSSpacing.md),
          // Quantity row with inline editing
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Quantity:',
                  style: TextStyle(
                    color: labelSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: _isEditingQuantity
                    ? _buildInlineEditField(
                        controller: _inlineQuantityController,
                        isDarkMode: isDarkMode,
                        labelPrimary: labelPrimary,
                        onSave: _saveInlineQuantity,
                        onCancel: _cancelInlineEdit,
                        keyboardType: TextInputType.number,
                      )
                    : GestureDetector(
                        onTap: _startEditingQuantity,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: IOSSpacing.md,
                            vertical: IOSSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: systemBg,
                            borderRadius:
                                BorderRadius.circular(IOSBorderRadius.small),
                            border: Border.all(
                                color: primaryColor.withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$_transactionQuantity ${_getUnitDisplay()}',
                                style: TextStyle(
                                  color: labelPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(
                                CupertinoIcons.pencil,
                                size: 16,
                                color: primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: IOSSpacing.md),
          // Unit Price row with inline editing
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Unit Price:',
                  style: TextStyle(
                    color: labelSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: _isEditingUnitPrice
                    ? _buildInlineEditField(
                        controller: _inlineUnitPriceController,
                        isDarkMode: isDarkMode,
                        labelPrimary: labelPrimary,
                        onSave: _saveInlineUnitPrice,
                        onCancel: _cancelInlineEdit,
                        keyboardType: TextInputType.number,
                        prefix: 'UGX ',
                      )
                    : GestureDetector(
                        onTap: _startEditingUnitPrice,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: IOSSpacing.md,
                            vertical: IOSSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: systemBg,
                            borderRadius:
                                BorderRadius.circular(IOSBorderRadius.small),
                            border: Border.all(
                                color: primaryColor.withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'UGX ${_transactionUnitPrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: labelPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(
                                CupertinoIcons.pencil,
                                size: 16,
                                color: primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: IOSSpacing.sm),
          // Total display
          Container(
            padding: const EdgeInsets.all(IOSSpacing.md),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(IOSBorderRadius.small),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Total: ',
                  style: TextStyle(
                    color: labelPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'UGX ${_totalAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: IOSSpacing.sm),
          // Voice input hint
          Text(
            '💡 Say "Edit" or tap fields above to modify',
            style: TextStyle(
              color: labelSecondary,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInlineEditField({
    required TextEditingController controller,
    required bool isDarkMode,
    required Color labelPrimary,
    required VoidCallback onSave,
    required VoidCallback onCancel,
    required TextInputType keyboardType,
    String? prefix,
  }) {
    final systemBg = isDarkMode
        ? IOSDarkColors.systemBackground
        : IOSColors.systemBackground;
    final secondarySystemBg = isDarkMode
        ? IOSDarkColors.secondarySystemBackground
        : IOSColors.secondarySystemBackground;
    final primaryColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: systemBg,
        borderRadius: BorderRadius.circular(IOSBorderRadius.small),
        border: Border.all(color: primaryColor),
      ),
      child: Row(
        children: [
          if (prefix != null)
            Padding(
              padding: const EdgeInsets.only(left: IOSSpacing.sm),
              child: Text(
                prefix,
                style: TextStyle(
                  color: labelPrimary,
                  fontSize: 14,
                ),
              ),
            ),
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              keyboardType: keyboardType,
              autofocus: true,
              padding: const EdgeInsets.symmetric(
                horizontal: IOSSpacing.md,
                vertical: IOSSpacing.sm,
              ),
              decoration: null,
              style: TextStyle(
                color: labelPrimary,
                fontSize: 14,
              ),
              onSubmitted: (_) => onSave(),
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: IOSSpacing.sm),
            onPressed: onSave,
            child: Icon(
              CupertinoIcons.checkmark_circle_fill,
              size: 20,
              color: primaryColor,
            ),
            minimumSize: Size(32, 32),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: IOSSpacing.sm),
            onPressed: onCancel,
            child: Icon(
              CupertinoIcons.xmark_circle_fill,
              size: 20,
              color: isDarkMode ? IOSDarkColors.error : IOSColors.error,
            ),
            minimumSize: Size(32, 32),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInputArea(bool isDarkMode, Color primaryColor,
      Color errorColor, Color labelPrimary, Color systemBg) {
    // Enable voice button as long as we're not processing
    // The _startRecording method will handle initialization if needed
    final bool canRecord = !_isProcessing;
    final bool isRecording = _isListening;

    return Container(
      padding: const EdgeInsets.all(IOSSpacing.md),
      decoration: BoxDecoration(
        color: systemBg,
        border: Border(
          top: BorderSide(
            color: primaryColor.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Text input field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? IOSDarkColors.secondarySystemBackground
                    : IOSColors.secondarySystemBackground,
                borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
                border: Border.all(
                  color: primaryColor.withOpacity(0.3),
                ),
              ),
              child: CupertinoTextField(
                controller: _textController,
                placeholder: 'Type or speak your request...',
                maxLines: null,
                padding: const EdgeInsets.all(IOSSpacing.md),
                decoration: null,
                style: TextStyle(color: labelPrimary),
                enabled: !_isProcessing,
                onChanged: (value) {
                  setState(() {
                    _transcribedText = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: IOSSpacing.sm),
          // Send button
          if (_transcribedText.isNotEmpty)
            GestureDetector(
              onTap: _isProcessing ? null : _processTextInput,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: _isProcessing
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : const Icon(
                        CupertinoIcons.arrow_up,
                        color: Colors.white,
                        size: 24,
                      ),
              ),
            ),
          if (_transcribedText.isNotEmpty) const SizedBox(width: IOSSpacing.sm),
          // Voice button - using clean reusable VoiceButton widget
          VoiceButton(
            primaryColor: primaryColor,
            errorColor: errorColor,
            enabled: !_isProcessing,
            onTextRecognized: (text) {
              // Update text controller and process with AI
              _textController.text = text;
              setState(() {
                _transcribedText = text;
              });
              _processWithAI(text);
            },
            onRecordingStarted: () {
              setState(() {
                _isListening = true;
                _statusMessage = 'Listening...';
              });
            },
            onRecordingStopped: () {
              setState(() {
                _isListening = false;
              });
            },
          ),
        ],
      ),
    );
  }

  void _showChatBubbleOptions(BuildContext context, ChatMessage message) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Chat Options'),
        message: const Text('Select an action for this message'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // Copy message text to clipboard
              Clipboard.setData(ClipboardData(text: message.text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message copied to clipboard')),
              );
            },
            child: const Text('Copy Text'),
          ),
          if (!message.isUser) ...[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                // For entity messages, navigate to relevant screen
                _navigateToEntityScreen(context, message.type);
              },
              child: const Text('View Details'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                // Save/export options
                _showExportOptions(context, message);
              },
              child: const Text('Save/Export'),
            ),
          ],
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _navigateToEntityScreen(BuildContext context, ChatMessageType type) {
    Navigator.pop(context); // Close the action sheet
    switch (type) {
      case ChatMessageType.transaction:
        // Navigate to transaction details or list
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => const TransactionsListScreen()),
        );
        break;
      case ChatMessageType.inventory:
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => const InventoryScreen()),
        );
        break;
      case ChatMessageType.supplier:
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => const SuppliersScreen()),
        );
        break;
      case ChatMessageType.customer:
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => const CustomersScreen()),
        );
        break;
      case ChatMessageType.category:
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => const CategoriesScreen()),
        );
        break;
      case ChatMessageType.receipt:
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => const ReceiptsScreen()),
        );
        break;
      case ChatMessageType.profit:
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => const ReportsScreen()),
        );
        break;
      default:
        // For other types, just show a message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Details for ${type.name} coming soon')),
        );
    }
  }

  void _showExportOptions(BuildContext context, ChatMessage message) {
    Navigator.pop(context); // Close the action sheet
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Export Options'),
        message: const Text('How would you like to save this?'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // Save as note
              _saveAsNote(message.text);
            },
            child: const Text('Save as Note'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // Print the message
              _printMessage(message.text);
            },
            child: const Text('Print'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // Download as file
              _downloadAsFile(message.text);
            },
            child: const Text('Download'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _saveAsNote(String text) async {
    try {
      final note = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': text,
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'chat_note',
      };

      await LocalDatabaseService.saveNote(note);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving note: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save note: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _downloadAsFile(String text) async {
    try {
      // Get the documents directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'chat_export_$timestamp.txt';
      final file = File('${directory.path}/$fileName');

      // Write the text content to the file
      await file.writeAsString(text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File saved: $fileName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error downloading file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _printMessage(String text) async {
    try {
      // Create a PDF document
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text(
                text,
                style: const pw.TextStyle(fontSize: 12),
              ),
            );
          },
        ),
      );

      // Print the document
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Print dialog opened'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error printing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to print: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Print a receipt for a transaction
  Future<void> _printReceipt(Transaction transaction) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'iSMART SHOP',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    'Receipt',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                        'Receipt #: ${transaction.id.substring(0, 8).toUpperCase()}'),
                    pw.Text(DateFormat('dd MMM yyyy HH:mm')
                        .format(transaction.createdAt)),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Item',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Qty',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.center),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Price',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.right),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Total',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.right),
                        ),
                      ],
                    ),
                    ...transaction.items.map((item) => pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(item.itemName),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                  '${item.quantity.toStringAsFixed(0)} ${item.unitDisplay}',
                                  textAlign: pw.TextAlign.center),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                  NumberFormat('#,###')
                                      .format(item.pricePerUnit),
                                  textAlign: pw.TextAlign.right),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                  NumberFormat('#,###').format(item.amount),
                                  textAlign: pw.TextAlign.right),
                            ),
                          ],
                        )),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text('TOTAL: ',
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                        'UGX ${NumberFormat('#,###').format(transaction.totalAmount)}',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Spacer(),
                pw.Divider(),
                pw.Center(
                  child: pw.Text('Thank you for your business!',
                      style: const pw.TextStyle(fontSize: 12)),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt printed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error printing receipt: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to print receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Print an invoice for a transaction
  Future<void> _printInvoice(Transaction transaction,
      {String? customerName, String? customerPhone}) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('iSMART SHOP',
                            style: pw.TextStyle(
                                fontSize: 24, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Your Trusted Business Partner'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('INVOICE',
                            style: pw.TextStyle(
                                fontSize: 20, fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                            'Invoice #: INV-${transaction.id.substring(0, 8).toUpperCase()}'),
                        pw.Text(
                            'Date: ${DateFormat('dd MMM yyyy').format(transaction.createdAt)}'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 20),
                if (customerName != null || customerPhone != null) ...[
                  pw.Text('Bill To:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  if (customerName != null) pw.Text(customerName),
                  if (customerPhone != null) pw.Text(customerPhone),
                  pw.SizedBox(height: 20),
                ],
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Description',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Quantity',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.center),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Unit Price',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.right),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Amount',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.right),
                        ),
                      ],
                    ),
                    ...transaction.items.map((item) => pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(item.itemName),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                  '${item.quantity.toStringAsFixed(0)} ${item.unitDisplay}',
                                  textAlign: pw.TextAlign.center),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                  NumberFormat('#,###')
                                      .format(item.pricePerUnit),
                                  textAlign: pw.TextAlign.right),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Text(
                                  NumberFormat('#,###').format(item.amount),
                                  textAlign: pw.TextAlign.right),
                            ),
                          ],
                        )),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Row(
                          children: [
                            pw.Text('Subtotal: '),
                            pw.Text(
                                'UGX ${NumberFormat('#,###').format(transaction.totalAmount)}'),
                          ],
                        ),
                        pw.SizedBox(height: 5),
                        pw.Row(
                          children: [
                            pw.Text('Tax (0%): '),
                            pw.Text('UGX 0'),
                          ],
                        ),
                        pw.Divider(),
                        pw.Row(
                          children: [
                            pw.Text('TOTAL: ',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 16)),
                            pw.Text(
                                'UGX ${NumberFormat('#,###').format(transaction.totalAmount)}',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Spacer(),
                pw.Divider(),
                pw.Center(
                  child: pw.Text('Thank you for your business!',
                      style: const pw.TextStyle(fontSize: 12)),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice printed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error printing invoice: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to print invoice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Print a report
  Future<void> _printReport(
      List<Transaction> transactions, String reportType) async {
    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      // Calculate summary data
      double todaySales = 0;
      double todayExpenses = 0;
      for (var t in transactions) {
        if (t.createdAt.isAfter(todayStart)) {
          if (t.type == TransactionType.sale) todaySales += t.totalAmount;
          if (t.type == TransactionType.expense) todayExpenses += t.totalAmount;
        }
      }
      final todayProfit = todaySales - todayExpenses;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'iSMART SHOP',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    reportType == 'daily'
                        ? 'Daily Sales Report'
                        : 'Profit Summary Report',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Center(
                  child: pw.Text(DateFormat('dd MMM yyyy').format(now)),
                ),
                pw.Divider(),
                pw.SizedBox(height: 15),
                pw.Text('SUMMARY',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 14)),
                pw.SizedBox(height: 10),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.green),
                          borderRadius: pw.BorderRadius.circular(5),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Total Sales',
                                style: const pw.TextStyle(
                                    fontSize: 10, color: PdfColors.grey700)),
                            pw.SizedBox(height: 5),
                            pw.Text(
                                'UGX ${NumberFormat('#,###').format(todaySales)}',
                                style: pw.TextStyle(
                                    fontSize: 14,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.green)),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.red),
                          borderRadius: pw.BorderRadius.circular(5),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Total Expenses',
                                style: const pw.TextStyle(
                                    fontSize: 10, color: PdfColors.grey700)),
                            pw.SizedBox(height: 5),
                            pw.Text(
                                'UGX ${NumberFormat('#,###').format(todayExpenses)}',
                                style: pw.TextStyle(
                                    fontSize: 14,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.red)),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                              color: todayProfit >= 0
                                  ? PdfColors.blue
                                  : PdfColors.orange),
                          borderRadius: pw.BorderRadius.circular(5),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Net Profit',
                                style: const pw.TextStyle(
                                    fontSize: 10, color: PdfColors.grey700)),
                            pw.SizedBox(height: 5),
                            pw.Text(
                                'UGX ${NumberFormat('#,###').format(todayProfit)}',
                                style: pw.TextStyle(
                                    fontSize: 14,
                                    fontWeight: pw.FontWeight.bold,
                                    color: todayProfit >= 0
                                        ? PdfColors.blue
                                        : PdfColors.orange)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Divider(),
                pw.Center(
                  child: pw.Text(
                      'Generated on ${DateFormat('dd MMM yyyy HH:mm').format(now)} | Total Transactions: ${transactions.length}'),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report printed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error printing report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to print report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

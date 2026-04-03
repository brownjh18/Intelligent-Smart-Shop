import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:ismart_shop/models/transaction.dart' as app;
import 'package:ismart_shop/models/transaction_item.dart';
import 'package:ismart_shop/models/product.dart';
import 'package:ismart_shop/providers/auth_provider.dart';
import 'package:ismart_shop/providers/transaction_provider.dart';
import 'package:ismart_shop/providers/language_provider.dart';
import 'package:ismart_shop/services/speech_service.dart';
import 'package:ismart_shop/services/nlp_service.dart';
import 'package:ismart_shop/services/translation_service.dart';
import 'package:ismart_shop/services/local_database_service.dart';
import 'package:ismart_shop/services/report_service.dart';
import 'package:ismart_shop/utils/ios_theme.dart';
import 'package:ismart_shop/widgets/ios_app_bar.dart';
import 'package:ismart_shop/widgets/app_bottom_nav.dart';
import 'home_screen.dart';
import 'voice_recording_screen.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final SpeechService _speechService = SpeechService();
  bool _isSpeechInitialized = false;
  bool _isListening = false;
  String _voiceStatusMessage = 'Tap to speak';
  int _listeningItemIndex = -1; // -1 means not listening for any specific item

  app.TransactionType _type = app.TransactionType.sale;
  List<TransactionItem> _items = [];
  DateTime _createdAt = DateTime.now();
  String _description = '';
  String _category = '';
  String _customerName = '';
  String _notes = '';
  List<Product> _inventoryProducts = [];
  bool _isLoadingProducts = false;

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Add one empty item by default
    _addItem();
    // Initialize speech service
    _initializeSpeech();
    // Load inventory products
    _loadInventoryProducts();
  }

  Future<void> _loadInventoryProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userModel?.id;

      if (userId == null || userId.isEmpty) {
        setState(() {
          _inventoryProducts = [];
          _isLoadingProducts = false;
        });
        return;
      }

      // Load products from local database
      final localProducts = await LocalDatabaseService.getProducts(userId);

      setState(() {
        _inventoryProducts = localProducts
            .map((local) => Product(
                  id: local.firebaseId ?? local.id,
                  name: local.name,
                  description: local.description,
                  categoryId: local.categoryId,
                  categoryName: local.categoryName,
                  unit: local.unit,
                  sellingPrice: local.sellingPrice,
                  costPrice: local.costPrice,
                  stockQuantity: local.stockQuantity,
                  lowStockThreshold: local.lowStockThreshold,
                  imageUrl: local.imageUrl,
                  userId: local.userId,
                  createdAt: local.createdAt,
                  updatedAt: local.updatedAt,
                  isActive: local.isActive,
                ))
            .toList();
        _isLoadingProducts = false;
      });
    } catch (e) {
      debugPrint('Error loading inventory products: $e');
      setState(() => _isLoadingProducts = false);
    }
  }

  void _showProductPicker(int itemIndex) {
    showCupertinoModalPopup(
      context: context,
      builder: (dialogContext) => _ProductPickerSheet(
        products: _inventoryProducts,
        isLoading: _isLoadingProducts,
        onSelect: (product) {
          // Update the item with the selected product
          final currentItem = _items[itemIndex];
          final updatedItem = currentItem.copyWith(
            itemName: product.name,
            pricePerUnit: product.sellingPrice,
            amount: product.sellingPrice * currentItem.quantity,
          );
          _updateItem(itemIndex, updatedItem);
          Navigator.pop(dialogContext);
        },
      ),
    );
  }

  Future<void> _initializeSpeech() async {
    final success = await _speechService.initialize();
    setState(() {
      _isSpeechInitialized = success;
      if (!_isSpeechInitialized) {
        _voiceStatusMessage = 'Voice not available - try on physical device';
        debugPrint(
            'SpeechService: Initialization failed - ${_speechService.lastError}');
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _categoryController.dispose();
    _customerNameController.dispose();
    _notesController.dispose();
    _speechService.stopListening();
    super.dispose();
  }

  double get _totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.amount);
  }

  void _addItem() {
    final newItem = TransactionItem(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      itemName: '',
      quantity: 1,
      unit: QuantityUnit.pcs,
      pricePerUnit: 0,
      amount: 0,
    );
    setState(() {
      _items.add(newItem);
    });
  }

  /// Start voice input for a specific item (or -1 for general input)
  Future<void> _startVoiceInput({int itemIndex = -1}) async {
    if (!_isSpeechInitialized) {
      _showVoiceError(
          'Speech recognition is not available on this device. Please try on a physical device.');
      return;
    }

    setState(() {
      _listeningItemIndex = itemIndex;
      _isListening = true;
      _voiceStatusMessage = itemIndex == -1
          ? 'Listening for transaction...'
          : 'Listening for item...';
    });

    try {
      final languageProvider = context.read<LanguageProvider>();
      final localeId =
          languageProvider.currentLanguage == 'lg' ? 'lg' : 'en_US';

      final success = await _speechService.startListening(localeId: localeId);

      if (!success) {
        _showVoiceError(
            'Failed to start speech recognition: ${_speechService.lastError}');
        return;
      }

      // Wait for speech to complete (with timeout for emulator)
      await _waitForSpeechResult();
    } catch (e) {
      _showVoiceError('Failed to start voice recognition: $e');
    }
  }

  Future<void> _waitForSpeechResult() async {
    // Poll until speech stops or timeout (30 seconds max)
    int pollCount = 0;
    const maxPolls = 60; // 30 seconds at 500ms intervals

    while (_speechService.isListening && pollCount < maxPolls) {
      await Future.delayed(const Duration(milliseconds: 500));
      pollCount++;
    }

    // Even if we timed out, get whatever text we have
    final transcribedText = _speechService.text;

    // Force stop if still listening
    if (_speechService.isListening) {
      await _speechService.stopListening();
    }

    setState(() {
      _isListening = false;
    });

    debugPrint('SpeechService: Final transcribed text: "$transcribedText"');
    debugPrint('SpeechService: Last status: ${_speechService.lastStatus}');
    debugPrint('SpeechService: Last error: ${_speechService.lastError}');

    if (transcribedText.isEmpty) {
      // Show error message - speech recognition may not work on emulator
      _showVoiceError(
          'No speech detected. Please speak clearly and try again.\n\nNote: Speech recognition requires a physical device with microphone.');
      return;
    }

    // Process the transcribed text
    _processVoiceInput(transcribedText);
  }

  void _processVoiceInput(String transcribedText) {
    // Get current language and translate if needed
    final languageProvider = context.read<LanguageProvider>();
    final processedText = TranslationService.processText(
      transcribedText,
      languageProvider.currentLanguage,
    );

    // Parse the transaction using NLP
    final intent = NLPService.parseTransaction(processedText);

    setState(() {
      // Update transaction type if detected
      _type = intent.type;

      // Update category if detected
      if (intent.category.isNotEmpty) {
        _categoryController.text = intent.category;
        _category = intent.category;
      }

      // If listening for a specific item, update that item
      if (_listeningItemIndex >= 0 && _listeningItemIndex < _items.length) {
        final currentItem = _items[_listeningItemIndex];
        final updatedItem = currentItem.copyWith(
          itemName: intent.itemName.isNotEmpty
              ? intent.itemName
              : currentItem.itemName,
          pricePerUnit:
              intent.amount > 0 ? intent.amount : currentItem.pricePerUnit,
          amount: intent.amount > 0
              ? intent.amount * currentItem.quantity
              : currentItem.amount,
        );
        _items[_listeningItemIndex] = updatedItem;
        _voiceStatusMessage = 'Item updated: ${intent.itemName}';
      } else {
        // General transaction input - update first item or create new
        if (_items.isNotEmpty) {
          final firstItem = _items[0];
          final updatedItem = firstItem.copyWith(
            itemName: intent.itemName.isNotEmpty
                ? intent.itemName
                : firstItem.itemName,
            pricePerUnit:
                intent.amount > 0 ? intent.amount : firstItem.pricePerUnit,
            amount: intent.amount > 0
                ? intent.amount * firstItem.quantity
                : firstItem.amount,
          );
          _items[0] = updatedItem;
        } else {
          _addItem();
          final newItem = _items[0].copyWith(
            itemName: intent.itemName,
            pricePerUnit: intent.amount,
            amount: intent.amount,
          );
          _items[0] = newItem;
        }
        _voiceStatusMessage =
            'Transaction parsed: ${intent.itemName} - UGX ${intent.amount.toStringAsFixed(0)}';
      }
    });

    // Show confirmation snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_voiceStatusMessage),
          backgroundColor: IOSColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _stopVoiceInput() async {
    await _speechService.stopListening();
    setState(() {
      _isListening = false;
      _listeningItemIndex = -1;
    });
  }

  void _showVoiceError(String message) {
    setState(() {
      _isListening = false;
      _listeningItemIndex = -1;
    });

    // Show error dialog
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Voice Input'),
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

  /// Navigate to transaction review screen with the captured text
  void _showReviewPreview(String transcribedText) {
    final processedText = TranslationService.processText(
      transcribedText,
      context.read<LanguageProvider>().currentLanguage,
    );
    final intent = NLPService.parseTransaction(processedText);

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => const VoiceRecordingScreen(),
      ),
    );
  }

  /// Build a voice input button for items
  Widget _buildVoiceInputButton({int itemIndex = -1, bool isCompact = false}) {
    final isCurrentlyListening =
        _isListening && _listeningItemIndex == itemIndex;

    return GestureDetector(
      onTap: () {
        if (isCurrentlyListening) {
          _stopVoiceInput();
        } else {
          _startVoiceInput(itemIndex: itemIndex);
        }
      },
      child: Container(
        padding: EdgeInsets.all(isCompact ? 6 : 8),
        decoration: BoxDecoration(
          color: isCurrentlyListening
              ? IOSColors.error.withOpacity(0.15)
              : IOSColors.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(IOSBorderRadius.small),
          border: Border.all(
            color: isCurrentlyListening
                ? IOSColors.error
                : IOSColors.primary.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCurrentlyListening
                  ? CupertinoIcons.stop_fill
                  : CupertinoIcons.mic_fill,
              size: isCompact ? 16 : 18,
              color: isCurrentlyListening ? IOSColors.error : IOSColors.primary,
            ),
            if (!isCompact) ...[
              const SizedBox(width: 4),
              Text(
                isCurrentlyListening ? 'Stop' : 'Voice',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isCurrentlyListening
                      ? IOSColors.error
                      : IOSColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _updateItem(int index, TransactionItem item) {
    setState(() {
      _items[index] = item;
    });
  }

  Future<void> _selectDate() async {
    final selected = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (context) => Container(
        height: 300,
        decoration: BoxDecoration(
          color: IOSColors.systemBackground,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(IOSBorderRadius.large),
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.dateAndTime,
                initialDateTime: _createdAt,
                onDateTimeChanged: (DateTime value) {},
              ),
            ),
            CupertinoButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            CupertinoButton(
              onPressed: () => Navigator.pop(context, _createdAt),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
    if (selected != null) {
      setState(() {
        _createdAt = selected;
      });
    }
  }

  Future<void> _saveTransaction() async {
    // Validate at least one item with name and valid amount
    final validItems =
        _items.where((item) => item.itemName.isNotEmpty && item.amount > 0);
    if (validItems.isEmpty) {
      _showErrorDialog('Please add at least one item with name and amount');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final transactionProvider = context.read<TransactionProvider>();

    final transaction = app.Transaction.create(
      type: _type,
      items: validItems.toList(),
      userId: authProvider.userModel?.id ?? '',
      description: _descriptionController.text.trim(),
      category: _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
      customerName: _customerNameController.text.trim().isEmpty
          ? null
          : _customerNameController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    await transactionProvider.addTransaction(transaction);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(
            builder: (_) => const HomeScreen(initialTabIndex: 1)),
      );
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
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

  Color _getTypeColor(app.TransactionType type) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    switch (type) {
      case app.TransactionType.sale:
        return IOSColors.saleColor;
      case app.TransactionType.expense:
        return IOSColors.expenseColor;
      case app.TransactionType.purchase:
        return isDarkMode
            ? IOSDarkColors.purchaseColor
            : IOSColors.purchaseColor;
      case app.TransactionType.cashReceipt:
        return isDarkMode ? IOSDarkColors.primary : IOSColors.primary;
    }
  }

  /// Get transaction types excluding cashReceipt for the type selector
  List<app.TransactionType> get _availableTypes {
    return app.TransactionType.values
        .where((type) => type != app.TransactionType.cashReceipt)
        .toList();
  }

  /// Show receipt options bottom sheet
  void _showReceiptOptions() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Receipt Options'),
        message: const Text('Choose an action for this transaction'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _printReceipt();
            },
            child: const Text('Print Receipt (PDF)'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDestructiveAction: true,
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  /// Print receipt to PDF - saves transaction first, then generates receipt
  Future<void> _printReceipt() async {
    // Validate at least one item with name and valid amount
    final validItems =
        _items.where((item) => item.itemName.isNotEmpty && item.amount > 0);
    if (validItems.isEmpty) {
      _showErrorDialog('Please add at least one item with name and amount');
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final transactionProvider = context.read<TransactionProvider>();

      // Create the transaction
      final transaction = app.Transaction.create(
        type: _type,
        items: validItems.toList(),
        userId: authProvider.userModel?.id ?? '',
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        customerName: _customerNameController.text.trim().isEmpty
            ? null
            : _customerNameController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      // Save the transaction first
      await transactionProvider.addTransaction(transaction);
      debugPrint('Transaction saved successfully: ${transaction.id}');

      // Now print the receipt directly using the printing package
      await ReportService.printReceipt(transaction);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Receipt printed successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        // Navigate to home screen
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
              builder: (_) => const HomeScreen(initialTabIndex: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(_type);

    return Scaffold(
      backgroundColor: IOSColors.secondarySystemBackground,
      appBar: IOSNavigationBar(
        title: 'Add Transaction',
        automaticallyImplyLeading: false,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            Navigator.pushReplacement(
              context,
              CupertinoPageRoute(builder: (_) => const HomeScreen()),
            );
          },
          child: const Icon(
            CupertinoIcons.xmark,
            color: IOSColors.labelPrimary,
          ),
        ),
        actions: [
          CupertinoButton(
            onPressed: _saveTransaction,
            child: const Text(
              'Save',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: IOSColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(IOSSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Transaction Type
            IOSCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Type',
                    style: TextStyle(
                      fontSize: 12,
                      color: IOSColors.labelSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: IOSSpacing.sm),
                  Row(
                    children: _availableTypes.map((type) {
                      final color = _getTypeColor(type);
                      final isSelected = _type == type;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _type = type;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(
                                vertical: IOSSpacing.md),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withOpacity(0.15)
                                  : IOSColors.secondarySystemBackground,
                              borderRadius:
                                  BorderRadius.circular(IOSBorderRadius.medium),
                              border: Border.all(
                                color: isSelected ? color : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  type == app.TransactionType.sale
                                      ? CupertinoIcons.arrow_up
                                      : type == app.TransactionType.expense
                                          ? CupertinoIcons.arrow_down
                                          : CupertinoIcons.cart_fill,
                                  color: isSelected
                                      ? color
                                      : IOSColors.labelTertiary,
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  type.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? color
                                        : IOSColors.labelTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: IOSSpacing.md),

            // Items Section
            IOSCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Items',
                            style: TextStyle(
                              fontSize: 12,
                              color: IOSColors.labelSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: IOSSpacing.sm),
                          // Voice input button for quick transaction entry
                          _buildVoiceInputButton(),
                        ],
                      ),
                      CupertinoButton(
                        onPressed: _addItem,
                        padding: EdgeInsets.zero,
                        child: const Text(
                          '+ Add Item',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: IOSColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: IOSSpacing.sm),

                  // Listening indicator
                  if (_isListening)
                    Container(
                      margin: const EdgeInsets.only(bottom: IOSSpacing.sm),
                      padding: const EdgeInsets.symmetric(
                        horizontal: IOSSpacing.md,
                        vertical: IOSSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: IOSColors.error.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(IOSBorderRadius.small),
                        border:
                            Border.all(color: IOSColors.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.mic_fill,
                            color: IOSColors.error,
                            size: 16,
                          ),
                          const SizedBox(width: IOSSpacing.sm),
                          Expanded(
                            child: Text(
                              _voiceStatusMessage,
                              style: TextStyle(
                                fontSize: 13,
                                color: IOSColors.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _stopVoiceInput,
                            child: Icon(
                              CupertinoIcons.stop_fill,
                              color: IOSColors.error,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Items List
                  if (_items.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(IOSSpacing.lg),
                        child: Text(
                          'No items added yet',
                          style: TextStyle(
                            color: IOSColors.labelTertiary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._items.asMap().entries.map((entry) {
                      return _buildItemWidget(entry.key, entry.value);
                    }),
                ],
              ),
            ),

            const SizedBox(height: IOSSpacing.md),

            // Total Amount
            IOSCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: IOSColors.labelPrimary,
                    ),
                  ),
                  Text(
                    'UGX ${_totalAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: typeColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: IOSSpacing.md),

            // Customer Name
            IOSCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer Name',
                    style: TextStyle(
                      fontSize: 12,
                      color: IOSColors.labelSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: IOSSpacing.sm),
                  TextField(
                    controller: _customerNameController,
                    style: const TextStyle(
                      fontSize: 16,
                      color: IOSColors.labelPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Enter customer name (optional)',
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: IOSSpacing.md),

            // Category
            IOSCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 12,
                      color: IOSColors.labelSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: IOSSpacing.sm),
                  TextField(
                    controller: _categoryController,
                    style: const TextStyle(
                      fontSize: 16,
                      color: IOSColors.labelPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Optional',
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: IOSSpacing.md),

            // Notes
            IOSCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notes',
                    style: TextStyle(
                      fontSize: 12,
                      color: IOSColors.labelSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: IOSSpacing.sm),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    style: const TextStyle(
                      fontSize: 16,
                      color: IOSColors.labelPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Additional notes (optional)',
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: IOSSpacing.md),

            // Date & Time
            IOSCard(
              child: GestureDetector(
                onTap: _selectDate,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date & Time',
                      style: TextStyle(
                        fontSize: 12,
                        color: IOSColors.labelSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: IOSSpacing.sm),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.calendar,
                          color: IOSColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: IOSSpacing.md),
                        Text(
                          '${_createdAt.day}/${_createdAt.month}/${_createdAt.year} at ${_createdAt.hour}:${_createdAt.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: IOSColors.labelPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: IOSSpacing.md),

            // Receipt Button
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showReceiptOptions,
              child: Container(
                padding: const EdgeInsets.all(IOSSpacing.md),
                decoration: BoxDecoration(
                  color: IOSColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
                  border: Border.all(
                    color: IOSColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.doc_text,
                      color: IOSColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: IOSSpacing.sm),
                    const Text(
                      'Receipt',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: IOSColors.primary,
                      ),
                    ),
                    const SizedBox(width: IOSSpacing.xs),
                    Icon(
                      CupertinoIcons.chevron_down,
                      color: IOSColors.primary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: IOSSpacing.xl),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1, // Start at Transactions tab
        onNavigate: (index) {
          // Navigate based on index, but don't allow adding new transaction from this screen
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

  Widget _buildItemWidget(int index, TransactionItem item) {
    final isCurrentlyListening = _isListening && _listeningItemIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: IOSSpacing.md),
      padding: const EdgeInsets.all(IOSSpacing.md),
      decoration: BoxDecoration(
        color: IOSColors.secondarySystemBackground,
        borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
        border: Border.all(
          color: isCurrentlyListening
              ? IOSColors.primary
              : IOSColors.labelQuaternary,
          width: isCurrentlyListening ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row for item name, voice button and delete button
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Item name',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  onChanged: (value) {
                    _updateItem(index, item.copyWith(itemName: value));
                  },
                  controller: TextEditingController(text: item.itemName)
                    ..selection =
                        TextSelection.collapsed(offset: item.itemName.length),
                ),
              ),
              // Inventory selection button
              GestureDetector(
                onTap: () => _showProductPicker(index),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: IOSColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(IOSBorderRadius.small),
                    border: Border.all(
                      color: IOSColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Icon(
                    CupertinoIcons.cube_box,
                    size: 18,
                    color: IOSColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Voice input button for this item
              _buildVoiceInputButton(itemIndex: index, isCompact: true),
              if (_items.length > 1)
                CupertinoButton(
                  onPressed: () => _removeItem(index),
                  padding: EdgeInsets.zero,
                  child: Icon(
                    CupertinoIcons.minus_circle_fill,
                    color: IOSColors.error,
                    size: 24,
                  ),
                ),
            ],
          ),
          const SizedBox(height: IOSSpacing.sm),

          // Quantity, Unit, Price row
          Row(
            children: [
              // Quantity
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Qty',
                      style: TextStyle(
                        fontSize: 11,
                        color: IOSColors.labelSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: IOSColors.systemBackground,
                        borderRadius:
                            BorderRadius.circular(IOSBorderRadius.small),
                        border: Border.all(color: IOSColors.labelQuaternary),
                      ),
                      child: TextField(
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: false),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 14),
                        onChanged: (value) {
                          final qty = int.tryParse(value) ?? 1;
                          _updateItem(
                              index, item.copyWith(quantity: qty.toDouble()));
                        },
                        controller: TextEditingController(
                            text: item.quantity.toStringAsFixed(0))
                          ..selection = TextSelection.collapsed(
                              offset: item.quantity.toStringAsFixed(0).length),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: IOSSpacing.sm),

              // Unit
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Unit',
                      style: TextStyle(
                        fontSize: 11,
                        color: IOSColors.labelSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: IOSColors.systemBackground,
                        borderRadius:
                            BorderRadius.circular(IOSBorderRadius.small),
                        border: Border.all(color: IOSColors.labelQuaternary),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<QuantityUnit>(
                          value: item.unit,
                          isExpanded: true,
                          items: QuantityUnit.values.map((unit) {
                            return DropdownMenuItem(
                              value: unit,
                              child: Text(
                                _getUnitDisplay(unit),
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _updateItem(index, item.copyWith(unit: value));
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: IOSSpacing.sm),

              // Price per unit
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Price (UGX)',
                      style: TextStyle(
                        fontSize: 11,
                        color: IOSColors.labelSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: IOSColors.systemBackground,
                        borderRadius:
                            BorderRadius.circular(IOSBorderRadius.small),
                        border: Border.all(color: IOSColors.labelQuaternary),
                      ),
                      child: TextField(
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: false),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 14),
                        onChanged: (value) {
                          final price = int.tryParse(value) ?? 0;
                          _updateItem(index,
                              item.copyWith(pricePerUnit: price.toDouble()));
                        },
                        controller: TextEditingController(
                            text: item.pricePerUnit.toStringAsFixed(0))
                          ..selection = TextSelection.collapsed(
                              offset:
                                  item.pricePerUnit.toStringAsFixed(0).length),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: IOSSpacing.sm),

          // Amount display
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Amount: UGX ${item.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: IOSColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getUnitDisplay(QuantityUnit unit) {
    switch (unit) {
      case QuantityUnit.pcs:
        return 'pcs';
      case QuantityUnit.kgs:
        return 'kgs';
      case QuantityUnit.grams:
        return 'grams';
      case QuantityUnit.liters:
        return 'liters';
      case QuantityUnit.ml:
        return 'ml';
      case QuantityUnit.dozens:
        return 'dozens';
      case QuantityUnit.boxes:
        return 'boxes';
      case QuantityUnit.bags:
        return 'bags';
      case QuantityUnit.sacks:
        return 'sacks';
      case QuantityUnit.pieces:
        return 'pieces';
    }
  }
}

// Product Picker Sheet Widget
class _ProductPickerSheet extends StatefulWidget {
  final List<Product> products;
  final bool isLoading;
  final Function(Product) onSelect;

  const _ProductPickerSheet({
    required this.products,
    required this.isLoading,
    required this.onSelect,
  });

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  String _searchQuery = '';

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) {
      return widget.products;
    }
    return widget.products
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDarkMode
            ? IOSDarkColors.systemBackground
            : IOSColors.systemBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Gradient header with handle bar
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  IOSColors.primary,
                  IOSColors.primary.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(IOSSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 60),
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.cube_box_fill,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: IOSSpacing.sm),
                          Text(
                            'Select Product',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.all(IOSSpacing.md),
            child: CupertinoSearchTextField(
              placeholder: 'Search products...',
              placeholderStyle: TextStyle(
                color: isDarkMode
                    ? IOSDarkColors.labelTertiary
                    : IOSColors.labelTertiary,
              ),
              style: TextStyle(
                color: isDarkMode
                    ? IOSDarkColors.labelPrimary
                    : IOSColors.labelPrimary,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          // Products list
          Expanded(
            child: widget.isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : _filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.cube_box,
                              size: 56,
                              color: isDarkMode
                                  ? IOSDarkColors.labelTertiary
                                  : IOSColors.labelTertiary,
                            ),
                            const SizedBox(height: IOSSpacing.md),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No products in inventory'
                                  : 'No products found',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkMode
                                    ? IOSDarkColors.labelSecondary
                                    : IOSColors.labelSecondary,
                              ),
                            ),
                            if (_searchQuery.isEmpty) ...[
                              const SizedBox(height: IOSSpacing.sm),
                              Text(
                                'Add products from Inventory first',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDarkMode
                                      ? IOSDarkColors.labelTertiary
                                      : IOSColors.labelTertiary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: IOSSpacing.md),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return _ProductPickerItem(
                            product: product,
                            onTap: () => widget.onSelect(product),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _ProductPickerItem extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductPickerItem({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Determine stock status color
    Color stockColor;
    String stockStatus;
    if (product.stockQuantity <= 0) {
      stockColor = IOSColors.error;
      stockStatus = 'Out of stock';
    } else if (product.stockQuantity <= product.lowStockThreshold) {
      stockColor = const Color(0xFFFF9500); // Orange for low stock
      stockStatus = 'Low stock';
    } else {
      stockColor = const Color(0xFF34C759); // Green for in stock
      stockStatus = 'In stock';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: IOSSpacing.sm),
        decoration: BoxDecoration(
          gradient: isDarkMode
              ? LinearGradient(
                  colors: [
                    IOSDarkColors.secondarySystemBackground,
                    IOSDarkColors.secondarySystemBackground.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.95),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
          child: Container(
            padding: const EdgeInsets.all(IOSSpacing.md),
            child: Row(
              children: [
                // Modern product icon with gradient background
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        IOSColors.primary,
                        IOSColors.primary.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
                    boxShadow: [
                      BoxShadow(
                        color: IOSColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    CupertinoIcons.cube_box_fill,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: IOSSpacing.md),
                // Product info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode
                              ? IOSDarkColors.labelPrimary
                              : IOSColors.labelPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Category chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: IOSColors.secondary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.categoryName.isNotEmpty
                              ? product.categoryName
                              : 'Uncategorized',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: IOSColors.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Stock status badge
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: stockColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            stockStatus,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: stockColor,
                            ),
                          ),
                          if (product.stockQuantity > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              '• ${product.stockQuantity.toStringAsFixed(0)} ${product.unit}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDarkMode
                                    ? IOSDarkColors.labelSecondary
                                    : IOSColors.labelSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Price container
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: IOSSpacing.md,
                    vertical: IOSSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? IOSDarkColors.secondarySystemBackground
                        : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(IOSBorderRadius.small),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'UGX ${product.sellingPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: IOSColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'per ${product.unit}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDarkMode
                              ? IOSDarkColors.labelSecondary
                              : IOSColors.labelSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: IOSSpacing.sm),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 18,
                  color: isDarkMode
                      ? IOSDarkColors.labelTertiary
                      : IOSColors.labelTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:ismart_shop/models/transaction.dart' as app;
import 'package:ismart_shop/models/transaction_item.dart';
import 'package:ismart_shop/models/product.dart';
import 'package:ismart_shop/providers/auth_provider.dart';
import 'package:ismart_shop/providers/transaction_provider.dart';
import 'package:ismart_shop/services/local_database_service.dart';
import 'package:ismart_shop/utils/ios_theme.dart';
import 'package:ismart_shop/widgets/ios_app_bar.dart';
import 'home_screen.dart';

class TransactionEditScreen extends StatefulWidget {
  final app.Transaction transaction;

  const TransactionEditScreen({
    super.key,
    required this.transaction,
  });

  @override
  State<TransactionEditScreen> createState() => _TransactionEditScreenState();
}

class _TransactionEditScreenState extends State<TransactionEditScreen> {
  final int _currentIndex = 0;
  late app.TransactionType _type;
  late List<TransactionItem> _items;
  late DateTime _createdAt;
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
    _type = widget.transaction.type;
    _items = List.from(widget.transaction.items);
    _createdAt = widget.transaction.createdAt;
    _description = widget.transaction.description;
    _category = widget.transaction.category ?? '';
    _customerName = widget.transaction.customerName ?? '';
    _notes = widget.transaction.notes ?? '';

    _descriptionController.text = _description;
    _categoryController.text = _category;
    _customerNameController.text = _customerName;
    _notesController.text = _notes;

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

  @override
  void dispose() {
    _descriptionController.dispose();
    _categoryController.dispose();
    _customerNameController.dispose();
    _notesController.dispose();
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
        decoration: const BoxDecoration(
          color: IOSColors.systemBackground,
          borderRadius: BorderRadius.vertical(
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

    final transactionProvider = context.read<TransactionProvider>();

    final updatedTransaction = widget.transaction.copyWith(
      type: _type,
      items: validItems.toList(),
      totalAmount: _totalAmount,
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
      createdAt: _createdAt,
      updatedAt: DateTime.now(),
    );

    await transactionProvider.updateTransaction(updatedTransaction);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(
            builder: (_) => const HomeScreen(initialTabIndex: 1)),
      );
    }
  }

  Future<void> _deleteTransaction() async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Transaction'),
        content:
            const Text('Are you sure you want to delete this transaction?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, true),
            isDestructiveAction: true,
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final transactionProvider = context.read<TransactionProvider>();
      await transactionProvider.deleteTransaction(widget.transaction.id);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
              builder: (_) => const HomeScreen(initialTabIndex: 1)),
        );
      }
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

  Color _getTypeColor(app.TransactionType type, bool isDarkMode) {
    if (isDarkMode) {
      switch (type) {
        case app.TransactionType.sale:
          return IOSDarkColors.saleColor;
        case app.TransactionType.expense:
          return IOSDarkColors.expenseColor;
        case app.TransactionType.purchase:
          return IOSDarkColors.purchaseColor;
        case app.TransactionType.cashReceipt:
          return IOSDarkColors.primary;
      }
    } else {
      switch (type) {
        case app.TransactionType.sale:
          return IOSColors.saleColor;
        case app.TransactionType.expense:
          return IOSColors.expenseColor;
        case app.TransactionType.purchase:
          return IOSColors.purchaseColor;
        case app.TransactionType.cashReceipt:
          return IOSColors.primary;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final primaryColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;
    final secondarySystemBg = isDarkMode
        ? IOSDarkColors.secondarySystemBackground
        : IOSColors.secondarySystemBackground;
    final labelPrimary =
        isDarkMode ? IOSDarkColors.labelPrimary : IOSColors.labelPrimary;
    final labelSecondary =
        isDarkMode ? IOSDarkColors.labelSecondary : IOSColors.labelSecondary;
    final labelTertiary =
        isDarkMode ? IOSDarkColors.labelTertiary : IOSColors.labelTertiary;
    final labelQuaternary =
        isDarkMode ? IOSDarkColors.labelQuaternary : IOSColors.labelQuaternary;
    final systemBg = isDarkMode
        ? IOSDarkColors.systemBackground
        : IOSColors.systemBackground;
    final errorColor = isDarkMode ? IOSDarkColors.error : IOSColors.error;

    final typeColor = _getTypeColor(_type, isDarkMode);

    return Scaffold(
      backgroundColor: secondarySystemBg,
      appBar: IOSNavigationBar(
        title: 'Edit Transaction',
        automaticallyImplyLeading: true,
        actions: [
          CupertinoButton(
            onPressed: _saveTransaction,
            child: Text(
              'Save',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: primaryColor,
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
                  Text(
                    'Type',
                    style: TextStyle(
                      fontSize: 12,
                      color: labelSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: IOSSpacing.sm),
                  Row(
                    children: app.TransactionType.values.map((type) {
                      final color = _getTypeColor(type, isDarkMode);
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
                                  : secondarySystemBg,
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
                                          : type == app.TransactionType.purchase
                                              ? CupertinoIcons.cart_fill
                                              : CupertinoIcons
                                                  .money_dollar_circle_fill,
                                  color: isSelected ? color : labelTertiary,
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  type.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? color : labelTertiary,
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
                      Text(
                        'Items',
                        style: TextStyle(
                          fontSize: 12,
                          color: labelSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      CupertinoButton(
                        onPressed: _addItem,
                        padding: EdgeInsets.zero,
                        child: Text(
                          '+ Add Item',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: IOSSpacing.sm),

                  // Items List
                  if (_items.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(IOSSpacing.lg),
                        child: Text(
                          'No items added yet',
                          style: TextStyle(
                            color: labelTertiary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._items.asMap().entries.map((entry) {
                      return _buildItemWidget(
                          entry.key, entry.value, isDarkMode);
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
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: labelPrimary,
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
                  Text(
                    'Customer Name',
                    style: TextStyle(
                      fontSize: 12,
                      color: labelSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: IOSSpacing.sm),
                  TextField(
                    controller: _customerNameController,
                    style: TextStyle(
                      fontSize: 16,
                      color: labelPrimary,
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
                  Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 12,
                      color: labelSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: IOSSpacing.sm),
                  TextField(
                    controller: _categoryController,
                    style: TextStyle(
                      fontSize: 16,
                      color: labelPrimary,
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
                  Text(
                    'Notes',
                    style: TextStyle(
                      fontSize: 12,
                      color: labelSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: IOSSpacing.sm),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    style: TextStyle(
                      fontSize: 16,
                      color: labelPrimary,
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
                    Text(
                      'Date & Time',
                      style: TextStyle(
                        fontSize: 12,
                        color: labelSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: IOSSpacing.sm),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.calendar,
                          color: primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: IOSSpacing.md),
                        Text(
                          '${_createdAt.day}/${_createdAt.month}/${_createdAt.year} at ${_createdAt.hour}:${_createdAt.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 16,
                            color: labelPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: IOSSpacing.xl),

            // Delete Button
            SizedBox(
              height: 50,
              child: CupertinoButton(
                onPressed: _deleteTransaction,
                color: errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.trash_fill,
                      size: 18,
                      color: errorColor,
                    ),
                    const SizedBox(width: IOSSpacing.sm),
                    Text(
                      'Delete Transaction',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: errorColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: IOSSpacing.xl),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: systemBg.withOpacity(0.95),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                  0, CupertinoIcons.house, 'Home', primaryColor, labelTertiary),
              _buildNavItem(1, CupertinoIcons.list_bullet, 'Transactions',
                  primaryColor, labelTertiary),
              _buildNavItem(2, CupertinoIcons.chart_bar, 'Reports',
                  primaryColor, labelTertiary),
              _buildNavItem(3, CupertinoIcons.settings, 'Settings',
                  primaryColor, labelTertiary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label,
      Color primaryColor, Color labelTertiary) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        _navigateToScreen(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color:
              isSelected ? primaryColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isSelected ? 24 : 22,
              color: isSelected ? primaryColor : labelTertiary,
            ),
            if (isSelected) const SizedBox(width: 8),
            if (isSelected)
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToScreen(int index) {
    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(builder: (_) => HomeScreen(initialTabIndex: index)),
    );
  }

  Widget _buildItemWidget(int index, TransactionItem item, bool isDarkMode) {
    final secondarySystemBg = isDarkMode
        ? IOSDarkColors.secondarySystemBackground
        : IOSColors.secondarySystemBackground;
    final labelQuaternary =
        isDarkMode ? IOSDarkColors.labelQuaternary : IOSColors.labelQuaternary;
    final labelSecondary =
        isDarkMode ? IOSDarkColors.labelSecondary : IOSColors.labelSecondary;
    final systemBg = isDarkMode
        ? IOSDarkColors.systemBackground
        : IOSColors.systemBackground;
    final primaryColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;
    final errorColor = isDarkMode ? IOSDarkColors.error : IOSColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: IOSSpacing.md),
      padding: const EdgeInsets.all(IOSSpacing.md),
      decoration: BoxDecoration(
        color: secondarySystemBg,
        borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
        border: Border.all(color: labelQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row for item name and delete button
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
                    color: primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(IOSBorderRadius.small),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Icon(
                    CupertinoIcons.cube_box,
                    size: 18,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              CupertinoButton(
                onPressed: () => _removeItem(index),
                padding: EdgeInsets.zero,
                child: Icon(
                  CupertinoIcons.minus_circle_fill,
                  color: errorColor,
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
                    Text(
                      'Qty',
                      style: TextStyle(
                        fontSize: 11,
                        color: labelSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: systemBg,
                        borderRadius:
                            BorderRadius.circular(IOSBorderRadius.small),
                        border: Border.all(color: labelQuaternary),
                      ),
                      child: TextField(
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: false),
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
                    Text(
                      'Unit',
                      style: TextStyle(
                        fontSize: 11,
                        color: labelSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: systemBg,
                        borderRadius:
                            BorderRadius.circular(IOSBorderRadius.small),
                        border: Border.all(color: labelQuaternary),
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
                    Text(
                      'Price (UGX)',
                      style: TextStyle(
                        fontSize: 11,
                        color: labelSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: systemBg,
                        borderRadius:
                            BorderRadius.circular(IOSBorderRadius.small),
                        border: Border.all(color: labelQuaternary),
                      ),
                      child: TextField(
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: false),
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
                  color: primaryColor,
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
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? IOSDarkColors.labelQuaternary
                  : IOSColors.labelQuaternary,
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
                const Text(
                  'Select from Inventory',
                  style: IOSTextStyles.headline,
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: IOSSpacing.md),
            child: CupertinoSearchTextField(
              placeholder: 'Search products...',
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          const SizedBox(height: IOSSpacing.sm),
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
                              size: 48,
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
                                color: isDarkMode
                                    ? IOSDarkColors.labelSecondary
                                    : IOSColors.labelSecondary,
                              ),
                            ),
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: IOSSpacing.sm),
        padding: const EdgeInsets.all(IOSSpacing.md),
        decoration: BoxDecoration(
          color: isDarkMode
              ? IOSDarkColors.secondarySystemBackground
              : IOSColors.secondarySystemBackground,
          borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
          border: Border.all(
            color: isDarkMode
                ? IOSDarkColors.labelQuaternary
                : IOSColors.labelQuaternary,
          ),
        ),
        child: Row(
          children: [
            // Product icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: IOSColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(IOSBorderRadius.small),
              ),
              child: const Icon(
                CupertinoIcons.cube_box_fill,
                color: IOSColors.primary,
                size: 24,
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
                      fontWeight: FontWeight.w600,
                      color: isDarkMode
                          ? IOSDarkColors.labelPrimary
                          : IOSColors.labelPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.categoryName,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode
                          ? IOSDarkColors.labelSecondary
                          : IOSColors.labelSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'UGX ${product.sellingPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: IOSColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Stock: ${product.stockQuantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode
                        ? IOSDarkColors.labelSecondary
                        : IOSColors.labelSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: IOSSpacing.sm),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: isDarkMode
                  ? IOSDarkColors.labelTertiary
                  : IOSColors.labelTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

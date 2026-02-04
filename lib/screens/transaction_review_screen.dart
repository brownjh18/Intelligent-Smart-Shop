import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:ismart_shop/models/transaction.dart';
import 'package:ismart_shop/models/transaction_item.dart';
import 'package:ismart_shop/providers/auth_provider.dart';
import 'package:ismart_shop/providers/transaction_provider.dart';
import 'package:ismart_shop/services/nlp_service.dart';
import 'package:ismart_shop/utils/ios_theme.dart';
import 'package:ismart_shop/widgets/ios_app_bar.dart';
import 'home_screen.dart';

class TransactionReviewScreen extends StatefulWidget {
  final String transcribedText;
  final TransactionIntent transactionIntent;

  const TransactionReviewScreen({
    super.key,
    required this.transcribedText,
    required this.transactionIntent,
  });

  @override
  State<TransactionReviewScreen> createState() =>
      _TransactionReviewScreenState();
}

class _TransactionReviewScreenState extends State<TransactionReviewScreen> {
  late TransactionType _type;
  String _description = '';
  String _category = '';

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _type = widget.transactionIntent.type;
    _description = widget.transcribedText;
    _category = widget.transactionIntent.category;

    _descriptionController.text = _description;
    _categoryController.text = _category;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _saveTransaction() {
    final authProvider = context.read<AuthProvider>();
    final transactionProvider = context.read<TransactionProvider>();

    // Create a default item from the parsed data
    final item = TransactionItem.create(
      itemName: widget.transactionIntent.itemName,
      quantity: 1,
      unit: QuantityUnit.pcs,
      pricePerUnit: widget.transactionIntent.amount,
    );

    final transaction = Transaction.create(
      type: _type,
      items: [item],
      userId: authProvider.userModel?.id ?? '',
      description: _description,
      category: _category.isNotEmpty ? _category : null,
    );

    // Save in background - navigate back immediately
    transactionProvider.addTransaction(transaction);

    // Navigate back to home immediately
    Navigator.pushAndRemoveUntil(
      context,
      CupertinoPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  void _showEditDialog() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 400,
        decoration: BoxDecoration(
          color: IOSColors.systemBackground,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(IOSBorderRadius.large),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(IOSSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: IOSColors.labelQuaternary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: IOSSpacing.lg),
              const Text(
                'Edit Transaction',
                style: IOSTextStyles.title2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: IOSSpacing.lg),
              // Transaction Type
              Container(
                padding: const EdgeInsets.symmetric(horizontal: IOSSpacing.md),
                decoration: BoxDecoration(
                  color: IOSColors.secondarySystemBackground,
                  borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
                ),
                child: DropdownButtonFormField<TransactionType>(
                  value: _type,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: InputBorder.none,
                  ),
                  items: TransactionType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _type = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: IOSSpacing.md),
              // Category
              IOSTextField(
                controller: _categoryController,
                placeholder: 'Category',
                onTap: () {},
              ),
              const SizedBox(height: IOSSpacing.lg),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      onPressed: () => Navigator.pop(ctx),
                      color: IOSColors.secondarySystemBackground,
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: IOSColors.labelPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: IOSSpacing.md),
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: () {
                        _category = _categoryController.text;
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

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      CupertinoPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    Color typeColor;
    String typeLabel;

    switch (_type) {
      case TransactionType.sale:
        typeColor = IOSColors.saleColor;
        typeLabel = 'SALE';
        break;
      case TransactionType.expense:
        typeColor = IOSColors.expenseColor;
        typeLabel = 'EXPENSE';
        break;
      case TransactionType.purchase:
        typeColor = IOSColors.purchaseColor;
        typeLabel = 'PURCHASE';
        break;
    }

    final amount = widget.transactionIntent.amount;

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        backgroundColor: IOSColors.secondarySystemBackground,
        appBar: IOSLargeTitleNavigationBar(
          title: 'Review Transaction',
          onBackPressed: _navigateToHome,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(IOSSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Original text
              IOSCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          CupertinoIcons.recordingtape,
                          color: IOSColors.primary,
                          size: 18,
                        ),
                        SizedBox(width: IOSSpacing.sm),
                        Text(
                          'Original Input:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: IOSColors.labelSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: IOSSpacing.sm),
                    Text(
                      '"${widget.transcribedText}"',
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: IOSColors.labelPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: IOSSpacing.md),
              // Parsed details
              IOSCard(
                child: Column(
                  children: [
                    // Transaction type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: IOSSpacing.lg,
                        vertical: IOSSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor,
                        borderRadius:
                            BorderRadius.circular(IOSBorderRadius.medium),
                        boxShadow: [
                          BoxShadow(
                            color: typeColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        typeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: IOSSpacing.xl),
                    // Amount
                    Column(
                      children: [
                        const Text(
                          'Amount',
                          style: TextStyle(
                            fontSize: 14,
                            color: IOSColors.labelSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: IOSSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: IOSSpacing.xl,
                            vertical: IOSSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(IOSBorderRadius.medium),
                          ),
                          child: Text(
                            'UGX ${amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: typeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: IOSSpacing.xl),
                    const Divider(height: 1),
                    const SizedBox(height: IOSSpacing.lg),
                    // Item name
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: IOSColors.primary.withOpacity(0.15),
                            borderRadius:
                                BorderRadius.circular(IOSBorderRadius.medium),
                          ),
                          child: Icon(
                            CupertinoIcons.bag_fill,
                            color: IOSColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: IOSSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Item',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: IOSColors.labelSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                widget.transactionIntent.itemName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: IOSColors.labelPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: IOSSpacing.md),
                    // Category
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: IOSColors.primary.withOpacity(0.15),
                            borderRadius:
                                BorderRadius.circular(IOSBorderRadius.medium),
                          ),
                          child: Icon(
                            CupertinoIcons.tag_fill,
                            color: IOSColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: IOSSpacing.md),
                        Expanded(
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
                              Text(
                                _category.isEmpty ? 'Not specified' : _category,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: IOSColors.labelPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: IOSSpacing.md),
              // Edit button
              SizedBox(
                height: 50,
                child: CupertinoButton(
                  onPressed: _showEditDialog,
                  color: IOSColors.secondarySystemBackground,
                  borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        CupertinoIcons.pencil,
                        size: 18,
                        color: IOSColors.labelPrimary,
                      ),
                      SizedBox(width: IOSSpacing.sm),
                      Text(
                        'Edit Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: IOSColors.labelPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: IOSSpacing.md),
              // Save button
              SizedBox(
                height: 56,
                child: CupertinoButton.filled(
                  onPressed: _saveTransaction,
                  borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        CupertinoIcons.checkmark_circle_fill,
                        size: 20,
                      ),
                      SizedBox(width: IOSSpacing.sm),
                      Text(
                        'Save Transaction',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: IOSSpacing.lg),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          height: 80,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: IOSColors.systemBackground.withOpacity(0.95),
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
                _buildNavItem(0, CupertinoIcons.house, 'Home'),
                _buildNavItem(1, CupertinoIcons.list_bullet, 'Transactions'),
                _buildNavItem(2, CupertinoIcons.chart_bar, 'Reports'),
                _buildNavItem(3, CupertinoIcons.settings, 'Settings'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        _navigateToHome();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: index == 0
              ? IOSColors.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: index == 0 ? 24 : 22,
              color: index == 0 ? IOSColors.primary : IOSColors.labelTertiary,
            ),
            if (index == 0) const SizedBox(width: 8),
            if (index == 0)
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: IOSColors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

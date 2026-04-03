import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:ismart_shop/models/receipt.dart';
import 'package:ismart_shop/providers/auth_provider.dart';
import 'package:ismart_shop/utils/ios_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ismart_shop/models/transaction.dart' as app;
import 'package:ismart_shop/models/transaction_item.dart';
import 'package:ismart_shop/widgets/ios_app_bar.dart';
import 'package:ismart_shop/widgets/app_sidebar.dart';
import 'package:ismart_shop/widgets/app_bottom_nav.dart';
import 'package:ismart_shop/screens/expenses_screen.dart';
import 'package:ismart_shop/screens/customers_screen.dart';
import 'package:ismart_shop/screens/suppliers_screen.dart';
import 'package:ismart_shop/screens/categories_screen.dart';
import 'package:ismart_shop/services/report_service.dart';

class ReceiptsScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const ReceiptsScreen({super.key, this.onNavigate});

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  String _searchQuery = '';
  bool _isLoading = true;
  List<Receipt> _receipts = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      String? userId = authProvider.userModel?.id;

      debugPrint(
          'Loading receipts - userId: $userId, isAuthenticated: ${authProvider.isAuthenticated}');

      if (userId == null || userId.isEmpty) {
        setState(() {
          _receipts = [];
          _isLoading = false;
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      debugPrint('Loaded ${snapshot.docs.length} receipts');

      setState(() {
        _receipts =
            snapshot.docs.map((doc) => Receipt.fromFirestore(doc)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading receipts: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading receipts: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Receipt> get _filteredReceipts {
    return _receipts.where((receipt) {
      return _searchQuery.isEmpty ||
          receipt.receiptNumber
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          (receipt.customerName
                  ?.toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ??
              false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode
        ? IOSDarkColors.systemBackground
        : IOSColors.systemBackground;
    final primaryColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDarkMode
          ? IOSDarkColors.secondarySystemBackground
          : IOSColors.secondarySystemBackground,
      drawer: AppSidebar(
        currentIndex: -4,
        onNavigate: (index) {
          if (index >= 0 && index <= 4) {
            widget.onNavigate?.call(index);
          } else if (index == -1) {
            Navigator.push(context,
                CupertinoPageRoute(builder: (_) => const CustomersScreen()));
          } else if (index == -2) {
            Navigator.push(context,
                CupertinoPageRoute(builder: (_) => const SuppliersScreen()));
          } else if (index == -3) {
            Navigator.push(context,
                CupertinoPageRoute(builder: (_) => const CategoriesScreen()));
          } else if (index == -4) {
            Navigator.push(context,
                CupertinoPageRoute(builder: (_) => const ReceiptsScreen()));
          } else if (index == -5) {
            Navigator.push(context,
                CupertinoPageRoute(builder: (_) => const ExpensesScreen()));
          }
        },
      ),
      appBar: IOSNavigationBar(
        title: 'Receipts',
        automaticallyImplyLeading: false,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          child: Icon(
            CupertinoIcons.line_horizontal_3,
            color: isDarkMode ? IOSDarkColors.primary : IOSColors.primary,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: isDarkMode
                ? IOSDarkColors.systemBackground
                : IOSColors.systemBackground,
            padding: const EdgeInsets.all(IOSSpacing.md),
            child: CupertinoSearchTextField(
              placeholder: 'Search receipts...',
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          // Receipt list
          Expanded(
            child: _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : _filteredReceipts.isEmpty
                    ? IOSEmptyState(
                        icon: CupertinoIcons.doc_text,
                        title: 'No Receipts',
                        subtitle: _searchQuery.isEmpty
                            ? 'Your receipts will appear here'
                            : 'Try a different search term',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(IOSSpacing.md),
                        itemCount: _filteredReceipts.length,
                        itemBuilder: (context, index) {
                          final receipt = _filteredReceipts[index];
                          return _ReceiptCard(
                            receipt: receipt,
                            onTap: () => _showReceiptDetails(context, receipt),
                            onPrint: () => _printReceiptFromList(receipt),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onNavigate: (index) {
          Navigator.pop(context);
          if (index >= 0 && index <= 4) {
            widget.onNavigate?.call(index);
          } else if (index == -1) {
            Navigator.push(context,
                CupertinoPageRoute(builder: (_) => const CustomersScreen()));
          } else if (index == -2) {
            Navigator.push(context,
                CupertinoPageRoute(builder: (_) => const SuppliersScreen()));
          } else if (index == -3) {
            Navigator.push(context,
                CupertinoPageRoute(builder: (_) => const CategoriesScreen()));
          } else if (index == -4) {
            Navigator.push(context,
                CupertinoPageRoute(builder: (_) => const ReceiptsScreen()));
          } else if (index == -5) {
            Navigator.push(context,
                CupertinoPageRoute(builder: (_) => const ExpensesScreen()));
          }
        },
      ),
    );
  }

  void _showReceiptDetails(BuildContext context, Receipt receipt) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _ReceiptDetailsSheet(
        receipt: receipt,
        onPrint: () => _printReceiptFromList(receipt),
      ),
    );
  }

  Future<void> _printReceiptFromList(Receipt receipt) async {
    try {
      final authProvider = context.read<AuthProvider>();

      // Convert ReceiptItem to TransactionItem
      final items = receipt.items.map((item) {
        // Convert unit string to QuantityUnit
        QuantityUnit unit;
        final unitLower = item.unit.toLowerCase();
        if (unitLower.startsWith('pc') || unitLower.isEmpty) {
          unit = QuantityUnit.pcs;
        } else if (unitLower.startsWith('kg')) {
          unit = QuantityUnit.kgs;
        } else if (unitLower.startsWith('gram') || unitLower == 'g') {
          unit = QuantityUnit.grams;
        } else if (unitLower == 'l' || unitLower.startsWith('liter')) {
          unit = QuantityUnit.liters;
        } else if (unitLower == 'ml' || unitLower.startsWith('milliliter')) {
          unit = QuantityUnit.ml;
        } else if (unitLower.startsWith('dozen')) {
          unit = QuantityUnit.dozens;
        } else if (unitLower.startsWith('box')) {
          unit = QuantityUnit.boxes;
        } else if (unitLower.startsWith('bag')) {
          unit = QuantityUnit.bags;
        } else if (unitLower.startsWith('sack')) {
          unit = QuantityUnit.sacks;
        } else if (unitLower.startsWith('piece')) {
          unit = QuantityUnit.pieces;
        } else {
          unit = QuantityUnit.pcs;
        }

        return TransactionItem(
          id: item.id,
          itemName: item.itemName,
          quantity: item.quantity,
          unit: unit,
          pricePerUnit: item.pricePerUnit,
          amount: item.amount,
        );
      }).toList();

      // Create a transaction object using Transaction.create
      final transaction = app.Transaction.create(
        type: receipt.transactionType,
        items: items,
        userId: authProvider.userModel?.id ?? '',
        description: '',
      );

      // Print receipt directly using the printing package
      await ReportService.printReceipt(transaction,
          receiptNumber: receipt.receiptNumber);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Receipt printed successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error printing receipt: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _ReceiptCard extends StatelessWidget {
  final Receipt receipt;
  final VoidCallback onTap;
  final VoidCallback onPrint;

  const _ReceiptCard(
      {required this.receipt, required this.onTap, required this.onPrint});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final saleColor =
        isDarkMode ? IOSDarkColors.saleColor : IOSColors.saleColor;
    final expenseColor =
        isDarkMode ? IOSDarkColors.expenseColor : IOSColors.expenseColor;
    final purchaseColor =
        isDarkMode ? IOSDarkColors.purchaseColor : IOSColors.purchaseColor;

    Color typeColor;
    switch (receipt.transactionType) {
      case app.TransactionType.sale:
        typeColor = saleColor;
        break;
      case app.TransactionType.expense:
        typeColor = expenseColor;
        break;
      case app.TransactionType.purchase:
        typeColor = purchaseColor;
        break;
      case app.TransactionType.cashReceipt:
        typeColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: IOSSpacing.sm),
        padding: const EdgeInsets.all(IOSSpacing.md),
        decoration: BoxDecoration(
          color: isDarkMode
              ? IOSDarkColors.cardBackground
              : IOSColors.systemBackground,
          borderRadius: BorderRadius.circular(IOSBorderRadius.large),
          border: Border.all(
            color: (isDarkMode
                    ? IOSDarkColors.labelQuaternary
                    : IOSColors.labelQuaternary)
                .withOpacity(0.3),
          ),
          boxShadow: isDarkMode
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
              ),
              child: Icon(
                CupertinoIcons.doc_text_fill,
                color: typeColor,
                size: 24,
              ),
            ),
            const SizedBox(width: IOSSpacing.md),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Receipt #${receipt.receiptNumber}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isDarkMode
                          ? IOSDarkColors.labelPrimary
                          : IOSColors.labelPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    receipt.transactionTypeDisplay,
                    style: TextStyle(
                      fontSize: 13,
                      color: typeColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Total and date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  receipt.formattedTotal,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: typeColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  receipt.formattedDate,
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
            // Print button directly on the card
            GestureDetector(
              onTap: onPrint,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(IOSBorderRadius.small),
                  border: Border.all(
                    color: typeColor.withOpacity(0.3),
                  ),
                ),
                child: Icon(
                  CupertinoIcons.printer,
                  color: typeColor,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptDetailsSheet extends StatelessWidget {
  final Receipt receipt;
  final VoidCallback? onPrint;

  const _ReceiptDetailsSheet({required this.receipt, this.onPrint});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final saleColor =
        isDarkMode ? IOSDarkColors.saleColor : IOSColors.saleColor;
    final expenseColor =
        isDarkMode ? IOSDarkColors.expenseColor : IOSColors.expenseColor;
    final purchaseColor =
        isDarkMode ? IOSDarkColors.purchaseColor : IOSColors.purchaseColor;
    final labelPrimary =
        isDarkMode ? IOSDarkColors.labelPrimary : IOSColors.labelPrimary;
    final labelSecondary =
        isDarkMode ? IOSDarkColors.labelSecondary : IOSColors.labelSecondary;
    final cardBg =
        isDarkMode ? IOSDarkColors.cardBackground : IOSColors.systemBackground;

    Color typeColor;
    switch (receipt.transactionType) {
      case app.TransactionType.sale:
        typeColor = saleColor;
        break;
      case app.TransactionType.expense:
        typeColor = expenseColor;
        break;
      case app.TransactionType.purchase:
        typeColor = purchaseColor;
        break;
      case app.TransactionType.cashReceipt:
        typeColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;
        break;
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: isDarkMode
            ? IOSDarkColors.systemBackground
            : IOSColors.systemBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Modern handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? IOSDarkColors.labelQuaternary
                  : IOSColors.labelQuaternary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 60),
                Expanded(
                  child: Text(
                    'Receipt #${receipt.receiptNumber}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: labelPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    Navigator.pop(context);
                    if (onPrint != null) {
                      onPrint!();
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.printer,
                        color: typeColor,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Print',
                        style: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Type badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: typeColor.withOpacity(0.3)),
              ),
              child: Text(
                receipt.transactionTypeDisplay,
                style: TextStyle(
                  color: typeColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Receipt content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Items Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDarkMode
                          ? IOSDarkColors.labelQuaternary.withOpacity(0.2)
                          : IOSColors.labelQuaternary.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.cube_box_fill,
                            size: 18,
                            color: labelSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text('Items',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: labelPrimary)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...receipt.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.quantityDisplay} × ${item.formattedPrice}',
                                    style: TextStyle(
                                        fontSize: 14, color: labelSecondary),
                                  ),
                                ),
                                Text(item.formattedAmount,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: labelPrimary)),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Totals Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDarkMode
                          ? IOSDarkColors.labelQuaternary.withOpacity(0.2)
                          : IOSColors.labelQuaternary.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildTotalRow(
                          'Subtotal',
                          'UGX ${receipt.subtotal.toStringAsFixed(0)}',
                          isDarkMode,
                          labelPrimary,
                          labelSecondary,
                          isTotal: false),
                      if (receipt.discount > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          height: 1,
                          color: isDarkMode
                              ? IOSDarkColors.labelQuaternary.withOpacity(0.2)
                              : IOSColors.labelQuaternary.withOpacity(0.2),
                        ),
                        const SizedBox(height: 12),
                        _buildTotalRow(
                            'Discount',
                            '-UGX ${receipt.discount.toStringAsFixed(0)}',
                            isDarkMode,
                            labelPrimary,
                            labelSecondary,
                            isTotal: false),
                      ],
                      if (receipt.tax > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          height: 1,
                          color: isDarkMode
                              ? IOSDarkColors.labelQuaternary.withOpacity(0.2)
                              : IOSColors.labelQuaternary.withOpacity(0.2),
                        ),
                        const SizedBox(height: 12),
                        _buildTotalRow(
                            'Tax',
                            'UGX ${receipt.tax.toStringAsFixed(0)}',
                            isDarkMode,
                            labelPrimary,
                            labelSecondary,
                            isTotal: false),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        height: 1,
                        color: isDarkMode
                            ? IOSDarkColors.labelQuaternary.withOpacity(0.2)
                            : IOSColors.labelQuaternary.withOpacity(0.2),
                      ),
                      const SizedBox(height: 12),
                      _buildTotalRow('Total', receipt.formattedTotal,
                          isDarkMode, labelPrimary, labelSecondary,
                          isTotal: true, totalColor: typeColor),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Details
                if (receipt.customerName != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDarkMode
                            ? IOSDarkColors.labelQuaternary.withOpacity(0.2)
                            : IOSColors.labelQuaternary.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.person_fill,
                              size: 18,
                              color: labelSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text('Customer',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: labelPrimary)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(receipt.customerName!,
                            style:
                                TextStyle(fontSize: 14, color: labelSecondary)),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, bool isDarkMode,
      Color labelPrimary, Color labelSecondary,
      {bool isTotal = false, Color? totalColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            fontSize: isTotal ? 17 : 15,
            color: isTotal ? labelPrimary : labelSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            fontSize: isTotal ? 20 : 15,
            color: totalColor ??
                (isDarkMode ? IOSDarkColors.primary : IOSColors.primary),
          ),
        ),
      ],
    );
  }
}

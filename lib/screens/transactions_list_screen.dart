import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:ismart_shop/models/transaction.dart' as app;
import 'package:ismart_shop/providers/transaction_provider.dart';
import 'package:ismart_shop/services/report_service.dart';
import 'package:ismart_shop/utils/ios_theme.dart';
import 'package:ismart_shop/widgets/ios_app_bar.dart';
import 'transaction_edit_screen.dart';

class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  String _filterType = 'all';
  DateTime? _selectedDate;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
    });
    // Add scroll listener for infinite loading
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load more when user scrolls near the bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<TransactionProvider>();
      if (!provider.isLoadingMore && provider.hasMore) {
        provider.loadMoreTransactions();
      }
    }
  }

  // Date picker getter
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
                mode: CupertinoDatePickerMode.date,
                initialDateTime: DateTime.now(),
                onDateTimeChanged: (DateTime value) {},
              ),
            ),
            CupertinoButton(
              onPressed: () {
                Navigator.pop(context, null);
              },
              child: const Text('Cancel'),
            ),
            CupertinoButton(
              onPressed: () {
                Navigator.pop(context, DateTime.now());
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
    if (selected != null) {
      setState(() {
        _selectedDate = selected;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    if (dateTime.day == now.day &&
        dateTime.month == now.month &&
        dateTime.year == now.year) {
      return 'Today, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
    return '${dateTime.day}/${dateTime.month}, ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    List<app.Transaction> filteredTransactions =
        transactionProvider.transactions.cast<app.Transaction>();

    // Filter by type
    if (_filterType != 'all') {
      filteredTransactions = filteredTransactions.where((t) {
        return t.type.name == _filterType;
      }).toList();
    }

    // Filter by date
    if (_selectedDate != null) {
      filteredTransactions = filteredTransactions.where((t) {
        return t.createdAt.day == _selectedDate!.day &&
            t.createdAt.month == _selectedDate!.month &&
            t.createdAt.year == _selectedDate!.year;
      }).toList();
    }

    // Group transactions by date
    Map<String, List<app.Transaction>> groupedTransactions = {};
    for (var transaction in filteredTransactions) {
      String dateKey = _getDateKey(transaction.createdAt);
      if (!groupedTransactions.containsKey(dateKey)) {
        groupedTransactions[dateKey] = [];
      }
      groupedTransactions[dateKey]!.add(transaction);
    }

    return Scaffold(
      backgroundColor: isDarkMode
          ? IOSDarkColors.secondarySystemBackground
          : IOSColors.secondarySystemBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Section
          Container(
            color: isDarkMode
                ? IOSDarkColors.systemBackground
                : IOSColors.systemBackground,
            padding: const EdgeInsets.symmetric(
              horizontal: IOSSpacing.md,
              vertical: IOSSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: IOSSpacing.md),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      IOSFilterChip(
                        label: 'All',
                        isSelected: _filterType == 'all',
                        onTap: () {
                          setState(() {
                            _filterType = 'all';
                          });
                        },
                      ),
                      const SizedBox(width: IOSSpacing.xs),
                      IOSFilterChip(
                        label: 'Sales',
                        isSelected: _filterType == 'sale',
                        onTap: () {
                          setState(() {
                            _filterType =
                                _filterType == 'sale' ? 'all' : 'sale';
                          });
                        },
                      ),
                      const SizedBox(width: IOSSpacing.xs),
                      IOSFilterChip(
                        label: 'Expenses',
                        isSelected: _filterType == 'expense',
                        onTap: () {
                          setState(() {
                            _filterType =
                                _filterType == 'expense' ? 'all' : 'expense';
                          });
                        },
                      ),
                      const SizedBox(width: IOSSpacing.xs),
                      IOSFilterChip(
                        label: 'Purchases',
                        isSelected: _filterType == 'purchase',
                        onTap: () {
                          setState(() {
                            _filterType =
                                _filterType == 'purchase' ? 'all' : 'purchase';
                          });
                        },
                      ),
                      const SizedBox(width: IOSSpacing.xs),
                      CupertinoButton(
                        onPressed: () async {
                          await _selectDate();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: IOSSpacing.md,
                            vertical: IOSSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedDate != null
                                ? (isDarkMode
                                        ? IOSDarkColors.primary
                                        : IOSColors.primary)
                                    .withValues(alpha: 0.1)
                                : isDarkMode
                                    ? IOSDarkColors.secondarySystemBackground
                                    : IOSColors.secondarySystemBackground,
                            borderRadius:
                                BorderRadius.circular(IOSBorderRadius.circular),
                            border: Border.all(
                              color: _selectedDate != null
                                  ? (isDarkMode
                                      ? IOSDarkColors.primary
                                      : IOSColors.primary)
                                  : (isDarkMode
                                      ? IOSDarkColors.labelQuaternary
                                      : IOSColors.labelQuaternary),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.calendar,
                                size: 14,
                                color: _selectedDate != null
                                    ? (isDarkMode
                                        ? IOSDarkColors.primary
                                        : IOSColors.primary)
                                    : (isDarkMode
                                        ? IOSDarkColors.labelSecondary
                                        : IOSColors.labelSecondary),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _selectedDate != null
                                    ? '${_selectedDate!.day}/${_selectedDate!.month}'
                                    : 'Date',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: _selectedDate != null
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: _selectedDate != null
                                      ? (isDarkMode
                                          ? IOSDarkColors.primary
                                          : IOSColors.primary)
                                      : (isDarkMode
                                          ? IOSDarkColors.labelSecondary
                                          : IOSColors.labelSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Selected date filter indicator
                if (_selectedDate != null) ...[
                  const SizedBox(height: IOSSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: IOSSpacing.md,
                          vertical: IOSSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: (isDarkMode
                                  ? IOSDarkColors.primary
                                  : IOSColors.primary)
                              .withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(IOSBorderRadius.small),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.calendar,
                              color: isDarkMode
                                  ? IOSDarkColors.primary
                                  : IOSColors.primary,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Filtered: ${_formatDate(_selectedDate!)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: isDarkMode
                                    ? IOSDarkColors.primary
                                    : IOSColors.primary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CupertinoButton(
                        onPressed: () {
                          setState(() {
                            _selectedDate = null;
                          });
                        },
                        child: Text(
                          'Clear',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode
                                ? IOSDarkColors.error
                                : IOSColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          // Transactions List
          Expanded(
            child: transactionProvider.isLoading
                ? const IOSLoadingIndicator()
                : groupedTransactions.isEmpty
                    ? const IOSEmptyState(
                        icon: CupertinoIcons.doc_text,
                        title: 'No Transactions Found',
                        subtitle: 'Start recording your sales and expenses',
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(IOSSpacing.md),
                        itemCount: groupedTransactions.length +
                            (transactionProvider.hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Show loading indicator at the bottom when loading more
                          if (index == groupedTransactions.length) {
                            return const Padding(
                              padding: EdgeInsets.all(IOSSpacing.md),
                              child: Center(
                                child: CupertinoActivityIndicator(),
                              ),
                            );
                          }
                          String dateKey =
                              groupedTransactions.keys.elementAt(index);
                          List<app.Transaction> transactions =
                              groupedTransactions[dateKey]!;
                          return _buildSection(dateKey, transactions);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.day == yesterday.day &&
        date.month == yesterday.month &&
        date.year == yesterday.year) {
      return 'Yesterday';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildSection(String dateKey, List<app.Transaction> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.only(
            bottom: IOSSpacing.sm,
            left: IOSSpacing.xs,
          ),
          child: Text(
            dateKey,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: IOSColors.labelSecondary,
            ),
          ),
        ),
        // Transactions in this section
        ...transactions.map((transaction) {
          return Padding(
            padding: const EdgeInsets.only(bottom: IOSSpacing.xs),
            child: GestureDetector(
              onLongPress: () => _showTransactionOptions(context, transaction),
              child: IOSTransactionItem(
                title: transaction.itemName,
                amount: 'UGX ${transaction.amount.toStringAsFixed(0)}',
                time: _formatDateTime(transaction.createdAt),
                color: _getTransactionColor(transaction.type),
                icon: _getTransactionIcon(transaction.type),
                category: transaction.category,
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) =>
                          TransactionEditScreen(transaction: transaction),
                    ),
                  );
                },
              ),
            ),
          );
        }),
        const SizedBox(height: IOSSpacing.sm),
      ],
    );
  }

  Color _getTransactionColor(app.TransactionType type) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    switch (type) {
      case app.TransactionType.sale:
        return isDarkMode ? IOSDarkColors.saleColor : IOSColors.saleColor;
      case app.TransactionType.expense:
        return isDarkMode ? IOSDarkColors.expenseColor : IOSColors.expenseColor;
      case app.TransactionType.purchase:
        return isDarkMode
            ? IOSDarkColors.purchaseColor
            : IOSColors.purchaseColor;
      case app.TransactionType.cashReceipt:
        return isDarkMode ? IOSDarkColors.primary : IOSColors.primary;
    }
  }

  IconData _getTransactionIcon(app.TransactionType type) {
    switch (type) {
      case app.TransactionType.sale:
        return CupertinoIcons.arrow_up;
      case app.TransactionType.expense:
        return CupertinoIcons.arrow_down;
      case app.TransactionType.purchase:
        return CupertinoIcons.cart_fill;
      case app.TransactionType.cashReceipt:
        return CupertinoIcons.money_dollar_circle_fill;
    }
  }

  void _showTransactionOptions(
      BuildContext context, app.Transaction transaction) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(transaction.itemName),
        message: Text('UGX ${transaction.amount.toStringAsFixed(0)}'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Use direct printing for better user experience
                await ReportService.printReceipt(transaction);
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
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error printing receipt: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Print Receipt'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) =>
                      TransactionEditScreen(transaction: transaction),
                ),
              );
            },
            child: const Text('Edit Transaction'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

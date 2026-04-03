import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:ismart_shop/models/transaction.dart' as app;
import 'package:ismart_shop/providers/transaction_provider.dart';
import 'package:ismart_shop/utils/ios_theme.dart';
import 'package:ismart_shop/widgets/app_sidebar.dart';
import 'package:ismart_shop/widgets/app_bottom_nav.dart';
import 'package:ismart_shop/screens/customers_screen.dart';
import 'package:ismart_shop/screens/suppliers_screen.dart';
import 'package:ismart_shop/screens/categories_screen.dart';
import 'package:ismart_shop/screens/receipts_screen.dart';

class ExpensesScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const ExpensesScreen({super.key, this.onNavigate});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final expenseColor =
        isDarkMode ? IOSDarkColors.expenseColor : IOSColors.expenseColor;

    final expenses = transactionProvider.transactions
        .where((t) => t.type == app.TransactionType.expense)
        .toList();

    final totalExpenses = transactionProvider.todayExpenses;
    final weeklyExpenses = transactionProvider
        .getWeeklyTransactions()
        .where((t) => t.type == app.TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.totalAmount);
    final monthlyExpenses = transactionProvider
        .getMonthlyTransactions()
        .where((t) => t.type == app.TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.totalAmount);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDarkMode
          ? IOSDarkColors.secondarySystemBackground
          : IOSColors.secondarySystemBackground,
      drawer: AppSidebar(
        currentIndex: -5,
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
      body: CustomScrollView(
        slivers: [
          // Navigation bar with hamburger menu
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Expenses'),
            backgroundColor: isDarkMode
                ? IOSDarkColors.systemBackground
                : IOSColors.systemBackground,
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              child: Icon(
                CupertinoIcons.bars,
                color: isDarkMode
                    ? IOSDarkColors.labelPrimary
                    : IOSColors.labelPrimary,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: isDarkMode
                  ? IOSDarkColors.systemBackground
                  : IOSColors.systemBackground,
              padding: const EdgeInsets.all(IOSSpacing.md),
              child: Column(
                children: [
                  // Today's expenses
                  IOSStatCard(
                    title: "Today's Expenses",
                    value: 'UGX ${totalExpenses.toStringAsFixed(0)}',
                    color: expenseColor,
                    icon: CupertinoIcons.arrow_down_circle_fill,
                  ),
                  const SizedBox(height: IOSSpacing.sm),
                  // Weekly and Monthly
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStatCard(
                          title: 'This Week',
                          value: 'UGX ${weeklyExpenses.toStringAsFixed(0)}',
                          color: expenseColor,
                        ),
                      ),
                      const SizedBox(width: IOSSpacing.sm),
                      Expanded(
                        child: _MiniStatCard(
                          title: 'This Month',
                          value: 'UGX ${monthlyExpenses.toStringAsFixed(0)}',
                          color: expenseColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Expense list header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(IOSSpacing.md),
              child: Text(
                'Recent Expenses',
                style: IOSTextStyles.title2.copyWith(
                  color: isDarkMode
                      ? IOSDarkColors.labelPrimary
                      : IOSColors.labelPrimary,
                ),
              ),
            ),
          ),
          // Expense list
          if (transactionProvider.isLoading)
            const SliverFillRemaining(
              child: Center(child: CupertinoActivityIndicator()),
            )
          else if (expenses.isEmpty)
            const SliverFillRemaining(
              child: IOSEmptyState(
                icon: CupertinoIcons.money_dollar_circle,
                title: 'No Expenses Yet',
                subtitle: 'Your expenses will appear here',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: IOSSpacing.md),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final expense = expenses[index];
                    return _ExpenseCard(
                      title: expense.description.isNotEmpty
                          ? expense.description
                          : expense.itemName,
                      amount: expense.totalAmount,
                      date: expense.createdAt,
                      category: expense.category,
                      onTap: () => _showExpenseDetails(context, expense),
                    );
                  },
                  childCount: expenses.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: IOSSpacing.xxl),
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

  void _showExpenseDetails(BuildContext context, app.Transaction expense) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final expenseColor =
        isDarkMode ? IOSDarkColors.expenseColor : IOSColors.expenseColor;
    final labelPrimary =
        isDarkMode ? IOSDarkColors.labelPrimary : IOSColors.labelPrimary;
    final labelSecondary =
        isDarkMode ? IOSDarkColors.labelSecondary : IOSColors.labelSecondary;
    final cardBg =
        isDarkMode ? IOSDarkColors.cardBackground : IOSColors.systemBackground;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.55,
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
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDarkMode
                      ? [
                          expenseColor.withOpacity(0.15),
                          IOSDarkColors.systemBackground
                        ]
                      : [
                          expenseColor.withOpacity(0.1),
                          IOSColors.systemBackground
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: expenseColor.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [expenseColor, expenseColor.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: expenseColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.arrow_down_circle_fill,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.description.isNotEmpty
                              ? expense.description
                              : 'Expense',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: labelPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          expense.formattedDate,
                          style: TextStyle(
                            fontSize: 14,
                            color: labelSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Expense Details
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // Amount Card
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
                        _buildDetailRow(
                          'Amount',
                          'UGX ${expense.totalAmount.toStringAsFixed(0)}',
                          CupertinoIcons.money_dollar_circle_fill,
                          expenseColor,
                          isDarkMode,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 1,
                          color: isDarkMode
                              ? IOSDarkColors.labelQuaternary.withOpacity(0.2)
                              : IOSColors.labelQuaternary.withOpacity(0.2),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          'Category',
                          expense.category ?? 'Uncategorized',
                          CupertinoIcons.tag_fill,
                          labelSecondary,
                          isDarkMode,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 1,
                          color: isDarkMode
                              ? IOSDarkColors.labelQuaternary.withOpacity(0.2)
                              : IOSColors.labelQuaternary.withOpacity(0.2),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          'Date',
                          _formatFullDate(expense.createdAt),
                          CupertinoIcons.calendar,
                          labelSecondary,
                          isDarkMode,
                        ),
                      ],
                    ),
                  ),
                  if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
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
                                CupertinoIcons.doc_text_fill,
                                size: 18,
                                color: labelSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text('Notes',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: labelPrimary)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(expense.notes!,
                              style: TextStyle(
                                  fontSize: 14, color: labelSecondary)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFullDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    bool isDarkMode,
  ) {
    final labelSecondary =
        isDarkMode ? IOSDarkColors.labelSecondary : IOSColors.labelSecondary;
    final labelPrimary =
        isDarkMode ? IOSDarkColors.labelPrimary : IOSColors.labelPrimary;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12, color: labelSecondary)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: labelPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(IOSSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(IOSBorderRadius.large),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode
                  ? IOSDarkColors.labelSecondary
                  : IOSColors.labelSecondary,
            ),
          ),
          const SizedBox(height: IOSSpacing.xs),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final String title;
  final double amount;
  final DateTime date;
  final String? category;
  final VoidCallback onTap;

  const _ExpenseCard({
    required this.title,
    required this.amount,
    required this.date,
    this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final expenseColor =
        isDarkMode ? IOSDarkColors.expenseColor : IOSColors.expenseColor;

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
                color: expenseColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
              ),
              child: Icon(
                CupertinoIcons.arrow_down,
                color: expenseColor,
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
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isDarkMode
                          ? IOSDarkColors.labelPrimary
                          : IOSColors.labelPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? IOSDarkColors.secondarySystemBackground
                            : IOSColors.secondarySystemBackground,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        category!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode
                              ? IOSDarkColors.labelSecondary
                              : IOSColors.labelSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Amount and date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '-UGX ${amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: expenseColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(date),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode
                        ? IOSDarkColors.labelSecondary
                        : IOSColors.labelSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    if (dateTime.day == now.day &&
        dateTime.month == now.month &&
        dateTime.year == now.year) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

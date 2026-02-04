import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:ismart_shop/models/transaction.dart' as app;
import 'package:ismart_shop/providers/transaction_provider.dart';
import 'package:ismart_shop/utils/ios_theme.dart';
import 'package:ismart_shop/widgets/ios_app_bar.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'today';

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

    final todaySales = transactionProvider.todaySales;
    final todayExpenses = transactionProvider.todayExpenses;
    final profit = todaySales - todayExpenses;

    final weeklyTransactions = transactionProvider.getWeeklyTransactions();
    final weeklySales = weeklyTransactions
        .where((t) => t.type == app.TransactionType.sale)
        .fold(0.0, (sum, t) => sum + t.totalAmount);
    final weeklyExpenses = weeklyTransactions
        .where((t) => t.type == app.TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.totalAmount);

    final monthlyTransactions = transactionProvider.getMonthlyTransactions();
    final monthlySales = monthlyTransactions
        .where((t) => t.type == app.TransactionType.sale)
        .fold(0.0, (sum, t) => sum + t.totalAmount);
    final monthlyExpenses = monthlyTransactions
        .where((t) => t.type == app.TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.totalAmount);

    return Scaffold(
      backgroundColor: IOSColors.secondarySystemBackground,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Period Selector
            Container(
              color: IOSColors.systemBackground,
              padding: const EdgeInsets.symmetric(
                horizontal: IOSSpacing.md,
                vertical: IOSSpacing.sm,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    IOSPeriodChip(
                      label: 'Today',
                      isSelected: _selectedPeriod == 'today',
                      onTap: () {
                        setState(() {
                          _selectedPeriod = 'today';
                        });
                      },
                    ),
                    const SizedBox(width: IOSSpacing.xs),
                    IOSPeriodChip(
                      label: 'This Week',
                      isSelected: _selectedPeriod == 'week',
                      onTap: () {
                        setState(() {
                          _selectedPeriod = 'week';
                        });
                      },
                    ),
                    const SizedBox(width: IOSSpacing.xs),
                    IOSPeriodChip(
                      label: 'This Month',
                      isSelected: _selectedPeriod == 'month',
                      onTap: () {
                        setState(() {
                          _selectedPeriod = 'month';
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            // Summary Cards
            Padding(
              padding: const EdgeInsets.all(IOSSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_selectedPeriod == 'today') ...[
                    IOSStatCard(
                      title: 'Total Sales',
                      value: 'UGX ${todaySales.toStringAsFixed(0)}',
                      color: IOSColors.saleColor,
                      icon: Icons.trending_up,
                    ),
                    const SizedBox(height: IOSSpacing.sm),
                    IOSStatCard(
                      title: 'Total Expenses',
                      value: 'UGX ${todayExpenses.toStringAsFixed(0)}',
                      color: IOSColors.expenseColor,
                      icon: Icons.trending_down,
                    ),
                    const SizedBox(height: IOSSpacing.sm),
                    IOSStatCard(
                      title: 'Net Profit',
                      value: 'UGX ${profit.toStringAsFixed(0)}',
                      color: profit >= 0 ? IOSColors.success : IOSColors.error,
                      icon: profit >= 0 ? Icons.check_circle : Icons.cancel,
                    ),
                  ] else if (_selectedPeriod == 'week') ...[
                    IOSStatCard(
                      title: 'Weekly Sales',
                      value: 'UGX ${weeklySales.toStringAsFixed(0)}',
                      color: IOSColors.saleColor,
                      icon: Icons.trending_up,
                    ),
                    const SizedBox(height: IOSSpacing.sm),
                    IOSStatCard(
                      title: 'Weekly Expenses',
                      value: 'UGX ${weeklyExpenses.toStringAsFixed(0)}',
                      color: IOSColors.expenseColor,
                      icon: Icons.trending_down,
                    ),
                    const SizedBox(height: IOSSpacing.sm),
                    IOSStatCard(
                      title: 'Net Profit',
                      value:
                          'UGX ${(weeklySales - weeklyExpenses).toStringAsFixed(0)}',
                      color: weeklySales - weeklyExpenses >= 0
                          ? IOSColors.success
                          : IOSColors.error,
                      icon: weeklySales - weeklyExpenses >= 0
                          ? Icons.check_circle
                          : Icons.cancel,
                    ),
                  ] else ...[
                    IOSStatCard(
                      title: 'Monthly Sales',
                      value: 'UGX ${monthlySales.toStringAsFixed(0)}',
                      color: IOSColors.saleColor,
                      icon: Icons.trending_up,
                    ),
                    const SizedBox(height: IOSSpacing.sm),
                    IOSStatCard(
                      title: 'Monthly Expenses',
                      value: 'UGX ${monthlyExpenses.toStringAsFixed(0)}',
                      color: IOSColors.expenseColor,
                      icon: Icons.trending_down,
                    ),
                    const SizedBox(height: IOSSpacing.sm),
                    IOSStatCard(
                      title: 'Net Profit',
                      value:
                          'UGX ${(monthlySales - monthlyExpenses).toStringAsFixed(0)}',
                      color: monthlySales - monthlyExpenses >= 0
                          ? IOSColors.success
                          : IOSColors.error,
                      icon: monthlySales - monthlyExpenses >= 0
                          ? Icons.check_circle
                          : Icons.cancel,
                    ),
                  ],
                  const SizedBox(height: IOSSpacing.lg),
                  // Transaction Breakdown Chart
                  IOSCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              CupertinoIcons.chart_pie,
                              color: IOSColors.primary,
                              size: 20,
                            ),
                            SizedBox(width: IOSSpacing.sm),
                            Text(
                              'Transaction Breakdown',
                              style: IOSTextStyles.title3,
                            ),
                          ],
                        ),
                        const SizedBox(height: IOSSpacing.md),
                        SizedBox(
                          height: 200,
                          child: _buildPieChart(transactionProvider.transactions
                              .cast<app.Transaction>()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: IOSSpacing.lg),
                  // Quick Summary
                  IOSCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              CupertinoIcons.clock,
                              color: IOSColors.primary,
                              size: 20,
                            ),
                            SizedBox(width: IOSSpacing.sm),
                            Text(
                              'Last 7 Days Summary',
                              style: IOSTextStyles.title3,
                            ),
                          ],
                        ),
                        const SizedBox(height: IOSSpacing.md),
                        _buildQuickSummary(transactionProvider),
                      ],
                    ),
                  ),
                  const SizedBox(height: IOSSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(List<app.Transaction> transactions) {
    final salesCount =
        transactions.where((t) => t.type == app.TransactionType.sale).length;
    final expensesCount =
        transactions.where((t) => t.type == app.TransactionType.expense).length;
    final purchasesCount = transactions
        .where((t) => t.type == app.TransactionType.purchase)
        .length;

    if (salesCount + expensesCount + purchasesCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: IOSColors.secondarySystemBackground,
                borderRadius: BorderRadius.circular(IOSBorderRadius.large),
              ),
              child: Icon(
                CupertinoIcons.chart_pie,
                size: 48,
                color: IOSColors.labelTertiary,
              ),
            ),
            const SizedBox(height: IOSSpacing.sm),
            const Text(
              'No data to display',
              style: TextStyle(
                color: IOSColors.labelSecondary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: salesCount.toDouble(),
            title: 'Sales\n$salesCount',
            color: IOSColors.saleColor,
            radius: 60,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          PieChartSectionData(
            value: expensesCount.toDouble(),
            title: 'Exp\n$expensesCount',
            color: IOSColors.expenseColor,
            radius: 60,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          PieChartSectionData(
            value: purchasesCount.toDouble(),
            title: 'Pur\n$purchasesCount',
            color: IOSColors.purchaseColor,
            radius: 60,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildQuickSummary(TransactionProvider provider) {
    final transactions = provider.transactions.take(7).toList();
    double totalSales = 0;
    double totalExpenses = 0;

    for (var t in transactions) {
      if (t.type == app.TransactionType.sale) {
        totalSales += t.totalAmount;
      } else if (t.type == app.TransactionType.expense) {
        totalExpenses += t.totalAmount;
      }
    }

    final profit = totalSales - totalExpenses;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(IOSSpacing.md),
                decoration: BoxDecoration(
                  color: IOSColors.saleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
                  border: Border.all(
                    color: IOSColors.saleColor.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          color: IOSColors.saleColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Sales',
                          style: TextStyle(
                            fontSize: 12,
                            color: IOSColors.labelSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: IOSSpacing.xs),
                    Text(
                      'UGX ${totalSales.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: IOSColors.saleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: IOSSpacing.sm),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(IOSSpacing.md),
                decoration: BoxDecoration(
                  color: IOSColors.expenseColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
                  border: Border.all(
                    color: IOSColors.expenseColor.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.trending_down,
                          color: IOSColors.expenseColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Expenses',
                          style: TextStyle(
                            fontSize: 12,
                            color: IOSColors.labelSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: IOSSpacing.xs),
                    Text(
                      'UGX ${totalExpenses.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: IOSColors.expenseColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: IOSSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: IOSSpacing.md,
            vertical: IOSSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: profit >= 0
                ? IOSColors.success.withOpacity(0.1)
                : IOSColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                profit >= 0 ? Icons.check_circle : Icons.cancel,
                color: profit >= 0 ? IOSColors.success : IOSColors.error,
                size: 20,
              ),
              const SizedBox(width: IOSSpacing.xs),
              Text(
                'Profit: UGX ${profit.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: profit >= 0 ? IOSColors.success : IOSColors.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

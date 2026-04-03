import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:ismart_shop/models/transaction.dart' as app;
import 'package:ismart_shop/providers/transaction_provider.dart';
import 'package:ismart_shop/services/report_service.dart';
import 'package:ismart_shop/utils/ios_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'today';
  bool _isExporting = false;

  // Custom date range for flexible periods
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // Preset periods
  final List<Map<String, String>> _periodPresets = [
    {'id': 'today', 'label': 'Today'},
    {'id': 'yesterday', 'label': 'Yesterday'},
    {'id': 'week', 'label': 'This Week'},
    {'id': 'lastWeek', 'label': 'Last Week'},
    {'id': 'month', 'label': 'This Month'},
    {'id': 'lastMonth', 'label': 'Last Month'},
    {'id': 'custom', 'label': 'Custom'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
    });
  }

  /// Get transactions for the selected period
  List<app.Transaction> _getTransactionsForPeriod(String period) {
    final provider = context.read<TransactionProvider>();
    final allTransactions = provider.transactions;
    final now = DateTime.now();

    switch (period) {
      case 'today':
        final todayStart = DateTime(now.year, now.month, now.day);
        return allTransactions
            .where((t) => t.createdAt.isAfter(todayStart))
            .toList();

      case 'yesterday':
        final yesterdayStart = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 1));
        final todayStart = DateTime(now.year, now.month, now.day);
        return allTransactions
            .where((t) =>
                t.createdAt.isAfter(yesterdayStart) &&
                t.createdAt.isBefore(todayStart))
            .toList();

      case 'week':
        final startOfWeek = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        return allTransactions
            .where((t) => t.createdAt.isAfter(startOfWeek))
            .toList();

      case 'lastWeek':
        final startOfThisWeek = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        final startOfLastWeek =
            startOfThisWeek.subtract(const Duration(days: 7));
        return allTransactions
            .where((t) =>
                t.createdAt.isAfter(startOfLastWeek) &&
                t.createdAt.isBefore(startOfThisWeek))
            .toList();

      case 'month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        return allTransactions
            .where((t) => t.createdAt.isAfter(startOfMonth))
            .toList();

      case 'lastMonth':
        final startOfThisMonth = DateTime(now.year, now.month, 1);
        final startOfLastMonth =
            DateTime(now.year, now.month - 1 > 0 ? now.month - 1 : 12, 1);
        return allTransactions
            .where((t) =>
                t.createdAt.isAfter(startOfLastMonth) &&
                t.createdAt.isBefore(startOfThisMonth))
            .toList();

      case 'custom':
        if (_customStartDate != null && _customEndDate != null) {
          return allTransactions
              .where((t) =>
                  t.createdAt.isAfter(_customStartDate!) &&
                  t.createdAt
                      .isBefore(_customEndDate!.add(const Duration(days: 1))))
              .toList();
        }
        return allTransactions;

      default:
        return allTransactions;
    }
  }

  /// Calculate totals for the selected period
  Map<String, double> _getPeriodTotals(
      String period, List<app.Transaction> transactions) {
    double sales = 0;
    double expenses = 0;
    double purchases = 0;

    for (var t in transactions) {
      switch (t.type) {
        case app.TransactionType.sale:
          sales += t.totalAmount;
          break;
        case app.TransactionType.expense:
          expenses += t.totalAmount;
          break;
        case app.TransactionType.purchase:
          purchases += t.totalAmount;
          break;
        case app.TransactionType.cashReceipt:
          break;
      }
    }

    return {
      'sales': sales,
      'expenses': expenses,
      'purchases': purchases,
      'profit': sales - expenses,
    };
  }

  /// Get display label for period
  String _getPeriodLabel(String period) {
    switch (period) {
      case 'today':
        return 'Today';
      case 'yesterday':
        return 'Yesterday';
      case 'week':
        return 'This Week';
      case 'lastWeek':
        return 'Last Week';
      case 'month':
        return 'This Month';
      case 'lastMonth':
        return 'Last Month';
      case 'custom':
        return 'Custom';
      default:
        return period;
    }
  }

  /// Show date picker for custom period
  Future<void> _showCustomDatePicker() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Show date range picker
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDarkMode
                ? const ColorScheme.dark(primary: CupertinoColors.activeOrange)
                : const ColorScheme.light(
                    primary: CupertinoColors.activeOrange),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedPeriod = 'custom';
      });
    }
  }

  Future<void> _exportReport(String type) async {
    if (_isExporting) return;

    setState(() => _isExporting = true);

    try {
      final provider = context.read<TransactionProvider>();
      final transactions = provider.transactions;
      String? filePath;

      switch (type) {
        case 'daily':
          filePath = await ReportService.generateDailyReport(
              transactions, DateTime.now());
          break;
        case 'profit':
          final now = DateTime.now();
          final startOfMonth = DateTime(now.year, now.month, 1);
          filePath = await ReportService.generateProfitSummary(
            transactions,
            startDate: startOfMonth,
            endDate: now,
          );
          break;
        case 'sales':
          filePath = await ReportService.generateSalesExcel(transactions);
          break;
        case 'expenses':
          filePath = await ReportService.generateExpenseExcel(transactions);
          break;
      }

      if (mounted && filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Report saved to Downloads: ${filePath.split('/').last}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
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
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Dynamic colors
    final saleColor =
        isDarkMode ? IOSDarkColors.saleColor : IOSColors.saleColor;
    final expenseColor =
        isDarkMode ? IOSDarkColors.expenseColor : IOSColors.expenseColor;
    final successColor = isDarkMode ? IOSDarkColors.success : IOSColors.success;
    final errorColor = isDarkMode ? IOSDarkColors.error : IOSColors.error;
    final primaryColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;

    return Scaffold(
      backgroundColor: isDarkMode
          ? IOSDarkColors.secondarySystemBackground
          : IOSColors.secondarySystemBackground,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Period Selector
            Container(
              color: isDarkMode
                  ? IOSDarkColors.systemBackground
                  : IOSColors.systemBackground,
              padding: const EdgeInsets.symmetric(
                horizontal: IOSSpacing.md,
                vertical: IOSSpacing.sm,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _periodPresets.map((preset) {
                    final isSelected = _selectedPeriod == preset['id'];
                    final isCustom = preset['id'] == 'custom';

                    return Padding(
                      padding: const EdgeInsets.only(right: IOSSpacing.xs),
                      child: IOSPeriodChip(
                        label: preset['label']!,
                        isSelected: isSelected,
                        onTap: () {
                          if (isCustom) {
                            _showCustomDatePicker();
                          } else {
                            setState(() {
                              _selectedPeriod = preset['id']!;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const Divider(height: 1),
            // Summary Cards - Dynamic based on selected period
            Padding(
              padding: const EdgeInsets.all(IOSSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Get transactions and totals for selected period
                  Builder(builder: (context) {
                    final periodTransactions =
                        _getTransactionsForPeriod(_selectedPeriod);
                    final periodTotals =
                        _getPeriodTotals(_selectedPeriod, periodTransactions);
                    final periodSales = periodTotals['sales']!;
                    final periodExpenses = periodTotals['expenses']!;
                    final periodProfit = periodTotals['profit']!;
                    final periodLabel = _getPeriodLabel(_selectedPeriod);

                    return Column(
                      children: [
                        // Custom period info bar
                        if (_selectedPeriod == 'custom' &&
                            _customStartDate != null &&
                            _customEndDate != null)
                          Container(
                            margin:
                                const EdgeInsets.only(bottom: IOSSpacing.sm),
                            padding: const EdgeInsets.symmetric(
                                horizontal: IOSSpacing.md,
                                vertical: IOSSpacing.sm),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(IOSBorderRadius.medium),
                            ),
                            child: Row(
                              children: [
                                Icon(CupertinoIcons.calendar,
                                    size: 16, color: primaryColor),
                                const SizedBox(width: IOSSpacing.xs),
                                Text(
                                  '${DateFormat('dd MMM').format(_customStartDate!)} - ${DateFormat('dd MMM yyyy').format(_customEndDate!)}',
                                  style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: _showCustomDatePicker,
                                  child: Text('Change',
                                      style: TextStyle(
                                          color: primaryColor, fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                        IOSStatCard(
                          title: '$periodLabel Sales',
                          value: 'UGX ${periodSales.toStringAsFixed(0)}',
                          color: saleColor,
                          icon: Icons.trending_up,
                        ),
                        const SizedBox(height: IOSSpacing.sm),
                        IOSStatCard(
                          title: '$periodLabel Expenses',
                          value: 'UGX ${periodExpenses.toStringAsFixed(0)}',
                          color: expenseColor,
                          icon: Icons.trending_down,
                        ),
                        const SizedBox(height: IOSSpacing.sm),
                        IOSStatCard(
                          title: 'Net Profit',
                          value: 'UGX ${periodProfit.toStringAsFixed(0)}',
                          color: periodProfit >= 0 ? successColor : errorColor,
                          icon: periodProfit >= 0
                              ? Icons.check_circle
                              : Icons.cancel,
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: IOSSpacing.lg),
                  // Transaction Breakdown Chart
                  IOSCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.chart_pie,
                              color: primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: IOSSpacing.sm),
                            Text(
                              'Transaction Breakdown',
                              style: IOSTextStyles.title3.copyWith(
                                color: isDarkMode
                                    ? IOSDarkColors.labelPrimary
                                    : IOSColors.labelPrimary,
                              ),
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
                          children: [
                            Icon(
                              CupertinoIcons.clock,
                              color: primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: IOSSpacing.sm),
                            Text(
                              'Last 7 Days Summary',
                              style: IOSTextStyles.title3.copyWith(
                                color: isDarkMode
                                    ? IOSDarkColors.labelPrimary
                                    : IOSColors.labelPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: IOSSpacing.md),
                        _buildQuickSummary(transactionProvider),
                      ],
                    ),
                  ),
                  const SizedBox(height: IOSSpacing.lg),
                  // Export Options
                  IOSCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.share,
                              color: primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: IOSSpacing.sm),
                            Text(
                              'Export Reports',
                              style: IOSTextStyles.title3.copyWith(
                                color: isDarkMode
                                    ? IOSDarkColors.labelPrimary
                                    : IOSColors.labelPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: IOSSpacing.md),
                        _buildExportButtons(context, transactionProvider),
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

  Widget _buildExportButtons(
      BuildContext context, TransactionProvider provider) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ExportButton(
                icon: Icons.calendar_today,
                label: 'Daily Report',
                color: Colors.blue,
                onPressed: _isExporting ? null : () => _exportReport('daily'),
              ),
            ),
            const SizedBox(width: IOSSpacing.sm),
            Expanded(
              child: _ExportButton(
                icon: Icons.trending_up,
                label: 'Profit Summary',
                color: Colors.purple,
                onPressed: _isExporting ? null : () => _exportReport('profit'),
              ),
            ),
          ],
        ),
        const SizedBox(height: IOSSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _ExportButton(
                icon: Icons.table_chart,
                label: 'Sales Excel',
                color: Colors.green,
                onPressed: _isExporting ? null : () => _exportReport('sales'),
              ),
            ),
            const SizedBox(width: IOSSpacing.sm),
            Expanded(
              child: _ExportButton(
                icon: Icons.receipt_long,
                label: 'Expenses Excel',
                color: Colors.orange,
                onPressed:
                    _isExporting ? null : () => _exportReport('expenses'),
              ),
            ),
          ],
        ),
        if (_isExporting) ...[
          const SizedBox(height: IOSSpacing.md),
          const CupertinoActivityIndicator(),
        ],
      ],
    );
  }

  Widget _buildPieChart(List<app.Transaction> transactions) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final salesCount =
        transactions.where((t) => t.type == app.TransactionType.sale).length;
    final expensesCount =
        transactions.where((t) => t.type == app.TransactionType.expense).length;
    final purchasesCount = transactions
        .where((t) => t.type == app.TransactionType.purchase)
        .length;

    final saleColor =
        isDarkMode ? IOSDarkColors.saleColor : IOSColors.saleColor;
    final expenseColor =
        isDarkMode ? IOSDarkColors.expenseColor : IOSColors.expenseColor;
    final purchaseColor =
        isDarkMode ? IOSDarkColors.purchaseColor : IOSColors.purchaseColor;

    if (salesCount + expensesCount + purchasesCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? IOSDarkColors.secondarySystemBackground
                    : IOSColors.secondarySystemBackground,
                borderRadius: BorderRadius.circular(IOSBorderRadius.large),
              ),
              child: Icon(
                CupertinoIcons.chart_pie,
                size: 48,
                color: isDarkMode
                    ? IOSDarkColors.labelTertiary
                    : IOSColors.labelTertiary,
              ),
            ),
            const SizedBox(height: IOSSpacing.sm),
            Text(
              'No data to display',
              style: TextStyle(
                color: isDarkMode
                    ? IOSDarkColors.labelSecondary
                    : IOSColors.labelSecondary,
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
            color: saleColor,
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
            color: expenseColor,
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
            color: purchaseColor,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
    final saleColor =
        isDarkMode ? IOSDarkColors.saleColor : IOSColors.saleColor;
    final expenseColor =
        isDarkMode ? IOSDarkColors.expenseColor : IOSColors.expenseColor;
    final successColor = isDarkMode ? IOSDarkColors.success : IOSColors.success;
    final errorColor = isDarkMode ? IOSDarkColors.error : IOSColors.error;
    final labelSecondary =
        isDarkMode ? IOSDarkColors.labelSecondary : IOSColors.labelSecondary;
    final secondarySystemBg = isDarkMode
        ? IOSDarkColors.secondarySystemBackground
        : IOSColors.secondarySystemBackground;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(IOSSpacing.md),
                decoration: BoxDecoration(
                  color: saleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
                  border: Border.all(
                    color: saleColor.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          color: saleColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Sales',
                          style: TextStyle(
                            fontSize: 12,
                            color: labelSecondary,
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
                        color: saleColor,
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
                  color: expenseColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
                  border: Border.all(
                    color: expenseColor.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.trending_down,
                          color: expenseColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Expenses',
                          style: TextStyle(
                            fontSize: 12,
                            color: labelSecondary,
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
                        color: expenseColor,
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
                ? successColor.withOpacity(0.1)
                : errorColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                profit >= 0 ? Icons.check_circle : Icons.cancel,
                color: profit >= 0 ? successColor : errorColor,
                size: 20,
              ),
              const SizedBox(width: IOSSpacing.xs),
              Text(
                'Profit: UGX ${profit.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: profit >= 0 ? successColor : errorColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _ExportButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: IOSSpacing.md,
            vertical: IOSSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: IOSSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

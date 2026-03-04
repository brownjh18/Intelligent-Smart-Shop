import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:ismart_shop/providers/auth_provider.dart';
import 'package:ismart_shop/providers/transaction_provider.dart';
import 'package:ismart_shop/models/transaction.dart' as app;
import 'package:ismart_shop/utils/ios_theme.dart';
import 'package:ismart_shop/widgets/ios_app_bar.dart';
import 'package:ismart_shop/widgets/profile_dropdown.dart';
import 'onboarding_screen.dart';
import 'voice_recording_screen.dart';
import 'add_transaction_screen.dart';
import 'transactions_list_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialTabIndex;

  const HomeScreen({super.key, this.initialTabIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const TransactionsListScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  final List<String> _titles = [
    'iSmart Shop',
    'Transactions',
    'Reports',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        appBar: IOSNavigationBar(
          title: _titles[_currentIndex],
          automaticallyImplyLeading: false,
          actions: [
            ProfileDropdown(
              onSettingsTap: () {
                setState(() {
                  _currentIndex = 3; // Switch to Settings tab
                });
              },
              onLogoutTap: () async {
                await authProvider.logout();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  CupertinoPageRoute(builder: (_) => const OnboardingScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
        body: _screens[_currentIndex],
        backgroundColor: IOSColors.secondarySystemBackground,
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
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: _currentIndex != 3
            ? Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [IOSColors.secondary, IOSColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: IOSColors.secondary.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: FloatingActionButton(
                      heroTag: 'addTransactionFab',
                      onPressed: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) => const AddTransactionScreen(),
                          ),
                        );
                      },
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      child: const Icon(
                        CupertinoIcons.pencil,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [IOSColors.primary, IOSColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: IOSColors.primary.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: FloatingActionButton(
                      heroTag: 'voiceRecordingFab',
                      onPressed: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) => const VoiceRecordingScreen(),
                          ),
                        );
                      },
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      child: const Icon(
                        CupertinoIcons.mic_fill,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? IOSColors.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isSelected ? 24 : 22,
              color: isSelected ? IOSColors.primary : IOSColors.labelTertiary,
            ),
            if (isSelected) const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? Text(
                      label,
                      key: ValueKey(label),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: IOSColors.primary,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(IOSSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Today's Summary Section
          IOSSectionHeader(title: 'Today'),
          const SizedBox(height: IOSSpacing.sm),
          Row(
            children: [
              Expanded(
                child: IOSSummarCard(
                  title: 'Sales',
                  amount:
                      'UGX ${transactionProvider.todaySales.toStringAsFixed(0)}',
                  color: IOSColors.saleColor,
                  icon: CupertinoIcons.arrow_up_circle_fill,
                ),
              ),
              const SizedBox(width: IOSSpacing.sm),
              Expanded(
                child: IOSSummarCard(
                  title: 'Expenses',
                  amount:
                      'UGX ${transactionProvider.todayExpenses.toStringAsFixed(0)}',
                  color: IOSColors.expenseColor,
                  icon: CupertinoIcons.arrow_down_circle_fill,
                ),
              ),
            ],
          ),
          const SizedBox(height: IOSSpacing.lg),
          // Recent Transactions Section
          IOSSectionHeader(
            title: 'Recent Transactions',
            hasAction: true,
            actionLabel: 'See All',
            onActionTap: () {
              // Switch to Transactions tab (index 1) in the bottom navigation
              final homeState =
                  context.findAncestorStateOfType<_HomeScreenState>();
              homeState?.setState(() {
                homeState._currentIndex = 1;
              });
            },
          ),
          const SizedBox(height: IOSSpacing.xs),
          if (transactionProvider.isLoading)
            const IOSLoadingIndicator()
          else if (transactionProvider.transactions.isEmpty)
            IOSEmptyState(
              icon: CupertinoIcons.doc_text,
              title: 'No Transactions Yet',
              subtitle: 'Start recording your sales and expenses',
            )
          else
            ...transactionProvider.transactions.take(5).map((tx) {
              return IOSTransactionItem(
                title: tx.itemName,
                amount: 'UGX ${tx.amount.toStringAsFixed(0)}',
                time: _formatTime(tx.createdAt),
                color: _getTransactionColor(tx.type),
                icon: _getTransactionIcon(tx.type),
                category: tx.category,
              );
            }),
          const SizedBox(height: IOSSpacing.xxl),
        ],
      ),
    );
  }

  Color _getTransactionColor(app.TransactionType type) {
    switch (type) {
      case app.TransactionType.sale:
        return IOSColors.saleColor;
      case app.TransactionType.expense:
        return IOSColors.expenseColor;
      case app.TransactionType.purchase:
        return IOSColors.purchaseColor;
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
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    if (dateTime.day == now.day &&
        dateTime.month == now.month &&
        dateTime.year == now.year) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
    return '${dateTime.day}/${dateTime.month}';
  }
}

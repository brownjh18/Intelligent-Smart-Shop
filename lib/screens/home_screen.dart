import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:ismart_shop/providers/auth_provider.dart';
import 'package:ismart_shop/providers/transaction_provider.dart';
import 'package:ismart_shop/models/transaction.dart' as app;
import 'package:ismart_shop/utils/ios_theme.dart';
import 'package:ismart_shop/widgets/ios_app_bar.dart';
import 'package:ismart_shop/widgets/profile_dropdown.dart';
import 'package:ismart_shop/widgets/app_sidebar.dart';
import 'package:ismart_shop/widgets/app_bottom_nav.dart';
import 'package:ismart_shop/widgets/expandable_fab.dart';
import 'onboarding_screen.dart';
import 'voice_recording_screen.dart';
import 'add_transaction_screen.dart';
import 'transactions_list_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'inventory_screen.dart';
import 'categories_screen.dart';
import 'customers_screen.dart';
import 'suppliers_screen.dart';
import 'receipts_screen.dart';
import 'expenses_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialTabIndex;

  const HomeScreen({super.key, this.initialTabIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = [
    const DashboardScreen(),
    const TransactionsListScreen(),
    const InventoryScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Transactions',
    'Inventory',
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: AppSidebar(
          currentIndex: _currentIndex,
          onNavigate: _handleSidebarNavigation,
        ),
        appBar: IOSNavigationBar(
          title: _titles[_currentIndex],
          automaticallyImplyLeading: false,
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            child: Icon(
              CupertinoIcons.line_horizontal_3,
              color: isDarkMode ? IOSDarkColors.primary : IOSColors.primary,
            ),
          ),
          actions: [
            ProfileDropdown(
              onSettingsTap: () {
                setState(() {
                  _currentIndex = 4;
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
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: KeyedSubtree(
            key: ValueKey<int>(_currentIndex),
            child: _screens[_currentIndex],
          ),
        ),
        backgroundColor: isDarkMode
            ? IOSDarkColors.secondarySystemBackground
            : IOSColors.secondarySystemBackground,
        bottomNavigationBar: AppBottomNav(
          currentIndex: _currentIndex,
          onNavigate: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: _currentIndex == 2
            ? null
            : (_currentIndex != 4
                ? ExpandableFab(
                    actions: [
                      FabAction(
                        label: 'Voice',
                        icon: CupertinoIcons.mic_fill,
                        color: IOSColors.secondary,
                        onPressed: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (_) => const VoiceRecordingScreen(),
                            ),
                          );
                        },
                      ),
                      FabAction(
                        label: _getFabLabel(),
                        icon: CupertinoIcons.add,
                        color: IOSColors.primary,
                        onPressed: () => _handleFabAction(),
                      ),
                    ],
                  )
                : null),
      ),
    );
  }

  void _handleSidebarNavigation(int index) {
    // Handle negative indices for secondary screens
    if (index < 0) {
      switch (index) {
        case -1:
          // Customers
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => CustomersScreen(
                onNavigate: (navIndex) {
                  setState(() => _currentIndex = navIndex);
                },
              ),
            ),
          );
          break;
        case -2:
          // Suppliers
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => SuppliersScreen(
                onNavigate: (navIndex) {
                  setState(() => _currentIndex = navIndex);
                },
              ),
            ),
          );
          break;
        case -3:
          // Categories
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => CategoriesScreen(
                onNavigate: (navIndex) {
                  setState(() => _currentIndex = navIndex);
                },
              ),
            ),
          );
          break;
        case -4:
          // Receipts
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => ReceiptsScreen(
                onNavigate: (navIndex) {
                  setState(() => _currentIndex = navIndex);
                },
              ),
            ),
          );
          break;
        case -5:
          // Expenses
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => ExpensesScreen(
                onNavigate: (navIndex) {
                  setState(() => _currentIndex = navIndex);
                },
              ),
            ),
          );
          break;
      }
    } else {
      // Main navigation indices
      setState(() {
        _currentIndex = index;
      });
    }
  }

  String _getFabLabel() {
    switch (_currentIndex) {
      case 0:
      case 1:
        return 'Transaction';
      case 2:
        return 'Product';
      case 3:
        return 'Report';
      default:
        return 'Add';
    }
  }

  void _handleFabAction() {
    // Always add transaction from home screen
    // The secondary screens (customers, suppliers, categories, inventory)
    // have their own context-specific FABs
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => const AddTransactionScreen(),
      ),
    );
  }

  void _showAddProductDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Add Product'),
        message: const Text('Navigate to Inventory screen to add products'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => const InventoryScreen(),
                ),
              );
            },
            child: const Text('Go to Inventory'),
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

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(IOSSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Today's Summary Section
          const IOSSectionHeader(title: 'Today'),
          const SizedBox(height: IOSSpacing.sm),
          Row(
            children: [
              Expanded(
                child: IOSSummarCard(
                  title: 'Sales',
                  amount:
                      'UGX ${transactionProvider.todaySales.toStringAsFixed(0)}',
                  color: isDarkMode
                      ? IOSDarkColors.saleColor
                      : IOSColors.saleColor,
                  icon: CupertinoIcons.arrow_up_circle_fill,
                ),
              ),
              const SizedBox(width: IOSSpacing.sm),
              Expanded(
                child: IOSSummarCard(
                  title: 'Expenses',
                  amount:
                      'UGX ${transactionProvider.todayExpenses.toStringAsFixed(0)}',
                  color: isDarkMode
                      ? IOSDarkColors.expenseColor
                      : IOSColors.expenseColor,
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
              // This will be handled by the parent widget
            },
          ),
          const SizedBox(height: IOSSpacing.xs),
          if (transactionProvider.isLoading)
            const IOSLoadingIndicator()
          else if (transactionProvider.transactions.isEmpty)
            const IOSEmptyState(
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
                color: _getTransactionColor(tx.type, isDarkMode),
                icon: _getTransactionIcon(tx.type),
                category: tx.category,
              );
            }),
          const SizedBox(height: IOSSpacing.xxl),
        ],
      ),
    );
  }

  Color _getTransactionColor(app.TransactionType type, bool isDarkMode) {
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:ismart_shop/providers/auth_provider.dart';
import 'package:ismart_shop/utils/ios_theme.dart';
import 'transactions_list_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: IOSColors.systemBackground,
          elevation: 0,
          title: Text(_titles[_currentIndex]),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                        builder: (_) => const ProfileEditScreen()),
                  );
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: IOSColors.primary.withValues(alpha: 0.1),
                  child: authProvider.userModel?.profileImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.network(
                            authProvider.userModel!.profileImageUrl!,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                CupertinoIcons.person_fill,
                                color: IOSColors.primary,
                                size: 24,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          CupertinoIcons.person_fill,
                          color: IOSColors.primary,
                          size: 24,
                        ),
                ),
              ),
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
                color: Colors.black.withValues(alpha: 0.08),
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
        floatingActionButton: _currentIndex == 0
            ? Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [IOSColors.primary, IOSColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: IOSColors.primary.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => const SizedBox.shrink(),
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
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                      style: const TextStyle(
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

// Simplified Dashboard for profile screen
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userName =
        authProvider.userModel?.displayName.split(' ').first ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(IOSSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome Section
          Container(
            padding: const EdgeInsets.all(IOSSpacing.lg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  IOSColors.primary,
                  IOSColors.primaryDark,
                ],
              ),
              borderRadius: BorderRadius.circular(IOSBorderRadius.large),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: IOSSpacing.xs),
                Text(
                  userName.isNotEmpty ? userName : 'User',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: IOSSpacing.sm),
                Text(
                  'Manage your sales and expenses efficiently',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: IOSSpacing.lg),
          // Quick Stats
          Row(
            children: [
              Expanded(
                child: IOSQuickActionButton(
                  icon: CupertinoIcons.arrow_up_circle_fill,
                  label: 'Sales',
                  onTap: () {},
                  iconColor: IOSColors.saleColor,
                ),
              ),
              const SizedBox(width: IOSSpacing.sm),
              Expanded(
                child: IOSQuickActionButton(
                  icon: CupertinoIcons.arrow_down_circle_fill,
                  label: 'Expenses',
                  onTap: () {},
                  iconColor: IOSColors.expenseColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: IOSSpacing.lg),
          // Profile Summary
          IOSCard(
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: IOSColors.primary.withValues(alpha: 0.1),
                      child: authProvider.userModel?.profileImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Image.network(
                                authProvider.userModel!.profileImageUrl!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    CupertinoIcons.person_fill,
                                    color: IOSColors.primary,
                                    size: 32,
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              CupertinoIcons.person_fill,
                              color: IOSColors.primary,
                              size: 32,
                            ),
                    ),
                    const SizedBox(width: IOSSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authProvider.userModel?.displayName ?? 'Not set',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: IOSColors.labelPrimary,
                            ),
                          ),
                          const SizedBox(height: IOSSpacing.xxs),
                          Text(
                            authProvider.userModel?.email ?? 'Not set',
                            style: const TextStyle(
                              fontSize: 14,
                              color: IOSColors.labelSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: IOSSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (_) => const ProfileEditScreen()),
                      );
                    },
                    child: const Text('Edit Profile'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

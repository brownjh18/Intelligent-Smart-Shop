import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ismart_shop/utils/ios_theme.dart';

class CommonScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBackButton;
  final int currentIndex;
  final Function(int)? onNavTap;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  const CommonScaffold({
    super.key,
    required this.body,
    required this.title,
    this.leading,
    this.actions,
    this.showBackButton = false,
    this.currentIndex = 0,
    this.onNavTap,
    this.floatingActionButton,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode
        ? IOSDarkColors.systemBackground
        : IOSColors.systemBackground;
    final primaryColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;

    return Scaffold(
      backgroundColor: backgroundColor ?? bgColor,
      appBar: showBackButton
          ? AppBar(
              backgroundColor: bgColor,
              elevation: 0,
              leading: leading ??
                  IconButton(
                    icon: Icon(
                      CupertinoIcons.back,
                      color: primaryColor,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
              title: Text(
                title,
                style: TextStyle(
                  color: isDarkMode
                      ? IOSDarkColors.labelPrimary
                      : IOSColors.labelPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: actions,
            )
          : null,
      body: body,
      bottomNavigationBar: onNavTap != null
          ? Container(
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(
                  top: BorderSide(
                    color: isDarkMode
                        ? IOSDarkColors.labelQuaternary
                        : IOSColors.labelQuaternary,
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(0, CupertinoIcons.house, 'Home',
                          primaryColor, isDarkMode),
                      _buildNavItem(1, CupertinoIcons.list_bullet,
                          'Transactions', primaryColor, isDarkMode),
                      _buildNavItem(2, CupertinoIcons.cube_box, 'Inventory',
                          primaryColor, isDarkMode),
                      _buildNavItem(3, CupertinoIcons.chart_bar, 'Reports',
                          primaryColor, isDarkMode),
                      _buildNavItem(4, CupertinoIcons.settings, 'Settings',
                          primaryColor, isDarkMode),
                    ],
                  ),
                ),
              ),
            )
          : null,
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label,
      Color primaryColor, bool isDarkMode) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onNavTap?.call(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? primaryColor
                  : (isDarkMode
                      ? IOSDarkColors.labelQuaternary
                      : IOSColors.labelQuaternary),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? primaryColor
                    : (isDarkMode
                        ? IOSDarkColors.labelQuaternary
                        : IOSColors.labelQuaternary),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to navigate with bottom nav
void navigateWithBottomNav(BuildContext context, int index) {
  // Pop back to home first
  Navigator.popUntil(context, (route) => route.isFirst);
  // Then notify home to change tab
  // This is handled by passing a callback
}

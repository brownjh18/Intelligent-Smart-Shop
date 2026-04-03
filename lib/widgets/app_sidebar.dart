import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:ismart_shop/providers/auth_provider.dart';
import 'package:ismart_shop/utils/ios_theme.dart';

/// Unified Sidebar Navigation Widget
/// Slides from the left when the sidebar toggle button is clicked
class AppSidebar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onNavigate;
  final VoidCallback? onClose;

  const AppSidebar({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = screenWidth * 0.8;

    return Drawer(
      width: sidebarWidth,
      backgroundColor: isDarkMode
          ? IOSDarkColors.systemBackground
          : IOSColors.systemBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _buildHeader(context, isDarkMode, authProvider),
            const SizedBox(height: IOSSpacing.md),

            // Main Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: IOSSpacing.md),
                children: [
                  _buildSectionTitle('Main', isDarkMode),
                  const SizedBox(height: IOSSpacing.xs),
                  _buildNavItem(
                    context: context,
                    index: 0,
                    icon: CupertinoIcons.house_fill,
                    label: 'Dashboard',
                    isDarkMode: isDarkMode,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 1,
                    icon: CupertinoIcons.list_bullet,
                    label: 'Transactions',
                    isDarkMode: isDarkMode,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 2,
                    icon: CupertinoIcons.cube_box_fill,
                    label: 'Inventory',
                    isDarkMode: isDarkMode,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 3,
                    icon: CupertinoIcons.chart_bar_fill,
                    label: 'Reports',
                    isDarkMode: isDarkMode,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 4,
                    icon: CupertinoIcons.settings,
                    label: 'Settings',
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: IOSSpacing.lg),
                  _buildSectionTitle('More', isDarkMode),
                  const SizedBox(height: IOSSpacing.xs),
                  _buildSecondaryNavItem(
                    context: context,
                    icon: CupertinoIcons.person_2_fill,
                    label: 'Customers',
                    isDarkMode: isDarkMode,
                    routeIndex: -1, // Special index for secondary screens
                  ),
                  _buildSecondaryNavItem(
                    context: context,
                    icon: CupertinoIcons.cube_box_fill,
                    label: 'Suppliers',
                    isDarkMode: isDarkMode,
                    routeIndex: -2,
                  ),
                  _buildSecondaryNavItem(
                    context: context,
                    icon: CupertinoIcons.tag_fill,
                    label: 'Categories',
                    isDarkMode: isDarkMode,
                    routeIndex: -3,
                  ),
                  _buildSecondaryNavItem(
                    context: context,
                    icon: CupertinoIcons.doc_text_fill,
                    label: 'Receipts',
                    isDarkMode: isDarkMode,
                    routeIndex: -4,
                  ),
                  _buildSecondaryNavItem(
                    context: context,
                    icon: CupertinoIcons.money_dollar_circle_fill,
                    label: 'Expenses',
                    isDarkMode: isDarkMode,
                    routeIndex: -5,
                  ),
                ],
              ),
            ),

            // Footer
            _buildFooter(context, isDarkMode, authProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, bool isDarkMode, AuthProvider authProvider) {
    final primaryColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;
    final labelPrimary =
        isDarkMode ? IOSDarkColors.labelPrimary : IOSColors.labelPrimary;
    final secondaryBg = isDarkMode
        ? IOSDarkColors.secondarySystemBackground
        : IOSColors.secondarySystemBackground;

    return Container(
      padding: const EdgeInsets.all(IOSSpacing.md),
      decoration: BoxDecoration(
        color: secondaryBg,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode
                ? IOSDarkColors.labelQuaternary
                : IOSColors.labelQuaternary,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withOpacity(0.15),
              border: Border.all(
                color: primaryColor,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                authProvider.userModel != null &&
                        authProvider.userModel!.displayName.isNotEmpty
                    ? authProvider.userModel!.displayName[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: IOSSpacing.md),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authProvider.userModel?.displayName ?? 'User',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: labelPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  authProvider.userModel?.email ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode
                        ? IOSDarkColors.labelSecondary
                        : IOSColors.labelSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Close button
          IconButton(
            icon: Icon(
              CupertinoIcons.xmark_circle_fill,
              color: isDarkMode
                  ? IOSDarkColors.labelTertiary
                  : IOSColors.labelTertiary,
            ),
            onPressed: onClose ?? () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(left: IOSSpacing.xs, top: IOSSpacing.sm),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDarkMode
              ? IOSDarkColors.labelTertiary
              : IOSColors.labelTertiary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
    required bool isDarkMode,
  }) {
    final isSelected = currentIndex == index;
    final primaryColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;
    final labelPrimary =
        isDarkMode ? IOSDarkColors.labelPrimary : IOSColors.labelPrimary;
    final labelTertiary =
        isDarkMode ? IOSDarkColors.labelTertiary : IOSColors.labelTertiary;
    final secondaryBg = isDarkMode
        ? IOSDarkColors.secondarySystemBackground
        : IOSColors.secondarySystemBackground;

    return Padding(
      padding: const EdgeInsets.only(bottom: IOSSpacing.xs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
          onTap: () async {
            // Close the drawer first
            Navigator.pop(context);
            // Small delay to ensure drawer closes before navigation
            await Future.delayed(const Duration(milliseconds: 250));
            // Navigate
            onNavigate(index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: IOSSpacing.md,
              vertical: IOSSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryColor.withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? primaryColor : labelTertiary,
                ),
                const SizedBox(width: IOSSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? primaryColor : labelPrimary,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: primaryColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isDarkMode,
    required int routeIndex,
  }) {
    final labelPrimary =
        isDarkMode ? IOSDarkColors.labelPrimary : IOSColors.labelPrimary;
    final labelTertiary =
        isDarkMode ? IOSDarkColors.labelTertiary : IOSColors.labelTertiary;

    return Padding(
      padding: const EdgeInsets.only(bottom: IOSSpacing.xs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
          onTap: () async {
            // Close the drawer first
            Navigator.pop(context);
            // Small delay to ensure drawer closes before navigation
            await Future.delayed(const Duration(milliseconds: 250));
            // Navigate to secondary screen
            onNavigate(routeIndex);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: IOSSpacing.md,
              vertical: IOSSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: labelTertiary,
                ),
                const SizedBox(width: IOSSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: labelPrimary,
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: labelTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(
      BuildContext context, bool isDarkMode, AuthProvider authProvider) {
    final labelSecondary =
        isDarkMode ? IOSDarkColors.labelSecondary : IOSColors.labelSecondary;

    return Container(
      padding: const EdgeInsets.all(IOSSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDarkMode
                ? IOSDarkColors.labelQuaternary
                : IOSColors.labelQuaternary,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'iSmart Shop v1.0.0',
            style: TextStyle(
              fontSize: 12,
              color: labelSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper function to show the sidebar
void showAppSidebar(
  BuildContext context, {
  required int currentIndex,
  required Function(int) onNavigate,
}) {
  Scaffold.of(context).openDrawer();
}

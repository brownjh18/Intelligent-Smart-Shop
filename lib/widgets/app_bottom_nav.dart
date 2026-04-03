import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ismart_shop/utils/ios_theme.dart';

/// Modern Floating Bottom Navigation Widget
/// Features a floating pill design with smooth indicator animations
class AppBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onNavigate;
  final bool showLabels;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
    this.showLabels = true,
  });

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  final List<_NavItemData> _navItems = [
    _NavItemData(
      icon: CupertinoIcons.house,
      selectedIcon: CupertinoIcons.house_fill,
      label: 'Home',
    ),
    _NavItemData(
      icon: CupertinoIcons.list_bullet,
      selectedIcon: CupertinoIcons.list_bullet,
      label: 'Transactions',
    ),
    _NavItemData(
      icon: CupertinoIcons.cube_box,
      selectedIcon: CupertinoIcons.cube_box_fill,
      label: 'Inventory',
    ),
    _NavItemData(
      icon: CupertinoIcons.chart_bar,
      selectedIcon: CupertinoIcons.chart_bar_fill,
      label: 'Reports',
    ),
    _NavItemData(
      icon: CupertinoIcons.settings,
      selectedIcon: CupertinoIcons.settings_solid,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;
    final labelTertiaryColor =
        isDarkMode ? IOSDarkColors.labelTertiary : IOSColors.labelTertiary;
    final backgroundColor =
        isDarkMode ? IOSDarkColors.systemBackground : Colors.white;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (isDarkMode ? Colors.black : Colors.grey)
                .withValues(alpha: isDarkMode ? 0.5 : 0.2),
            blurRadius: 40,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: 65,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(
              color: (isDarkMode ? Colors.white : Colors.black)
                  .withValues(alpha: 0.06),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_navItems.length, (index) {
              return _buildNavItem(
                context: context,
                index: index,
                item: _navItems[index],
                isDarkMode: isDarkMode,
                primaryColor: primaryColor,
                labelTertiaryColor: labelTertiaryColor,
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required _NavItemData item,
    required bool isDarkMode,
    required Color primaryColor,
    required Color labelTertiaryColor,
  }) {
    final isSelected = widget.currentIndex == index;

    return GestureDetector(
      onTap: () => widget.onNavigate(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: Icon(
                isSelected ? item.selectedIcon : item.icon,
                size: isSelected ? 24 : 22,
                color: isSelected ? primaryColor : labelTertiaryColor,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 9.5 : 0,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? primaryColor : Colors.transparent,
                letterSpacing: 0.3,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  _NavItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Compact Bottom Navigation with subtle indicator
class AppBottomNavCompact extends StatelessWidget {
  final int currentIndex;
  final Function(int) onNavigate;

  const AppBottomNavCompact({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;
    final labelTertiary =
        isDarkMode ? IOSDarkColors.labelTertiary : IOSColors.labelTertiary;
    final systemBg = isDarkMode
        ? IOSDarkColors.systemBackground
        : IOSColors.systemBackground;

    return Container(
      decoration: BoxDecoration(
        color: systemBg,
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCompactNavItem(
                  0, CupertinoIcons.house, 'Home', primaryColor, labelTertiary),
              _buildCompactNavItem(1, CupertinoIcons.list_bullet,
                  'Transactions', primaryColor, labelTertiary),
              _buildCompactNavItem(2, CupertinoIcons.cube_box, 'Inventory',
                  primaryColor, labelTertiary),
              _buildCompactNavItem(3, CupertinoIcons.chart_bar, 'Reports',
                  primaryColor, labelTertiary),
              _buildCompactNavItem(4, CupertinoIcons.settings, 'Settings',
                  primaryColor, labelTertiary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactNavItem(int index, IconData icon, String label,
      Color primaryColor, Color labelTertiary) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onNavigate(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? primaryColor : labelTertiary,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? primaryColor : labelTertiary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

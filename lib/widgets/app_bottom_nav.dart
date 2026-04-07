import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ismart_shop/utils/ios_theme.dart';

/// Modern Minimal Bottom Navigation
/// Clean design with centered active indicator and smooth animations
class AppBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onNavigate;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
  });

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final List<_NavItemData> _navItems = const [
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
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didUpdateWidget(AppBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;
    final surfaceColor =
        isDarkMode ? IOSDarkColors.systemBackground : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (index) {
              return _buildNavItem(
                index: index,
                item: _navItems[index],
                isDarkMode: isDarkMode,
                primaryColor: primaryColor,
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required _NavItemData item,
    required bool isDarkMode,
    required Color primaryColor,
  }) {
    final isSelected = widget.currentIndex == index;
    final inactiveColor =
        isDarkMode ? IOSDarkColors.labelTertiary : IOSColors.labelTertiary;

    return Expanded(
      child: InkWell(
        onTap: () => widget.onNavigate(index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withOpacity(isDarkMode ? 0.2 : 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  size: 24,
                  color: isSelected ? primaryColor : inactiveColor,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 20 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (isSelected)
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                  child: Text(item.label),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItemData({
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

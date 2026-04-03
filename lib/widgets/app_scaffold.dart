import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ismart_shop/utils/ios_theme.dart';
import 'package:ismart_shop/widgets/app_sidebar.dart';
import 'package:ismart_shop/widgets/app_bottom_nav.dart';

/// Unified Scaffold Widget
/// Combines sidebar navigation, bottom navigation, and app bar
/// Used across all pages for consistent navigation experience
class AppScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final int currentIndex;
  final Function(int) onNavigate;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final bool showBottomNav;
  final bool showSidebarToggle;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final PreferredSizeWidget? bottom;

  const AppScaffold({
    super.key,
    required this.body,
    required this.title,
    required this.currentIndex,
    required this.onNavigate,
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.showBottomNav = true,
    this.showSidebarToggle = true,
    this.floatingActionButton,
    this.backgroundColor,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDarkMode
            ? IOSDarkColors.secondarySystemBackground
            : IOSColors.secondarySystemBackground);
    final primaryColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;

    return Scaffold(
      backgroundColor: bgColor,
      drawer: AppSidebar(
        currentIndex: currentIndex,
        onNavigate: onNavigate,
      ),
      appBar: showBackButton || showSidebarToggle
          ? AppBar(
              backgroundColor: bgColor,
              elevation: 0,
              leading: leading ??
                  (showBackButton
                      ? IconButton(
                          icon: Icon(
                            CupertinoIcons.back,
                            color: primaryColor,
                          ),
                          onPressed: () => Navigator.pop(context),
                        )
                      : (showSidebarToggle
                          ? IconButton(
                              icon: Icon(
                                CupertinoIcons.line_horizontal_3,
                                color: primaryColor,
                              ),
                              onPressed: () {
                                Scaffold.of(context).openDrawer();
                              },
                            )
                          : null)),
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
              bottom: bottom,
            )
          : null,
      body: body,
      bottomNavigationBar: showBottomNav
          ? AppBottomNav(
              currentIndex: currentIndex,
              onNavigate: onNavigate,
            )
          : null,
      floatingActionButton: floatingActionButton,
    );
  }
}

/// Minimal App Scaffold (without app bar but with navigation)
class AppScaffoldMinimal extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final Function(int) onNavigate;
  final bool showBottomNav;
  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const AppScaffoldMinimal({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onNavigate,
    this.showBottomNav = true,
    this.backgroundColor,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDarkMode
            ? IOSDarkColors.secondarySystemBackground
            : IOSColors.secondarySystemBackground);

    return Scaffold(
      backgroundColor: bgColor,
      drawer: AppSidebar(
        currentIndex: currentIndex,
        onNavigate: onNavigate,
      ),
      body: body,
      bottomNavigationBar: showBottomNav
          ? AppBottomNav(
              currentIndex: currentIndex,
              onNavigate: onNavigate,
            )
          : null,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}

/// Full Screen Scaffold (no navigation)
class AppScaffoldFull extends StatelessWidget {
  final Widget body;
  final Color? backgroundColor;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const AppScaffoldFull({
    super.key,
    required this.body,
    this.backgroundColor,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}

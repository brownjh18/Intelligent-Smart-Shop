import 'package:flutter/material.dart';

/// App Color Palette - Following iOS Human Interface Guidelines
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF007AFF);
  static const Color primaryDark = Color(0xFF0056B3);
  static const Color secondary = Color(0xFF4CAF50);
  static const Color accent = Color(0xFFFF9800);

  // Light Mode Background Colors
  static const Color background = Color(0xFFF2F2F7); // iOS secondary background
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Semantic Colors
  static const Color error = Color(0xFFFF3B30);
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);

  // Text Colors - Light Mode
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textHint = Color(0xFFC7C7CC);

  // Transaction Colors
  static const Color saleColor = Color(0xFF34C759);
  static const Color expenseColor = Color(0xFFFF3B30);
  static const Color purchaseColor = Color(0xFF007AFF);

  // Border and Divider
  static const Color divider = Color(0xFFE5E5EA);
  static const Color border = Color(0xFFE5E5EA);
}

/// Dark Mode Colors - Following iOS Human Interface Guidelines
/// Uses true black for main background (OLED optimization)
/// Uses elevated surfaces for grouped content
class AppDarkColors {
  // Primary Colors - Slightly brighter for dark mode visibility
  static const Color primary = Color(0xFF0A84FF);
  static const Color primaryDark = Color(0xFF0066CC);
  static const Color secondary = Color(0xFF30D158);
  static const Color accent = Color(0xFFFFD60A);

  // Dark Mode Background Colors - Following iOS HIG
  // True black for main background (OLED)
  static const Color background = Color(0xFF000000);
  // Elevated gray for grouped content
  static const Color surface = Color(0xFF1C1C1E);
  // Tertiary for nested content
  static const Color cardBackground = Color(0xFF1C1C1E);
  // Fill colors
  static const Color fillBackground = Color(0xFF2C2C2E);
  static const Color fillSecondary = Color(0xFF3A3A3C);

  // Semantic Colors - Adjusted for dark mode
  static const Color error = Color(0xFFFF453A);
  static const Color success = Color(0xFF30D158);
  static const Color warning = Color(0xFFFFD60A);

  // Text Colors - Proper contrast for dark mode
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textHint = Color(0xFF636366);

  // Transaction Colors
  static const Color saleColor = Color(0xFF30D158);
  static const Color expenseColor = Color(0xFFFF453A);
  static const Color purchaseColor = Color(0xFF0A84FF);

  // Border and Divider
  static const Color divider = Color(0xFF38383A);
  static const Color border = Color(0xFF38383A);

  // App Bar
  static const Color appBarBackground = Color(0xFF1C1C1E);
}

/// Helper class for dynamic color switching
class AppThemeColors {
  /// Get primary color based on brightness
  static Color getPrimary(BuildContext context, {bool darkOverride = false}) {
    final isDark =
        darkOverride || Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppDarkColors.primary : AppColors.primary;
  }

  /// Get background color
  static Color getBackground(BuildContext context,
      {bool darkOverride = false}) {
    final isDark =
        darkOverride || Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppDarkColors.background : AppColors.background;
  }

  /// Get surface/card color
  static Color getSurface(BuildContext context, {bool darkOverride = false}) {
    final isDark =
        darkOverride || Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppDarkColors.surface : AppColors.surface;
  }

  /// Get primary text color
  static Color getTextPrimary(BuildContext context,
      {bool darkOverride = false}) {
    final isDark =
        darkOverride || Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
  }

  /// Get secondary text color
  static Color getTextSecondary(BuildContext context,
      {bool darkOverride = false}) {
    final isDark =
        darkOverride || Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppDarkColors.textSecondary : AppColors.textSecondary;
  }

  /// Get error color
  static Color getError(BuildContext context, {bool darkOverride = false}) {
    final isDark =
        darkOverride || Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppDarkColors.error : AppColors.error;
  }

  /// Get success color
  static Color getSuccess(BuildContext context, {bool darkOverride = false}) {
    final isDark =
        darkOverride || Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppDarkColors.success : AppColors.success;
  }

  /// Check if dark mode is active
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}

class AppTextStyles {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
}

class AppDarkTextStyles {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppDarkColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppDarkColors.textPrimary,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppDarkColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppDarkColors.textPrimary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppDarkColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: AppDarkColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: AppDarkColors.textSecondary,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppDarkColors.textPrimary,
  );
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppBorderRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 24;
}

class AppIcons {
  static const String home = 'home';
  static const String add = 'add';
  static const String transactions = 'list';
  static const String reports = 'chart';
  static const String settings = 'settings';
  static const String voice = 'mic';
  static const String text = 'edit';
}

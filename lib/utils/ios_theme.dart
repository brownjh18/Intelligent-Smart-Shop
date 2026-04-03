import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// iOS Design Theme Configuration
/// Provides consistent iOS-style colors, typography, and spacing
/// Following Apple Human Interface Guidelines for iOS Dark Mode

class IOSColors {
  // Primary Colors
  static const Color primary = Color(0xFF007AFF);
  static const Color primaryDark = Color(0xFF0056B3);
  static const Color secondary = Color(0xFF34C759);
  static const Color tertiary = Color(0xFFAF52DE);

  // Background Colors
  static const Color systemBackground = Color(0xFFFFFFFF);
  static const Color secondarySystemBackground = Color(0xFFF2F2F7);
  static const Color tertiarySystemBackground = Color(0xFFE5E5EA);
  static const Color groupTableBackground = Color(0xFFF9F9F9);

  // Text Colors
  static const Color labelPrimary = Color(0xFF000000);
  static const Color labelSecondary = Color(0xFF8E8E93);
  static const Color labelTertiary = Color(0xFFC7C7CC);
  static const Color labelQuaternary = Color(0xFFE5E5EA);

  // Semantic Colors
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF007AFF);

  // Transaction Colors
  static const Color saleColor = Color(0xFF34C759);
  static const Color expenseColor = Color(0xFFFF3B30);
  static const Color purchaseColor = Color(0xFF007AFF);
}

/// Dark Mode iOS Colors - Following Apple Human Interface Guidelines
/// Uses true black for main background (OLED optimization)
/// Uses elevated surfaces for grouped content
class IOSDarkColors {
  // Primary Colors - Slightly brighter for dark mode
  static const Color primary = Color(0xFF0A84FF);
  static const Color primaryDark = Color(0xFF0066CC);
  static const Color secondary = Color(0xFF30D158);
  static const Color tertiary = Color(0xFFBF5AF2);

  // Background Colors - Following iOS HIG
  // True black for main background (OLED)
  static const Color systemBackground = Color(0xFF000000);
  // Elevated gray for grouped content
  static const Color secondarySystemBackground = Color(0xFF1C1C1E);
  // Tertiary for nested content
  static const Color tertiarySystemBackground = Color(0xFF2C2C2E);
  // Slightly lighter for cards/surfaces
  static const Color groupTableBackground = Color(0xFF1C1C1E);
  // Card surface color
  static const Color cardBackground = Color(0xFF1C1C1E);
  // Fill colors for various elements
  static const Color fillBackground = Color(0xFF2C2C2E);
  static const Color fillSecondary = Color(0xFF3A3A3C);
  static const Color fillTertiary = Color(0xFF48484A);

  // Text Colors - Proper contrast for dark mode
  static const Color labelPrimary = Color(0xFFFFFFFF);
  static const Color labelSecondary = Color(0xFF8E8E93);
  static const Color labelTertiary = Color(0xFF636366);
  static const Color labelQuaternary = Color(0xFF48484A);

  // Semantic Colors - Adjusted for dark mode visibility
  static const Color success = Color(0xFF30D158);
  static const Color warning = Color(0xFFFFD60A);
  static const Color error = Color(0xFFFF453A);
  static const Color info = Color(0xFF0A84FF);

  // Transaction Colors
  static const Color saleColor = Color(0xFF30D158);
  static const Color expenseColor = Color(0xFFFF453A);
  static const Color purchaseColor = Color(0xFF0A84FF);

  // Border and separator colors
  static const Color separator = Color(0xFF38383A);
  static const Color opaqueSeparator = Color(0xFF545458);
}

/// Helper class to get iOS colors based on brightness
/// Use this for consistent dark/light mode color switching
class IOSThemeColors {
  /// Get primary color based on brightness
  static Color getPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? IOSDarkColors.primary
        : IOSColors.primary;
  }

  /// Get secondary color based on brightness
  static Color getSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? IOSDarkColors.secondary
        : IOSColors.secondary;
  }

  /// Get main background color (true black in dark mode)
  static Color getBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? IOSDarkColors.systemBackground
        : IOSColors.systemBackground;
  }

  /// Get secondary/elevated background for grouped content
  static Color getSecondaryBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? IOSDarkColors.secondarySystemBackground
        : IOSColors.secondarySystemBackground;
  }

  /// Get tertiary background for nested content
  static Color getTertiaryBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? IOSDarkColors.tertiarySystemBackground
        : IOSColors.tertiarySystemBackground;
  }

  /// Get card background color
  static Color getCardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? IOSDarkColors.cardBackground
        : IOSColors.systemBackground;
  }

  /// Get fill background color
  static Color getFillBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? IOSDarkColors.fillBackground
        : IOSColors.secondarySystemBackground;
  }

  /// Get fill secondary color
  static Color getFillSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? IOSDarkColors.fillSecondary
        : IOSColors.tertiarySystemBackground;
  }

  /// Get primary text color
  static Color getLabelPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? IOSDarkColors.labelPrimary
        : IOSColors.labelPrimary;
  }

  /// Get secondary text color
  static Color getLabelSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? IOSDarkColors.labelSecondary
        : IOSColors.labelSecondary;
  }

  /// Get tertiary text color
  static Color getLabelTertiary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? IOSDarkColors.labelTertiary
        : IOSColors.labelTertiary;
  }

  /// Get quaternary text color
  static Color getLabelQuaternary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? IOSDarkColors.labelQuaternary
        : IOSColors.labelQuaternary;
  }

  /// Get success color
  static Color getSuccess(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? IOSDarkColors.success
        : IOSColors.success;
  }

  /// Get warning color
  static Color getWarning(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? IOSDarkColors.warning
        : IOSColors.warning;
  }

  /// Get error color
  static Color getError(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? IOSDarkColors.error
        : IOSColors.error;
  }

  /// Get sale/positive transaction color
  static Color getSaleColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? IOSDarkColors.saleColor
        : IOSColors.saleColor;
  }

  /// Get expense/negative transaction color
  static Color getExpenseColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? IOSDarkColors.expenseColor
        : IOSColors.expenseColor;
  }

  /// Get purchase color
  static Color getPurchaseColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? IOSDarkColors.purchaseColor
        : IOSColors.purchaseColor;
  }

  /// Get separator color
  static Color getSeparator(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? IOSDarkColors.separator
        : IOSColors.labelQuaternary;
  }

  /// Check if dark mode is active
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}

class IOSTextStyles {
  // Large Titles
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.37,
    color: IOSColors.labelPrimary,
  );

  // Titles
  static const TextStyle title1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.36,
    color: IOSColors.labelPrimary,
  );

  static const TextStyle title2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.35,
    color: IOSColors.labelPrimary,
  );

  static const TextStyle title3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.38,
    color: IOSColors.labelPrimary,
  );

  // Headlines
  static const TextStyle headline = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: IOSColors.labelPrimary,
  );

  // Bodies
  static const TextStyle body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: IOSColors.labelPrimary,
  );

  static const TextStyle callout = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: IOSColors.labelPrimary,
  );

  static const TextStyle subheadline = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: IOSColors.labelSecondary,
  );

  // Footnotes
  static const TextStyle footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: IOSColors.labelSecondary,
  );

  static const TextStyle caption1 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: IOSColors.labelSecondary,
  );

  static const TextStyle caption2 = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: IOSColors.labelTertiary,
  );
}

/// Text styles that automatically adapt to dark mode
class IOSTextStylesAdaptive {
  static TextStyle largeTitle(BuildContext context) {
    return IOSTextStyles.largeTitle.copyWith(
      color: IOSThemeColors.getLabelPrimary(context),
    );
  }

  static TextStyle title1(BuildContext context) {
    return IOSTextStyles.title1.copyWith(
      color: IOSThemeColors.getLabelPrimary(context),
    );
  }

  static TextStyle title2(BuildContext context) {
    return IOSTextStyles.title2.copyWith(
      color: IOSThemeColors.getLabelPrimary(context),
    );
  }

  static TextStyle title3(BuildContext context) {
    return IOSTextStyles.title3.copyWith(
      color: IOSThemeColors.getLabelPrimary(context),
    );
  }

  static TextStyle headline(BuildContext context) {
    return IOSTextStyles.headline.copyWith(
      color: IOSThemeColors.getLabelPrimary(context),
    );
  }

  static TextStyle body(BuildContext context) {
    return IOSTextStyles.body.copyWith(
      color: IOSThemeColors.getLabelPrimary(context),
    );
  }

  static TextStyle callout(BuildContext context) {
    return IOSTextStyles.callout.copyWith(
      color: IOSThemeColors.getLabelPrimary(context),
    );
  }

  static TextStyle subheadline(BuildContext context) {
    return IOSTextStyles.subheadline.copyWith(
      color: IOSThemeColors.getLabelSecondary(context),
    );
  }

  static TextStyle footnote(BuildContext context) {
    return IOSTextStyles.footnote.copyWith(
      color: IOSThemeColors.getLabelSecondary(context),
    );
  }

  static TextStyle caption1(BuildContext context) {
    return IOSTextStyles.caption1.copyWith(
      color: IOSThemeColors.getLabelSecondary(context),
    );
  }

  static TextStyle caption2(BuildContext context) {
    return IOSTextStyles.caption2.copyWith(
      color: IOSThemeColors.getLabelTertiary(context),
    );
  }
}

class IOSSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
}

class IOSBorderRadius {
  static const double small = 8.0;
  static const double medium = 10.0;
  static const double large = 14.0;
  static const double xl = 20.0;
  static const double xxxl = 28.0;
  static const double circular = 50.0;
}

/// iOS-style Card Container - Adapts to dark mode
class IOSCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final bool withBorder;

  const IOSCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.withBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    if (backgroundColor != null) {
      bgColor = backgroundColor!;
    } else if (isDarkMode) {
      bgColor = IOSDarkColors.cardBackground;
    } else {
      bgColor = IOSColors.systemBackground;
    }

    return Container(
      padding: padding ?? const EdgeInsets.all(IOSSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(IOSBorderRadius.large),
        border: withBorder
            ? Border.all(
                color: (isDarkMode
                        ? IOSDarkColors.labelQuaternary
                        : IOSColors.labelQuaternary)
                    .withOpacity(0.5))
            : null,
        boxShadow: isDarkMode
            ? null // No shadows in dark mode - iOS doesn't use them
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }
}

/// iOS-style Section Container - Adapts to dark mode
class IOSSection extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;

  const IOSSection({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isDarkMode
                ? IOSDarkColors.secondarySystemBackground
                : IOSColors.secondarySystemBackground),
        borderRadius: BorderRadius.circular(IOSBorderRadius.large),
      ),
      child: child,
    );
  }
}

/// iOS-style Button - Adapts to dark mode
class IOSButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isSecondary;
  final bool isDestructive;
  final Widget? leading;

  const IOSButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.isSecondary = false,
    this.isDestructive = false,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final errorColor = isDarkMode ? IOSDarkColors.error : IOSColors.error;
    final secondaryBg = isDarkMode
        ? IOSDarkColors.secondarySystemBackground
        : IOSColors.secondarySystemBackground;
    final primaryColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;
    final labelPrimary =
        isDarkMode ? IOSDarkColors.labelPrimary : IOSColors.labelPrimary;

    final bgColor = backgroundColor ??
        (isDestructive
            ? errorColor
            : (isSecondary ? secondaryBg : primaryColor));
    final txtColor = textColor ??
        (isSecondary
            ? labelPrimary
            : (isDestructive ? Colors.white : Colors.white));

    return CupertinoButton(
      onPressed: onPressed,
      color: bgColor,
      borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
      padding: const EdgeInsets.symmetric(
        horizontal: IOSSpacing.xl,
        vertical: IOSSpacing.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: IOSSpacing.sm),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: txtColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// iOS-style Outline Button
class IOSOutlineButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  final Color? borderColor;

  const IOSOutlineButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;
    final labelQuaternary =
        isDarkMode ? IOSDarkColors.labelQuaternary : IOSColors.labelQuaternary;
    final borderCol = borderColor ?? primaryColor;

    return CupertinoButton(
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
      padding: const EdgeInsets.symmetric(
        horizontal: IOSSpacing.xl,
        vertical: IOSSpacing.sm,
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: borderCol,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: IOSSpacing.xl - 1,
          vertical: IOSSpacing.sm,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: borderCol,
          ),
        ),
      ),
    );
  }
}

/// iOS-style Text Field - Adapts to dark mode
class IOSTextField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefix;
  final Widget? suffix;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const IOSTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    this.keyboardType,
    this.obscureText = false,
    this.prefix,
    this.suffix,
    this.onTap,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final labelTertiary =
        isDarkMode ? IOSDarkColors.labelTertiary : IOSColors.labelTertiary;
    final labelPrimary =
        isDarkMode ? IOSDarkColors.labelPrimary : IOSColors.labelPrimary;
    final secondaryBg = isDarkMode
        ? IOSDarkColors.secondarySystemBackground
        : IOSColors.secondarySystemBackground;
    final labelQuaternary =
        isDarkMode ? IOSDarkColors.labelQuaternary : IOSColors.labelQuaternary;

    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onTap: onTap,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      placeholderStyle: TextStyle(
        color: labelTertiary,
        fontSize: 17,
      ),
      style: TextStyle(
        color: labelPrimary,
        fontSize: 17,
      ),
      prefix: prefix != null
          ? Padding(
              padding: const EdgeInsets.only(left: IOSSpacing.md),
              child: prefix,
            )
          : null,
      suffix: suffix != null
          ? Padding(
              padding: const EdgeInsets.only(right: IOSSpacing.md),
              child: suffix,
            )
          : null,
      decoration: BoxDecoration(
        color: secondaryBg,
        borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
        border: Border.all(color: labelQuaternary),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: IOSSpacing.md,
        vertical: IOSSpacing.md,
      ),
    );
  }
}

/// iOS-style Summary Card for Dashboard - Adapts to dark mode
class IOSSummarCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;
  final IconData icon;

  const IOSSummarCard({
    super.key,
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(IOSSpacing.md),
      decoration: BoxDecoration(
        color:
            isDarkMode ? IOSDarkColors.cardBackground : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(IOSBorderRadius.large),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: isDarkMode
                      ? IOSDarkColors.labelSecondary
                      : IOSColors.labelSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(IOSBorderRadius.small),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: IOSSpacing.xs),
          Text(
            amount,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// iOS-style Quick Action Button - Adapts to dark mode
class IOSQuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  const IOSQuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final secondaryBg = isDarkMode
        ? IOSDarkColors.secondarySystemBackground
        : IOSColors.secondarySystemBackground;
    final labelPrimary =
        isDarkMode ? IOSDarkColors.labelPrimary : IOSColors.labelPrimary;
    final labelQuaternary =
        isDarkMode ? IOSDarkColors.labelQuaternary : IOSColors.labelQuaternary;
    final primaryColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;
    final iconCol = iconColor ?? primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(IOSSpacing.md),
        decoration: BoxDecoration(
          color: secondaryBg,
          borderRadius: BorderRadius.circular(IOSBorderRadius.large),
          border: Border.all(color: labelQuaternary.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: iconCol.withOpacity(0.15),
                borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
              ),
              child: Icon(
                icon,
                color: iconCol,
                size: 28,
              ),
            ),
            const SizedBox(height: IOSSpacing.xs),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: labelPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// iOS-style Transaction List Item - Adapts to dark mode
class IOSTransactionItem extends StatelessWidget {
  final String title;
  final String amount;
  final String time;
  final Color color;
  final IconData icon;
  final String? category;
  final VoidCallback? onTap;

  const IOSTransactionItem({
    super.key,
    required this.title,
    required this.amount,
    required this.time,
    required this.color,
    required this.icon,
    this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final systemBg =
        isDarkMode ? IOSDarkColors.cardBackground : IOSColors.systemBackground;
    final labelPrimary =
        isDarkMode ? IOSDarkColors.labelPrimary : IOSColors.labelPrimary;
    final labelSecondary =
        isDarkMode ? IOSDarkColors.labelSecondary : IOSColors.labelSecondary;
    final labelQuaternary =
        isDarkMode ? IOSDarkColors.labelQuaternary : IOSColors.labelQuaternary;
    final secondaryBg = isDarkMode
        ? IOSDarkColors.secondarySystemBackground
        : IOSColors.secondarySystemBackground;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: IOSSpacing.xs),
        decoration: BoxDecoration(
          color: systemBg,
          borderRadius: BorderRadius.circular(IOSBorderRadius.large),
          border: Border.all(color: labelQuaternary.withOpacity(0.5)),
          boxShadow: isDarkMode
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(IOSSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: IOSSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: labelPrimary,
                      ),
                    ),
                    if (category != null) ...[
                      const SizedBox(height: IOSSpacing.xxs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: IOSSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: secondaryBg,
                          borderRadius:
                              BorderRadius.circular(IOSBorderRadius.small),
                        ),
                        child: Text(
                          category!,
                          style: TextStyle(
                            fontSize: 12,
                            color: labelSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: IOSSpacing.xxs),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: labelSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// iOS-style Empty State - Adapts to dark mode
class IOSEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const IOSEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;
    final labelPrimary =
        isDarkMode ? IOSDarkColors.labelPrimary : IOSColors.labelPrimary;
    final labelSecondary =
        isDarkMode ? IOSDarkColors.labelSecondary : IOSColors.labelSecondary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(IOSBorderRadius.xxxl),
            ),
            child: Icon(
              icon,
              size: 56,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: IOSSpacing.lg),
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: labelPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: IOSSpacing.xs),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 15,
              color: labelSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: IOSSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}

/// iOS-style Period Selector Chip - Adapts to dark mode
class IOSPeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const IOSPeriodChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;
    final secondaryBg = isDarkMode
        ? IOSDarkColors.secondarySystemBackground
        : IOSColors.secondarySystemBackground;
    final labelQuaternary =
        isDarkMode ? IOSDarkColors.labelQuaternary : IOSColors.labelQuaternary;
    final labelPrimary =
        isDarkMode ? IOSDarkColors.labelPrimary : IOSColors.labelPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: IOSSpacing.lg,
          vertical: IOSSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : secondaryBg,
          borderRadius: BorderRadius.circular(IOSBorderRadius.circular),
          border: Border.all(
            color: isSelected ? primaryColor : labelQuaternary,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : labelPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

/// iOS-style Filter Chip - Adapts to dark mode
class IOSFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const IOSFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;
    final systemBg =
        isDarkMode ? IOSDarkColors.cardBackground : IOSColors.systemBackground;
    final labelQuaternary =
        isDarkMode ? IOSDarkColors.labelQuaternary : IOSColors.labelQuaternary;
    final labelPrimary =
        isDarkMode ? IOSDarkColors.labelPrimary : IOSColors.labelPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: IOSSpacing.md,
          vertical: IOSSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : systemBg,
          borderRadius: BorderRadius.circular(IOSBorderRadius.circular),
          border: Border.all(
            color: isSelected ? primaryColor : labelQuaternary,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : labelPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// iOS-style Stat Card for Reports - Adapts to dark mode
class IOSStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const IOSStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final labelSecondary =
        isDarkMode ? IOSDarkColors.labelSecondary : IOSColors.labelSecondary;

    return Container(
      padding: const EdgeInsets.all(IOSSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(IOSBorderRadius.large),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: labelSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: IOSSpacing.xs),
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

/// iOS-style Section Header - Adapts to dark mode
class IOSSectionHeader extends StatelessWidget {
  final String title;
  final bool hasAction;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const IOSSectionHeader({
    super.key,
    required this.title,
    this.hasAction = false,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final labelPrimary =
        isDarkMode ? IOSDarkColors.labelPrimary : IOSColors.labelPrimary;
    final primaryColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: IOSSpacing.md,
        vertical: IOSSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: labelPrimary,
            ),
          ),
          if (hasAction && actionLabel != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                actionLabel!,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// iOS-style Divider - Adapts to dark mode
class IOSDivider extends StatelessWidget {
  final double height;
  final double thickness;

  const IOSDivider({
    super.key,
    this.height = 1,
    this.thickness = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      color: isDarkMode ? IOSDarkColors.separator : IOSColors.labelQuaternary,
      height: height,
      thickness: thickness,
    );
  }
}

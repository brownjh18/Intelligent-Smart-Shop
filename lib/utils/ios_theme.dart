import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// iOS Design Theme Configuration
/// Provides consistent iOS-style colors, typography, and spacing

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

/// iOS-style Card Container
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
    return Container(
      padding: padding ?? const EdgeInsets.all(IOSSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor ?? IOSColors.systemBackground,
        borderRadius: BorderRadius.circular(IOSBorderRadius.large),
        border: withBorder
            ? Border.all(color: IOSColors.labelQuaternary.withOpacity(0.5))
            : null,
        boxShadow: [
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

/// iOS-style Section Container
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
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? IOSColors.systemBackground,
        borderRadius: BorderRadius.circular(IOSBorderRadius.large),
      ),
      child: child,
    );
  }
}

/// iOS-style Button
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
    final bgColor = backgroundColor ??
        (isDestructive
            ? IOSColors.error
            : (isSecondary
                ? IOSColors.secondarySystemBackground
                : IOSColors.primary));
    final txtColor = textColor ??
        (isSecondary
            ? IOSColors.labelPrimary
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
            color: borderColor ?? IOSColors.labelQuaternary,
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
            color: borderColor ?? IOSColors.primary,
          ),
        ),
      ),
    );
  }
}

/// iOS-style Text Field
class IOSTextField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefix;
  final Widget? suffix;
  final VoidCallback? onTap;

  const IOSTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    this.keyboardType,
    this.obscureText = false,
    this.prefix,
    this.suffix,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onTap: onTap,
      placeholderStyle: const TextStyle(
        color: IOSColors.labelTertiary,
        fontSize: 17,
      ),
      style: const TextStyle(
        color: IOSColors.labelPrimary,
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
        color: IOSColors.secondarySystemBackground,
        borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
        border: Border.all(color: IOSColors.labelQuaternary),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: IOSSpacing.md,
        vertical: IOSSpacing.md,
      ),
    );
  }
}

/// iOS-style Summary Card for Dashboard
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
    return Container(
      padding: const EdgeInsets.all(IOSSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
                style: const TextStyle(
                  fontSize: 13,
                  color: IOSColors.labelSecondary,
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

/// iOS-style Quick Action Button
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(IOSSpacing.md),
        decoration: BoxDecoration(
          color: IOSColors.secondarySystemBackground,
          borderRadius: BorderRadius.circular(IOSBorderRadius.large),
          border: Border.all(color: IOSColors.labelQuaternary.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (iconColor ?? IOSColors.primary).withOpacity(0.15),
                borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
              ),
              child: Icon(
                icon,
                color: iconColor ?? IOSColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: IOSSpacing.xs),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: IOSColors.labelPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// iOS-style Transaction List Item
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: IOSSpacing.xs),
        decoration: BoxDecoration(
          color: IOSColors.systemBackground,
          borderRadius: BorderRadius.circular(IOSBorderRadius.large),
          border: Border.all(color: IOSColors.labelQuaternary.withOpacity(0.5)),
          boxShadow: [
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: IOSColors.labelPrimary,
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
                          color: IOSColors.secondarySystemBackground,
                          borderRadius:
                              BorderRadius.circular(IOSBorderRadius.small),
                        ),
                        child: Text(
                          category!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: IOSColors.labelSecondary,
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
                    style: const TextStyle(
                      fontSize: 12,
                      color: IOSColors.labelSecondary,
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

/// iOS-style Empty State
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: IOSColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(IOSBorderRadius.xxxl),
            ),
            child: Icon(
              icon,
              size: 56,
              color: IOSColors.primary,
            ),
          ),
          const SizedBox(height: IOSSpacing.lg),
          Text(
            title,
            style: IOSTextStyles.headline,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: IOSSpacing.xs),
          Text(
            subtitle,
            style: IOSTextStyles.subheadline,
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

/// iOS-style Period Selector Chip
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: IOSSpacing.lg,
          vertical: IOSSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? IOSColors.primary
              : IOSColors.secondarySystemBackground,
          borderRadius: BorderRadius.circular(IOSBorderRadius.circular),
          border: Border.all(
            color: isSelected ? IOSColors.primary : IOSColors.labelQuaternary,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : IOSColors.labelPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

/// iOS-style Filter Chip
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: IOSSpacing.md,
          vertical: IOSSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? IOSColors.primary : IOSColors.systemBackground,
          borderRadius: BorderRadius.circular(IOSBorderRadius.circular),
          border: Border.all(
            color: isSelected ? IOSColors.primary : IOSColors.labelQuaternary,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : IOSColors.labelPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// iOS-style Stat Card for Reports
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
    return Container(
      padding: const EdgeInsets.all(IOSSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
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
                style: const TextStyle(
                  fontSize: 13,
                  color: IOSColors.labelSecondary,
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

/// iOS-style Section Header
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
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: IOSColors.labelPrimary,
            ),
          ),
          if (hasAction && actionLabel != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: IOSColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

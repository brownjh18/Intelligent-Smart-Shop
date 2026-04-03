import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ismart_shop/utils/ios_theme.dart';

/// iOS-style Navigation Bar
class IOSNavigationBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final Widget? leading;
  final Color? backgroundColor;
  final bool isLargeTitle;

  const IOSNavigationBar({
    super.key,
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.leading,
    this.backgroundColor,
    this.isLargeTitle = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        isLargeTitle ? kToolbarHeight + 20 : kToolbarHeight + 10,
      );

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final systemBg = isDarkMode
        ? IOSDarkColors.systemBackground
        : IOSColors.systemBackground;
    final labelQuaternary =
        isDarkMode ? IOSDarkColors.labelQuaternary : IOSColors.labelQuaternary;
    final labelPrimary =
        isDarkMode ? IOSDarkColors.labelPrimary : IOSColors.labelPrimary;
    final primaryColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? systemBg,
        border: Border(
          bottom: BorderSide(
            color: labelQuaternary.withOpacity(0.5),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: IOSSpacing.md,
            vertical: IOSSpacing.xs,
          ),
          child: Row(
            children: [
              if (automaticallyImplyLeading && Navigator.canPop(context))
                _buildBackButton(context)
              else if (leading != null)
                leading!,
              Expanded(
                child: isLargeTitle
                    ? Text(
                        title,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.37,
                          color: labelPrimary,
                        ),
                      )
                    : Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: labelPrimary,
                        ),
                      ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;

    return CupertinoButton(
      onPressed: () => Navigator.maybePop(context),
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.back,
            color: primaryColor,
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            'Back',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// iOS-style Large Title Navigation Bar
class IOSLargeTitleNavigationBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;

  const IOSLargeTitleNavigationBar({
    super.key,
    required this.title,
    this.actions,
    this.onBackPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 52);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final systemBg = isDarkMode
        ? IOSDarkColors.systemBackground
        : IOSColors.systemBackground;
    final labelQuaternary =
        isDarkMode ? IOSDarkColors.labelQuaternary : IOSColors.labelQuaternary;
    final labelPrimary =
        isDarkMode ? IOSDarkColors.labelPrimary : IOSColors.labelPrimary;
    final primaryColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: systemBg,
        border: Border(
          bottom: BorderSide(
            color: labelQuaternary.withOpacity(0.5),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: IOSSpacing.md,
            vertical: IOSSpacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (canPop)
                    CupertinoButton(
                      onPressed:
                          onBackPressed ?? () => Navigator.maybePop(context),
                      padding: EdgeInsets.zero,
                      child: Icon(
                        CupertinoIcons.back,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.37,
                        color: labelPrimary,
                      ),
                    ),
                  ),
                  if (actions != null) ...actions!,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// iOS-style Bottom Action Sheet
Future<T?> showIOSActionSheet<T>({
  required BuildContext context,
  required String title,
  required List<Widget> actions,
  String? cancelButtonText,
  VoidCallback? onCancel,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    builder: (context) => CupertinoActionSheet(
      title: title.isNotEmpty ? Text(title) : null,
      actions: actions,
      cancelButton: cancelButtonText != null
          ? CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                onCancel?.call();
              },
              child: Text(cancelButtonText),
            )
          : null,
    ),
  );
}

/// iOS-style Alert Dialog
Future<T?> showIOSAlertDialog<T>({
  required BuildContext context,
  required String title,
  required String content,
  required String confirmText,
  required VoidCallback onConfirm,
  String? cancelText,
  VoidCallback? onCancel,
  bool isDestructive = false,
}) {
  return showCupertinoDialog<T>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        if (cancelText != null)
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              onCancel?.call();
            },
            child: Text(cancelText),
          ),
        CupertinoDialogAction(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          isDefaultAction: true,
          isDestructiveAction: isDestructive,
          child: Text(confirmText),
        ),
      ],
    ),
  );
}

/// iOS-style Loading Indicator
class IOSLoadingIndicator extends StatelessWidget {
  final Color? color;
  final double size;

  const IOSLoadingIndicator({
    super.key,
    this.color,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CupertinoActivityIndicator(
        color: color,
        radius: size / 2,
      ),
    );
  }
}

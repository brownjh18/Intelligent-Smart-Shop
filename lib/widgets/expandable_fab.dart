import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ismart_shop/utils/ios_theme.dart';

/// An expandable floating action button that shows multiple action buttons
class ExpandableFab extends StatefulWidget {
  final List<FabAction> actions;
  final IconData icon;

  const ExpandableFab({
    super.key,
    required this.actions,
    this.icon = CupertinoIcons.add,
  });

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Action buttons
        ...widget.actions.asMap().entries.map((entry) {
          final index = entry.key;
          final action = entry.value;
          return _buildActionButton(
            context,
            action: action,
            index: index,
            isDarkMode: isDarkMode,
          );
        }),

        // Main FAB
        const SizedBox(height: 8),
        _buildMainFab(isDarkMode),
      ],
    );
  }

  Widget _buildMainFab(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [IOSDarkColors.primary, IOSDarkColors.primaryDark]
              : [IOSColors.primary, IOSColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDarkMode ? IOSDarkColors.primary : IOSColors.primary)
                .withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: 'expandableFab',
        onPressed: _toggle,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: AnimatedIcon(
          icon: AnimatedIcons.menu_close,
          progress: _animation,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required FabAction action,
    required int index,
    required bool isDarkMode,
  }) {
    // Calculate delay for staggered animation
    final delay = (index + 1) * 0.1;
    final animatedWidth = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animation,
        curve: Interval(
          delay.clamp(0.0, 0.5),
          (delay + 0.3).clamp(0.3, 0.8),
          curve: Curves.easeOut,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label
              Transform.scale(
                scale: animatedWidth.value,
                child: Opacity(
                  opacity: animatedWidth.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? IOSDarkColors.secondarySystemBackground
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      action.label,
                      style: TextStyle(
                        color: isDarkMode
                            ? IOSDarkColors.labelPrimary
                            : IOSColors.labelPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Button
              ScaleTransition(
                scale: animatedWidth,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: action.color != null
                          ? [action.color!, action.color!.withOpacity(0.7)]
                          : (isDarkMode
                              ? [
                                  IOSDarkColors.secondary,
                                  IOSDarkColors.secondary
                                ]
                              : [IOSColors.secondary, IOSColors.secondary]),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (action.color ??
                                (isDarkMode
                                    ? IOSDarkColors.secondary
                                    : IOSColors.secondary))
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: FloatingActionButton.small(
                    heroTag: 'fabAction$index',
                    onPressed: () {
                      _toggle();
                      action.onPressed();
                    },
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    child: Icon(
                      action.icon,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Represents a single action in the expandable FAB
class FabAction {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  const FabAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  });
}

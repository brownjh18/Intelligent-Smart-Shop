import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:ismart_shop/providers/auth_provider.dart';
import 'package:ismart_shop/utils/ios_theme.dart';
import 'package:ismart_shop/screens/profile_edit_screen.dart';

class ProfileDropdown extends StatefulWidget {
  final VoidCallback? onProfileTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onLogoutTap;
  final bool showLabels;

  const ProfileDropdown({
    super.key,
    this.onProfileTap,
    this.onSettingsTap,
    this.onLogoutTap,
    this.showLabels = false,
  });

  @override
  State<ProfileDropdown> createState() => _ProfileDropdownState();
}

class _ProfileDropdownState extends State<ProfileDropdown> {
  final GlobalKey _dropdownKey = GlobalKey();

  void _showDropdownMenu(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final RenderBox renderBox =
        _dropdownKey.currentContext?.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 4,
        offset.dx + size.width,
        offset.dy + size.height + 200,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: IOSColors.systemBackground,
      elevation: 8,
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          enabled: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authProvider.userModel?.displayName ?? 'User',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: IOSColors.labelPrimary,
                  ),
                ),
                Text(
                  authProvider.userModel?.email ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: IOSColors.labelSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'profile',
          child: _buildMenuItem(
            CupertinoIcons.person_fill,
            'Profile',
          ),
        ),
        PopupMenuItem<String>(
          value: 'settings',
          child: _buildMenuItem(
            CupertinoIcons.gear,
            'Settings',
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'logout',
          child: _buildMenuItem(
            CupertinoIcons.arrow_right_square_fill,
            'Logout',
            isDestructive: true,
          ),
        ),
      ],
    ).then((value) {
      if (value == 'profile') {
        _navigateToProfile(context);
      } else if (value == 'settings') {
        _navigateToSettings(context);
      } else if (value == 'logout') {
        _handleLogout(context);
      }
    });
  }

  Widget _buildMenuItem(IconData icon, String text,
      {bool isDestructive = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDestructive ? IOSColors.error : IOSColors.primary,
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: isDestructive ? IOSColors.error : IOSColors.labelPrimary,
          ),
        ),
      ],
    );
  }

  void _navigateToProfile(BuildContext context) {
    widget.onProfileTap?.call();
    if (widget.onProfileTap == null) {
      // Default behavior: navigate to profile edit screen
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => const ProfileEditScreen(),
        ),
      );
    }
  }

  void _navigateToSettings(BuildContext context) {
    widget.onSettingsTap?.call();
  }

  Future<void> _handleLogout(BuildContext context) async {
    widget.onLogoutTap?.call();
    if (widget.onLogoutTap == null) {
      // Default behavior
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();
      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/onboarding',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final hasProfileImage = authProvider.userModel?.profileImageUrl != null;

    return GestureDetector(
      key: _dropdownKey,
      onTap: () => _showDropdownMenu(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: IOSColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: hasProfileImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  authProvider.userModel!.profileImageUrl!,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      CupertinoIcons.person_fill,
                      color: IOSColors.primary,
                      size: 28,
                    );
                  },
                ),
              )
            : const Icon(
                CupertinoIcons.person_fill,
                color: IOSColors.primary,
                size: 28,
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:ismart_shop/providers/auth_provider.dart';
import 'package:ismart_shop/providers/language_provider.dart';
import 'package:ismart_shop/utils/ios_theme.dart';
import 'profile_edit_screen.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final languageProvider = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: IOSColors.secondarySystemBackground,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Account Section
            IOSSectionHeader(title: 'Account'),
            IOSCard(
              child: Column(
                children: [
                  _buildSettingsTileWithAction(
                    CupertinoIcons.person_fill,
                    'Name',
                    authProvider.userModel?.displayName ?? 'Not set',
                    CupertinoIcons.chevron_right,
                    () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                            builder: (_) => const ProfileEditScreen()),
                      );
                    },
                    trailing: _buildProfileImage(
                        authProvider.userModel?.profileImageUrl),
                  ),
                  _buildDivider(),
                  _buildSettingsTile(
                    CupertinoIcons.envelope_fill,
                    'Email',
                    authProvider.userModel?.email ?? 'Not set',
                    null,
                  ),
                  _buildDivider(),
                  _buildSettingsTileWithAction(
                    CupertinoIcons.globe,
                    'Language',
                    languageProvider.getLanguageName(
                      languageProvider.currentLanguage,
                    ),
                    CupertinoIcons.chevron_right,
                    () {
                      _showLanguagePicker(context, languageProvider);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: IOSSpacing.lg),
            // Preferences Section
            IOSSectionHeader(title: 'Preferences'),
            IOSCard(
              child: Column(
                children: [
                  _buildSettingsSwitch(
                    CupertinoIcons.bell_fill,
                    'Daily Summary Notifications',
                    'Get a summary of your daily transactions',
                    _notificationsEnabled,
                    (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                  ),
                  _buildDivider(),
                  _buildSettingsTile(
                    CupertinoIcons.info_circle_fill,
                    'App Version',
                    '1.0.0',
                    null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: IOSSpacing.lg),
            // Help Section
            IOSSectionHeader(title: 'Help & Support'),
            IOSCard(
              child: Column(
                children: [
                  _buildSettingsTileWithAction(
                    CupertinoIcons.question_circle_fill,
                    'How to use',
                    'Learn how to record transactions',
                    CupertinoIcons.chevron_right,
                    () {
                      _showHowToUseDialog();
                    },
                  ),
                  _buildDivider(),
                  _buildSettingsTileWithAction(
                    CupertinoIcons.doc_text_fill,
                    'Privacy Policy',
                    'Read our privacy policy',
                    CupertinoIcons.chevron_right,
                    () {},
                  ),
                  _buildDivider(),
                  _buildSettingsTileWithAction(
                    CupertinoIcons.envelope_fill,
                    'Contact Us',
                    'Get help and support',
                    CupertinoIcons.chevron_right,
                    () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: IOSSpacing.xl),
            // Logout Button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: IOSSpacing.md),
              child: IOSButton(
                title: 'Logout',
                onPressed: () async {
                  await authProvider.logout();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    CupertinoPageRoute(
                        builder: (_) => const OnboardingScreen()),
                    (route) => false,
                  );
                },
                isDestructive: true,
                leading: const Icon(
                  CupertinoIcons.arrow_right_circle_fill,
                  color: IOSColors.error,
                ),
              ),
            ),
            const SizedBox(height: IOSSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String subtitle,
    Widget? trailing,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: IOSSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: IOSColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
            ),
            child: Icon(icon, color: IOSColors.primary, size: 20),
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
                    fontWeight: FontWeight.w500,
                    color: IOSColors.labelPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: IOSColors.labelSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildSettingsTileWithAction(
    IconData icon,
    String title,
    String subtitle,
    IconData actionIcon,
    VoidCallback onTap, {
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: IOSSpacing.sm),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: IOSColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
              ),
              child: Icon(icon, color: IOSColors.primary, size: 20),
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
                      fontWeight: FontWeight.w500,
                      color: IOSColors.labelPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: IOSColors.labelSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
            if (trailing == null)
              Icon(actionIcon, color: IOSColors.labelTertiary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage(String? imageUrl) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: IOSColors.labelQuaternary,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderIcon();
                },
              )
            : _buildPlaceholderIcon(),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: IOSColors.tertiarySystemBackground,
      ),
      child: const Icon(
        CupertinoIcons.person_fill,
        size: 20,
        color: IOSColors.labelTertiary,
      ),
    );
  }

  Widget _buildSettingsSwitch(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: IOSSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: IOSColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
            ),
            child: Icon(icon, color: IOSColors.primary, size: 20),
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
                    fontWeight: FontWeight.w500,
                    color: IOSColors.labelPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: IOSColors.labelSecondary,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: IOSColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: IOSColors.labelQuaternary.withOpacity(0.5),
      height: 1,
    );
  }

  void _showLanguagePicker(
    BuildContext context,
    LanguageProvider languageProvider,
  ) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => Container(
        height: 200,
        decoration: BoxDecoration(
          color: IOSColors.systemBackground,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(IOSBorderRadius.large),
          ),
        ),
        child: CupertinoPicker(
          itemExtent: 44,
          onSelectedItemChanged: (index) {
            final languages = ['en', 'lg'];
            if (index < languages.length) {
              languageProvider.setLanguage(languages[index]);
            }
          },
          children: [
            Center(
              child: Text(
                'English',
                style: TextStyle(
                  fontSize: 17,
                  color: languageProvider.currentLanguage == 'en'
                      ? IOSColors.labelPrimary
                      : IOSColors.labelTertiary,
                ),
              ),
            ),
            Center(
              child: Text(
                'Luganda',
                style: TextStyle(
                  fontSize: 17,
                  color: languageProvider.currentLanguage == 'lg'
                      ? IOSColors.labelPrimary
                      : IOSColors.labelTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHowToUseDialog() {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('How to Use iSmart Shop'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Recording Transactions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: IOSSpacing.sm),
              Text('1. Tap the microphone button on the home screen'),
              SizedBox(height: IOSSpacing.xs),
              Text('2. Speak your transaction clearly'),
              SizedBox(height: IOSSpacing.xs),
              Text('3. Review the extracted information'),
              SizedBox(height: IOSSpacing.xs),
              Text('4. Tap Save to record the transaction'),
              SizedBox(height: IOSSpacing.md),
              Text(
                'Example Phrases',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: IOSSpacing.sm),
              Text('• "Sold bread for 5000 shillings"'),
              Text('• "Spent 20000 on transport"'),
              Text('• "Sold milk to customer for 3000"'),
              SizedBox(height: IOSSpacing.md),
              Text(
                'Language Support',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: IOSSpacing.sm),
              Text('You can record transactions in English or Luganda. '
                  'Select your preferred language in Settings.'),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

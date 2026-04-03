import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:ismart_shop/providers/auth_provider.dart';
import 'package:ismart_shop/providers/language_provider.dart';
import 'package:ismart_shop/providers/theme_provider.dart';
import 'package:ismart_shop/utils/ios_theme.dart';
import 'package:ismart_shop/services/firestore_setup.dart';
import 'package:ismart_shop/services/openai_parser_service.dart';
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
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? IOSDarkColors.secondarySystemBackground
          : IOSColors.secondarySystemBackground,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Account Section
            const IOSSectionHeader(title: 'Account'),
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
            const IOSSectionHeader(title: 'Preferences'),
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
                  _buildSettingsSwitch(
                    CupertinoIcons.moon_fill,
                    'Dark Mode',
                    'Switch between light and dark theme',
                    themeProvider.isDarkMode,
                    (value) {
                      themeProvider.setDarkMode(value);
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
            // AI Configuration Section
            const IOSSectionHeader(title: 'AI Configuration'),
            IOSCard(
              child: Column(
                children: [
                  _buildSettingsTileWithAction(
                    CupertinoIcons.sparkles,
                    'OpenAI API Key',
                    OpenAIParserService.isApiKeyConfigured
                        ? 'API key configured'
                        : 'Not configured - using local AI',
                    CupertinoIcons.chevron_right,
                    () {
                      _showApiKeyDialog();
                    },
                  ),
                  _buildDivider(),
                  _buildSettingsTile(
                    CupertinoIcons.info_circle_fill,
                    'AI Parsing',
                    'Uses OpenAI GPT for better accuracy',
                    null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: IOSSpacing.lg),
            // Help Section
            const IOSSectionHeader(title: 'Help & Support'),
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
                  _buildDivider(),
                  _buildSettingsTileWithAction(
                    CupertinoIcons.cloud_fill,
                    'Initialize Database',
                    'Set up Firestore collections',
                    CupertinoIcons.chevron_right,
                    () {
                      _initializeFirestore();
                    },
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: IOSSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDarkMode ? IOSDarkColors.primary : IOSColors.primary)
                  .withOpacity(0.15),
              borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
            ),
            child: Icon(icon,
                color: isDarkMode ? IOSDarkColors.primary : IOSColors.primary,
                size: 20),
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
                    fontWeight: FontWeight.w500,
                    color: isDarkMode
                        ? IOSDarkColors.labelPrimary
                        : IOSColors.labelPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode
                        ? IOSDarkColors.labelSecondary
                        : IOSColors.labelSecondary,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: IOSSpacing.sm),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isDarkMode ? IOSDarkColors.primary : IOSColors.primary)
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
              ),
              child: Icon(icon,
                  color: isDarkMode ? IOSDarkColors.primary : IOSColors.primary,
                  size: 20),
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
                      fontWeight: FontWeight.w500,
                      color: isDarkMode
                          ? IOSDarkColors.labelPrimary
                          : IOSColors.labelPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode
                          ? IOSDarkColors.labelSecondary
                          : IOSColors.labelSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
            if (trailing == null)
              Icon(actionIcon,
                  color: isDarkMode
                      ? IOSDarkColors.labelTertiary
                      : IOSColors.labelTertiary,
                  size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage(String? imageUrl) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDarkMode
              ? IOSDarkColors.labelQuaternary
              : IOSColors.labelQuaternary,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDarkMode
            ? IOSDarkColors.tertiarySystemBackground
            : IOSColors.tertiarySystemBackground,
      ),
      child: Icon(
        CupertinoIcons.person_fill,
        size: 20,
        color:
            isDarkMode ? IOSDarkColors.labelTertiary : IOSColors.labelTertiary,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: IOSSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDarkMode ? IOSDarkColors.primary : IOSColors.primary)
                  .withOpacity(0.15),
              borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
            ),
            child: Icon(icon,
                color: isDarkMode ? IOSDarkColors.primary : IOSColors.primary,
                size: 20),
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
                    fontWeight: FontWeight.w500,
                    color: isDarkMode
                        ? IOSDarkColors.labelPrimary
                        : IOSColors.labelPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode
                        ? IOSDarkColors.labelSecondary
                        : IOSColors.labelSecondary,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor:
                isDarkMode ? IOSDarkColors.primary : IOSColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      color: (isDarkMode
              ? IOSDarkColors.labelQuaternary
              : IOSColors.labelQuaternary)
          .withOpacity(0.5),
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
        decoration: const BoxDecoration(
          color: IOSColors.systemBackground,
          borderRadius: BorderRadius.vertical(
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
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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

  void _initializeFirestore() async {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => const CupertinoAlertDialog(
        title: Text('Initializing Database'),
        content: Padding(
          padding: EdgeInsets.only(top: 10),
          child: CupertinoActivityIndicator(),
        ),
      ),
    );

    await FirestoreSetup.initializeCollections();

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Database Initialized'),
        content: const Text(
          'Firestore collections have been created. '
          'Your transactions will now be saved permanently!',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog() {
    final TextEditingController apiKeyController = TextEditingController();
    apiKeyController.text = OpenAIParserService.apiKey;

    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('OpenAI API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: IOSSpacing.sm),
            const Text(
              'Enter your OpenAI API key to enable AI-powered transaction parsing. '
              'You can get an API key from platform.openai.com',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: IOSSpacing.md),
            CupertinoTextField(
              controller: apiKeyController,
              placeholder: 'sk-...',
              obscureText: true,
              padding: const EdgeInsets.all(IOSSpacing.md),
              decoration: BoxDecoration(
                color: IOSColors.systemBackground,
                borderRadius: BorderRadius.circular(IOSBorderRadius.small),
                border: Border.all(
                  color: IOSColors.labelQuaternary.withOpacity(0.3),
                ),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              final apiKey = apiKeyController.text.trim();
              if (apiKey.isNotEmpty) {
                final success = await OpenAIParserService.saveApiKey(apiKey);
                if (success) {
                  setState(() {});
                  Navigator.pop(context);
                  _showSuccessDialog('API key saved successfully!');
                } else {
                  Navigator.pop(context);
                  _showErrorDialog('Failed to save API key. Please try again.');
                }
              } else {
                Navigator.pop(context);
                _showErrorDialog('Please enter a valid API key.');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

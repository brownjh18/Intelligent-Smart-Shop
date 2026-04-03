import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:ismart_shop/providers/language_provider.dart';
import 'package:ismart_shop/services/nlp_service.dart';
import 'package:ismart_shop/services/translation_service.dart';
import 'package:ismart_shop/utils/ios_theme.dart';
import 'package:ismart_shop/widgets/ios_app_bar.dart';
import 'package:ismart_shop/widgets/app_bottom_nav.dart';
import 'voice_recording_screen.dart';
import 'home_screen.dart';

class TextEntryScreen extends StatefulWidget {
  const TextEntryScreen({super.key});

  @override
  State<TextEntryScreen> createState() => _TextEntryScreenState();
}

class _TextEntryScreenState extends State<TextEntryScreen> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _processText() {
    if (!_formKey.currentState!.validate()) return;

    final inputText = _controller.text.trim();
    if (inputText.isEmpty) return;

    final processedText = TranslationService.processText(
      inputText,
      context.read<LanguageProvider>().currentLanguage,
    );

    final intent = NLPService.parseTransaction(processedText);

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => const VoiceRecordingScreen(),
      ),
    );
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        backgroundColor: IOSColors.secondarySystemBackground,
        appBar: IOSLargeTitleNavigationBar(
          title: 'Add Transaction',
          onBackPressed: _navigateToHome,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(IOSSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                IOSCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            CupertinoIcons.pencil_circle_fill,
                            color: IOSColors.primary,
                            size: 24,
                          ),
                          SizedBox(width: IOSSpacing.sm),
                          Text(
                            'Enter Details',
                            style: IOSTextStyles.title3,
                          ),
                        ],
                      ),
                      const SizedBox(height: IOSSpacing.sm),
                      // Language indicator
                      Consumer<LanguageProvider>(
                        builder: (context, languageProvider, _) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: IOSSpacing.md,
                              vertical: IOSSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: IOSColors.secondarySystemBackground,
                              borderRadius:
                                  BorderRadius.circular(IOSBorderRadius.small),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  CupertinoIcons.globe,
                                  color: IOSColors.primary,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Typing in: ${languageProvider.getLanguageName(languageProvider.currentLanguage)}',
                                  style: const TextStyle(
                                    color: IOSColors.labelPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: IOSSpacing.md),
                // Text input field
                IOSCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transaction Description',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: IOSColors.labelPrimary,
                        ),
                      ),
                      const SizedBox(height: IOSSpacing.sm),
                      Container(
                        decoration: BoxDecoration(
                          color: IOSColors.secondarySystemBackground,
                          borderRadius:
                              BorderRadius.circular(IOSBorderRadius.medium),
                          border: Border.all(
                            color: IOSColors.labelQuaternary.withOpacity(0.5),
                          ),
                        ),
                        child: TextFormField(
                          controller: _controller,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            hintText: 'e.g., Sold bread for 5000 shillings',
                            alignLabelWithHint: true,
                            contentPadding: EdgeInsets.all(IOSSpacing.md),
                            border: InputBorder.none,
                            hintStyle: TextStyle(
                              color: IOSColors.labelTertiary,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter transaction details';
                            }
                            return null;
                          },
                          style: const TextStyle(
                            fontSize: 16,
                            color: IOSColors.labelPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: IOSSpacing.md),
                // Examples section
                IOSCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            CupertinoIcons.lightbulb_fill,
                            color: IOSColors.warning,
                            size: 18,
                          ),
                          SizedBox(width: IOSSpacing.sm),
                          Text(
                            'Example phrases:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: IOSColors.labelPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: IOSSpacing.sm),
                      _buildExample('"Sold bread for 5000 shillings"'),
                      _buildExample('"Spent 20000 on transport"'),
                      _buildExample('"Sold milk to customer for 3000"'),
                      _buildExample('"Bought stock for 500000"'),
                    ],
                  ),
                ),
                const SizedBox(height: IOSSpacing.xl),
                // Submit button
                SizedBox(
                  height: 56,
                  child: CupertinoButton.filled(
                    onPressed: _processText,
                    borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
                    child: const Text(
                      'Review Transaction',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: IOSSpacing.lg),
              ],
            ),
          ),
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: 0, // Start at Home tab
          onNavigate: (index) {
            // Navigate based on index
            Navigator.pushReplacement(
              context,
              CupertinoPageRoute(
                builder: (_) => HomeScreen(initialTabIndex: index),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildExample(String example) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: IOSSpacing.xs),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.chevron_right,
            size: 12,
            color: IOSColors.labelTertiary,
          ),
          const SizedBox(width: IOSSpacing.xs),
          Text(
            example,
            style: const TextStyle(
              color: IOSColors.labelSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

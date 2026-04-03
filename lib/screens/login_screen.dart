import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:ismart_shop/providers/auth_provider.dart';
import 'package:ismart_shop/utils/ios_theme.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (mounted) {
      if (authProvider.isAuthenticated) {
        // Navigate immediately without delay for faster experience
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (_) => const HomeScreen()),
        );
      } else if (authProvider.error.isNotEmpty) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(authProvider.error);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Login Failed'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode
        ? IOSDarkColors.systemBackground
        : IOSColors.systemBackground;
    final labelPrimary =
        isDarkMode ? IOSDarkColors.labelPrimary : IOSColors.labelPrimary;
    final labelSecondary =
        isDarkMode ? IOSDarkColors.labelSecondary : IOSColors.labelSecondary;
    final labelTertiary =
        isDarkMode ? IOSDarkColors.labelTertiary : IOSColors.labelTertiary;
    final labelQuaternary =
        isDarkMode ? IOSDarkColors.labelQuaternary : IOSColors.labelQuaternary;
    final primaryColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: IOSSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: IOSSpacing.xxl),
                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(IOSBorderRadius.xl),
                  ),
                  child: Icon(
                    Icons.store,
                    size: 40,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: IOSSpacing.lg),
                // Title
                Text(
                  'Welcome Back',
                  style: IOSTextStyles.title1.copyWith(color: labelPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: IOSSpacing.xs),
                Text(
                  'Sign in to continue',
                  style:
                      IOSTextStyles.subheadline.copyWith(color: labelSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: IOSSpacing.xxxl),
                // Email field
                IOSTextField(
                  controller: _emailController,
                  placeholder: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    _passwordFocusNode.requestFocus();
                  },
                  prefix: Icon(CupertinoIcons.mail, color: labelTertiary),
                ),
                const SizedBox(height: IOSSpacing.md),
                // Password field
                IOSTextField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  placeholder: 'Password',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleLogin(),
                  prefix: Icon(CupertinoIcons.lock_fill, color: labelTertiary),
                  suffix: GestureDetector(
                    onTap: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    child: Icon(
                      _obscurePassword
                          ? CupertinoIcons.eye_slash
                          : CupertinoIcons.eye,
                      color: labelTertiary,
                    ),
                  ),
                ),
                const SizedBox(height: IOSSpacing.md),
                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: CupertinoButton(
                    onPressed: () {},
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontSize: 15,
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: IOSSpacing.xl),
                // Simple login button with loading indicator
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: CupertinoButton.filled(
                    onPressed: authProvider.isLoading || _isLoading
                        ? null
                        : _handleLogin,
                    borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CupertinoActivityIndicator(
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: IOSSpacing.xl),
                // Or divider
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: labelQuaternary,
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: IOSSpacing.md),
                      child: Text(
                        'or',
                        style: TextStyle(
                          fontSize: 15,
                          color: labelSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: labelQuaternary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: IOSSpacing.lg),
                // Register link
                Center(
                  child: CupertinoButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        CupertinoPageRoute(
                            builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(
                          fontSize: 15,
                          color: labelSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign Up',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: IOSSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

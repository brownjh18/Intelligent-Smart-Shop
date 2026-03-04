import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:ismart_shop/providers/auth_provider.dart';
import 'package:ismart_shop/utils/ios_theme.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Start button animation
    _animationController.forward();

    final authProvider = context.read<AuthProvider>();
    await authProvider.register(
      _emailController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
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
        // Reset animation on error
        _animationController.reset();
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(authProvider.error);
      } else {
        // Reset animation
        _animationController.reset();
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
        title: const Text('Registration Failed'),
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

    return Scaffold(
      backgroundColor: IOSColors.systemBackground,
      appBar: AppBar(
        backgroundColor: IOSColors.systemBackground,
        elevation: 0,
        leading: CupertinoButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Icon(
            CupertinoIcons.back,
            color: IOSColors.primary,
          ),
        ),
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
                // Logo with animation
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isLoading
                          ? 0.8 + (0.2 * (1 - _animationController.value))
                          : 1.0,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: IOSColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(IOSBorderRadius.xl),
                    ),
                    child: const Icon(
                      Icons.store,
                      size: 40,
                      color: IOSColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: IOSSpacing.lg),
                // Title
                const Text(
                  'Create Account',
                  style: IOSTextStyles.title1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: IOSSpacing.xs),
                const Text(
                  'Sign up to get started',
                  style: IOSTextStyles.subheadline,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: IOSSpacing.xxl),
                // Name field
                IOSTextField(
                  controller: _nameController,
                  placeholder: 'Full Name',
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    _emailFocusNode.requestFocus();
                  },
                  prefix: const Icon(CupertinoIcons.person_fill,
                      color: IOSColors.labelTertiary),
                ),
                const SizedBox(height: IOSSpacing.md),
                // Email field
                IOSTextField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  placeholder: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    _passwordFocusNode.requestFocus();
                  },
                  prefix: const Icon(CupertinoIcons.mail,
                      color: IOSColors.labelTertiary),
                ),
                const SizedBox(height: IOSSpacing.md),
                // Password field
                IOSTextField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  placeholder: 'Password',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    _confirmPasswordFocusNode.requestFocus();
                  },
                  prefix: const Icon(CupertinoIcons.lock_fill,
                      color: IOSColors.labelTertiary),
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
                      color: IOSColors.labelTertiary,
                    ),
                  ),
                ),
                const SizedBox(height: IOSSpacing.md),
                // Confirm Password field
                IOSTextField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocusNode,
                  placeholder: 'Confirm Password',
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleRegister(),
                  prefix: const Icon(CupertinoIcons.lock_fill,
                      color: IOSColors.labelTertiary),
                  suffix: GestureDetector(
                    onTap: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    child: Icon(
                      _obscureConfirmPassword
                          ? CupertinoIcons.eye_slash
                          : CupertinoIcons.eye,
                      color: IOSColors.labelTertiary,
                    ),
                  ),
                ),
                const SizedBox(height: IOSSpacing.xl),
                // Animated register button
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Stack(
                        children: [
                          // Success checkmark
                          Positioned.fill(
                            child: IgnorePointer(
                              child: AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  final progress = _animationController.value;
                                  final successOpacity = progress > 0.7
                                      ? (progress - 0.7) * 3.33
                                      : 0.0;
                                  return Opacity(
                                    opacity: successOpacity.clamp(0.0, 1.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: IOSColors.success,
                                        borderRadius: BorderRadius.circular(
                                            IOSBorderRadius.medium),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          CupertinoIcons.checkmark,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          // Button
                          Positioned.fill(
                            child: CupertinoButton.filled(
                              onPressed: authProvider.isLoading || _isLoading
                                  ? null
                                  : _handleRegister,
                              borderRadius:
                                  BorderRadius.circular(IOSBorderRadius.medium),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CupertinoActivityIndicator(
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: IOSSpacing.lg),
                // Login link
                Center(
                  child: CupertinoButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        CupertinoPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: const TextStyle(
                          fontSize: 15,
                          color: IOSColors.labelSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign In',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: IOSColors.primary,
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

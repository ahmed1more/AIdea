import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../main_shell.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      bool success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      if (success && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainShell()),
          (route) => false,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Sign up failed'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = Provider.of<SettingsProvider>(context);

    Widget formContent = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Logo ────────────────────────────────
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkSurface
                          : AppTheme.lightTextPrimary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: settings.logo(size: 40, applyTheme: false),
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms).scale(
                      begin: const Offset(0.8, 0.8),
                      duration: 500.ms,
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: 28),

                // ─── Headline ────────────────────────────
                Text(
                  'Create Account',
                  style: AppTheme.headline2(
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 150.ms).slideY(
                      begin: 0.15,
                      duration: 400.ms,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 8),

                Text(
                  'Join the curated editorial community.',
                  style: AppTheme.bodyMedium(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 250.ms),

                const SizedBox(height: 40),

                // ─── Full Name ────────────────────────────
                Text(
                  'FULL NAME',
                  style: AppTheme.labelSmall(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ).copyWith(letterSpacing: 2),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: AppTheme.bodyMedium(
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Your name',
                    filled: true,
                    fillColor:
                        isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your name';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 350.ms),

                const SizedBox(height: 20),

                // ─── Email ────────────────────────────────
                Text(
                  'EMAIL ADDRESS',
                  style: AppTheme.labelSmall(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ).copyWith(letterSpacing: 2),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTheme.bodyMedium(
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'you@email.com',
                    filled: true,
                    fillColor:
                        isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your email';
                    }
                    if (!value.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ).animate().fadeIn(delay: 450.ms),

                const SizedBox(height: 20),

                // ─── Password ─────────────────────────────
                Text(
                  'PASSWORD',
                  style: AppTheme.labelSmall(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ).copyWith(letterSpacing: 2),
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: AppTheme.bodyMedium(
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    filled: true,
                    fillColor:
                        isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter a password';
                    }
                    if (value.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ).animate().fadeIn(delay: 550.ms),

                const SizedBox(height: 32),

                // ─── Create Account Button ────────────────
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _handleSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                          foregroundColor:
                              isDark ? AppTheme.darkBg : Colors.white,
                          disabledBackgroundColor: (isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.lightTextPrimary)
                              .withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          elevation: 0,
                        ),
                        child: auth.isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: isDark ? AppTheme.darkBg : Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'CREATE ACCOUNT',
                                style: AppTheme.button()
                                    .copyWith(letterSpacing: 1),
                              ),
                      ),
                    );
                  },
                ).animate().fadeIn(delay: 600.ms),

                const SizedBox(height: 32),

                // ─── Sign In Link ─────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: AppTheme.bodyMedium(
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Text(
                        'Sign In',
                        style: AppTheme.labelLarge(
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 700.ms),
              ],
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: Stack(
        children: [
          // ─── Background ───────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/images/signup_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: (isDark ? AppTheme.darkBg : AppTheme.lightBg)
                  .withValues(alpha: isDark ? 0.6 : 0.7),
            ),
          ),

          // ─── Main Content ────────────────────────────
          SafeArea(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: formContent,
            ),
          ),
        ],
      ),
    );
  }
}


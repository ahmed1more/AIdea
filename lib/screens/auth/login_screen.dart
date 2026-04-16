import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../main_shell.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      bool success = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainShell()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Login failed'),
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
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkSurface
                          : AppTheme.lightTextPrimary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: settings.logo(size: 50, applyTheme: false),
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms).scale(
                      begin: const Offset(0.8, 0.8),
                      duration: 500.ms,
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: 32),

                // ─── Headline ────────────────────────────
                Text(
                  'Welcome Back',
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
                  'Access your editorial intelligence',
                  style: AppTheme.bodyMedium(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 250.ms),

                const SizedBox(height: 48),

                // ─── Email Label + Field ──────────────────
                Text(
                  'EMAIL ADDRESS',
                  style: AppTheme.labelSmall(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ).copyWith(letterSpacing: 2),
                ).animate().fadeIn(delay: 300.ms),
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
                    hintText: 'editor@aidea.com',
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
                ).animate().fadeIn(delay: 350.ms),

                const SizedBox(height: 24),

                // ─── Password Label + Field ───────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PASSWORD',
                      style: AppTheme.labelSmall(
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ).copyWith(letterSpacing: 2),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        'Forgot Password?',
                        style: AppTheme.bodySmall(
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms),
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
                      return 'Enter your password';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 450.ms),

                const SizedBox(height: 32),

                // ─── Sign In Button ───────────────────────
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _handleLogin,
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
                                BorderRadius.circular(AppTheme.radiusMd),
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
                            : Text('Sign In', style: AppTheme.button()),
                      ),
                    );
                  },
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 40),

                // ─── Sign Up Link ─────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTheme.bodyMedium(
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SignUpScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Sign Up',
                        style: AppTheme.labelLarge(
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 600.ms),
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


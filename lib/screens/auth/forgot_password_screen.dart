import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  bool _emailSent = false;

  bool get _useBackdropBlur =>
      !kIsWeb && defaultTargetPlatform != TargetPlatform.android;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resetPassword(
      _emailController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _isSubmitting = false;
        _emailSent = true;
      });
    } else {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ??
                'Failed to send reset email. Please try again.',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
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
            child: _emailSent ? _buildSuccessView(isDark) : _buildFormView(isDark, settings),
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
            child: _useBackdropBlur
                ? BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: formContent,
                  )
                : formContent,
          ),
        ],
      ),
    );
  }

  Widget _buildFormView(bool isDark, SettingsProvider settings) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Logo ────────────────────────────────
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightTextPrimary,
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

        // ─── Icon ─────────────────────────────────
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.lock_reset_rounded,
              size: 32,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
          ),
        ).animate().fadeIn(delay: 100.ms).scale(
              begin: const Offset(0.8, 0.8),
              duration: 400.ms,
              curve: Curves.easeOutBack,
            ),
        const SizedBox(height: 24),

        // ─── Headline ─────────────────────────────
        Text(
          'Reset Password',
          style: AppTheme.headline2(
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 150.ms).slideY(
              begin: 0.15,
              duration: 400.ms,
              curve: Curves.easeOut,
            ),

        const SizedBox(height: 8),

        Text(
          'Enter the email address associated with your account and we\'ll send you a link to reset your password.',
          style: AppTheme.bodyMedium(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 250.ms),

        const SizedBox(height: 36),

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
          autofocus: true,
          style: AppTheme.bodyMedium(
            color:
                isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'editor@aidea.com',
            filled: true,
            fillColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your email';
            }
            if (!value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ).animate().fadeIn(delay: 350.ms),

        const SizedBox(height: 32),

        // ─── Send Reset Link Button ───────────────
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _handleResetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
              foregroundColor: isDark ? AppTheme.darkBg : Colors.white,
              disabledBackgroundColor: (isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary)
                  .withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: isDark ? AppTheme.darkBg : Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text('Send Reset Link', style: AppTheme.button()),
          ),
        ).animate().fadeIn(delay: 400.ms),

        const SizedBox(height: 40),

        // ─── Back to Login Link ───────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_back_rounded,
              size: 16,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            const SizedBox(width: 6),
            _HoverUnderlineText(
              text: 'Back to Sign In',
              style: AppTheme.bodyMedium(
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }

  Widget _buildSuccessView(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Success Icon ──────────────────────────
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              size: 40,
              color: Colors.green,
            ),
          ),
        ).animate().fadeIn(duration: 500.ms).scale(
              begin: const Offset(0.6, 0.6),
              duration: 500.ms,
              curve: Curves.easeOutBack,
            ),
        const SizedBox(height: 32),

        // ─── Success Headline ──────────────────────
        Text(
          'Check Your Inbox',
          style: AppTheme.headline2(
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 150.ms).slideY(
              begin: 0.15,
              duration: 400.ms,
              curve: Curves.easeOut,
            ),

        const SizedBox(height: 12),

        Text(
          'We\'ve sent a password reset link to:',
          style: AppTheme.bodyMedium(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 250.ms),

        const SizedBox(height: 8),

        Text(
          _emailController.text.trim(),
          style: AppTheme.labelLarge(
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms),

        const SizedBox(height: 16),

        Text(
          'Please check your email and follow the instructions to reset your password. If you don\'t see the email, check your spam folder.',
          style: AppTheme.bodySmall(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 350.ms),

        const SizedBox(height: 40),

        // ─── Back to Login Button ──────────────────
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
              foregroundColor: isDark ? AppTheme.darkBg : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              elevation: 0,
            ),
            child: Text('Back to Sign In', style: AppTheme.button()),
          ),
        ).animate().fadeIn(delay: 400.ms),

        const SizedBox(height: 20),

        // ─── Resend Link ───────────────────────────
        Center(
          child: _HoverUnderlineText(
            text: 'Didn\'t receive the email? Resend',
            style: AppTheme.bodySmall(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
            onTap: () {
              setState(() {
                _emailSent = false;
              });
            },
          ),
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }
}

/// A reusable text widget that shows an underline on hover, like a hyperlink.
class _HoverUnderlineText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final VoidCallback onTap;

  const _HoverUnderlineText({
    required this.text,
    required this.style,
    required this.onTap,
  });

  @override
  State<_HoverUnderlineText> createState() => _HoverUnderlineTextState();
}

class _HoverUnderlineTextState extends State<_HoverUnderlineText> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: widget.style.copyWith(
            decoration:
                _isHovered ? TextDecoration.underline : TextDecoration.none,
            decorationColor: widget.style.color,
          ),
          child: Text(widget.text),
        ),
      ),
    );
  }
}

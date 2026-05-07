import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../theme/app_theme.dart';

class SignUpHeadline extends StatelessWidget {
  const SignUpHeadline({super.key});

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark
        ? (_isAndroid
            ? AppTheme.darkTextPrimary.withValues(alpha: 0.82)
            : AppTheme.darkTextSecondary)
        : AppTheme.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Get started on AIdea',
          style: AppTheme.headline2(
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 8),
        Text(
          'Create an account to access your editorial intelligence and connect with your team.',
          style: AppTheme.bodyMedium(color: secondaryTextColor),
        ).animate().fadeIn(delay: 150.ms),
      ],
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../theme/app_theme.dart';
import '../../signup_controller.dart';

class SignUpContactField extends StatelessWidget {
  const SignUpContactField({super.key});

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = context.read<SignUpController>();
    final secondaryTextColor = isDark
        ? (_isAndroid
            ? AppTheme.darkTextPrimary.withValues(alpha: 0.82)
            : AppTheme.darkTextSecondary)
        : AppTheme.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Mobile number or email address',
          style: AppTheme.labelLarge(
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary),
        ).animate().fadeIn(delay: 500.ms),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller.contactController,
          style: AppTheme.bodyMedium(
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary),
          decoration: controller.inputDecoration(
              context, isDark, 'Mobile number or email address'),
          validator: (value) =>
              value == null || value.isEmpty ? 'Required' : null,
        ).animate().fadeIn(delay: 550.ms),
        const SizedBox(height: 4),
        Text(
          'You may receive notifications from us.',
          style: AppTheme.bodySmall(color: secondaryTextColor),
        ).animate().fadeIn(delay: 600.ms),
      ],
    );
  }
}

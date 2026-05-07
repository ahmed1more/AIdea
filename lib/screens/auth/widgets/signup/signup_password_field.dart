import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../theme/app_theme.dart';
import '../../signup_controller.dart';

class SignUpPasswordField extends StatelessWidget {
  const SignUpPasswordField({super.key});

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = context.watch<SignUpController>();
    final secondaryTextColor = isDark
        ? (_isAndroid
            ? AppTheme.darkTextPrimary.withValues(alpha: 0.82)
            : AppTheme.darkTextSecondary)
        : AppTheme.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Password',
          style: AppTheme.labelLarge(
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary),
        ).animate().fadeIn(delay: 650.ms),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller.passwordController,
          obscureText: controller.obscurePassword,
          style: AppTheme.bodyMedium(
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary),
          decoration:
              controller.inputDecoration(context, isDark, 'Password').copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                controller.obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
              onPressed: () => controller.togglePasswordVisibility(),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Password is required';
            if (value.length < 8) return 'At least 8 characters';
            if (!RegExp(r'[A-Z]').hasMatch(value)) {
              return 'Include at least one uppercase letter';
            }
            if (!RegExp(r'[a-z]').hasMatch(value)) {
              return 'Include at least one lowercase letter';
            }
            if (!RegExp(r'[0-9]').hasMatch(value)) {
              return 'Include at least one number';
            }
            if (!RegExp(r'[!@#\$%\^&\*(),.?":{}|<>]').hasMatch(value)) {
              return 'Include at least one special character';
            }
            return null;
          },
        ).animate().fadeIn(delay: 700.ms),

        // ─── Password Strength Indicator ──────────────────────
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  child: LinearProgressIndicator(
                    value: controller.passwordStrength,
                    backgroundColor:
                        isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      controller.passwordStrength <= 0.25
                          ? Colors.red
                          : controller.passwordStrength <= 0.5
                              ? Colors.orange
                              : controller.passwordStrength <= 0.75
                                  ? Colors.amber
                                  : Colors.green,
                    ),
                  ),
                ),
              ),
            ),
            if (controller.passwordStrengthLabel.isNotEmpty) ...[
              const SizedBox(width: 10),
              Text(
                controller.passwordStrengthLabel,
                style: AppTheme.labelSmall(
                  color: controller.passwordStrength <= 0.25
                      ? Colors.red
                      : controller.passwordStrength <= 0.5
                          ? Colors.orange
                          : controller.passwordStrength <= 0.75
                              ? Colors.amber
                              : Colors.green,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Use 8+ characters with uppercase, lowercase, numbers & symbols',
          style: AppTheme.bodySmall(
            color: secondaryTextColor,
          ).copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

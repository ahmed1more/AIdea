import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../theme/app_theme.dart';
import '../../signup_controller.dart';

class SignUpGenderDropdown extends StatelessWidget {
  const SignUpGenderDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = context.watch<SignUpController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Gender',
          style: AppTheme.labelLarge(
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary),
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 6),
        controller
            .buildDropdown(
              context,
              isDark,
              'Select your gender',
              ['Female', 'Male'],
              controller.selectedGender,
              (v) => controller.setGender(v),
            )
            .animate()
            .fadeIn(delay: 450.ms),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../theme/app_theme.dart';
import '../../signup_controller.dart';

class SignUpNameFields extends StatelessWidget {
  const SignUpNameFields({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = context.read<SignUpController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Name',
          style: AppTheme.labelLarge(
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: controller.firstNameController,
                style: AppTheme.bodyMedium(
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary),
                decoration:
                    controller.inputDecoration(context, isDark, 'First name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ).animate().fadeIn(delay: 250.ms),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: controller.surnameController,
                style: AppTheme.bodyMedium(
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary),
                decoration:
                    controller.inputDecoration(context, isDark, 'Surname'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ).animate().fadeIn(delay: 250.ms),
            ),
          ],
        ),
      ],
    );
  }
}

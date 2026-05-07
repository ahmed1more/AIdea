import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../theme/app_theme.dart';
import '../../signup_controller.dart';

class SignUpDateOfBirth extends StatelessWidget {
  const SignUpDateOfBirth({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = context.watch<SignUpController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Date of birth',
          style: AppTheme.labelLarge(
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: controller.buildDropdown(
                context,
                isDark,
                'Day',
                List.generate(31, (i) => (i + 1).toString()),
                controller.selectedDay,
                (v) => controller.setDay(v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: controller.buildDropdown(
                context,
                isDark,
                'Month',
                [
                  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
                ],
                controller.selectedMonth,
                (v) => controller.setMonth(v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: controller.buildDropdown(
                context,
                isDark,
                'Year',
                List.generate(
                    100, (i) => (DateTime.now().year - i).toString()),
                controller.selectedYear,
                (v) => controller.setYear(v),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 350.ms),
      ],
    );
  }
}

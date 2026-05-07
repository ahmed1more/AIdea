import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../theme/app_theme.dart';
import '../../../../providers/settings_provider.dart';

class SignUpTopBar extends StatelessWidget {
  final VoidCallback onBack;

  const SignUpTopBar({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = Provider.of<SettingsProvider>(context);

    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary),
          onPressed: onBack,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 12),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightTextPrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: settings.logo(size: 32, applyTheme: false),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'AIdea',
          style: AppTheme.headline3(
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }
}

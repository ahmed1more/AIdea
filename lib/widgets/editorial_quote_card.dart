import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// A reusable editorial-style quote card used throughout the app.
class EditorialQuoteCard extends StatelessWidget {
  final String quote;
  final String attribution;

  const EditorialQuoteCard({
    super.key,
    required this.quote,
    this.attribution = 'WEEKLY INSPIRATION',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Quote copied to clipboard'),
            behavior: SnackBarBehavior.floating,
            width: 250,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        child: Stack(
          children: [
            // Decorative quote mark
            Positioned(
              top: -16,
              left: -8,
              child: Icon(
                Icons.format_quote,
                size: 100,
                color: (isDark ? Colors.white : AppTheme.lightTextPrimary)
                    .withValues(alpha: 0.04),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"$quote"',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  attribution.toUpperCase(),
                  style: AppTheme.labelSmall(color: AppTheme.teal).copyWith(
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

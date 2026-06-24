import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../theme/app_theme.dart';
import '../../../models/analytics_model.dart';

class InsightsCard extends StatelessWidget {
  final AnalyticsModel analytics;

  const InsightsCard({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    final insights = _generateInsights();

    if (insights.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  primary.withValues(alpha: 0.15),
                  AppTheme.darkSurface,
                ]
              : [
                  primary.withValues(alpha: 0.08),
                  Colors.white,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FaIcon(
                  FontAwesomeIcons.lightbulb,
                  color: primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Insights',
                style: AppTheme.titleLarge(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...insights.map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FaIcon(
                      insight.icon,
                      size: 14,
                      color: insight.color,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        insight.text,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  List<_Insight> _generateInsights() {
    final insights = <_Insight>[];

    // Hours saved this month
    if (analytics.thisMonthSavedHours > 0) {
      insights.add(_Insight(
        text: 'You saved ${analytics.thisMonthSavedHours.toStringAsFixed(1)} hours this month by using AI summaries.',
        icon: FontAwesomeIcons.clock,
        color: const Color(0xFF10B981),
      ));
    }

    // Favorite category percentage
    if (analytics.favoriteCategory != 'None' && analytics.notesCount > 0) {
      final favCount = analytics.categoryCount[analytics.favoriteCategory] ?? 0;
      if (favCount > 0) {
        final pct = (favCount / analytics.notesCount * 100).round();
        insights.add(_Insight(
          text: '$pct% of your summaries are ${analytics.favoriteCategory} videos.',
          icon: FontAwesomeIcons.chartPie,
          color: const Color(0xFF6366F1),
        ));
      }
    }

    // Streak
    if (analytics.currentStreak > 1) {
      insights.add(_Insight(
        text: 'You\'re on a ${analytics.currentStreak}-day learning streak! Keep it up! 🔥',
        icon: FontAwesomeIcons.fire,
        color: const Color(0xFFF59E0B),
      ));
    }

    // Weekly activity
    if (analytics.thisWeekVideos > 0) {
      insights.add(_Insight(
        text: 'You summarized ${analytics.thisWeekVideos} video${analytics.thisWeekVideos > 1 ? 's' : ''} this week.',
        icon: FontAwesomeIcons.video,
        color: const Color(0xFFF43F5E),
      ));
    }

    // Total hours saved
    if (analytics.totalSavedHours > 1) {
      insights.add(_Insight(
        text: 'Total time saved: ${analytics.totalSavedHours.toStringAsFixed(1)} hours across ${analytics.notesCount} videos.',
        icon: FontAwesomeIcons.hourglass,
        color: const Color(0xFF8B5CF6),
      ));
    }

    return insights.take(4).toList();
  }
}

class _Insight {
  final String text;
  final IconData icon;
  final Color color;

  const _Insight({required this.text, required this.icon, required this.color});
}

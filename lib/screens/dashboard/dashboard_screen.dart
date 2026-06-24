import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/analytics_provider.dart';
import '../../../theme/app_theme.dart';
import 'widgets/kpi_card.dart';
import 'widgets/category_pie_chart.dart';
import 'widgets/category_bar_chart.dart';
import 'widgets/weekly_activity_chart.dart';
import 'widgets/hours_saved_chart.dart';
import 'widgets/insights_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final analyticsProvider = context.watch<AnalyticsProvider>();
    final analytics = analyticsProvider.analytics;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    // ── Loading state ──
    if (analyticsProvider.isLoading && analytics == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading analytics…',
              style: AppTheme.bodyMedium(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // ── Empty state (no notes yet) ──
    if (analytics == null || analytics.notesCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.chartLine,
              size: 64,
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.2,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Dashboard',
              style: AppTheme.headline3(
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Analytics and Recommendations will appear here once you start creating notes.',
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Format hours for display
    final hoursStr = analytics.totalSavedHours >= 1
        ? '${analytics.totalSavedHours.toStringAsFixed(0)}h'
        : '${analytics.totalMinutes}m';

    // ── Populated dashboard ──
    // Returns content directly (no nested Scaffold) so it composes
    // cleanly inside the HomeScreen's own Scaffold body.
    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 28 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Text(
            'Dashboard',
            style: AppTheme.headline2(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your learning analytics at a glance',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // ── KPI Cards ──
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isWide ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isWide ? 1.3 : 1.15,
            children: [
              KpiCard(
                title: 'Videos',
                value: analytics.notesCount.toString(),
                subtitle: '${analytics.thisWeekVideos} this week',
                icon: FontAwesomeIcons.video,
                color: Theme.of(context).colorScheme.primary,
              ),
              KpiCard(
                title: 'Hours Saved',
                value: hoursStr,
                subtitle: '${analytics.thisMonthSavedHours.toStringAsFixed(1)}h this month',
                icon: FontAwesomeIcons.clock,
                color: const Color(0xFF10B981),
              ),
              KpiCard(
                title: 'Streak',
                value: analytics.currentStreak.toString(),
                subtitle: analytics.currentStreak > 0 ? 'days 🔥' : 'Start today!',
                icon: FontAwesomeIcons.fire,
                color: const Color(0xFFF59E0B),
              ),
              KpiCard(
                title: 'Favorite',
                value: _truncate(analytics.favoriteCategory, 12),
                subtitle: '${analytics.categoryCount[analytics.favoriteCategory] ?? 0} videos',
                icon: FontAwesomeIcons.heart,
                color: const Color(0xFFF43F5E),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Charts Section ──
          if (isWide)
            _buildWideCharts(analytics, isDark)
          else
            _buildNarrowCharts(analytics, isDark),

          const SizedBox(height: 24),

          // ── Insights ──
          InsightsCard(analytics: analytics),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Desktop: 2-column grid for charts
  Widget _buildWideCharts(dynamic analytics, bool isDark) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: WeeklyActivityChart(
                thisWeekVideos: analytics.thisWeekVideos,
                currentStreak: analytics.currentStreak,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CategoryPieChart(
                categoryCount: analytics.categoryCount,
                totalCount: analytics.notesCount,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CategoryBarChart(
                categoryCount: analytics.categoryCount,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: HoursSavedChart(
                totalSavedHours: analytics.totalSavedHours,
                thisMonthSavedHours: analytics.thisMonthSavedHours,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Mobile: stacked vertically
  Widget _buildNarrowCharts(dynamic analytics, bool isDark) {
    return Column(
      children: [
        WeeklyActivityChart(
          thisWeekVideos: analytics.thisWeekVideos,
          currentStreak: analytics.currentStreak,
        ),
        const SizedBox(height: 16),
        CategoryPieChart(
          categoryCount: analytics.categoryCount,
          totalCount: analytics.notesCount,
        ),
        const SizedBox(height: 16),
        CategoryBarChart(
          categoryCount: analytics.categoryCount,
        ),
        const SizedBox(height: 16),
        HoursSavedChart(
          totalSavedHours: analytics.totalSavedHours,
          thisMonthSavedHours: analytics.thisMonthSavedHours,
        ),
      ],
    );
  }

  String _truncate(String text, int maxLen) {
    if (text.length <= maxLen) return text;
    return '${text.substring(0, maxLen - 1)}…';
  }
}

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/analytics_model.dart';
import '../../providers/analytics_provider.dart';
import '../../theme/app_theme.dart';
import 'widgets/categories_distribution_chart.dart';
import 'widgets/hours_saved_chart.dart';
import 'widgets/insights_card.dart';
import 'widgets/kpi_card.dart';
import 'widgets/videos_per_category_chart.dart';
import 'widgets/weekly_activity_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final analyticsProvider = context.watch<AnalyticsProvider>();
    final analytics = analyticsProvider.analytics;

    if (analyticsProvider.isLoading) {
      return const _DashboardLoadingState();
    }

    // FIX: totalVideos removed — use notesCount directly
    if (analytics == null || analytics.notesCount == 0) {
      return const _DashboardEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final horizontalPadding = isWide ? 28.0 : 20.0;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            24,
            horizontalPadding,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DashboardHeader(analytics: analytics),
              const SizedBox(height: 24),
              _KpiCards(analytics: analytics),
              const SizedBox(height: 24),
              _DashboardCharts(analytics: analytics, isWide: isWide),
              const SizedBox(height: 24),
              InsightsCard(analytics: analytics),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final AnalyticsModel analytics;

  const _DashboardHeader({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: AppTheme.headline2(
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Your learning analytics at a glance',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}

class _KpiCards extends StatelessWidget {
  final AnalyticsModel analytics;

  const _KpiCards({required this.analytics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 640
            ? 2
            : 1;
        final cardWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              height: 150,
              child: KpiCard(
                title: 'Total Videos',
                // FIX: was analytics.totalVideos
                value: analytics.notesCount.toString(),
                subtitle: '${analytics.thisWeekVideos} this week',
                icon: FontAwesomeIcons.video,
                color: Theme.of(context).colorScheme.primary,
                animationIndex: 0,
              ),
            ),
            SizedBox(
              width: cardWidth,
              height: 150,
              child: KpiCard(
                title: 'Hours Saved',
                value: _formatHours(analytics.totalSavedHours),
                subtitle:
                    '${_formatHours(analytics.thisMonthSavedHours)} this month',
                icon: FontAwesomeIcons.clock,
                color: const Color(0xFF10B981),
                animationIndex: 1,
              ),
            ),
            SizedBox(
              width: cardWidth,
              height: 150,
              child: KpiCard(
                title: 'Current Streak',
                value: analytics.currentStreak.toString(),
                subtitle: analytics.currentStreak == 1
                    ? '1 day active'
                    : '${analytics.currentStreak} days active',
                icon: FontAwesomeIcons.fire,
                color: const Color(0xFFF59E0B),
                animationIndex: 2,
              ),
            ),
            SizedBox(
              width: cardWidth,
              height: 150,
              child: KpiCard(
                title: 'Favorite Category',
                value: _fallbackCategory(analytics.favoriteCategory),
                subtitle:
                    '${analytics.categoryCount[analytics.favoriteCategory] ?? 0} videos',
                icon: FontAwesomeIcons.heart,
                color: const Color(0xFFF43F5E),
                animationIndex: 3,
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatHours(double hours) {
    if (hours <= 0) return '0h';
    if (hours < 1) return '${(hours * 60).round()}m';
    if (hours < 10) return '${hours.toStringAsFixed(1)}h';
    return '${hours.round()}h';
  }

  String _fallbackCategory(String category) {
    if (category.trim().isEmpty || category == 'None') return 'None yet';
    return category;
  }
}

class _DashboardCharts extends StatelessWidget {
  final AnalyticsModel analytics;
  final bool isWide;

  const _DashboardCharts({required this.analytics, required this.isWide});

  @override
  Widget build(BuildContext context) {
    final charts = [
      WeeklyActivityChart(
        thisWeekVideos: analytics.thisWeekVideos,
        currentStreak: analytics.currentStreak,
      ),
      CategoriesDistributionChart(
        categoryCount: analytics.categoryCount,
        // FIX: was analytics.totalVideos
        totalVideos: analytics.notesCount,
      ),
      VideosPerCategoryChart(categoryCount: analytics.categoryCount),
      HoursSavedChart(
        totalSavedHours: analytics.totalSavedHours,
        thisMonthSavedHours: analytics.thisMonthSavedHours,
      ),
    ];

    if (!isWide) {
      return Column(
        children: [
          for (var i = 0; i < charts.length; i++) ...[
            charts[i],
            if (i != charts.length - 1) const SizedBox(height: 16),
          ],
        ],
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: charts[0]),
            const SizedBox(width: 16),
            Expanded(child: charts[1]),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: charts[2]),
            const SizedBox(width: 16),
            Expanded(child: charts[3]),
          ],
        ),
      ],
    );
  }
}

class _DashboardLoadingState extends StatelessWidget {
  const _DashboardLoadingState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading analytics...',
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
}

class _DashboardEmptyState extends StatelessWidget {
  const _DashboardEmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.chartLine,
              size: 64,
              color: color.withValues(alpha: 0.35),
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
            Text(
              'Analytics and recommendations will appear here once you summarize your first video.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

class CategoriesDistributionChart extends StatefulWidget {
  final Map<String, int> categoryCount;
  final int totalVideos;

  const CategoriesDistributionChart({
    super.key,
    required this.categoryCount,
    required this.totalVideos,
  });

  @override
  State<CategoriesDistributionChart> createState() =>
      _CategoriesDistributionChartState();
}

class _CategoriesDistributionChartState
    extends State<CategoriesDistributionChart> {
  int _touchedIndex = -1;

  static const _palette = [
    Color(0xFF0D9488),
    Color(0xFFE65C5C),
    Color(0xFF6366F1),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFF0EA5E9),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = _topCategoryEntries(widget.categoryCount);

    return _ChartPanel(
      title: 'Categories Distribution',
      child: entries.isEmpty
          ? const _EmptyChartMessage(message: 'No category data yet.')
          : Column(
              children: [
                SizedBox(
                  height: 210,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          if (!mounted) return;
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                response?.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex =
                                response!.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sectionsSpace: 3,
                      centerSpaceRadius: 46,
                      sections: _buildSections(entries),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _CategoryLegend(entries: entries, colors: _palette),
              ],
            ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.08, end: 0);
  }

  List<PieChartSectionData> _buildSections(
    List<MapEntry<String, int>> entries,
  ) {
    final safeTotal = widget.totalVideos > 0
        ? widget.totalVideos
        : entries.fold<int>(0, (sum, entry) => sum + entry.value);

    return List.generate(entries.length, (index) {
      final entry = entries[index];
      final isTouched = index == _touchedIndex;
      final percentage = safeTotal == 0 ? 0 : (entry.value / safeTotal * 100);

      return PieChartSectionData(
        color: _palette[index % _palette.length],
        value: entry.value.toDouble(),
        title: '${percentage.round()}%',
        radius: isTouched ? 62 : 54,
        titleStyle: GoogleFonts.inter(
          fontSize: isTouched ? 14 : 12,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      );
    });
  }

  List<MapEntry<String, int>> _topCategoryEntries(Map<String, int> counts) {
    final sorted = counts.entries.where((entry) => entry.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = sorted.take(5).toList();
    final otherCount = sorted
        .skip(5)
        .fold<int>(0, (sum, entry) => sum + entry.value);

    if (otherCount > 0) {
      top.add(MapEntry('Other', otherCount));
    }

    return top;
  }
}

class _CategoryLegend extends StatelessWidget {
  final List<MapEntry<String, int>> entries;
  final List<Color> colors;

  const _CategoryLegend({required this.entries, required this.colors});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 14,
      runSpacing: 10,
      children: List.generate(entries.length, (index) {
        final entry = entries[index];

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: colors[index % colors.length],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${entry.key} (${entry.value})',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _ChartPanel extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartPanel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.07),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.titleLarge(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _EmptyChartMessage extends StatelessWidget {
  final String message;

  const _EmptyChartMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 210,
      child: Center(
        child: Text(
          message,
          style: AppTheme.bodyMedium(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
      ),
    );
  }
}

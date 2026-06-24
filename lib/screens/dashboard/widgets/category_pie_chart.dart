import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_theme.dart';

/// A donut-style pie chart showing the category distribution of
/// summarised videos.
class CategoryPieChart extends StatefulWidget {
  final Map<String, int> categoryCount;
  final int totalCount;

  const CategoryPieChart({
    super.key,
    required this.categoryCount,
    required this.totalCount,
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _touchedIndex = -1;

  static const _palette = [
    Color(0xFF6366F1), // indigo
    Color(0xFFF43F5E), // rose
    Color(0xFF10B981), // emerald
    Color(0xFFF59E0B), // amber
    Color(0xFF8B5CF6), // violet
    Color(0xFF0EA5E9), // sky
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    // Sort by count, keep top 5, collapse remainder into "Others"
    final sorted = widget.categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = sorted.take(5).toList();
    final othersCount =
        sorted.skip(5).fold(0, (sum, item) => sum + item.value);
    if (othersCount > 0) {
      top.add(MapEntry('Others', othersCount));
    }

    if (top.isEmpty) return const SizedBox.shrink();

    final colors = [primary, ..._palette];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          // Title
          Text(
            'Categories Distribution',
            style: AppTheme.titleLarge(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 20),

          // Pie chart
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    if (!mounted) return;
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex =
                          response.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 3,
                centerSpaceRadius: 42,
                sections: List.generate(top.length, (i) {
                  final entry = top[i];
                  final safeTotal =
                      widget.totalCount > 0 ? widget.totalCount : 1;
                  final pct =
                      (entry.value / safeTotal * 100).toStringAsFixed(0);
                  final isTouched = i == _touchedIndex;

                  return PieChartSectionData(
                    color: colors[i % colors.length],
                    value: entry.value.toDouble(),
                    title: '$pct%',
                    radius: isTouched ? 58 : 50,
                    titleStyle: GoogleFonts.inter(
                      fontSize: isTouched ? 14 : 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: List.generate(top.length, (i) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors[i % colors.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${top[i].key} (${top[i].value})',
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
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }
}

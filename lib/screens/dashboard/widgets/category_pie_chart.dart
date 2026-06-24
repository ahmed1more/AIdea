import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class CategoryPieChart extends StatelessWidget {
  final Map<String, int> categoryCount;
  final int totalCount;

  const CategoryPieChart({super.key, required this.categoryCount, required this.totalCount});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Sort by count and take top 5
    final sortedCategories = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topCategories = sortedCategories.take(5).toList();
    final othersCount = sortedCategories.skip(5).fold(0, (sum, item) => sum + item.value);
    
    if (othersCount > 0) {
      topCategories.add(MapEntry('Others', othersCount));
    }

    if (topCategories.isEmpty) return const SizedBox.shrink();

    final colors = [
      Theme.of(context).colorScheme.primary,
      const Color(0xFF6366F1),
      const Color(0xFFF43F5E),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categories Distribution',
            style: AppTheme.titleLarge(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 42,
                sections: List.generate(topCategories.length, (i) {
                  final category = topCategories[i];
                  final safeTotal = totalCount > 0 ? totalCount : 1;
                  final percentage = (category.value / safeTotal * 100).toStringAsFixed(0);
                  
                  return PieChartSectionData(
                    color: colors[i % colors.length],
                    value: category.value.toDouble(),
                    title: '$percentage%',
                    radius: 50,
                    titleStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: List.generate(topCategories.length, (i) {
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
                    topCategories[i].key,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

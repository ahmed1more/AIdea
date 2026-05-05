import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../models/video_note.dart';
import '../../../theme/app_theme.dart';

class CategoryPieChart extends StatelessWidget {
  final List<VideoNote> notes;

  const CategoryPieChart({super.key, required this.notes});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Count notes by category
    final categoryCounts = <String, int>{};
    for (final note in notes) {
      for (final cat in note.categories) {
        categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
      }
    }

    // Sort by count and take top 5
    final sortedCategories = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topCategories = sortedCategories.take(5).toList();
    final othersCount = sortedCategories.skip(5).fold(0, (sum, item) => sum + item.value);
    
    if (othersCount > 0) {
      topCategories.add(MapEntry('Others', othersCount));
    }

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
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Categories Distribution',
            style: AppTheme.headline3(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: List.generate(topCategories.length, (i) {
                  final category = topCategories[i];
                  final percentage = (category.value / notes.length * 100).toStringAsFixed(1);
                  
                  return PieChartSectionData(
                    color: colors[i % colors.length],
                    value: category.value.toDouble(),
                    title: '$percentage%',
                    radius: 50,
                    titleStyle: const TextStyle(
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
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[i % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    topCategories[i].key,
                    style: AppTheme.bodySmall(
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

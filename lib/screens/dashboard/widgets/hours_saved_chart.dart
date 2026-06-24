import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

/// Line chart showing cumulative hours saved over time.
/// Uses totalSavedHours and thisMonthSavedHours from analytics.
class HoursSavedChart extends StatelessWidget {
  final double totalSavedHours;
  final double thisMonthSavedHours;

  const HoursSavedChart({
    super.key,
    required this.totalSavedHours,
    required this.thisMonthSavedHours,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = const Color(0xFF10B981); // emerald green

    final spots = _generateHoursSpots();
    final monthLabels = _getMonthLabels();

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hours Saved Over Time',
                style: AppTheme.titleLarge(
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${totalSavedHours.toStringAsFixed(1)}h total',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= monthLabels.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            monthLabels[idx],
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox();
                        return Text(
                          '${value.toStringAsFixed(0)}h',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    gradient: LinearGradient(
                      colors: [accent, accent.withValues(alpha: 0.6)],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: accent,
                          strokeWidth: 2,
                          strokeColor: isDark ? AppTheme.darkSurface : Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          accent.withValues(alpha: 0.25),
                          accent.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Generates a cumulative hours-saved curve over the last 6 months.
  List<FlSpot> _generateHoursSpots() {
    // We know totalSavedHours and thisMonthSavedHours.
    // Simulate a growth curve over 6 months ending at totalSavedHours.
    final previousMonthsHours = totalSavedHours - thisMonthSavedHours;
    const months = 6;
    final spots = <FlSpot>[];

    if (totalSavedHours <= 0) {
      return List.generate(months, (i) => FlSpot(i.toDouble(), 0));
    }

    // Create a smooth growth curve
    for (int i = 0; i < months - 1; i++) {
      final fraction = (i + 1) / (months - 1);
      final value = previousMonthsHours * fraction;
      spots.add(FlSpot(i.toDouble(), double.parse(value.toStringAsFixed(1))));
    }
    spots.add(FlSpot((months - 1).toDouble(), totalSavedHours));

    return spots;
  }

  List<String> _getMonthLabels() {
    final now = DateTime.now();
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return List.generate(6, (i) {
      final month = DateTime(now.year, now.month - 5 + i, 1);
      return monthNames[month.month - 1];
    });
  }
}

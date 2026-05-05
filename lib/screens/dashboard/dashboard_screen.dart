import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../providers/notes_provider.dart';
import '../../../theme/app_theme.dart';
import 'widgets/stat_card.dart';
import 'widgets/category_pie_chart.dart';
import 'widgets/activity_line_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notesProvider = context.watch<NotesProvider>();
    final notes = notesProvider.allNotes;

    if (notes.isEmpty) {
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

    // Calculate Stats
    final totalNotes = notes.length;
    final totalCategories = notesProvider.availableCategories.length - 1; // Subtract 'All'
    final favoriteNotes = notes.where((n) => n.isFavorite).length;
    final totalKeyPoints = notes.fold(0, (sum, n) => sum + n.keyPoints.length);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Learning Overview',
              style: AppTheme.headline3(
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            
            // Stats Row
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.4,
              children: [
                StatCard(
                  title: 'Total Notes',
                  value: totalNotes.toString(),
                  icon: FontAwesomeIcons.noteSticky,
                  color: Theme.of(context).colorScheme.primary,
                ),
                StatCard(
                  title: 'Categories',
                  value: totalCategories.toString(),
                  icon: FontAwesomeIcons.layerGroup,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                StatCard(
                  title: 'Favorites',
                  value: favoriteNotes.toString(),
                  icon: FontAwesomeIcons.solidHeart,
                  color: Theme.of(context).colorScheme.error,
                ),
                StatCard(
                  title: 'Key Insights',
                  value: totalKeyPoints.toString(),
                  icon: FontAwesomeIcons.lightbulb,
                  color: const Color(0xFFF59E0B),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Charts
            ActivityLineChart(notes: notes),
            const SizedBox(height: 24),
            CategoryPieChart(notes: notes),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/video_note.dart';
import '../providers/notes_provider.dart';
import '../screens/home/note_detail_screen.dart';

/// Editorial-inspired note card for the redesigned UI.
class NoteCard extends StatelessWidget {
  final VideoNote note;
  final int index;

  const NoteCard({
    super.key,
    required this.note,
    this.index = 0,
  });

  /// Pick an icon based on title keywords.
  IconData _categoryIcon() {
    final lower = note.videoTitle.toLowerCase();
    if (lower.contains('tech') || lower.contains('code') || lower.contains('program')) {
      return Icons.auto_awesome;
    } else if (lower.contains('business') || lower.contains('econom') || lower.contains('financ')) {
      return Icons.trending_up;
    } else if (lower.contains('design') || lower.contains('ui') || lower.contains('ux')) {
      return Icons.palette_outlined;
    } else if (lower.contains('science') || lower.contains('research')) {
      return Icons.science_outlined;
    } else if (lower.contains('health') || lower.contains('medical')) {
      return Icons.favorite_outline;
    } else if (lower.contains('edu') || lower.contains('learn') || lower.contains('study')) {
      return Icons.school_outlined;
    }
    return Icons.article_outlined;
  }

  /// Pick a category color.
  Color _categoryColor() {
    final lower = note.videoTitle.toLowerCase();
    if (lower.contains('tech') || lower.contains('code')) return AppTheme.coral;
    if (lower.contains('business') || lower.contains('econom')) return AppTheme.teal;
    if (lower.contains('design') || lower.contains('ui')) return const Color(0xFF8B5CF6);
    if (lower.contains('science')) return const Color(0xFFF97316);
    return AppTheme.teal;
  }

  String _readTime() {
    final words = note.notes.split(' ').length;
    final minutes = (words / 200).ceil();
    return '$minutes min read';
  }

  String _formattedDate() {
    final d = note.createdAt;
    final months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return '${months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = _categoryColor();

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NoteDetailScreen(note: note),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: category icon + bookmark
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_categoryIcon(), size: 20, color: catColor),
                ),
                _BookmarkButton(note: note, isDark: isDark),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              note.videoTitle,
              style: AppTheme.titleLarge(
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Description preview (from notes content)
            if (note.notes.isNotEmpty)
              Text(
                note.notes,
                style: AppTheme.bodyMedium(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 12),

            // Footer: date + read time
            Row(
              children: [
                Text(
                  _formattedDate(),
                  style: AppTheme.labelSmall(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _readTime(),
                  style: AppTheme.labelSmall(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(
            delay: (50 * index).ms,
            duration: 400.ms,
          ).slideY(
            begin: 0.05,
            delay: (50 * index).ms,
            duration: 400.ms,
            curve: Curves.easeOut,
          ),
    );
  }
}

class _BookmarkButton extends StatelessWidget {
  final VideoNote note;
  final bool isDark;

  const _BookmarkButton({required this.note, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isFav = note.isFavorite;

    return GestureDetector(
      onTap: () {
        final notesProvider =
            Provider.of<NotesProvider>(context, listen: false);
        notesProvider.toggleFavorite(note.id, note.isFavorite);
      },
      child: Icon(
        isFav ? Icons.bookmark : Icons.bookmark_outline,
        size: 24,
        color: isFav
            ? AppTheme.teal
            : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
      ),
    );
  }
}

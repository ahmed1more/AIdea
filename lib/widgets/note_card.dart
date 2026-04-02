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

  const NoteCard({super.key, required this.note, this.index = 0});

  /// Pick an icon based on title keywords.
  IconData _categoryIcon() {
    final lower = note.videoTitle.toLowerCase();
    if (lower.contains('tech') ||
        lower.contains('code') ||
        lower.contains('program')) {
      return Icons.auto_awesome;
    } else if (lower.contains('business') ||
        lower.contains('econom') ||
        lower.contains('financ')) {
      return Icons.trending_up;
    } else if (lower.contains('design') ||
        lower.contains('ui') ||
        lower.contains('ux')) {
      return Icons.palette_outlined;
    } else if (lower.contains('science') || lower.contains('research')) {
      return Icons.science_outlined;
    } else if (lower.contains('health') || lower.contains('medical')) {
      return Icons.favorite_outline;
    } else if (lower.contains('edu') ||
        lower.contains('learn') ||
        lower.contains('study')) {
      return Icons.school_outlined;
    }
    return Icons.article_outlined;
  }

  /// Pick a category color.
  Color _categoryColor() {
    final lower = note.videoTitle.toLowerCase();
    if (lower.contains('tech') || lower.contains('code')) return AppTheme.coral;
    if (lower.contains('business') || lower.contains('econom'))
      return AppTheme.teal;
    if (lower.contains('design') || lower.contains('ui'))
      return const Color(0xFF8B5CF6);
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
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return '${months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Animate(
      effects: [
        FadeEffect(duration: 400.ms),
        SlideEffect(
          begin: const Offset(0, 0.1),
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        ),
      ],
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => NoteDetailScreen(note: note),
                  ),
                );
              },
              child: settings.glassMorphicContainer(
                context: context,
                opacity: isDark ? 0.05 : 0.7,
                blur: 15,
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail with Play Overlay
                    if (note.thumbnail.isNotEmpty)
                      Stack(
                        children: [
                          Image.network(
                            note.thumbnail,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: settings.accentColor.withOpacity(0.1),
                                child: Icon(
                                  FontAwesomeIcons.video,
                                  size: 40,
                                  color: settings.accentColor,
                                ),
                              );
                            },
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.5),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child:
                                CircleAvatar(
                                      backgroundColor: settings.accentColor,
                                      radius: 24,
                                      child: const Icon(
                                        FontAwesomeIcons.play,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    )
                                    .animate(
                                      onPlay: (controller) =>
                                          controller.repeat(),
                                    )
                                    .shimmer(
                                      duration: 2000.ms,
                                      color: Colors.white30,
                                    ),
                          ),
                        ],
                      ),

                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  note.videoTitle,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: FaIcon(
                                  note.isFavorite
                                      ? FontAwesomeIcons.solidHeart
                                      : FontAwesomeIcons.heart,
                                  color: note.isFavorite
                                      ? Colors.red
                                      : Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () => _toggleFavorite(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              FaIcon(
                                FontAwesomeIcons.calendarDay,
                                size: 12,
                                color: isDark
                                    ? Colors.white60
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat(
                                  'MMM dd, yyyy',
                                ).format(note.createdAt),
                                style: GoogleFonts.inter(
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Text(
                            note.notes,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.white70 : Colors.grey[700],
                              height: 1.6,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),

                          if (note.keyPoints.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              children: [
                                settings.glassMorphicContainer(
                                  context: context,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  opacity: 0.1,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      FaIcon(
                                        FontAwesomeIcons.lightbulb,
                                        size: 12,
                                        color: settings.accentColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${note.keyPoints.length} Insights',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: settings.accentColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Colors.black12),
                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                onPressed: () => _launchUrl(note.videoUrl),
                                icon: FaIcon(
                                  FontAwesomeIcons.youtube,
                                  size: 16,
                                  color: settings.accentColor,
                                ),
                                label: Text(
                                  'WATCH VIDEO',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                    color: settings.accentColor,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const FaIcon(
                                      FontAwesomeIcons.shareNodes,
                                      size: 18,
                                    ),
                                    onPressed: _shareNote,
                                    tooltip: 'Share',
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.grey[600],
                                  ),
                                  IconButton(
                                    icon: const FaIcon(
                                      FontAwesomeIcons.trashCan,
                                      size: 18,
                                    ),
                                    onPressed: () => _deleteNote(context),
                                    tooltip: 'Delete',
                                    color: Colors.red.withOpacity(0.7),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

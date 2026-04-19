import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/video_note.dart';
import '../providers/notes_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/home/note_detail_screen.dart';
import '../theme/app_theme.dart';

/// Editorial-inspired note card for the redesigned UI.
class NoteCard extends StatelessWidget {
  final VideoNote note;
  final int index;

  const NoteCard({super.key, required this.note, this.index = 0});

  void _toggleFavorite(BuildContext context) {
    context.read<NotesProvider>().toggleFavorite(note.id, note.isFavorite);
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Technology & AI':
        return FontAwesomeIcons.microchip;
      case 'Business & Finance':
        return FontAwesomeIcons.chartLine;
      case 'Education & Science':
        return FontAwesomeIcons.flask;
      case 'Productivity & Self-Growth':
        return FontAwesomeIcons.rocket;
      case 'News & Politics':
        return FontAwesomeIcons.newspaper;
      case 'Entertainment & Lifestyle':
        return FontAwesomeIcons.mugHot;
      case 'Health & Sports':
        return FontAwesomeIcons.heartPulse;
      case 'Uncategorized':
      default:
        return FontAwesomeIcons.folderOpen;
    }
  }

// Removed unused methods _launchUrl and _shareNote to clean up compact NoteCard view.

  void _deleteNote(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    settings.showGlassDialog(
      context: context,
      title: 'Delete Note',
      content: Text(
        'Are you sure you want to delete this note?',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CANCEL', style: AppTheme.labelLarge(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary)),
        ),
        TextButton(
          onPressed: () {
            context.read<NotesProvider>().deleteNote(note.id, note.userId);
            Navigator.pop(context);
          },
          child: Text('DELETE', style: AppTheme.labelLarge(color: Colors.redAccent)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = Provider.of<SettingsProvider>(context);
    return RepaintBoundary(
      child: Animate(
        effects: [
          FadeEffect(duration: 400.ms),
          SlideEffect(
            begin: const Offset(0, 0.05),
            duration: 400.ms,
            curve: Curves.easeOutCubic,
          ),
        ],
        child: Container(
          // Remove margin to allow GridView/ListView spacers to handle layout.
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.1),
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
                  blur: isDark ? 8 : 4, // Reduced blur for performance in grid
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail with Play Overlay
                      if (note.thumbnail.isNotEmpty)
                        Stack(
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.network(
                                note.thumbnail,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: settings.accentColor.withValues(alpha: 0.1),
                                    child: Icon(
                                      FontAwesomeIcons.circlePlay,
                                      size: 40,
                                      color: settings.accentColor,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.5),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: CircleAvatar(
                                backgroundColor: settings.accentColor,
                                radius: 18,
                                child: const Icon(
                                  FontAwesomeIcons.play,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
  
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.videoTitle,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                FaIcon(
                                  _getCategoryIcon(note.category),
                                  size: 10,
                                  color: settings.accentColor.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    note.category,
                                    style: GoogleFonts.inter(
                                      color: isDark ? Colors.white54 : Colors.grey[600],
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('MMM dd, yyyy').format(note.createdAt),
                                  style: GoogleFonts.inter(
                                    color: isDark ? Colors.white30 : Colors.grey[400],
                                    fontSize: 10,
                                  ),
                                ),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _toggleFavorite(context),
                                      child: Icon(
                                        note.isFavorite ? Icons.favorite : Icons.favorite_border,
                                        color: note.isFavorite ? Colors.red : (isDark ? Colors.white30 : Colors.grey[400]),
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    GestureDetector(
                                      onTap: () => _deleteNote(context),
                                      child: Icon(
                                        Icons.delete_outline,
                                        color: Colors.red.withValues(alpha: 0.3),
                                        size: 16,
                                      ),
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
      ),
    );
  }
}


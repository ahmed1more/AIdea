import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _shareNote() {
    // ignore: deprecated_member_use
    Share.share('Check out these notes from "${note.videoTitle}": ${note.videoUrl}');
  }

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
    final settings = context.watch<SettingsProvider>();

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
                blur: 15,
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
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  note.videoTitle,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _toggleFavorite(context),
                                child: Icon(
                                  note.isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: note.isFavorite
                                      ? Colors.red
                                      : (isDark ? Colors.white60 : Colors.grey),
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '# YouTube Video',
                            style: GoogleFonts.inter(
                              color: isDark ? settings.accentColor.withValues(alpha: 0.7) : settings.accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          const Divider(height: 24, thickness: 0.5),

                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                                color: isDark ? Colors.white60 : Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  DateFormat('MMM dd, yyyy').format(note.createdAt),
                                  style: GoogleFonts.inter(
                                    color: isDark ? Colors.white60 : Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _launchUrl(note.videoUrl),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: settings.accentColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.open_in_new,
                                        size: 12,
                                        color: settings.accentColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Watch',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: settings.accentColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate(),
                            ],
                          ),

                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.share_outlined, size: 18),
                                onPressed: _shareNote,
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                                color: isDark ? Colors.white38 : Colors.grey[400],
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18),
                                onPressed: () => _deleteNote(context),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                                color: Colors.red.withValues(alpha: 0.4),
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


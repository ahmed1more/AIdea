import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/video_note.dart';
import '../providers/notes_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/home/note_detail_screen.dart';
import '../theme/app_theme.dart';
import 'shared_video_card.dart';

/// Editorial-inspired note card for the redesigned UI.
class NoteCard extends StatelessWidget {
  final VideoNote note;
  final int index;

  const NoteCard({super.key, required this.note, this.index = 0});

  void _toggleFavorite(BuildContext context) {
    context.read<NotesProvider>().toggleFavorite(note.id, note.isFavorite);
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
    return SharedVideoCard(
      title: note.videoTitle,
      thumbnail: note.thumbnail,
      categories: note.categories,
      dateString: DateFormat('MMM dd, yyyy').format(note.createdAt),
      isFavorite: note.isFavorite,
      showActions: true,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NoteDetailScreen(note: note),
          ),
        );
      },
      onFavoriteTap: () => _toggleFavorite(context),
      onDeleteTap: () => _deleteNote(context),
    );
  }
}

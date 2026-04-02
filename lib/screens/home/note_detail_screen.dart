import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/video_note.dart';
import '../../providers/notes_provider.dart';
import '../../theme/app_theme.dart';

class NoteDetailScreen extends StatefulWidget {
  final VideoNote note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late VideoNote _note;
  bool _isEditing = false;
  late TextEditingController _notesController;
  late List<TextEditingController> _keyPointsControllers;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
    _notesController = TextEditingController(text: _note.notes);
    _keyPointsControllers = _note.keyPoints
        .map((kp) => TextEditingController(text: kp))
        .toList();
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (var controller in _keyPointsControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _shareNote() {
    Share.share(
      '${_note.videoTitle}\n\n${_note.notes}\n\nWatch: ${_note.videoUrl}',
      subject: _note.videoTitle,
    );
  }

  Future<void> _toggleFavorite(BuildContext context) async {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    await notesProvider.toggleFavorite(_note.id, _note.isFavorite);
    if (mounted) {
      setState(() {
        _note = _note.copyWith(isFavorite: !_note.isFavorite);
      });
    }
  }

  Future<void> _saveChanges() async {
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);

    final newNotes = _notesController.text;
    final newKeyPoints = _keyPointsControllers.map((c) => c.text).toList();

    bool success = await notesProvider.updateNote(_note.id, {
      'notes': newNotes,
      'keyPoints': newKeyPoints,
    });

    if (success && mounted) {
      setState(() {
        _note = _note.copyWith(notes: newNotes, keyPoints: newKeyPoints);
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Note updated successfully'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to update note'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _notesController.text = _note.notes;
      for (int i = 0; i < _keyPointsControllers.length; i++) {
        _keyPointsControllers[i].text = _note.keyPoints[i];
      }
    });
  }

  String _readTime() {
    final words = _note.notes.split(' ').length;
    final minutes = (words / 200).ceil();
    return '$minutes min read';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(
          'Summary',
          style: AppTheme.headline3(
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          if (_isEditing) ...[
            TextButton(
              onPressed: _saveChanges,
              child: Text('Save',
                  style: AppTheme.labelLarge(color: primaryColor)),
            ),
            IconButton(
              icon: Icon(Icons.close,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary),
              onPressed: _cancelEditing,
            ),
          ] else ...[
            IconButton(
              icon: Icon(Icons.edit_outlined, size: 22, color: primaryColor),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: Icon(
                _note.isFavorite ? Icons.bookmark : Icons.bookmark_outline,
                color: _note.isFavorite ? AppTheme.teal : null,
                size: 22,
              ),
              onPressed: () => _toggleFavorite(context),
            ),
            IconButton(
              icon: Icon(Icons.share_outlined, size: 22,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary),
              onPressed: _shareNote,
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        children: [
          // ─── Title ──────────────────────────────────
          Text(
            _note.videoTitle,
            style: AppTheme.headline2(
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 16),

          // ─── Meta row ───────────────────────────────
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary),
              const SizedBox(width: 6),
              Text(
                DateFormat('MMMM dd, yyyy').format(_note.createdAt),
                style: AppTheme.bodySmall(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.schedule, size: 14,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary),
              const SizedBox(width: 6),
              Text(
                _readTime(),
                style: AppTheme.bodySmall(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

          const SizedBox(height: 16),

          // ─── Watch Button ───────────────────────────
          OutlinedButton.icon(
            onPressed: () => _launchUrl(_note.videoUrl),
            icon: Icon(Icons.play_circle_outline, color: primaryColor),
            label: Text('Watch Video',
                style: AppTheme.labelLarge(color: primaryColor)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                  color: primaryColor.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ).animate().fadeIn(delay: 150.ms, duration: 300.ms),

          const SizedBox(height: 32),

          // ─── Notes Section ──────────────────────────
          Row(
            children: [
              Icon(Icons.notes, size: 16, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                'NOTES',
                style: AppTheme.labelSmall(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ).copyWith(letterSpacing: 2),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: _isEditing
                ? TextFormField(
                    controller: _notesController,
                    maxLines: null,
                    style: AppTheme.bodyLarge(
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                : Text(
                    _note.notes,
                    style: AppTheme.bodyLarge(
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

          const SizedBox(height: 32),

          // ─── Key Points ─────────────────────────────
          if (_note.keyPoints.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.checklist, size: 16, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'KEY POINTS',
                  style: AppTheme.labelSmall(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ).copyWith(letterSpacing: 2),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(_note.keyPoints.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: AppTheme.labelSmall(color: Colors.white)
                                .copyWith(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _isEditing
                            ? TextFormField(
                                controller: _keyPointsControllers[index],
                                maxLines: null,
                                style: AppTheme.bodyMedium(
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.lightTextPrimary,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              )
                            : Text(
                                _note.keyPoints[index],
                                style: AppTheme.bodyMedium(
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.lightTextPrimary,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(
                    delay: (250 + 50 * index).ms,
                    duration: 400.ms,
                  )
                  .slideX(begin: 0.05, duration: 300.ms);
            }),
          ],
        ],
      ),
    );
  }
}

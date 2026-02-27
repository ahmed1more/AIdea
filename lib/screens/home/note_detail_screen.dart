import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/video_note.dart';
import '../../providers/notes_provider.dart';

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

    // Call updateNote mapping to database
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
        const SnackBar(content: Text('Note updated successfully')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update note')));
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _note.videoTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _note.thumbnail,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.video_library,
                          size: 80,
                          color: Colors.white54,
                        ),
                      );
                    },
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (_isEditing) ...[
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _saveChanges,
                  tooltip: 'Save',
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _cancelEditing,
                  tooltip: 'Cancel',
                ),
              ] else ...[
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: Icon(
                    _note.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _note.isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: () => _toggleFavorite(context),
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _shareNote,
                ),
              ],
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and Watch Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMMM dd, yyyy').format(_note.createdAt),
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _launchUrl(_note.videoUrl),
                        icon: const Icon(Icons.play_circle_outline),
                        label: const Text('Watch Video'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Notes Section
                  Text(
                    'Notes',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: _isEditing
                        ? TextFormField(
                            controller: _notesController,
                            maxLines: null,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.6,
                              color: colorScheme.onSurface,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          )
                        : Text(
                            _note.notes,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.6,
                              color: colorScheme.onSurface,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Key Points Section
                  if (_note.keyPoints.isNotEmpty) ...[
                    Text(
                      'Key Points',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_note.keyPoints.length, (index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _isEditing
                                  ? TextFormField(
                                      controller: _keyPointsControllers[index],
                                      maxLines: null,
                                      style: TextStyle(
                                        fontSize: 15,
                                        height: 1.5,
                                        color: colorScheme.onPrimaryContainer,
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    )
                                  : Text(
                                      _note.keyPoints[index],
                                      style: TextStyle(
                                        fontSize: 15,
                                        height: 1.5,
                                        color: colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

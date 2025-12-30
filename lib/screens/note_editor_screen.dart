import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/note_model.dart';
import '../providers/notes_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/tag_input_widget.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final String? noteId;

  const NoteEditorScreen({super.key, this.noteId});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  List<String> _tags = [];
  String? _selectedCategory;
  bool _isFavorite = false;
  bool _isLoading = false;
  bool _showPreview = false;

  final List<String> _categories = [
    'Physics',
    'Biology',
    'Chemistry',
    'Astronomy',
    'Technology',
    'Mathematics',
    'Earth Science',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Load note if editing
    if (widget.noteId != null) {
      final noteAsync = ref.watch(noteProvider(widget.noteId!));

      noteAsync.whenData((note) {
        if (note != null && _titleController.text.isEmpty) {
          _titleController.text = note.title;
          _contentController.text = note.content;
          _tags = List.from(note.tags);
          _selectedCategory = note.category;
          _isFavorite = note.isFavorite;
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.noteId != null ? 'Edit Note' : 'New Note'),
        actions: [
          IconButton(
            icon: Icon(_showPreview ? Icons.edit : Icons.preview),
            onPressed: () {
              setState(() => _showPreview = !_showPreview);
            },
            tooltip: _showPreview ? 'Edit' : 'Preview',
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
            },
          ),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveNote,
              tooltip: 'Save',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_showPreview) ...[
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter note title',
                  prefixIcon: Icon(Icons.title),
                ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
              ),
              const SizedBox(height: 16),
              TagInputWidget(
                tags: _tags,
                onTagsChanged: (tags) {
                  setState(() => _tags = tags);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  hintText:
                      'Write your note here...\n\nSupports markdown formatting',
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                minLines: 15,
                keyboardType: TextInputType.multiline,
              ),
            ] else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titleController.text.isEmpty
                            ? 'Untitled'
                            : _titleController.text,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      if (_selectedCategory != null) ...[
                        const SizedBox(height: 8),
                        Chip(
                          label: Text(_selectedCategory!),
                          avatar: const Icon(Icons.category, size: 16),
                        ),
                      ],
                      if (_tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _tags
                              .map(
                                (tag) => Chip(
                                  label: Text(tag),
                                  labelStyle: const TextStyle(fontSize: 12),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        _contentController.text.isEmpty
                            ? 'No content yet...'
                            : _contentController.text,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You must be logged in')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final notesService = ref.read(notesServiceProvider);

      if (widget.noteId != null) {
        // Update existing note
        final existingNote = await ref.read(
          noteProvider(widget.noteId!).future,
        );
        if (existingNote != null) {
          final updatedNote = existingNote.copyWith(
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            tags: _tags,
            category: _selectedCategory,
            isFavorite: _isFavorite,
            updatedAt: now,
          );
          await notesService.updateNote(updatedNote);
        }
      } else {
        // Create new note
        final note = Note(
          id: '', // Firestore will generate this
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          tags: _tags,
          category: _selectedCategory,
          isFavorite: _isFavorite,
          createdAt: now,
          updatedAt: now,
          userId: user.uid,
        );
        await notesService.createNote(note);
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.noteId != null
                  ? 'Note updated successfully'
                  : 'Note created successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

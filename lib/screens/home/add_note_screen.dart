import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import '../../models/video_note.dart';

class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _videoUrlController = TextEditingController();
  final _videoTitleController = TextEditingController();
  final _notesController = TextEditingController();
  final _keyPointController = TextEditingController();
  final List<String> _keyPoints = [];
  bool _isGenerating = false;

  @override
  void dispose() {
    _videoUrlController.dispose();
    _videoTitleController.dispose();
    _notesController.dispose();
    _keyPointController.dispose();
    super.dispose();
  }

  void _addKeyPoint() {
    if (_keyPointController.text.isNotEmpty) {
      setState(() {
        _keyPoints.add(_keyPointController.text.trim());
        _keyPointController.clear();
      });
    }
  }

  void _removeKeyPoint(int index) {
    setState(() {
      _keyPoints.removeAt(index);
    });
  }

  Future<void> _simulateAIGeneration() async {
    // This simulates AI note generation
    // In a real app, you would call an API here (like OpenAI, Claude, etc.)
    setState(() {
      _isGenerating = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _notesController.text = '''
This is a simulated AI-generated note from the video.

Key Concepts:
- Main idea from the video content
- Important details and explanations
- Supporting arguments and examples

Summary:
The video provides valuable insights into the topic, explaining various concepts in detail and offering practical examples for better understanding.

Conclusion:
Overall, this content offers a comprehensive overview that can help viewers gain deeper knowledge of the subject matter.
''';

      _keyPoints.addAll([
        'Main concept explained clearly',
        'Practical examples provided',
        'Detailed analysis included',
      ]);

      _isGenerating = false;
    });
  }

  Future<void> _saveNote() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final notesProvider = Provider.of<NotesProvider>(context, listen: false);

      if (authProvider.user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to save notes'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Extract video ID for thumbnail (YouTube example)
      String thumbnail = 'https://via.placeholder.com/320x180';
      if (_videoUrlController.text.contains('youtube.com') ||
          _videoUrlController.text.contains('youtu.be')) {
        // Simple YouTube thumbnail extraction
        final videoId = _extractYouTubeId(_videoUrlController.text);
        if (videoId != null) {
          thumbnail = 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
        }
      }

      final note = VideoNote(
        id: '',
        userId: authProvider.user!.id,
        videoUrl: _videoUrlController.text.trim(),
        videoTitle: _videoTitleController.text.trim(),
        thumbnail: thumbnail,
        notes: _notesController.text.trim(),
        keyPoints: _keyPoints,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool success = await notesProvider.createNote(note);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save note'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String? _extractYouTubeId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})',
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote,
            tooltip: 'Save Note',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Video URL
              TextFormField(
                controller: _videoUrlController,
                decoration: const InputDecoration(
                  labelText: 'Video URL',
                  hintText: 'https://youtube.com/watch?v=...',
                  prefixIcon: Icon(Icons.link),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a video URL';
                  }
                  if (!value.startsWith('http')) {
                    return 'Please enter a valid URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Video Title
              TextFormField(
                controller: _videoTitleController,
                decoration: const InputDecoration(
                  labelText: 'Video Title',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a video title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Generate Button
              ElevatedButton.icon(
                onPressed: _isGenerating ? null : _simulateAIGeneration,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _isGenerating ? 'Generating...' : 'Generate Notes with AI',
                ),
              ),
              const SizedBox(height: 24),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Write or generate your notes here...',
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please add some notes';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Key Points Section
              Text(
                'Key Points',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Add Key Point
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _keyPointController,
                      decoration: const InputDecoration(
                        hintText: 'Add a key point',
                      ),
                      onSubmitted: (_) => _addKeyPoint(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: _addKeyPoint,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Key Points List
              if (_keyPoints.isNotEmpty)
                ...List.generate(_keyPoints.length, (index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(_keyPoints[index]),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeKeyPoint(index),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

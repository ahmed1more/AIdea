import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/video_note.dart';
import '../../services/ai_service.dart';
import '../settings/settings_screen.dart';

class AddNoteScreen extends StatefulWidget {
  final String? initialUrl;
  final String? initialTitle;
  final PlatformFile? pickedFile;

  const AddNoteScreen({
    super.key,
    this.initialUrl,
    this.initialTitle,
    this.pickedFile,
  });

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
  void initState() {
    super.initState();
    if (widget.initialUrl != null) {
      _videoUrlController.text = widget.initialUrl!;
    }
    if (widget.initialTitle != null) {
      _videoTitleController.text = widget.initialTitle!;
    }
  }

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
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    if (!settings.isAiConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please configure your AI API key in Settings first.',
          ),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      String? idToken;
      if (settings.aiModel == AiModel.aidea) {
        idToken = await firebase_auth.FirebaseAuth.instance.currentUser
            ?.getIdToken();
        if (idToken == null) {
          throw Exception('Authentication required for AIdea model.');
        }
      }

      final result = await AiService.generateNotes(
        videoUrl: _videoUrlController.text.trim(),
        videoTitle: _videoTitleController.text.trim(),
        model: settings.aiModel.name,
        apiKey: settings.apiKey,
        aideaUrl: settings.aideaUrl,
        idToken: idToken,
      );

      setState(() {
        _notesController.text = result['notes'] as String;
        _keyPoints.clear();
        _keyPoints.addAll(List<String>.from(result['keyPoints']));
        _isGenerating = false;
      });
    } catch (e) {
      debugPrint('AI Generation Error Detail: $e');
      setState(() {
        _isGenerating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${settings.aiModel.name.toUpperCase()} failed: ${e.toString().replaceAll('Exception: ', '')}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: Colors.red.shade800,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
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

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/video_note.dart';
import '../../services/ai_service.dart';
import '../../theme/app_theme.dart';
import '../settings/settings_screen.dart';

class AddNoteScreen extends StatefulWidget {
  final String? initialUrl;
  final String? initialTitle;

  const AddNoteScreen({super.key, this.initialUrl, this.initialTitle});

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
      String? idToken = await firebase_auth.FirebaseAuth.instance.currentUser
          ?.getIdToken();
      if (idToken == null) {
        throw Exception('Authentication required to generate notes.');
      }

      final result = await AiService.generateNotes(
        videoUrl: _videoUrlController.text.trim(),
        videoTitle: _videoTitleController.text.trim(),
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
              'AI Generation failed: ${e.toString().replaceAll('Exception: ', '')}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: Colors.red.shade800,
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      final String? userId = authProvider.user?.id ?? firebaseUser?.uid;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('You must be logged in to save notes'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }

      String thumbnail = 'https://via.placeholder.com/320x180';
      if (_videoUrlController.text.contains('youtube.com') ||
          _videoUrlController.text.contains('youtu.be')) {
        final videoId = _extractYouTubeId(_videoUrlController.text);
        if (videoId != null) {
          thumbnail = 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
        }
      }

      final note = VideoNote(
        id: '',
        userId: userId,
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
          SnackBar(
            content: const Text('Note saved successfully!'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save note'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(
          'New Summary',
          style: AppTheme.headline3(
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _saveNote,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Save'),
              style: TextButton.styleFrom(foregroundColor: primaryColor),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── URL Field ──────────────────────────────
              Text(
                'VIDEO LINK',
                style: AppTheme.labelSmall(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ).copyWith(letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _videoUrlController,
                style: AppTheme.bodyMedium(
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Paste YouTube or Vimeo URL...',
                  prefixIcon: Icon(Icons.link, size: 20, color: primaryColor),
                  filled: true,
                  fillColor: isDark
                      ? AppTheme.darkSurface
                      : AppTheme.lightSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Link is required';
                  if (!value.startsWith('http')) return 'Invalid URL format';
                  return null;
                },
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 20),

              // ─── Title Field ────────────────────────────
              Text(
                'TOPIC TITLE',
                style: AppTheme.labelSmall(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ).copyWith(letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _videoTitleController,
                style: AppTheme.bodyMedium(
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'What is this video about?',
                  prefixIcon: Icon(Icons.title, size: 20, color: primaryColor),
                  filled: true,
                  fillColor: isDark
                      ? AppTheme.darkSurface
                      : AppTheme.lightSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

              const SizedBox(height: 24),

              // ─── Generate Button ────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _simulateAIGeneration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: primaryColor.withValues(
                      alpha: 0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    elevation: 4,
                    shadowColor: primaryColor.withValues(alpha: 0.3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isGenerating)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(Icons.auto_awesome, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _isGenerating ? 'GENERATING...' : 'ENHANCE WITH AI',
                        style: AppTheme.button().copyWith(letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

              const SizedBox(height: 32),

              // ─── Notes Section ──────────────────────────
              Row(
                children: [
                  Icon(Icons.notes, size: 16, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'YOUR INSIGHTS',
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
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: TextFormField(
                  controller: _notesController,
                  maxLines: 10,
                  style: AppTheme.bodyMedium(
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Start typing or use AI to generate notes...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 300.ms),

              const SizedBox(height: 32),

              // ─── Key Points Section ─────────────────────
              Row(
                children: [
                  Icon(Icons.checklist, size: 16, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'KEY TAKEAWAYS',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: TextField(
                  controller: _keyPointController,
                  style: AppTheme.bodyMedium(
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add a key point...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.add_circle,
                        color: primaryColor,
                        size: 22,
                      ),
                      onPressed: _addKeyPoint,
                    ),
                  ),
                  onSubmitted: (_) => _addKeyPoint(),
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(_keyPoints.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkSurface
                          : AppTheme.lightSurface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 18, color: primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _keyPoints[index],
                            style: AppTheme.bodyMedium(
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.lightTextPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _removeKeyPoint(index),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn().slideX(begin: 0.1);
              }),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

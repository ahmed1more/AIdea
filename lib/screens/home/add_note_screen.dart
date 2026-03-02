import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/video_note.dart';
import '../../services/ai_service.dart';
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
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      final String? userId = authProvider.user?.id ?? firebaseUser?.uid;

      if (userId == null) {
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
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Craft New Note',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: FaIcon(
                FontAwesomeIcons.solidFloppyDisk,
                size: 20,
                color: settings.accentColor,
              ),
              onPressed: _saveNote,
              tooltip: 'Save Note',
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Color
          Positioned.fill(
            child: Container(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Input Card
                    settings
                        .glassMorphicContainer(
                          context: context,
                          padding: const EdgeInsets.all(20),
                          opacity: isDark ? 0.05 : 0.7,
                          borderRadius: BorderRadius.circular(24),
                          child: Column(
                            children: [
                              _buildModernTextField(
                                controller: _videoUrlController,
                                label: 'Video Link',
                                hint: 'Paste YouTube URL here...',
                                icon: FontAwesomeIcons.link,
                                isDark: isDark,
                                accentColor: settings.accentColor,
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Link is required';
                                  if (!value.startsWith('http'))
                                    return 'Invalid URL format';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              _buildModernTextField(
                                controller: _videoTitleController,
                                label: 'Topic Title',
                                hint: 'What is this video about?',
                                icon: FontAwesomeIcons.heading,
                                isDark: isDark,
                                accentColor: settings.accentColor,
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Title is required';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn()
                        .slideY(begin: 0.1),

                    const SizedBox(height: 24),

                    // Generate Button with Gradient
                    Container(
                          height: 58,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [
                                settings.accentColor,
                                settings.accentColor.withBlue(255),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: settings.accentColor.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isGenerating
                                ? null
                                : _simulateAIGeneration,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isGenerating)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                else
                                  const FaIcon(
                                    FontAwesomeIcons.wandSparkles,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                const SizedBox(width: 12),
                                Text(
                                  _isGenerating
                                      ? 'AI BRAINSTORMING...'
                                      : 'ENHANCE WITH AI',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .shimmer(duration: 3.seconds, color: Colors.white12),

                    const SizedBox(height: 32),

                    // Notes Section Header
                    Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.solidNoteSticky,
                          size: 14,
                          color: settings.accentColor,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'YOUR INSIGHTS',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: isDark ? Colors.white60 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Notes Area
                    settings
                        .glassMorphicContainer(
                          context: context,
                          padding: const EdgeInsets.all(4),
                          opacity: isDark ? 0.05 : 0.7,
                          borderRadius: BorderRadius.circular(24),
                          child: TextFormField(
                            controller: _notesController,
                            maxLines: 12,
                            style: GoogleFonts.inter(fontSize: 15, height: 1.6),
                            decoration: InputDecoration(
                              hintText:
                                  'Start typing or use AI to generate notes...',
                              hintStyle: GoogleFonts.inter(
                                color: isDark ? Colors.white24 : Colors.black26,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(20),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 200.ms),

                    const SizedBox(height: 32),

                    // Key Points Header
                    Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.listCheck,
                          size: 14,
                          color: settings.accentColor,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'KEY TAKEAWAYS',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: isDark ? Colors.white60 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Add Takeaway
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black)
                            .withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _keyPointController,
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Add a pivotal point...',
                          hintStyle: GoogleFonts.inter(
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: FaIcon(
                              FontAwesomeIcons.circlePlus,
                              color: settings.accentColor,
                              size: 20,
                            ),
                            onPressed: _addKeyPoint,
                          ),
                        ),
                        onSubmitted: (_) => _addKeyPoint(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Takeaways List
                    if (_keyPoints.isNotEmpty)
                      ...List.generate(_keyPoints.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: settings.glassMorphicContainer(
                            context: context,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            opacity: isDark ? 0.03 : 0.5,
                            borderRadius: BorderRadius.circular(16),
                            child: Row(
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.circleCheck,
                                  size: 16,
                                  color: settings.accentColor,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    _keyPoints[index],
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const FaIcon(
                                    FontAwesomeIcons.trashCan,
                                    size: 14,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () => _removeKeyPoint(index),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn().slideX(begin: 0.1);
                      }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    required Color accentColor,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                color: isDark ? Colors.white24 : Colors.black26,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FaIcon(icon, size: 14, color: accentColor),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}

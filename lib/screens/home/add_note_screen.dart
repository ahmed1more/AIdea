import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/video_note.dart';
import '../../services/ai_service.dart';
import '../../theme/app_theme.dart';
import 'note_detail_screen.dart';

class AddNoteScreen extends StatefulWidget {
  final String? initialUrl;
  final String? initialTitle;

  const AddNoteScreen({super.key, this.initialUrl, this.initialTitle});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _videoUrlController = TextEditingController();
  final _videoTitleController = TextEditingController();

  // Processing state
  bool _isProcessing = false;
  int _currentStep = 0;
  String _statusMessage = '';
  String? _errorMessage;

  // Result state
  String _generatedNotes = '';
  String _generatedCategory = 'Uncategorized';
  List<String> _generatedKeyPoints = [];
  bool _isComplete = false;

  // Metadata state
  bool _isFetchingTitle = false;
  Timer? _debounceTimer;
  String? _lastFetchedUrl;

  late AnimationController _pulseController;

  static const _processingSteps = [
    {
      'icon': Icons.link,
      'label': 'Validating URL',
      'desc': 'Checking video link...',
    },
    {
      'icon': Icons.cloud_download_outlined,
      'label': 'Extracting Content',
      'desc': 'Fetching video transcript...',
    },
    {
      'icon': Icons.auto_awesome,
      'label': 'AI Processing',
      'desc': 'Generating intelligent summary...',
    },
    {
      'icon': Icons.fact_check_outlined,
      'label': 'Structuring Notes',
      'desc': 'Organizing key Recommendations...',
    },
    {
      'icon': Icons.check_circle,
      'label': 'Complete',
      'desc': 'Your notes are ready!',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    if (widget.initialUrl != null) {
      _videoUrlController.text = widget.initialUrl!;
      _onUrlChanged(); // Initial fetch if provided
    }
    if (widget.initialTitle != null) {
      _videoTitleController.text = widget.initialTitle!;
    }

    _videoUrlController.addListener(_onUrlChanged);
  }

  void _onUrlChanged() {
    final url = _videoUrlController.text.trim();
    if (url == _lastFetchedUrl) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (url.isNotEmpty &&
          (url.contains('youtube.com') || url.contains('youtu.be'))) {
        _fetchMetadata(url);
      }
    });
  }

  Future<void> _fetchMetadata(String url) async {
    setState(() => _isFetchingTitle = true);
    _lastFetchedUrl = url;

    final metadata = await AiService.fetchVideoMetadata(url);

    if (mounted && metadata.containsKey('title')) {
      setState(() {
        _videoTitleController.text = metadata['title']!;
        _isFetchingTitle = false;
      });
    } else if (mounted) {
      setState(() => _isFetchingTitle = false);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _videoUrlController.removeListener(_onUrlChanged);
    _videoUrlController.dispose();
    _videoTitleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String? _extractYouTubeId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})',
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  String _getThumbnail(String url) {
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      final videoId = _extractYouTubeId(url);
      if (videoId != null) {
        return 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
      }
    }
    return 'https://via.placeholder.com/320x180';
  }

  Future<void> _startGeneration() async {
    if (!_formKey.currentState!.validate()) return;

    final settings = Provider.of<SettingsProvider>(context, listen: false);

    if (!settings.isAiConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI configuration error. Please contact support.'),
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _currentStep = 0;
      _errorMessage = null;
      _statusMessage = 'Starting...';
    });

    try {
      // Step 0: Validating URL
      _updateStep(0, 'Validating video URL...');
      await Future.delayed(const Duration(milliseconds: 800));

      // Step 1: Extracting content
      _updateStep(1, 'Connecting to video source...');

      String? idToken = await firebase_auth.FirebaseAuth.instance.currentUser
          ?.getIdToken();
      if (idToken == null) {
        throw Exception('Authentication required. Please sign in again.');
      }
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 2: AI Processing (actual API call)
      _updateStep(2, 'AI is analyzing your video...');

      final result = await AiService.generateNotes(
        videoUrl: _videoUrlController.text.trim(),
        videoTitle: _videoTitleController.text.trim(),
        aideaUrl: settings.aideaUrl,
        idToken: idToken,
      );

      // Step 3: Structuring
      _updateStep(3, 'Organizing Recommendations...');
      await Future.delayed(const Duration(milliseconds: 600));

      // Step 4: Complete
      _updateStep(4, 'Your notes are ready!');

      setState(() {
        _generatedNotes = result['notes'] as String;
        _generatedKeyPoints = List<String>.from(result['keyPoints']);
        _generatedCategory = result['category'] as String? ?? 'Uncategorized';
        _isComplete = true;
      });
    } catch (e) {
      debugPrint('AI Generation Error: $e');
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _updateStep(int step, String message) {
    if (mounted) {
      setState(() {
        _currentStep = step;
        _statusMessage = message;
      });
    }
  }

  Future<void> _saveAndViewNote() async {
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

    final note = VideoNote(
      id: '',
      userId: userId,
      videoUrl: _videoUrlController.text.trim(),
      videoTitle: _videoTitleController.text.trim(),
      thumbnail: _getThumbnail(_videoUrlController.text),
      notes: _generatedNotes,
      category: _generatedCategory,
      keyPoints: _generatedKeyPoints,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    bool success = await notesProvider.createNote(note);

    if (success && mounted) {
      // Navigate to note detail, replacing the add screen
      final savedNotes = notesProvider.notes;
      if (savedNotes.isNotEmpty) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => NoteDetailScreen(note: savedNotes.first),
          ),
        );
      } else {
        Navigator.of(context).pop();
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to save note. Please try again.'),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _resetToInput() {
    setState(() {
      _isProcessing = false;
      _isComplete = false;
      _currentStep = 0;
      _errorMessage = null;
      _generatedNotes = '';
      _generatedCategory = 'Uncategorized';
      _generatedKeyPoints = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(
          _isProcessing || _isComplete ? '' : 'New Summary',
          style: AppTheme.headline3(
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: Icon(
            _isProcessing && !_isComplete ? Icons.close : Icons.arrow_back,
            color: isDark
                ? AppTheme.darkTextPrimary
                : AppTheme.lightTextPrimary,
          ),
          onPressed: () {
            if (_isProcessing && !_isComplete) {
              _resetToInput();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutCubic,
        child: _isProcessing
            ? _buildProcessingView(context, isDark)
            : _buildInputView(context, isDark),
      ),
    );
  }

  // ─── INPUT VIEW ──────────────────────────────────────────────────────
  Widget _buildInputView(BuildContext context, bool isDark) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      key: const ValueKey('input'),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Hero Section ─────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              primaryColor.withValues(alpha: 0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 36,
                        ),
                      ).animate().scale(
                        duration: 500.ms,
                        curve: Curves.elasticOut,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Generate AI Notes',
                        style: AppTheme.headline2(
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 8),
                      Text(
                        'Paste a video link and let AI create\nstructured notes for you.',
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyMedium(
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // ─── URL Input ────────────────────────────────
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
                    hintText: 'https://youtube.com/watch?v=...',
                    prefixIcon: Icon(Icons.link, size: 20, color: primaryColor),
                    filled: true,
                    fillColor: isDark
                        ? AppTheme.darkSurface
                        : AppTheme.lightSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Link is required';
                    }
                    if (!value.startsWith('http')) return 'Invalid URL format';
                    return null;
                  },
                ).animate().fadeIn(delay: 300.ms, duration: 300.ms),

                const SizedBox(height: 20),

                // ─── Title Input ──────────────────────────────
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
                    prefixIcon: Icon(
                      Icons.title,
                      size: 20,
                      color: primaryColor,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppTheme.darkSurface
                        : AppTheme.lightSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _isFetchingTitle
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: primaryColor.withValues(alpha: 0.5),
                            ),
                          )
                        : null,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 400.ms, duration: 300.ms),

                // ─── Error Message ────────────────────────────
                if (_errorMessage != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: AppTheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTheme.bodySmall(color: AppTheme.error),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().shakeX(hz: 3, amount: 2),
                ],

                const SizedBox(height: 32),

                // ─── Generate Button ─────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _startGeneration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      elevation: 8,
                      shadowColor: primaryColor.withValues(alpha: 0.4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          'GENERATE NOTES',
                          style: AppTheme.button(
                            color: Colors.white,
                          ).copyWith(letterSpacing: 1.5),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── PROCESSING VIEW ────────────────────────────────────────────────
  Widget _buildProcessingView(BuildContext context, bool isDark) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (_isComplete) {
      return _buildCompleteView(context, isDark);
    }

    return Center(
      key: const ValueKey('processing'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ─── Animated AI orb ──────────────────────────
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final value = _pulseController.value;
                  return Container(
                    width: 100 + (value * 20),
                    height: 100 + (value * 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          primaryColor.withValues(alpha: 0.3 + value * 0.2),
                          primaryColor.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              primaryColor.withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.4),
                              blurRadius: 24,
                              spreadRadius: value * 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 48),

              // ─── Status message ───────────────────────────
              Text(
                _statusMessage,
                style: AppTheme.titleLarge(
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
                textAlign: TextAlign.center,
              ).animate(key: ValueKey(_statusMessage)).fadeIn(duration: 300.ms),

              const SizedBox(height: 48),

              // ─── Step indicators ──────────────────────────
              ...List.generate(_processingSteps.length, (index) {
                final step = _processingSteps[index];
                final isActive = index == _currentStep;
                final isCompleted = index < _currentStep;
                final isPending = index > _currentStep;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? primaryColor.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // Step indicator icon
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? AppTheme.success
                                : isActive
                                ? primaryColor
                                : (isDark
                                      ? AppTheme.darkSurface
                                      : AppTheme.lightSurface),
                            border: isPending
                                ? Border.all(
                                    color: isDark
                                        ? AppTheme.darkTextSecondary.withValues(
                                            alpha: 0.3,
                                          )
                                        : AppTheme.lightTextSecondary
                                              .withValues(alpha: 0.3),
                                  )
                                : null,
                          ),
                          child: Icon(
                            isCompleted
                                ? Icons.check
                                : step['icon'] as IconData,
                            size: 16,
                            color: isCompleted || isActive
                                ? Colors.white
                                : (isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step['label'] as String,
                                style: AppTheme.titleMedium(
                                  color: isPending
                                      ? (isDark
                                                ? AppTheme.darkTextSecondary
                                                : AppTheme.lightTextSecondary)
                                            .withValues(alpha: 0.5)
                                      : (isDark
                                            ? AppTheme.darkTextPrimary
                                            : AppTheme.lightTextPrimary),
                                ),
                              ),
                              if (isActive)
                                Text(
                                  step['desc'] as String,
                                  style: AppTheme.bodySmall(
                                    color: isDark
                                        ? AppTheme.darkTextSecondary
                                        : AppTheme.lightTextSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isActive)
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: primaryColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: (index * 80).ms, duration: 400.ms);
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ─── COMPLETE VIEW ──────────────────────────────────────────────────
  Widget _buildCompleteView(BuildContext context, bool isDark) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      key: const ValueKey('complete'),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Success Header ────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.success.withValues(alpha: 0.15),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: AppTheme.success,
                        size: 40,
                      ),
                    ).animate().scale(
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Notes Generated!',
                      style: AppTheme.headline2(
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 8),
                    Text(
                      'Review your AI-generated summary below.',
                      style: AppTheme.bodyMedium(
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ─── Video Title Card ──────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.08),
                      primaryColor.withValues(alpha: 0.02),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _videoTitleController.text,
                            style: AppTheme.titleMedium(
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.lightTextPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _videoUrlController.text,
                            style: AppTheme.bodySmall(color: primaryColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

              const SizedBox(height: 24),

              // ─── Generated Notes ───────────────────────────
              _SectionLabel(
                icon: Icons.notes,
                label: 'AI SUMMARY',
                color: primaryColor,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: MarkdownBody(
                  data: _generatedNotes,
                  selectable: true,
                  styleSheet: AppTheme.markdownStyle(context, isDark),
                ),
              ).animate().fadeIn(delay: 500.ms),

              if (_generatedKeyPoints.isNotEmpty) ...[
                const SizedBox(height: 32),
                _SectionLabel(
                  icon: Icons.lightbulb_outline,
                  label: 'KEY Recommendations',
                  count: _generatedKeyPoints.length,
                  color: primaryColor,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                ...List.generate(_generatedKeyPoints.length, (index) {
                  return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSm,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      primaryColor,
                                      primaryColor.withValues(alpha: 0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: AppTheme.labelSmall(
                                      color: Colors.white,
                                    ).copyWith(fontSize: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  _generatedKeyPoints[index],
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
                      .fadeIn(delay: (600 + index * 80).ms, duration: 400.ms)
                      .slideX(begin: 0.05);
                }),
              ],

              const SizedBox(height: 32),

              // ─── Action Buttons ────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _resetToInput,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Regenerate'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _saveAndViewNote,
                      icon: const Icon(Icons.save_alt, size: 20),
                      label: const Text('SAVE & VIEW'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                        ),
                        elevation: 4,
                        shadowColor: primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared Section Label Widget ──────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? count;
  final Color color;
  final bool isDark;

  const _SectionLabel({
    required this.icon,
    required this.label,
    this.count,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/video_note.dart';
import '../../providers/notes_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_theme.dart';
// Removed: import '../../widgets/custom_youtube_player.dart';
// Removed: import 'package:youtube_player_flutter/youtube_player_flutter.dart' show YoutubePlayer;

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
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;
  
  // Video player state
  // Video player state removed
  // final GlobalKey _videoSectionKey = GlobalKey();
  // bool _hasVideo = false;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
    _notesController = TextEditingController(text: _note.notes);
    _keyPointsControllers = _note.keyPoints
        .map((kp) => TextEditingController(text: kp))
        .toList();
    _scrollController.addListener(_updateScrollProgress);
    
    // Check if video exists logic removed
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (var controller in _keyPointsControllers) {
      controller.dispose();
    }
    _scrollController.removeListener(_updateScrollProgress);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollProgress() {
    if (_scrollController.position.maxScrollExtent > 0) {
      setState(() {
        _scrollProgress = (_scrollController.offset /
                _scrollController.position.maxScrollExtent)
            .clamp(0.0, 1.0);
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _shareNote(BuildContext context) {
    final text = StringBuffer();
    text.writeln('📝 ${_note.videoTitle}');
    text.writeln();
    text.writeln(_note.notes);
    if (_note.keyPoints.isNotEmpty) {
      text.writeln();
      text.writeln('🔑 Key Points:');
      for (int i = 0; i < _note.keyPoints.length; i++) {
        text.writeln('${i + 1}. ${_note.keyPoints[i]}');
      }
    }
    text.writeln();
    text.writeln('🔗 ${_note.videoUrl}');
    // ignore: deprecated_member_use
    Share.share(text.toString());
  }

  void _copyToClipboard() {
    final text = StringBuffer();
    text.writeln(_note.videoTitle);
    text.writeln();
    text.writeln(_note.notes);
    if (_note.keyPoints.isNotEmpty) {
      text.writeln();
      text.writeln('Key Points:');
      for (int i = 0; i < _note.keyPoints.length; i++) {
        text.writeln('${i + 1}. ${_note.keyPoints[i]}');
      }
    }
    Clipboard.setData(ClipboardData(text: text.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notes copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
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
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Note updated successfully'),
            ],
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to update note'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final words = _note.notes.split(' ').length +
        _note.keyPoints.fold<int>(0, (sum, kp) => sum + kp.split(' ').length);
    final minutes = (words / 200).ceil();
    return '$minutes min read';
  }

  int _wordCount() {
    return _note.notes.split(' ').length +
        _note.keyPoints.fold<int>(0, (sum, kp) => sum + kp.split(' ').length);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ─── Hero App Bar ──────────────────────────────
              _buildHeroAppBar(context, isDark, primaryColor),

              // ─── Content ───────────────────────────────────
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─── Meta Stats Bar ──────────────────
                          _buildMetaBar(isDark, primaryColor),

                          const SizedBox(height: 32),

                          // ─── Notes Section ───────────────────
                          _buildNotesSection(isDark, primaryColor),

                          const SizedBox(height: 32),

                          // ─── Key Points Section ──────────────
                          if (_note.keyPoints.isNotEmpty)
                            _buildKeyPointsSection(isDark, primaryColor),

                          const SizedBox(height: 32),

                          // ─── Video Section Removed ───────────

                          const SizedBox(height: 32),

                          // ─── Source Card ─────────────────────
                          _buildSourceCard(isDark, primaryColor),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ─── Reading Progress Bar ──────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  height: 3,
                  width: MediaQuery.of(context).size.width * _scrollProgress,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),

          // ─── Floating Action Bar ───────────────────────────
          if (!_isEditing)
            _buildFloatingActionBar(isDark, primaryColor),
        ],
      ),
    );
  }

  // ─── HERO APP BAR ─────────────────────────────────────────────────
  SliverAppBar _buildHeroAppBar(
      BuildContext context, bool isDark, Color primaryColor) {
    final hasThumbnail = _note.thumbnail.isNotEmpty &&
        !_note.thumbnail.contains('placeholder');

    return SliverAppBar(
      expandedHeight: hasThumbnail ? 260 : 180,
      pinned: true,
      stretch: true,
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.7),
          child: IconButton(
            icon: Icon(Icons.arrow_back,
                color: isDark ? Colors.white : Colors.black, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      actions: [
        if (_isEditing) ...[
          TextButton(
            onPressed: _saveChanges,
            child: Text('Save', style: AppTheme.labelLarge(color: primaryColor)),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              backgroundColor: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.7),
              child: IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: _cancelEditing,
              ),
            ),
          ),
        ],
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail or gradient background
            if (hasThumbnail)
              Image.network(
                _note.thumbnail,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _gradientBackground(primaryColor),
              )
            else
              _gradientBackground(primaryColor),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    (isDark ? AppTheme.darkBg : AppTheme.lightBg).withValues(alpha: 0.3),
                    isDark ? AppTheme.darkBg : AppTheme.lightBg,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),

            // Title overlay at bottom
            Positioned(
              left: 24,
              right: 24,
              bottom: 16,
              child: Text(
                _note.videoTitle,
                style: AppTheme.headline2(
                  color: hasThumbnail
                      ? Colors.white
                      : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                ).copyWith(
                  shadows: hasThumbnail
                      ? [
                          Shadow(
                            blurRadius: 12,
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                        ]
                      : null,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientBackground(Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withValues(alpha: 0.2),
            primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  // ─── META BAR ─────────────────────────────────────────────────────
  Widget _buildMetaBar(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          _MetaChip(
            icon: Icons.calendar_today,
            label: DateFormat('MMM dd, yyyy').format(_note.createdAt),
            isDark: isDark,
          ),
          _metaDot(isDark),
          _MetaChip(
            icon: Icons.schedule,
            label: _readTime(),
            isDark: isDark,
          ),
          /* Watch Video meta chip removed */
          _metaDot(isDark),
          _MetaChip(
            icon: Icons.text_fields,
            label: '${_wordCount()} words',
            isDark: isDark,
          ),
          if (_note.keyPoints.isNotEmpty) ...[
            _metaDot(isDark),
            _MetaChip(
              icon: Icons.lightbulb_outline,
              label: '${_note.keyPoints.length} insights',
              isDark: isDark,
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }

  Widget _metaDot(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? AppTheme.darkTextSecondary.withValues(alpha: 0.4)
              : AppTheme.lightTextSecondary.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  // ─── NOTES SECTION ────────────────────────────────────────────────
  Widget _buildNotesSection(bool isDark, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SectionHeader(
              icon: Icons.article_outlined,
              label: 'SUMMARY',
              isDark: isDark,
              color: primaryColor,
            ),
            if (!_isEditing)
              Row(
                children: [
                  _ActionChip(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    onTap: () => setState(() => _isEditing = true),
                    isDark: isDark,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  _ActionChip(
                    icon: Icons.copy_outlined,
                    label: 'Copy',
                    onTap: _copyToClipboard,
                    isDark: isDark,
                    color: primaryColor,
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: isDark
                  ? AppTheme.darkDivider
                  : AppTheme.lightDivider,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _isEditing
              ? TextFormField(
                  controller: _notesController,
                  maxLines: null,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    height: 1.8,
                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                )
              : MarkdownBody(
                  data: _note.notes,
                  selectable: true,
                  styleSheet: AppTheme.markdownStyle(context, isDark),
                  onTapLink: (text, href, title) {
                    if (href != null) _launchUrl(href);
                  },
                ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
      ],
    );
  }

  // ─── KEY POINTS SECTION ───────────────────────────────────────────
  Widget _buildKeyPointsSection(bool isDark, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.lightbulb_outline,
          label: 'KEY INSIGHTS',
          count: _note.keyPoints.length,
          isDark: isDark,
          color: primaryColor,
        ),
        const SizedBox(height: 16),
        ...List.generate(_note.keyPoints.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: isDark
                      ? AppTheme.darkDivider
                      : AppTheme.lightDivider,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Number badge
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor,
                          primaryColor.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _isEditing
                        ? TextFormField(
                            controller: _keyPointsControllers[index],
                            maxLines: null,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              height: 1.6,
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
                        : SelectableText(
                            _note.keyPoints[index],
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              height: 1.6,
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
              .fadeIn(delay: (300 + 60 * index).ms, duration: 400.ms)
              .slideX(begin: 0.03, duration: 300.ms);
        }),
      ],
    );
  }

  // ─── VIDEO SECTION REMOVED ────────────────────────────────────────

  // ─── SOURCE CARD ──────────────────────────────────────────────────
  Widget _buildSourceCard(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withValues(alpha: 0.08),
            primaryColor.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SOURCE VIDEO',
                  style: AppTheme.labelSmall(color: primaryColor).copyWith(letterSpacing: 2),
                ),
                const SizedBox(height: 4),
                Text(
                  _note.videoUrl,
                  style: AppTheme.bodySmall(
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => _launchUrl(_note.videoUrl),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: BorderSide(color: primaryColor.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Watch'),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  // ─── FLOATING ACTION BAR ──────────────────────────────────────────
  Widget _buildFloatingActionBar(bool isDark, Color primaryColor) {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.darkSurface.withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: isDark
                    ? AppTheme.darkDivider
                    : AppTheme.lightDivider,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _FloatingAction(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  isDark: isDark,
                  onTap: () => setState(() => _isEditing = true),
                ),
                _floatingDivider(isDark),
                _FloatingAction(
                  icon: _note.isFavorite ? Icons.bookmark : Icons.bookmark_outline,
                  label: _note.isFavorite ? 'Saved' : 'Save',
                  isDark: isDark,
                  isActive: _note.isFavorite,
                  activeColor: AppTheme.teal,
                  onTap: () => _toggleFavorite(context),
                ),
                _floatingDivider(isDark),
                _FloatingAction(
                  icon: Icons.copy_outlined,
                  label: 'Copy',
                  isDark: isDark,
                  onTap: _copyToClipboard,
                ),
                _floatingDivider(isDark),
                _FloatingAction(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  isDark: isDark,
                  onTap: () => _shareNote(context),
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, curve: Curves.easeOutCubic),
    );
  }

  Widget _floatingDivider(bool isDark) {
    return Container(
      width: 1,
      height: 32,
      color: isDark
          ? AppTheme.darkDivider
          : AppTheme.lightDivider,
    );
  }
}

// ─── SUPPORTING WIDGETS ──────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback? onTap;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: content,
        ),
      );
    }

    return content;
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? count;
  final bool isDark;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.label,
    this.count,
    required this.isDark,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
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
              style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final Color color;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  final bool isActive;
  final Color? activeColor;

  const _FloatingAction({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.isActive = false,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? (activeColor ?? Theme.of(context).colorScheme.primary)
        : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

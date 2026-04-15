import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/video_note.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/settings_provider.dart';
import 'add_note_screen.dart';
import '../../widgets/note_card.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _urlController = TextEditingController();
  final _searchController = TextEditingController();
  int _selectedTab = 0; // 0 = All Notes, 1 = Favorites

  bool _isValidatingUrl = false;
  bool _urlIsValid = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadNotes() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    if (authProvider.user != null) {
      notesProvider.loadUserNotes(authProvider.user!.id);
      notesProvider.loadFavoriteNotes(authProvider.user!.id);
    }
  }

  bool _isValidYoutubeUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return false;
    final isYoutube =
        uri.host == 'www.youtube.com' ||
        uri.host == 'youtube.com' ||
        uri.host == 'youtu.be' ||
        uri.host == 'm.youtube.com';
    if (!isYoutube) return false;
    if (uri.host == 'youtu.be') return uri.pathSegments.isNotEmpty;
    return uri.queryParameters.containsKey('v');
  }

  Future<void> _onSummarize() async {
    final url = _urlController.text.trim();
    if (!_isValidYoutubeUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid YouTube URL.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isValidatingUrl = true);

    String? fetchedTitle;
    try {
      final oembedUrl = Uri.parse(
        'https://www.youtube.com/oembed?url=${Uri.encodeComponent(url)}&format=json',
      );
      final response = await http
          .get(oembedUrl)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        fetchedTitle = data['title'] as String?;
      }
    } catch (_) {
      // Title fetch is best-effort; proceed anyway
    } finally {
      if (mounted) setState(() => _isValidatingUrl = false);
    }

    if (!mounted) return;
    _urlController.clear();
    setState(() => _urlIsValid = false);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddNoteScreen(
          initialUrl: url,
          initialTitle: fetchedTitle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: settings.logo(size: 64),
        centerTitle: false,
        actions: [
          IconButton(
            icon: FaIcon(
              FontAwesomeIcons.circleUser,
              size: 20,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            tooltip: 'Account & Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── URL Input Section ──────────────────────────────────────────
          _buildUrlInputSection(settings, isDark, isWide),

          // ── Tab Row ───────────────────────────────────────────────────
          _buildTabRow(settings, isDark),

          const SizedBox(height: 8),

          // ── Notes Content ─────────────────────────────────────────────
          Expanded(
            child: _selectedTab == 0
                ? _buildNotesGrid(isWide)
                : _buildFavoritesGrid(isWide),
          ),
        ],
      ),
    );
  }

  // ── URL Input + Summarize button ───────────────────────────────────────
  Widget _buildUrlInputSection(
    SettingsProvider settings,
    bool isDark,
    bool isWide,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isWide ? 80 : 20, 12, isWide ? 80 : 20, 20),
      child: Row(
        children: [
          // Text Field
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _urlIsValid
                      ? settings.accentColor.withOpacity(0.6)
                      : (isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.08)),
                ),
              ),
              child: TextField(
                controller: _urlController,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  hintText: 'Paste YouTube or article URL…',
                  hintStyle: GoogleFonts.inter(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 14,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 10),
                    child: FaIcon(
                      FontAwesomeIcons.link,
                      size: 14,
                      color: _urlIsValid
                          ? settings.accentColor
                          : (isDark ? Colors.white38 : Colors.black38),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                  suffixIcon: _urlController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            size: 16,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          onPressed: () {
                            _urlController.clear();
                            setState(() => _urlIsValid = false);
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onChanged: (val) {
                  setState(() => _urlIsValid = _isValidYoutubeUrl(val.trim()));
                },
                onSubmitted: (_) => _onSummarize(),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Summarize button
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  settings.accentColor,
                  Color.alphaBlend(
                    Colors.blue.withOpacity(0.25),
                    settings.accentColor,
                  ),
                ],
              ),
              boxShadow: _urlIsValid
                  ? [
                      BoxShadow(
                        color: settings.accentColor.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [],
            ),
            child: ElevatedButton(
              onPressed: _isValidatingUrl ? null : _onSummarize,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 22),
              ),
              child: _isValidatingUrl
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.wandSparkles,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Summarize',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.15);
  }

  // ── Tab Row (All Notes / Favorites + Search) ───────────────────────────
  Widget _buildTabRow(SettingsProvider settings, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _tabChip(settings, isDark, 0, 'Recent Notes',
              FontAwesomeIcons.noteSticky),
          const SizedBox(width: 10),
          _tabChip(
              settings, isDark, 1, 'Favorites', FontAwesomeIcons.solidHeart),
          const Spacer(),
          // Mini search field
          SizedBox(
            width: 200,
            height: 38,
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search…',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                prefixIcon: Icon(
                  FontAwesomeIcons.magnifyingGlass,
                  size: 13,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: settings.accentColor.withOpacity(0.4),
                  ),
                ),
              ),
              onChanged: (val) {
                Provider.of<NotesProvider>(context, listen: false)
                    .setSearchQuery(val);
                setState(() {});
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _tabChip(
    SettingsProvider settings,
    bool isDark,
    int index,
    String label,
    IconData icon,
  ) {
    final selected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: 250.ms,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? settings.accentColor
              : (isDark
                    ? Colors.white.withOpacity(0.07)
                    : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: settings.accentColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              icon,
              size: 12,
              color: selected
                  ? Colors.white
                  : (isDark ? Colors.white54 : Colors.black45),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.white54 : Colors.black45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Notes Grid ─────────────────────────────────────────────────────────
  Widget _buildNotesGrid(bool isWide) {
    return Consumer<NotesProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final notes = provider.notes;
        if (notes.isEmpty) {
          return _buildEmptyState(
            'No notes yet',
            'Paste a YouTube URL above and tap Summarize to get started.',
          );
        }
        return _notesGridView(notes, isWide);
      },
    );
  }

  Widget _buildFavoritesGrid(bool isWide) {
    return Consumer<NotesProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final notes = provider.favoriteNotes;
        if (notes.isEmpty) {
          return _buildEmptyState(
            'No favorites yet',
            'Tap the heart on any note to save it here.',
          );
        }
        return _notesGridView(notes, isWide);
      },
    );
  }

  Widget _notesGridView(List<VideoNote> notes, bool isWide) {
    if (isWide) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 420,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.88,
        ),
        itemCount: notes.length,
        itemBuilder: (context, i) =>
            NoteCard(note: notes[i]).animate().fadeIn(delay: (i * 40).ms),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      itemCount: notes.length,
      itemBuilder: (context, i) =>
          NoteCard(note: notes[i]).animate().fadeIn(delay: (i * 40).ms),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────
  Widget _buildEmptyState(String title, String subtitle) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.folderOpen,
              size: 52,
              color: Colors.grey.withOpacity(0.25),
            ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 3.seconds),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () {
                // Scroll to top / focus URL field
                _urlController.clear();
                setState(() => _urlIsValid = false);
              },
              icon: const FaIcon(FontAwesomeIcons.arrowUp, size: 13),
              label: Text(
                'Paste a URL above',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: settings.accentColor,
                side: BorderSide(color: settings.accentColor.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }
}

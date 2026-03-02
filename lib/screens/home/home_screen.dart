import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
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
  int _selectedIndex = 0;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
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

  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }

  void _showAddNoteDialog(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final urlController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isValid = false;
    bool isFetchingTitle = false;
    String? fetchedTitle;
    String? fetchError;

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

    Future<void> _fetchTitle(
      String url,
      void Function(void Function()) setState,
    ) async {
      setState(() {
        isFetchingTitle = true;
        fetchedTitle = null;
        fetchError = null;
      });
      try {
        final oembedUrl = Uri.parse(
          'https://www.youtube.com/oembed?url=${Uri.encodeComponent(url)}&format=json',
        );
        final response = await http
            .get(oembedUrl)
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          setState(() {
            fetchedTitle = data['title'] as String?;
            isFetchingTitle = false;
          });
        } else {
          setState(() {
            fetchError = 'Could not fetch title';
            isFetchingTitle = false;
          });
        }
      } catch (_) {
        setState(() {
          fetchError = 'Could not fetch title';
          isFetchingTitle = false;
        });
      }
    }

    settings.showGlassDialog(
      context: context,
      title: 'Craft New Note',
      content: StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── URL field ───────────────────────────────────
                TextFormField(
                  controller: urlController,
                  autofocus: true,
                  keyboardType: TextInputType.url,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'YouTube URL',
                    labelStyle: GoogleFonts.inter(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    hintText: 'https://youtube.com/watch?v=...',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FaIcon(
                        FontAwesomeIcons.link,
                        size: 14,
                        color: settings.accentColor,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 0,
                      minHeight: 0,
                    ),
                    suffixIcon: isFetchingTitle
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : isValid
                        ? const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          )
                        : urlController.text.isNotEmpty
                        ? const Icon(
                            Icons.error_rounded,
                            color: Colors.red,
                            size: 20,
                          )
                        : null,
                    filled: true,
                    fillColor: (isDark ? Colors.black : Colors.white)
                        .withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    final valid = _isValidYoutubeUrl(value.trim());
                    setDialogState(() {
                      isValid = valid;
                      fetchedTitle = null;
                      fetchError = null;
                    });
                    if (valid) {
                      _fetchTitle(value.trim(), setDialogState);
                    }
                  },
                ),

                // ── Validation hint ─────────────────────────────
                if (urlController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      isValid ? '✓ Ready to enhance' : '✗ Invalid YouTube link',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isValid
                            ? Colors.green.withOpacity(0.8)
                            : Colors.redAccent,
                      ),
                    ),
                  ),

                // ── Fetched title preview ────────────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  child: fetchedTitle != null
                      ? Container(
                          margin: const EdgeInsets.only(top: 20),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: settings.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: settings.accentColor.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              FaIcon(
                                FontAwesomeIcons.circlePlay,
                                size: 18,
                                color: settings.accentColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  fetchedTitle!,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn().slideY(begin: 0.1)
                      : fetchError != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            '⚠ $fetchError',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.redAccent,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 24),

                // ── Action buttons ───────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: isDark ? Colors.white60 : Colors.black45,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          colors: [
                            settings.accentColor,
                            settings.accentColor.withBlue(255),
                          ],
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: (isValid && !isFetchingTitle)
                            ? () {
                                final url = urlController.text.trim();
                                Navigator.of(ctx).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AddNoteScreen(
                                      initialUrl: url,
                                      initialTitle: fetchedTitle,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isFetchingTitle)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            else
                              const FaIcon(
                                FontAwesomeIcons.arrowRight,
                                size: 14,
                                color: Colors.white,
                              ),
                            const SizedBox(width: 10),
                            Text(
                              isFetchingTitle ? 'Researching...' : 'Continue',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      _openSettings();
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 900;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: settings.logo(size: 70),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.circleUser, size: 20),
            onPressed: () => _onItemTapped(2),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Subtle Animated Background
          Positioned.fill(
            child: Container(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            ),
          ),
          if (isDark)
            Positioned(
              top: -100,
              right: -100,
              child:
                  Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: settings.accentColor.withOpacity(0.1),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .scale(
                        duration: 5.seconds,
                        begin: const Offset(1, 1),
                        end: const Offset(1.5, 1.5),
                        curve: Curves.easeInOut,
                      )
                      .blur(
                        begin: const Offset(50, 50),
                        end: const Offset(100, 100),
                      ),
            ),

          SafeArea(
            child: Column(
              children: [
                // Animated Search Bar Area
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: settings.glassMorphicContainer(
                    context: context,
                    opacity: isDark ? 0.05 : 0.8,
                    blur: 10,
                    borderRadius: BorderRadius.circular(20),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search your brilliant notes...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        prefixIcon: Icon(
                          FontAwesomeIcons.magnifyingGlass,
                          size: 16,
                          color: settings.accentColor,
                        ),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  Provider.of<NotesProvider>(
                                    context,
                                    listen: false,
                                  ).clearSearch();
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        Provider.of<NotesProvider>(
                          context,
                          listen: false,
                        ).setSearchQuery(value);
                        setState(() {});
                      },
                    ),
                  ),
                ).animate().fadeIn().slideY(begin: -0.2),

                // Custom Tab Bar (Glassy)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildTabButton(
                        0,
                        'All Notes',
                        FontAwesomeIcons.noteSticky,
                      ),
                      const SizedBox(width: 12),
                      _buildTabButton(
                        1,
                        'Favorites',
                        FontAwesomeIcons.solidHeart,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 20),

                // Content Area with Grid for Web/Large Screens
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: isWeb ? 40 : 0),
                    child: _selectedIndex == 0
                        ? _buildAllNotesTab(isWeb)
                        : _buildFavoritesTab(isWeb),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [settings.accentColor, settings.accentColor.withBlue(255)],
          ),
          boxShadow: [
            BoxShadow(
              color: settings.accentColor.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddNoteDialog(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(
            FontAwesomeIcons.plus,
            size: 16,
            color: Colors.white,
          ),
          label: Text(
            'NEW NOTE',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: Colors.white,
            ),
          ),
        ),
      ).animate().scale(delay: 500.ms, curve: Curves.elasticOut),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _selectedIndex == index;
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: 300.ms,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? settings.accentColor
              : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(15),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: settings.accentColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            FaIcon(
              icon,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllNotesTab(bool isWeb) {
    return Consumer<NotesProvider>(
      builder: (context, notesProvider, child) {
        if (notesProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (notesProvider.notes.isEmpty) {
          return _buildEmptyState(
            'No notes yet',
            'Tap + to start your AI-powered learning journey.',
          );
        }

        if (isWeb) {
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 450,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 0.85,
            ),
            itemCount: notesProvider.notes.length,
            itemBuilder: (context, index) =>
                NoteCard(note: notesProvider.notes[index]),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: notesProvider.notes.length,
          itemBuilder: (context, index) =>
              NoteCard(note: notesProvider.notes[index]),
        );
      },
    );
  }

  Widget _buildFavoritesTab(bool isWeb) {
    return Consumer<NotesProvider>(
      builder: (context, notesProvider, child) {
        if (notesProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (notesProvider.favoriteNotes.isEmpty) {
          return _buildEmptyState(
            'No favorites',
            'Mark your best insights with a heart to see them here.',
          );
        }

        if (isWeb) {
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 450,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 0.85,
            ),
            itemCount: notesProvider.favoriteNotes.length,
            itemBuilder: (context, index) =>
                NoteCard(note: notesProvider.favoriteNotes[index]),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: notesProvider.favoriteNotes.length,
          itemBuilder: (context, index) =>
              NoteCard(note: notesProvider.favoriteNotes[index]),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.folderOpen,
            size: 60,
            color: Colors.grey.withOpacity(0.3),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 3.seconds),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

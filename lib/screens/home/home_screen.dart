import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../models/video_note.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/settings_provider.dart';
import 'add_note_screen.dart';
import '../../widgets/note_card.dart';
import '../recommendations/recommendations_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../account/account_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _urlController = TextEditingController();
  final _searchController = TextEditingController();
  int _selectedTab = 0; // 0 = All Notes, 1 = Favorites

  final List<String> _categories = [
    'All',
    'Technology & AI',
    'Business & Finance',
    'Education & Science',
    'Productivity & Self-Growth',
    'News & Politics',
    'Entertainment & Lifestyle',
    'Health & Sports',
  ];

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
        builder: (_) =>
            AddNoteScreen(initialUrl: url, initialTitle: fetchedTitle),
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
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      // On desktop the AppBar is absent – controls live in the tab row instead.
      appBar: isWide
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              centerTitle: false,
              automaticallyImplyLeading: false,
              title: Image.asset(
                settings.logoAssetPath(context),
                width: 32,
                height: 32,
              ),
              actions: [
                // ── Theme Toggle ────────────────────────────────────────
                Consumer<SettingsProvider>(
                  builder: (context, settingsP, _) {
                    final IconData themeIcon;
                    final String themeTooltip;
                    switch (settingsP.themeMode) {
                      case ThemeMode.light:
                        themeIcon = Icons.light_mode_rounded;
                        themeTooltip = 'Switch to Dark Mode';
                        break;
                      case ThemeMode.dark:
                        themeIcon = Icons.dark_mode_rounded;
                        themeTooltip = 'Switch to System Mode';
                        break;
                      default:
                        themeIcon = Icons.brightness_auto_rounded;
                        themeTooltip = 'Switch to Light Mode';
                    }
                    return IconButton(
                      icon: Icon(
                        themeIcon,
                        size: 20,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      tooltip: themeTooltip,
                      onPressed: () {
                        final next = settingsP.themeMode == ThemeMode.system
                            ? ThemeMode.light
                            : settingsP.themeMode == ThemeMode.light
                                ? ThemeMode.dark
                                : ThemeMode.system;
                        settingsP.setThemeMode(next);
                      },
                    );
                  },
                ),
                const SizedBox(width: 16),
              ],
            ),
      floatingActionButton: (isWide || _selectedTab != 0)
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const AddNoteScreen(initialUrl: '', initialTitle: null),
                  ),
                );
              },
              backgroundColor: settings.accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const FaIcon(FontAwesomeIcons.plus, color: Colors.white),
            ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _selectedTab,
              onDestinationSelected: (index) =>
                  setState(() => _selectedTab = index),
              backgroundColor: isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF8FAFC),
              indicatorColor: settings.accentColor.withValues(alpha: 0.2),
              destinations: const [
                NavigationDestination(
                  icon: FaIcon(FontAwesomeIcons.house, size: 20),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: FaIcon(FontAwesomeIcons.solidHeart, size: 20),
                  label: 'Favorites',
                ),
                NavigationDestination(
                  icon: FaIcon(FontAwesomeIcons.lightbulb, size: 20),
                  label: 'Insights',
                ),
                NavigationDestination(
                  icon: FaIcon(FontAwesomeIcons.chartLine, size: 20),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: FaIcon(FontAwesomeIcons.user, size: 20),
                  label: 'Account',
                ),
              ],
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isWide)
            RepaintBoundary(child: _buildDesktopSidebar(settings, isDark)),
          Expanded(
            child: Column(
              children: [
                if (isWide) RepaintBoundary(child: _buildDesktopHeader(settings, isDark)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── URL Input Section (Desktop) ──
                      if (isWide && _selectedTab == 0)
                        _buildUrlInputSection(settings, isDark),

                      // ── Mobile Search Bar (Only shown on mobile) ──
                      if (!isWide && (_selectedTab == 0 || _selectedTab == 1))
                        _buildMobileSearchBar(settings, isDark),

                      // ── Category Filter Row ───────────────
                      if (_selectedTab == 0 || _selectedTab == 1)
                        _buildCategoryFilterRow(settings, isDark),

                      const SizedBox(height: 8),

                      // ── Content ───────────────────────────
                      Expanded(child: _buildSelectedTabContent(isWide)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedTabContent(bool isWide) {
    switch (_selectedTab) {
      case 0:
        return _buildNotesGrid(isWide);
      case 1:
        return _buildFavoritesGrid(isWide);
      case 2:
        return const RecommendationsScreen();
      case 3:
        return const DashboardScreen();
      case 4:
        return const AccountTab();
      default:
        return const SizedBox();
    }
  }

  // ── URL Input + Summarize button (Desktop) ─────────────────────────────────────
  Widget _buildUrlInputSection(SettingsProvider settings, bool isDark) {
    // URL bar should still span normally on desktop.
    return Padding(
      padding: const EdgeInsets.fromLTRB(80, 12, 80, 20),
      child: Row(
        children: [
          // Text Field
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _urlIsValid
                      ? settings.accentColor.withValues(alpha: 0.6)
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.08)),
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
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.38)
                        : Colors.black.withValues(alpha: 0.38),
                    fontSize: 14,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 10),
                    child: FaIcon(
                      FontAwesomeIcons.link,
                      size: 14,
                      color: _urlIsValid
                          ? settings.accentColor
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.38)
                                : Colors.black.withValues(alpha: 0.38)),
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
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.38)
                                : Colors.black.withValues(alpha: 0.38),
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
                    Colors.blue.withValues(alpha: 0.25),
                    settings.accentColor,
                  ),
                ],
              ),
              boxShadow: _urlIsValid
                  ? [
                      BoxShadow(
                        color: settings.accentColor.withValues(alpha: 0.35),
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

// Removed unused _buildMobileAddNoteButton as navigation is now handled by FAB.



// Removed unused _buildMobileTabRow as navigation is now handled by the bottom NavigationBar.

  // ── Mobile Search Bar ──────────────────────────────────────────────────
  Widget _buildMobileSearchBar(SettingsProvider settings, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: SizedBox(
        height: 44,
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: 'Search…',
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.38)
                  : Colors.black.withValues(alpha: 0.38),
            ),
            prefixIcon: Icon(
              FontAwesomeIcons.magnifyingGlass,
              size: 14,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.38)
                  : Colors.black.withValues(alpha: 0.38),
            ),
            contentPadding: EdgeInsets.zero,
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: settings.accentColor.withValues(alpha: 0.4),
              ),
            ),
          ),
          onChanged: (val) {
            Provider.of<NotesProvider>(
              context,
              listen: false,
            ).setSearchQuery(val);
            setState(() {});
          },
        ),
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildDesktopHeader(SettingsProvider settings, bool isDark) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_selectedTab == 0 || _selectedTab == 1) ...[
            // ── Desktop Search Bar ──
            SizedBox(
              width: 240,
              height: 38,
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.38)
                        : Colors.black.withValues(alpha: 0.38),
                  ),
                  prefixIcon: Icon(
                    FontAwesomeIcons.magnifyingGlass,
                    size: 13,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.38)
                        : Colors.black.withValues(alpha: 0.38),
                  ),
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: settings.accentColor.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                ),
                onChanged: (val) {
                  Provider.of<NotesProvider>(context, listen: false)
                      .setSearchQuery(val);
                },
              ),
            ),
            const SizedBox(width: 16),
          ],
          // ── Theme Toggle ──
          Consumer<SettingsProvider>(
            builder: (context, settingsP, _) {
              final IconData themeIcon;
              switch (settingsP.themeMode) {
                case ThemeMode.light:
                  themeIcon = Icons.light_mode_rounded;
                  break;
                case ThemeMode.dark:
                  themeIcon = Icons.dark_mode_rounded;
                  break;
                default:
                  themeIcon = Icons.brightness_auto_rounded;
              }
              return IconButton(
                icon: Icon(
                  themeIcon,
                  size: 20,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                onPressed: () {
                  final next = settingsP.themeMode == ThemeMode.system
                      ? ThemeMode.light
                      : settingsP.themeMode == ThemeMode.light
                          ? ThemeMode.dark
                          : ThemeMode.system;
                  settingsP.setThemeMode(next);
                },
              );
            },
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: settings.accentColor.withValues(alpha: 0.1),
            child: Text(
              'A',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: settings.accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar(SettingsProvider settings, bool isDark) {
    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: Border(
          right: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.05,
                  ),
                ),
              ),
            ),
            child: Transform.translate(
              offset: const Offset(0, -4),
            child: Image.asset(
              settings.logoAssetPath(context),
              width: 36,
              height: 36,
            ),
            ),
          ),
          // ── App Logo in Sidebar ──
          
          const SizedBox(height: 18),
          _desktopSidebarItem(0, 'Home', FontAwesomeIcons.house),
          _desktopSidebarItem(1, 'Favorites', FontAwesomeIcons.solidHeart),
          _desktopSidebarItem(2, 'Insights', FontAwesomeIcons.lightbulb),
          _desktopSidebarItem(3, 'Dashboard', FontAwesomeIcons.chartLine),
          _desktopSidebarItem(4, 'Account', FontAwesomeIcons.user),
        ],
      ),
    );
  }

  Widget _desktopSidebarItem(int index, String label, IconData icon) {
    final selected = _selectedTab == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Provider.of<SettingsProvider>(context).accentColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Tooltip(
        message: label,
        preferBelow: false,
        child: InkWell(
          onTap: () => setState(() => _selectedTab = index),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: 200.ms,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: selected
                  ? accentColor.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: FaIcon(
                icon,
                size: 18,
                color: selected
                    ? accentColor
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: -0.2, end: 0);
  }

  // ── Category Filter Row ─────────────────────────────────────────────
  Widget _buildCategoryFilterRow(SettingsProvider settings, bool isDark) {
    final notesProvider = Provider.of<NotesProvider>(context);
    final currentFilter = notesProvider.categoryFilter;


    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categories.map((category) {
            final isSelected = currentFilter == category;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () {
                  notesProvider.setCategoryFilter(category);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? settings.accentColor
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.04)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? settings.accentColor
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.08)),
                    ),
                  ),
                  child: Text(
                    category,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: -0.1, end: 0);
  }

  // ── Notes Grid ───────────────────────────────────────────────────────
  Widget _buildNotesGrid(bool isWide) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Consumer<NotesProvider>(
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
      ),
    );
  }

  Widget _buildFavoritesGrid(bool isWide) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Consumer<NotesProvider>(
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
      ),
    );
  }

  Widget _notesGridView(List<VideoNote> notes, bool isWide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: MasonryGridView.count(
        crossAxisCount: isWide ? 4 : 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: notes.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        addRepaintBoundaries: true,
        itemBuilder: (context, index) {
          return NoteCard(note: notes[index], index: index);
        },
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────
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
              color: Colors.grey.withValues(alpha: 0.25),
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
                color: Colors.grey.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () {
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
                side: BorderSide(
                  color: settings.accentColor.withValues(alpha: 0.5),
                ),
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

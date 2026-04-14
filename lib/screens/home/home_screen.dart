import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/note_card.dart';
import '../../widgets/editorial_quote_card.dart';
import '../main_shell.dart';
import 'add_note_screen.dart';

/// Home tab — editorial-inspired landing with URL input and recent notes.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _urlController = TextEditingController();
  final _searchController = TextEditingController();
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotes();
    });
  }

  void _loadNotes() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    if (authProvider.user != null) {
      notesProvider.loadUserNotes(authProvider.user!.id);
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleSummarize() {
    final url = _urlController.text.trim();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            AddNoteScreen(initialUrl: url.isNotEmpty ? url : null),
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        width: 300,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    final authProvider = Provider.of<AuthProvider>(context);
    final notesProvider = Provider.of<NotesProvider>(context);

    if (isDesktop) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
        body: _buildDesktopLayout(
          context,
          isDark,
          primaryColor,
          authProvider,
          notesProvider,
        ),
      );
    }

    return _buildMobileLayout(
      context,
      isDark,
      primaryColor,
      authProvider,
      notesProvider,
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    AuthProvider auth,
    NotesProvider notesProvider,
  ) {
    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: RefreshIndicator(
            onRefresh: () async => _loadNotes(),
            color: primaryColor,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
              children: [
                // ─── App Bar Row (Mobile only) ────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 12),
                        const SizedBox(width: 4),
                        Image.asset('assets/icon/aidea-logo.png', height: 28),
                        const SizedBox(width: 8),
                        Text(
                          'AiDea',
                          style:
                              AppTheme.headline3(
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.lightTextPrimary,
                              ).copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                        ),
                      ],
                    ),
                    // Profile avatar — taps to Account tab
                    Builder(
                      builder: (context) {
                        final name = auth.user?.displayName ?? 'U';
                        final photoUrl = auth.user?.photoUrl;
                        return GestureDetector(
                          onTap: () {
                            final shell = context
                                .findAncestorStateOfType<MainShellState>();
                            if (shell != null) {
                              shell.switchToTab(2);
                            }
                          },
                          child: Hero(
                            tag: 'profile_avatar',
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: isDark
                                  ? AppTheme.darkSurface
                                  : AppTheme.lightSurface,
                              backgroundImage: photoUrl != null
                                  ? CachedNetworkImageProvider(photoUrl)
                                  : null,
                              child: photoUrl == null
                                  ? Text(
                                      name[0].toUpperCase(),
                                      style: AppTheme.labelLarge(
                                        color: primaryColor,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 32),

                // ─── Hero Section ───────────────────────────
                RichText(
                      text: TextSpan(
                        style: AppTheme.headline1(
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                        ),
                        children: [
                          const TextSpan(text: 'Refine the Chaos into '),
                          TextSpan(
                            text: 'Authoritative Narrative',
                            style: TextStyle(color: primaryColor),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 500.ms)
                    .slideY(
                      begin: 0.1,
                      duration: 500.ms,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 16),

                Text(
                  'The world\'s most sophisticated distillation engine. We transform raw information into high-fidelity, curated intelligence for those who value depth.',
                  style: AppTheme.bodyLarge(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                const SizedBox(height: 32),

                // ─── URL Input ──────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkSurface
                        : AppTheme.lightSurface,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: TextField(
                    controller: _urlController,
                    style: AppTheme.bodyMedium(
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Paste YouTube or Video link...',
                      prefixIcon: Icon(
                        Icons.link,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                const SizedBox(height: 12),

                // ─── Summarize Button ───────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_urlController.text.trim().isEmpty) {
                        _showToast('Please paste a video link first');
                        return;
                      }
                      _handleSummarize();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                      foregroundColor: isDark ? AppTheme.darkBg : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                      ),
                      elevation: 8,
                      shadowColor:
                          (isDark ? Colors.black : AppTheme.lightTextPrimary)
                              .withValues(alpha: 0.15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Summarize', style: AppTheme.button()),
                        const SizedBox(width: 8),
                        const Icon(Icons.auto_awesome, size: 20),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                const SizedBox(height: 40),

                // ─── Quote Card ─────────────────────────────
                const EditorialQuoteCard(
                  quote:
                      'Information is not knowledge. The only source of knowledge is experience and focused reflection.',
                  attribution: 'WEEKLY INSPIRATION',
                ).animate().fadeIn(delay: 500.ms, duration: 500.ms),

                const SizedBox(height: 40),

                // ─── Search Bar ─────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => notesProvider.setSearchQuery(value),
                    style: AppTheme.bodyMedium(
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search',
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                notesProvider.clearSearch();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ).animate().fadeIn(delay: 450.ms, duration: 400.ms),

                const SizedBox(height: 32),

                // ─── Recent Summaries ───────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Summaries',
                          style: AppTheme.headline3(
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 3,
                          width: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.coral,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to Favorites tab (index 1) via parent MainShell
                        _showToast(
                          'Switch to the Favorites tab to see your archive',
                        );
                      },
                      child: Text(
                        'VIEW ALL',
                        style: AppTheme.labelSmall(
                          color: primaryColor,
                        ).copyWith(letterSpacing: 1),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

                const SizedBox(height: 20),

                // ─── Notes List ─────────────────────────────
                if (notesProvider.notes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 64,
                          color: isDark
                              ? AppTheme.darkTextSecondary.withValues(
                                  alpha: 0.3,
                                )
                              : AppTheme.lightTextSecondary.withValues(
                                  alpha: 0.3,
                                ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No summaries yet',
                          style: AppTheme.titleMedium(
                            color: isDark
                                ? AppTheme.darkTextSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Paste a video link above to get started',
                          style: AppTheme.bodySmall(
                            color: isDark
                                ? AppTheme.darkTextSecondary.withValues(
                                    alpha: 0.6,
                                  )
                                : AppTheme.lightTextSecondary.withValues(
                                    alpha: 0.6,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      ...List.generate(notesProvider.notes.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: NoteCard(
                            note: notesProvider.notes[index],
                            index: index,
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                      Text(
                        'END OF RECENT UPDATES',
                        style: AppTheme.labelSmall(
                          color:
                              (isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary)
                                  .withValues(alpha: 0.5),
                        ).copyWith(letterSpacing: 2),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    AuthProvider auth,
    NotesProvider notesProvider,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 100, bottom: 80, left: 32, right: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Hero Section
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (isDark
                      ? AppTheme.darkSurface
                      : Theme.of(context).colorScheme.secondaryContainer),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Text(
                  'INTELLIGENCE REDEFINED',
                  style: AppTheme.labelSmall(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : Theme.of(context).colorScheme.secondary,
                  ).copyWith(fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

              const SizedBox(height: 24),

              RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: AppTheme.headline1(
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ).copyWith(fontSize: 72, height: 0.9),
                      children: [
                        const TextSpan(text: 'Refine the Chaos into '),
                        TextSpan(
                          text: 'Authoritative Narrative',
                          style: TextStyle(
                            color: primaryColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 500.ms)
                  .slideY(begin: 0.1),

              const SizedBox(height: 32),

              Text(
                'The world\'s most sophisticated distillation engine. We transform raw information into high-fidelity, curated intelligence for those who value depth.',
                textAlign: TextAlign.center,
                style: AppTheme.bodyLarge(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ).copyWith(fontSize: 20, fontWeight: FontWeight.w300),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

              const SizedBox(height: 48),

              // Search Interaction
              Center(
                child: Container(
                  width: 700,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.black : Colors.black)
                            .withValues(alpha: 0.06),
                        blurRadius: 60,
                        offset: const Offset(0, 40),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(
                          Icons.link,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          style: AppTheme.bodyMedium(
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.lightTextPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Paste article or video URL...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (_urlController.text.trim().isEmpty) {
                            _showToast('Please paste a link first');
                            return;
                          }
                          _handleSummarize();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppTheme.darkTextPrimary
                              : primaryColor,
                          foregroundColor: isDark
                              ? AppTheme.darkBg
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Summarize',
                              style: AppTheme.button().copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

              const SizedBox(height: 64),

              // ─── Desktop Search Bar ──────────────────────
              Center(
                child: Container(
                  width: 500,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => notesProvider.setSearchQuery(value),
                    style: AppTheme.bodyMedium(
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search your summaries...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                notesProvider.clearSearch();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 350.ms, duration: 400.ms),

              const SizedBox(height: 80),

              // Split Grid
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Feed
                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Curations',
                              style: AppTheme.headline3(
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : primaryColor,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.grid_view,
                                    color: _isGridView
                                        ? primaryColor
                                        : (isDark
                                              ? AppTheme.darkTextSecondary
                                              : AppTheme.lightTextSecondary),
                                  ),
                                  onPressed: () =>
                                      setState(() => _isGridView = true),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(
                                    Icons.view_agenda,
                                    color: !_isGridView
                                        ? primaryColor
                                        : (isDark
                                                  ? AppTheme.darkTextSecondary
                                                  : AppTheme.lightTextSecondary)
                                              .withValues(alpha: 0.5),
                                  ),
                                  onPressed: () =>
                                      setState(() => _isGridView = false),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        if (notesProvider.notes.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'No curations yet. Paste a link above to get started.',
                                style: AppTheme.bodyMedium(
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.lightTextSecondary,
                                ),
                              ),
                            ),
                          )
                        else if (_isGridView)
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 40,
                                  mainAxisSpacing: 40,
                                  childAspectRatio: 0.7,
                                ),
                            itemCount: notesProvider.notes.length,
                            itemBuilder: (context, index) {
                              return NoteCard(
                                note: notesProvider.notes[index],
                                index: index,
                              );
                            },
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: notesProvider.notes.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 24),
                            itemBuilder: (context, index) {
                              return NoteCard(
                                note: notesProvider.notes[index],
                                index: index,
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 64),
                  // Sidebar
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        // Smart quote
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkSurface
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -20,
                                bottom: -20,
                                child: Icon(
                                  Icons.format_quote,
                                  size: 100,
                                  color: Theme.of(context).colorScheme.tertiary
                                      .withValues(alpha: 0.05),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Editorial Tip',
                                    style: AppTheme.headline3(
                                      color: primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '"Clarity is the byproduct of ruthless distillation. Use AiDea to identify the core argument before you begin your own analysis."',
                                    style:
                                        AppTheme.bodyMedium(
                                          color: isDark
                                              ? AppTheme.darkTextSecondary
                                              : AppTheme.lightTextSecondary,
                                        ).copyWith(
                                          fontStyle: FontStyle.italic,
                                          height: 1.6,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),
                        // Curation Mastery
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CURATION MASTERY',
                              style:
                                  AppTheme.labelSmall(
                                    color: isDark
                                        ? AppTheme.darkTextSecondary
                                        : Theme.of(context).colorScheme.outline,
                                  ).copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                            ),
                            const SizedBox(height: 24),
                            _buildSidebarFeature(
                              '01',
                              'Define the Lens',
                              'Set specific persona parameters for precise extraction.',
                              isDark,
                              () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const AddNoteScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            _buildSidebarFeature(
                              '02',
                              'Verify Sources',
                              'Auto-cross-reference claims against our vetted database.',
                              isDark,
                              () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const AddNoteScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            _buildSidebarFeature(
                              '03',
                              'Style Transfer',
                              'Apply your brand\'s unique voice to the distilled insights.',
                              isDark,
                              () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const AddNoteScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFeature(
    String number,
    String title,
    String subtitle,
    bool isDark,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkSurface
                    : Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                number,
                style:
                    AppTheme.headline3(
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : Theme.of(context).colorScheme.primary,
                    ).copyWith(
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.titleMedium(
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTheme.bodySmall(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary,
                    ).copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

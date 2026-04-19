import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/note_card.dart';
import '../../widgets/editorial_quote_card.dart';

/// Favorites tab — curated bookmarks with search and filter.
class FavoritesTab extends StatefulWidget {
  const FavoritesTab({super.key});

  @override
  State<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCollection = 'All Items';
  bool _sortNewestFirst = true;

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites();
    });
  }

  void _loadFavorites() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notesProvider = Provider.of<NotesProvider>(context, listen: false);
    if (authProvider.user != null) {
      notesProvider.loadFavoriteNotes(authProvider.user!.id);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> _filteredNotes(List<dynamic> notes) {
    var filtered = notes;

    // First apply collection filter
    if (_selectedCollection != 'All Items') {
      // In a real app we'd have categories.
      // For now we'll just mock it by showing only even/odd items or similar if there's no real category field.
      // Looking at the note object in other files, it might not have 'category'.
      // However, we can at least show it works by changing the list.
      // But let's check if 'category' exists.
    }

    if (_searchQuery.isEmpty) return filtered;
    return filtered.where((note) {
      final title = note.videoTitle.toLowerCase();
      final content = note.notes.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query) || content.contains(query);
    }).toList();
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
            onRefresh: () async => _loadFavorites(),
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
                    Builder(
                      builder: (context) {
                        final name = auth.user?.displayName ?? 'U';
                        return CircleAvatar(
                          radius: 20,
                          backgroundColor: isDark
                              ? AppTheme.darkSurface
                              : AppTheme.lightSurface,
                          child: Text(
                            name[0].toUpperCase(),
                            style: AppTheme.labelLarge(color: primaryColor),
                          ),
                        );
                      },
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 32),

                // ─── Section Header ─────────────────────────
                Text(
                  'NOTE',
                  style: AppTheme.labelSmall(
                    color: primaryColor,
                  ).copyWith(letterSpacing: 2),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 8),

                Text(
                      'Saved Recommendations',
                      style: AppTheme.headline2(
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 150.ms)
                    .slideY(
                      begin: 0.1,
                      duration: 400.ms,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 8),

                Text(
                  'Your curated repository of intelligence, synchronized across all your cognitive workflows.',
                  style: AppTheme.bodyMedium(
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 24),

                // ─── Search ─────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkSurface
                        : AppTheme.lightSurface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: AppTheme.bodyMedium(
                      color: isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search',
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.close,
                                size: 18,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ).animate().fadeIn(delay: 250.ms),

                const SizedBox(height: 24),

                // ─── Favorites List ─────────────────────────
                Builder(
                  builder: (context) {
                    final favorites = _filteredNotes(
                      notesProvider.favoriteNotes,
                    );

                    if (notesProvider.favoriteNotes.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Column(
                          children: [
                            Icon(
                              Icons.bookmark_outline,
                              size: 64,
                              color:
                                  (isDark
                                          ? AppTheme.darkTextSecondary
                                          : AppTheme.lightTextSecondary)
                                      .withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No saved Recommendations yet',
                              style: AppTheme.titleMedium(
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bookmark your favorite summaries to see them here',
                              style: AppTheme.bodySmall(
                                color:
                                    (isDark
                                            ? AppTheme.darkTextSecondary
                                            : AppTheme.lightTextSecondary)
                                        .withValues(alpha: 0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    if (favorites.isEmpty && _searchQuery.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color:
                                  (isDark
                                          ? AppTheme.darkTextSecondary
                                          : AppTheme.lightTextSecondary)
                                      .withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No results for "$_searchQuery"',
                              style: AppTheme.titleMedium(
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        ...List.generate(favorites.length, (index) {
                          final items = <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: NoteCard(
                                note: favorites[index],
                                index: index,
                              ),
                            ),
                          ];

                          // Insert a quote card after the second item
                          if (index == 1 && favorites.length > 2) {
                            items.add(
                              const Padding(
                                padding: EdgeInsets.only(bottom: 16),
                                child: EditorialQuoteCard(
                                  quote:
                                      'Intelligence is the ability to adapt to change.',
                                  attribution: 'STEPHEN HAWKING',
                                ),
                              ),
                            );
                          }

                          return Column(children: items);
                        }),
                      ],
                    );
                  },
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PERSONAL NOTE',
                        style: AppTheme.labelSmall(color: primaryColor)
                            .copyWith(
                              letterSpacing: 2,
                              fontWeight: FontWeight.w900,
                            ),
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 8),
                      Text(
                        'Saved Recommendations',
                        style: AppTheme.headline1(
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : Theme.of(context).colorScheme.tertiary,
                        ).copyWith(fontSize: 48),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.sort, size: 16),
                        label: const Text('Recently Saved'),
                        onPressed: () => setState(
                          () => _sortNewestFirst = !_sortNewestFirst,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppTheme.darkSurface
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHigh,
                          foregroundColor: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.auto_stories, size: 16),
                        label: const Text('Digest Mode'),
                        onPressed: () => _showToast(
                          'Digest Mode provides a condensed view of your saved Recommendations',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms),
                ],
              ),
              const SizedBox(height: 48),

              // Layout
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sidebar
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COLLECTIONS',
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
                        _buildCollectionItem(
                          'All Items',
                          Icons.folder,
                          '${notesProvider.favoriteNotes.length}',
                          isDark,
                        ),
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkSurface
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Newsletter Sync',
                                style: AppTheme.titleMedium(
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : Theme.of(context).colorScheme.tertiary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Your saved items are automatically synced with your weekly editorial digest.',
                                style: AppTheme.bodySmall(
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  onPressed: () => _showToast(
                                    'Newsletter sync configuration available soon',
                                  ),
                                  style: TextButton.styleFrom(
                                    backgroundColor: isDark
                                        ? AppTheme.darkSurfaceHigh
                                        : Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  child: Text(
                                    'CONFIGURE SYNC',
                                    style: AppTheme.labelSmall(
                                      color: isDark
                                          ? AppTheme.darkTextPrimary
                                          : Theme.of(
                                              context,
                                            ).colorScheme.tertiary,
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                  // Main content column with search + grid
                  Expanded(
                    flex: 9,
                    child: Column(
                      children: [
                        // Search bar for desktop
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.darkSurface
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) =>
                                setState(() => _searchQuery = value),
                            style: AppTheme.bodyMedium(
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.lightTextPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search',
                              prefixIcon: Icon(
                                Icons.search,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.close,
                                        size: 18,
                                        color: isDark
                                            ? AppTheme.darkTextSecondary
                                            : AppTheme.lightTextSecondary,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
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
                        // Bento Grid
                        Builder(
                          builder: (context) {
                            var favorites = _filteredNotes(
                              notesProvider.favoriteNotes,
                            );
                            // Apply sort
                            if (!_sortNewestFirst) {
                              favorites = List.from(favorites)
                                ..sort(
                                  (a, b) => a.createdAt.compareTo(b.createdAt),
                                );
                            }

                            if (notesProvider.favoriteNotes.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 80,
                                  ),
                                  child: Text(
                                    'No saved Recommendations yet.',
                                    style: AppTheme.bodyLarge(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                                  ),
                                ),
                              );
                            }

                            if (favorites.isEmpty && _searchQuery.isNotEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 80,
                                  ),
                                  child: Text(
                                    'No results for "$_searchQuery"',
                                    style: AppTheme.bodyLarge(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                                  ),
                                ),
                              );
                            }

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 32,
                                    mainAxisSpacing: 32,
                                    childAspectRatio: 0.85,
                                  ),
                              itemCount: favorites.length,
                              itemBuilder: (context, index) {
                                return NoteCard(
                                  note: favorites[index],
                                  index: index,
                                );
                              },
                            );
                          },
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

  Widget _buildCollectionItem(
    String title,
    IconData icon,
    String count,
    bool isDark,
  ) {
    final isSelected = _selectedCollection == title;
    return InkWell(
      onTap: () {
        setState(() => _selectedCollection = title);
        if (title != 'All Items') {
          _showToast('$title collection view coming soon');
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? AppTheme.darkSurface
                    : Theme.of(context).colorScheme.secondaryContainer)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onSecondaryContainer
                      : (isDark
                            ? AppTheme.darkTextSecondary
                            : Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: AppTheme.titleMedium(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onSecondaryContainer
                        : (isDark
                              ? AppTheme.darkTextSecondary
                              : Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            Text(
              count,
              style: AppTheme.labelSmall(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

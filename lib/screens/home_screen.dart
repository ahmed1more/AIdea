import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/notes_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/note_card.dart';
import '../widgets/search_bar_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _searchQuery = '';
  String? _selectedCategory;
  bool _showFavoritesOnly = false;

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesStreamProvider);
    final user = ref.watch(currentUserProvider);
    final stats = ref.watch(notesStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PopSci Notes',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${stats.totalNotes} notes',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
              color: _showFavoritesOnly ? Colors.red : null,
            ),
            onPressed: () {
              setState(() {
                _showFavoritesOnly = !_showFavoritesOnly;
              });
            },
            tooltip: 'Show favorites only',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedCategory = value == 'all' ? null : value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Categories')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'Physics', child: Text('Physics')),
              const PopupMenuItem(value: 'Biology', child: Text('Biology')),
              const PopupMenuItem(value: 'Chemistry', child: Text('Chemistry')),
              const PopupMenuItem(value: 'Astronomy', child: Text('Astronomy')),
              const PopupMenuItem(
                value: 'Technology',
                child: Text('Technology'),
              ),
              const PopupMenuItem(
                value: 'Mathematics',
                child: Text('Mathematics'),
              ),
            ],
          ),
          PopupMenuButton(
            icon: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(user?.displayName ?? 'User'),
                  subtitle: Text(user?.email ?? ''),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                ),
                onTap: () => Future.delayed(
                  Duration.zero,
                  () => context.push('/settings'),
                ),
              ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Sign Out'),
                ),
                onTap: () async {
                  await ref.read(authServiceProvider).signOut();
                },
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBarWidget(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          if (_selectedCategory != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Chip(
                    label: Text(_selectedCategory!),
                    onDeleted: () {
                      setState(() {
                        _selectedCategory = null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${stats.categoriesCount[_selectedCategory] ?? 0} notes',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          Expanded(
            child: notesAsync.when(
              data: (notes) {
                var filteredNotes = notes.where((note) {
                  final matchesSearch =
                      _searchQuery.isEmpty ||
                      note.title.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      note.content.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      note.tags.any(
                        (tag) => tag.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                      );

                  final matchesCategory =
                      _selectedCategory == null ||
                      note.category == _selectedCategory;

                  final matchesFavorite =
                      !_showFavoritesOnly || note.isFavorite;

                  return matchesSearch && matchesCategory && matchesFavorite;
                }).toList();

                if (filteredNotes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isEmpty
                              ? Icons.science_outlined
                              : Icons.search_off,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No notes yet'
                              : 'No notes found',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Create your first science note!'
                              : 'Try a different search term',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(notesStreamProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];
                      return NoteCard(
                        note: note,
                        onTap: () => context.push('/note/${note.id}'),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading notes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.invalidate(notesStreamProvider);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/note/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ),
    );
  }
}

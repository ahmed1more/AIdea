import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
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

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Header ──────────────────────────────────────
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(ctx).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.video_library_rounded,
                              color: Theme.of(
                                ctx,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Add Video Note',
                            style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── URL field ───────────────────────────────────
                      TextFormField(
                        controller: urlController,
                        autofocus: true,
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          labelText: 'YouTube URL',
                          hintText: 'https://youtube.com/watch?v=...',
                          prefixIcon: const Icon(Icons.link_rounded),
                          suffixIcon: isFetchingTitle
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : isValid
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : urlController.text.isNotEmpty
                              ? const Icon(
                                  Icons.error_rounded,
                                  color: Colors.red,
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          final valid = _isValidYoutubeUrl(value.trim());
                          setDialogState(() {
                            isValid = valid;
                            // reset title preview when URL changes
                            fetchedTitle = null;
                            fetchError = null;
                          });
                          if (valid) {
                            _fetchTitle(value.trim(), setDialogState);
                          }
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a YouTube URL';
                          }
                          if (!_isValidYoutubeUrl(value.trim())) {
                            return 'Please enter a valid YouTube URL';
                          }
                          return null;
                        },
                      ),

                      // ── Validation hint ─────────────────────────────
                      const SizedBox(height: 6),
                      AnimatedOpacity(
                        opacity: urlController.text.isNotEmpty ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          isValid
                              ? '✓ Valid YouTube URL'
                              : '✗ Not a valid YouTube URL',
                          style: TextStyle(
                            fontSize: 12,
                            color: isValid ? Colors.green : Colors.red,
                          ),
                        ),
                      ),

                      // ── Fetched title preview ────────────────────────
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: fetchedTitle != null
                            ? Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    ctx,
                                  ).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.play_circle_outline_rounded,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        fetchedTitle!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : fetchError != null
                            ? Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '⚠ $fetchError',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(ctx).colorScheme.error,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 20),

                      // ── OR divider ───────────────────────────────────
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(ctx).colorScheme.outline,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ── Pick from files button ───────────────────────
                      OutlinedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.video,
                            allowMultiple: false,
                          );
                          if (result != null && result.files.isNotEmpty) {
                            final file = result.files.first;
                            final title = file.name
                                .replaceAll(RegExp(r'\.[^.]+$'), '')
                                .replaceAll(RegExp(r'[_-]'), ' ');
                            // ignore: use_build_context_synchronously
                            Navigator.of(ctx).pop();
                            // ignore: use_build_context_synchronously
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AddNoteScreen(
                                  initialUrl: file.path ?? file.name,
                                  initialTitle: title,
                                  pickedFile: file,
                                ),
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.folder_open_rounded),
                        label: const Text('Pick a video from your files'),
                      ),

                      const SizedBox(height: 20),

                      // ── Action buttons ───────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: (isValid && !isFetchingTitle)
                                ? () {
                                    if (formKey.currentState!.validate()) {
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
                                  }
                                : null,
                            icon: isFetchingTitle
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.arrow_forward_rounded),
                            label: Text(
                              isFetchingTitle ? 'Fetching...' : 'Continue',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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
    return Scaffold(
      appBar: AppBar(title: const Text('AIdea')),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
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

          // Content based on selected tab
          Expanded(
            child: _selectedIndex == 0
                ? _buildAllNotesTab()
                : _buildFavoritesTab(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'All Notes',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final user = auth.user;
                return CircleAvatar(
                  radius: 14,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  backgroundImage: user?.photoUrl != null
                      ? NetworkImage(user!.photoUrl!)
                      : null,
                  child: user?.photoUrl == null
                      ? Text(
                          (user?.displayName ?? 'U')[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        )
                      : null,
                );
              },
            ),
            label: 'Account',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddNoteDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ),
    );
  }

  Widget _buildAllNotesTab() {
    return Consumer<NotesProvider>(
      builder: (context, notesProvider, child) {
        if (notesProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (notesProvider.notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.video_library_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No notes yet',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the button below to add your first note',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notesProvider.notes.length,
          itemBuilder: (context, index) {
            return NoteCard(note: notesProvider.notes[index]);
          },
        );
      },
    );
  }

  Widget _buildFavoritesTab() {
    return Consumer<NotesProvider>(
      builder: (context, notesProvider, child) {
        if (notesProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (notesProvider.favoriteNotes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No favorite notes',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mark notes as favorites to see them here',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notesProvider.favoriteNotes.length,
          itemBuilder: (context, index) {
            return NoteCard(note: notesProvider.favoriteNotes[index]);
          },
        );
      },
    );
  }
}

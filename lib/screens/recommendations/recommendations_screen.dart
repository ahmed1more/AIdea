import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/shared_video_card.dart';
import '../home/add_note_screen.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  List<dynamic> recommendations = [];
  bool isLoading = true;
  String? error;
  bool isPersonalized = false;
  int interactionsCount = 0;
  int interactionsNeeded = 5;

  @override
  void initState() {
    super.initState();
    loadRecommendations();
  }

  Future<void> loadRecommendations() async {
    if (!mounted) return; // ← guard at the start too

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();

      // ← widget might have been disposed while awaiting the token
      if (!mounted) return;

      final response = await http.get(
        Uri.parse('https://atinc1-aidea-server.hf.space/recommendations'),
        headers: {'Authorization': 'Bearer $token'},
      );

      // ← widget might have been disposed while awaiting the HTTP response
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          recommendations = data['recommendations'];
          isPersonalized = data['is_personalized'] ?? false;
          interactionsCount = data['interactions_count'] ?? 0;
          interactionsNeeded = data['interactions_needed'] ?? 5;
          isLoading = false;
        });
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          error =
              data['detail'] ??
              'Unexpected error while fetching recommendations.';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return; // ← guard before setState in catch too
      setState(() {
        error = 'Network error. Please check your connection.';
        isLoading = false;
      });
    }
  }

  // Video launching removed in favor of navigating to AddNoteScreen

  Widget _buildColdStartBanner(bool isDark) {
    final progress = (interactionsCount / interactionsNeeded).clamp(0.0, 1.0);
    final remaining = interactionsNeeded - interactionsCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.wandMagicSparkles,
                size: 16,
                color: Colors.amber,
              ),
              const SizedBox(width: 8),
              Text(
                'Personalizing your feed...',
                style: AppTheme.bodyMedium(color: Colors.amber),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.amber.withValues(alpha: 0.2),
              color: Colors.amber,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$remaining more ${remaining == 1 ? 'interaction' : 'interactions'} until your feed is personalized.',
            style: AppTheme.bodyMedium(
              color: isDark
                  ? AppTheme.darkTextSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.triangleExclamation,
              size: 48,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: loadRecommendations,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.lightbulb,
              size: 64,
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.2,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Recommendations Yet',
              style: AppTheme.headline3(
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Smart suggestions based on your study habits will appear here.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(dynamic video, BuildContext context) {
    final videoId = video['videoId'] as String?;
    final title = video['title'] ?? 'Untitled';
    final category = video['channelTitle'] ?? 'Recommendation';
    final thumbnail = video['thumbnail'] ?? '';

    return SharedVideoCard(
      title: title,
      thumbnail: thumbnail,
      categories: [category],
      dateString: 'Recently recommended',
      showActions: false,
      onTap: () {
        if (videoId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddNoteScreen(
                initialUrl: 'https://youtube.com/watch?v=$videoId',
                initialTitle: title,
              ),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return _buildErrorState(isDark);
    }

    if (recommendations.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return RefreshIndicator(
      onRefresh: loadRecommendations,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isPersonalized) _buildColdStartBanner(isDark),
            MasonryGridView.count(
              crossAxisCount: isWide ? 4 : 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              itemCount: recommendations.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final video = recommendations[index];
                return _buildVideoCard(video, context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

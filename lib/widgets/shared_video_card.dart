import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/settings_provider.dart';

/// A shared widget for rendering video cards (used in saved notes and recommendations)
class SharedVideoCard extends StatelessWidget {
  final String title;
  final String thumbnail;
  final List<String> categories;
  final String dateString;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onDeleteTap;
  final bool showActions;

  const SharedVideoCard({
    super.key,
    required this.title,
    required this.thumbnail,
    required this.categories,
    required this.dateString,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteTap,
    this.onDeleteTap,
    this.showActions = true,
  });

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Technology & AI':
        return FontAwesomeIcons.microchip;
      case 'Business & Finance':
        return FontAwesomeIcons.chartLine;
      case 'Education & Science':
        return FontAwesomeIcons.flask;
      case 'Productivity & Self-Growth':
        return FontAwesomeIcons.rocket;
      case 'News & Politics':
        return FontAwesomeIcons.newspaper;
      case 'Entertainment & Lifestyle':
        return FontAwesomeIcons.mugHot;
      case 'Health & Sports':
        return FontAwesomeIcons.heartPulse;
      case 'Uncategorized':
      default:
        return FontAwesomeIcons.folderOpen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = Provider.of<SettingsProvider>(context);

    return RepaintBoundary(
      child: Animate(
        effects: [
          FadeEffect(duration: 400.ms),
          SlideEffect(
            begin: const Offset(0, 0.05),
            duration: 400.ms,
            curve: Curves.easeOutCubic,
          ),
        ],
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: settings.glassMorphicContainer(
                  context: context,
                  opacity: isDark ? 0.05 : 0.7,
                  blur: isDark ? 8 : 4, // Reduced blur for performance in grid
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail with Play Overlay
                      if (thumbnail.isNotEmpty)
                        Stack(
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.network(
                                thumbnail,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: settings.accentColor.withValues(alpha: 0.1),
                                    child: Icon(
                                      FontAwesomeIcons.circlePlay,
                                      size: 40,
                                      color: settings.accentColor,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.5),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: CircleAvatar(
                                backgroundColor: settings.accentColor,
                                radius: 18,
                                child: const Icon(
                                  FontAwesomeIcons.play,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
  
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                FaIcon(
                                  _getCategoryIcon(categories.isNotEmpty ? categories.first : 'Uncategorized'),
                                  size: 10,
                                  color: settings.accentColor.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    categories.length > 1 
                                        ? '${categories.first} +${categories.length - 1}'
                                        : (categories.isNotEmpty ? categories.first : 'Uncategorized'),
                                    style: GoogleFonts.inter(
                                      color: isDark ? Colors.white54 : Colors.grey[600],
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dateString,
                                  style: GoogleFonts.inter(
                                    color: isDark ? Colors.white30 : Colors.grey[400],
                                    fontSize: 10,
                                  ),
                                ),
                                if (showActions)
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: onFavoriteTap,
                                        child: Icon(
                                          isFavorite ? Icons.favorite : Icons.favorite_border,
                                          color: isFavorite ? Colors.red : (isDark ? Colors.white30 : Colors.grey[400]),
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      GestureDetector(
                                        onTap: onDeleteTap,
                                        child: Icon(
                                          Icons.delete_outline,
                                          color: Colors.red.withValues(alpha: 0.3),
                                          size: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

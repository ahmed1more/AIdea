import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../theme/app_theme.dart';

class CustomYoutubePlayer extends StatefulWidget {
  final String videoUrl;
  final String? initialTitle;
  final VoidCallback? onBack;

  const CustomYoutubePlayer({
    super.key,
    required this.videoUrl,
    this.initialTitle,
    this.onBack,
  });

  @override
  State<CustomYoutubePlayer> createState() => _CustomYoutubePlayerState();
}

class _CustomYoutubePlayerState extends State<CustomYoutubePlayer> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;
  bool _showControls = true;
  bool _tookTooLong = false;
  Timer? _loadingTimer;

  @override
  void initState() {
    super.initState();
    _startLoadingTimer();
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
    
    if (videoId == null || videoId.isEmpty) {
      debugPrint('Invalid YouTube URL: ${widget.videoUrl}');
    }

    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
        enableCaption: true,
      ),
    )..addListener(_listener);
  }

  void _startLoadingTimer() {
    _loadingTimer?.cancel();
    _loadingTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && !_isPlayerReady && !_controller.value.hasError) {
        setState(() {
          _tookTooLong = true;
        });
      }
    });
  }

  void _listener() {
    if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
      setState(() {});
    }
    if (_controller.value.hasError) {
      if (mounted) {
        setState(() {
          _isPlayerReady = false;
        });
      }
    }
  }

  @override
  void deactivate() {
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _controller.removeListener(_listener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: false,
        onReady: () {
          setState(() {
            _isPlayerReady = true;
          });
        },
      ),
      builder: (context, player) {
        final hasError = _controller.value.hasError;
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Stack(
            children: [
              player,
              if (_isPlayerReady && !hasError)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showControls = !_showControls;
                      });
                    },
                    child: AnimatedOpacity(
                      opacity: _showControls ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.4),
                        child: _showControls ? _buildControlsOverlay() : null,
                      ),
                    ),
                  ),
                ),
              if (!_isPlayerReady && !hasError)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.7),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                          if (_tookTooLong || kIsWeb) ...[
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                _tookTooLong 
                                  ? "This is taking longer than usual..." 
                                  : "Preparing video...",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.manrope(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _launchUrl(widget.videoUrl),
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white30, width: 1),
                                    borderRadius: BorderRadius.circular(30),
                                    color: Colors.white10,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.open_in_new, size: 16, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Open in YouTube',
                                        style: GoogleFonts.manrope(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              if (hasError)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.85),
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Video Unavailable',
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'The player encountered an issue or the video is restricted. You can still watch it directly on YouTube.',
                            style: GoogleFonts.manrope(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _launchUrl(widget.videoUrl),
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white30, width: 1),
                                  borderRadius: BorderRadius.circular(30),
                                  color: Colors.white10,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.open_in_new, size: 16, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Watch on YouTube',
                                      style: GoogleFonts.manrope(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                       ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlsOverlay() {
    final metaData = _controller.metadata;
    final title = metaData.title.isNotEmpty ? metaData.title : (widget.initialTitle ?? 'Loading...');
    final author = metaData.author.isNotEmpty ? metaData.author : 'YouTube';
    final durationText = '${_durationToString(_controller.value.position)} / ${_durationToString(_controller.metadata.duration)}';

    return Column(
      children: [
        // ─── Top Bar ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.onBack != null)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  onPressed: widget.onBack,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              const SizedBox(width: 12),
              // "Visit" Button (زيارة)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'زيارة',
                      style: GoogleFonts.notoKufiArabic(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.open_in_new, color: Colors.white, size: 14),
                  ],
                ),
              ),
              const Spacer(),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      author,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Top Right YouTube Logo
              const Icon(Icons.play_circle_filled, color: Colors.red, size: 28),
            ],
          ),
        ),

        // ─── Secondary Control Row ─────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _ControlIcon(
                icon: Icons.settings_outlined,
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _ControlIcon(
                icon: Icons.closed_caption_outlined,
                onTap: () {
                  // Toggle captions isn't directly exposed in all versions, 
                  // using a placeholder for now or checking if there's an alternative.
                },
              ),
              const SizedBox(width: 8),
              _ControlIcon(
                icon: _controller.value.volume == 0 ? Icons.volume_off_outlined : Icons.volume_up_outlined,
                onTap: () {
                  _controller.value.volume == 0 ? _controller.unMute() : _controller.mute();
                },
              ),
            ],
          ),
        ),

        const Spacer(),

        // ─── Center Play/Pause ─────────────────────────────────────
        Center(
          child: GestureDetector(
            onTap: () {
              _controller.value.isPlaying ? _controller.pause() : _controller.play();
            },
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 2),
              ),
              child: Icon(
                _controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        ),

        const Spacer(),

        // ─── Bottom Bar ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Custom Progress Bar
              ProgressBar(
                controller: _controller,
                isExpanded: true,
                colors: const ProgressBarColors(
                  playedColor: Colors.red,
                  bufferedColor: Colors.white24,
                  handleColor: Colors.red,
                  backgroundColor: Colors.white10,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  // Bottom YouTube Logo + Text
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_circle_filled, color: Colors.white, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'YouTube',
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Thumbnail preview (cosmetic icon for now)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.crop_original, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    durationText,
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  _ControlIcon(icon: Icons.history, onTap: () {}),
                  _ControlIcon(icon: Icons.reply_outlined, onTap: () {}),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _durationToString(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch video URL')),
        );
      }
    }
  }
}

class _ControlIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ControlIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: Colors.white, size: 22),
      onPressed: onTap,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
    );
  }
}

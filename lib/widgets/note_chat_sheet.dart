import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/ai_service.dart';
import '../theme/app_theme.dart';

/// A single chat message (user or assistant).
class _ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  _ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == 'user';
}

/// Bottom-sheet chat interface for document-specific Q&A.
///
/// All history lives in-memory and is discarded when the sheet closes.
class NoteChatSheet extends StatefulWidget {
  /// The markdown/text content of the note (used as AI context).
  final String noteContent;

  /// Key points from the note (appended to context for richer answers).
  final List<String> keyPoints;

  /// The note title (shown in the header).
  final String noteTitle;

  const NoteChatSheet({
    super.key,
    required this.noteContent,
    required this.keyPoints,
    required this.noteTitle,
  });

  @override
  State<NoteChatSheet> createState() => _NoteChatSheetState();
}

class _NoteChatSheetState extends State<NoteChatSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  /// Build the full context string from notes + key points.
  String get _fullContext {
    final buffer = StringBuffer(widget.noteContent);
    if (widget.keyPoints.isNotEmpty) {
      buffer.writeln('\n\n--- KEY POINTS ---');
      for (int i = 0; i < widget.keyPoints.length; i++) {
        buffer.writeln('${i + 1}. ${widget.keyPoints[i]}');
      }
    }
    return buffer.toString();
  }

  /// Convert message history to the format expected by the API.
  List<Map<String, String>> get _historyForApi {
    return _messages
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    _controller.clear();

    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: text));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final idToken =
          await FirebaseAuth.instance.currentUser?.getIdToken() ?? '';

      // Build history excluding the last user message (it goes as "question")
      final history = _messages.length > 1
          ? _historyForApi.sublist(0, _messages.length - 1)
          : <Map<String, String>>[];

      final answer = await AiService.chatWithNote(
        noteContent: _fullContext,
        question: text,
        history: history.isNotEmpty ? history : null,
        aideaUrl: settings.aideaUrl,
        idToken: idToken,
      );

      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(role: 'assistant', content: answer));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ Error in NoteChatSheet _sendMessage: $e');
      setState(() {
        _messages.add(_ChatMessage(
          role: 'assistant',
          content: 'Something went wrong: $e',
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ─── Handle + Header ──────────────────────────────
          _buildHeader(isDark, primaryColor),

          // ─── Messages ─────────────────────────────────────
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(isDark, primaryColor)
                : _buildMessageList(isDark, primaryColor),
          ),

          // ─── Typing Indicator ─────────────────────────────
          if (_isLoading) _buildTypingIndicator(isDark, primaryColor),

          // ─── Input Bar ────────────────────────────────────
          _buildInputBar(isDark, primaryColor, bottomInset),
        ],
      ),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
          ),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor,
                      primaryColor.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chat with this Note',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.noteTitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 20,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── EMPTY STATE ────────────────────────────────────────────────
  Widget _buildEmptyState(bool isDark, Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.question_answer_outlined,
                size: 28,
                color: primaryColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ask anything about this note',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The AI will answer strictly from the note content.\nTry asking about key concepts, summaries, or details.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _SuggestionChip(
                  label: 'Summarize the main idea',
                  onTap: () {
                    _controller.text = 'What is the main idea of this video?';
                    _sendMessage();
                  },
                  primaryColor: primaryColor,
                  isDark: isDark,
                ),
                _SuggestionChip(
                  label: 'Key takeaways',
                  onTap: () {
                    _controller.text =
                        'What are the most important takeaways?';
                    _sendMessage();
                  },
                  primaryColor: primaryColor,
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }

  // ─── MESSAGE LIST ──────────────────────────────────────────────
  Widget _buildMessageList(bool isDark, Color primaryColor) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return _ChatBubble(
          message: msg,
          isDark: isDark,
          primaryColor: primaryColor,
        ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05);
      },
    );
  }

  // ─── TYPING INDICATOR ─────────────────────────────────────────
  Widget _buildTypingIndicator(bool isDark, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(
                        onPlay: (c) => c.repeat(),
                      )
                      .scaleXY(
                        begin: 0.6,
                        end: 1.0,
                        duration: 600.ms,
                        delay: (i * 150).ms,
                        curve: Curves.easeInOut,
                      )
                      .then()
                      .scaleXY(
                        begin: 1.0,
                        end: 0.6,
                        duration: 600.ms,
                        curve: Curves.easeInOut,
                      ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ─── INPUT BAR ────────────────────────────────────────────────
  Widget _buildInputBar(bool isDark, Color primaryColor, double bottomInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Ask about this note...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: 0.35),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : _sendMessage,
              borderRadius: BorderRadius.circular(50),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isLoading
                        ? [
                            primaryColor.withValues(alpha: 0.3),
                            primaryColor.withValues(alpha: 0.2),
                          ]
                        : [
                            primaryColor,
                            Color.alphaBlend(
                              Colors.blue.withValues(alpha: 0.2),
                              primaryColor,
                            ),
                          ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: _isLoading
                      ? []
                      : [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Icon(
                  _isLoading ? Icons.hourglass_top : Icons.arrow_upward,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CHAT BUBBLE ────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  final bool isDark;
  final Color primaryColor;

  const _ChatBubble({
    required this.message,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 4),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor,
                      primaryColor.withValues(alpha: 0.7),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? primaryColor
                    : (isDark
                        ? AppTheme.darkSurface
                        : AppTheme.lightSurface),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: isDark
                            ? AppTheme.darkDivider
                            : AppTheme.lightDivider,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SelectableText(
                message.content,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: isUser
                      ? Colors.white
                      : (isDark
                          ? AppTheme.darkTextPrimary
                          : AppTheme.lightTextPrimary),
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 36), // balance with avatar
        ],
      ),
    );
  }
}

// ─── SUGGESTION CHIP ────────────────────────────────────────────────

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color primaryColor;
  final bool isDark;

  const _SuggestionChip({
    required this.label,
    required this.onTap,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: primaryColor,
          ),
        ),
      ),
    );
  }
}

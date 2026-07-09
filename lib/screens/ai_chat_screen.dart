import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../core/ai/ai_models.dart';
import '../core/ai/ai_service.dart';
import '../models/note.dart';
import 'ai_menu_sheet.dart' show friendlyAIError;

/// Conversational UI for the "Chat with this note" feature. Streams assistant
/// replies and keeps a session-local history of [ChatMessage]s.
class AIChatScreen extends StatefulWidget {
  final Note note;
  const AIChatScreen({super.key, required this.note});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final List<_ChatBubble> _bubbles = [];
  final List<ChatMessage> _history = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isStreaming = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _bubbles.add(
      _ChatBubble(
        role: 'assistant',
        text:
            "Hi! Ask me anything about this note. I'll answer using only its content.",
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isStreaming) return;

    setState(() {
      _errorMessage = null;
      _isStreaming = true;
      _bubbles.add(_ChatBubble(role: 'user', text: text));
    });
    _inputController.clear();
    _scrollToBottom();

    // Placeholder for the streaming assistant message so we can mutate its
    // content incrementally.
    final pendingIndex = _bubbles.length;
    _bubbles.add(_ChatBubble(role: 'assistant', text: ''));

    final ai = context.read<AIService>();
    try {
      final fullReply = await ai.chatWithNoteStream(
        noteTitle: widget.note.title,
        noteBody: widget.note.description,
        history: _history,
        userMessage: text,
        onDelta: (delta) {
          setState(() {
            _bubbles[pendingIndex] = _ChatBubble(
              role: 'assistant',
              text: _bubbles[pendingIndex].text + delta,
            );
          });
          _scrollToBottom();
        },
      );
      _history
        ..add(ChatMessage(role: 'user', content: text))
        ..add(ChatMessage(role: 'assistant', content: fullReply));
    } catch (e) {
      setState(() {
        // Remove the empty assistant placeholder on failure so users don't
        // see a lingering bubble that has no content.
        if (_bubbles[pendingIndex].text.isEmpty) {
          _bubbles.removeAt(pendingIndex);
        }
        _errorMessage = friendlyAIError(e);
      });
    } finally {
      if (mounted) setState(() => _isStreaming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0F1E), Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              if (_errorMessage != null) _buildError(_errorMessage!),
              Expanded(child: _buildList()),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chat with note',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.note.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF8B83FF),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6584).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF6584).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFFF6584)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _errorMessage = null),
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white70,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: _bubbles.length,
      itemBuilder: (_, i) => _ChatBubbleView(bubble: _bubbles[i]),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E).withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                minLines: 1,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Ask about this note...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF0F0F1E),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isStreaming ? null : _send,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF4834DF)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _isStreaming
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble {
  final String role;
  String text;
  _ChatBubble({required this.role, required this.text});
}

class _ChatBubbleView extends StatelessWidget {
  final _ChatBubble bubble;
  const _ChatBubbleView({required this.bubble});

  @override
  Widget build(BuildContext context) {
    final isUser = bubble.role == 'user';
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bg = isUser ? const Color(0xFF6C63FF) : const Color(0xFF1E1E2E);
    final fg = Colors.white;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isUser ? 16 : 4),
      bottomRight: Radius.circular(isUser ? 4 : 16),
    );

    Widget content;
    if (bubble.text.isEmpty) {
      content = SizedBox(
        width: 120,
        child: LinearProgressIndicator(
          color: fg.withValues(alpha: 0.7),
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          minHeight: 2,
        ),
      );
    } else if (isUser) {
      content = Text(
        bubble.text,
        style: TextStyle(color: fg, fontSize: 15, height: 1.4),
      );
    } else {
      content = MarkdownBody(
        data: bubble.text,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          p: TextStyle(color: fg, fontSize: 15, height: 1.45),
          strong: TextStyle(color: fg, fontWeight: FontWeight.w700),
          em: TextStyle(color: fg.withValues(alpha: 0.95)),
          code: TextStyle(
            color: fg,
            backgroundColor: Colors.black.withValues(alpha: 0.4),
            fontFamily: 'monospace',
            fontSize: 13,
          ),
          codeblockDecoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
          ),
          listBullet: TextStyle(color: fg, fontSize: 15),
        ),
      );
    }

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(color: bg, borderRadius: radius),
        child: content,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../core/ai/ai_models.dart';
import '../core/ai/ai_service.dart';
import '../models/note.dart';
import 'ai_menu_sheet.dart' show friendlyAIError;

class AIBrainstormScreen extends StatefulWidget {
  final Note note;
  const AIBrainstormScreen({super.key, required this.note});

  @override
  State<AIBrainstormScreen> createState() => _AIBrainstormScreenState();
}

class _AIBrainstormScreenState extends State<AIBrainstormScreen> {
  List<BrainstormIdea> _ideas = [];
  String? _rawMarkdown;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final ai = context.read<AIService>();
    try {
      final ideas = await ai.brainstorm(
        noteTitle: widget.note.title,
        noteBody: widget.note.description,
      );
      if (!mounted) return;
      setState(() {
        _ideas = ideas;
        _rawMarkdown = _ideasToMarkdown(ideas);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = friendlyAIError(e);
      });
    }
  }

  /// Renders the structured ideas as a markdown document so we can use the
  /// same `flutter_markdown` renderer as the chat screen.
  String _ideasToMarkdown(List<BrainstormIdea> ideas) {
    final buf = StringBuffer();
    for (final group in ideas) {
      buf.writeln('## ${group.category}');
      buf.writeln();
      for (final idea in group.ideas) {
        buf.writeln('- $idea');
      }
      buf.writeln();
    }
    return buf.toString().trim();
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
              Expanded(child: _buildBody()),
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
                  'Brainstorm',
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
          IconButton(
            onPressed: _isLoading ? null : _load,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Regenerate',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: Color(0xFF6C63FF)),
            SizedBox(height: 16),
            Text(
              'Brainstorming ideas...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFFF6584),
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                ),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    if (_ideas.isEmpty) {
      return Center(
        child: Text(
          'No brainstorm ideas yet.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: MarkdownBody(
          data: _rawMarkdown ?? '',
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            h2: TextStyle(
              color: const Color(0xFF8B83FF),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.8,
            ),
            p: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.5,
            ),
            listBullet: TextStyle(color: const Color(0xFF8B83FF), fontSize: 14),
          ),
        ),
      ),
    );
  }
}

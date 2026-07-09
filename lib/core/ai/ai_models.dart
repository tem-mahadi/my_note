/// Lightweight value types used across the AI layer. Kept in their own file
/// so they're reusable from services, providers, and UI.

/// A single message in a chat conversation.
class ChatMessage {
  final String role; // "system" | "user" | "assistant"
  final String content;
  const ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

/// One task extracted by the AI.
class ExtractedTask {
  final String task;
  final TaskPriority priority;

  const ExtractedTask({required this.task, required this.priority});

  factory ExtractedTask.fromJson(Map<String, dynamic> json) {
    final raw = (json['priority'] as String? ?? 'medium').toLowerCase();
    final prio = TaskPriority.values.firstWhere(
      (p) => p.name == raw,
      orElse: () => TaskPriority.medium,
    );
    return ExtractedTask(
      task: (json['task'] as String? ?? '').trim(),
      priority: prio,
    );
  }
}

enum TaskPriority { low, medium, high }

/// A brainstorm idea returned by the AI (grouped by category).
class BrainstormIdea {
  final String category;
  final List<String> ideas;
  const BrainstormIdea({required this.category, required this.ideas});

  factory BrainstormIdea.fromJson(Map<String, dynamic> json) {
    final rawIdeas = (json['ideas'] as List?) ?? const [];
    return BrainstormIdea(
      category: (json['category'] as String? ?? 'Ideas').trim(),
      ideas: rawIdeas
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    );
  }
}

/// Result of a semantic search query.
class SemanticSearchResult {
  final String noteId;
  final double score; // 0..1, higher is more similar
  const SemanticSearchResult({required this.noteId, required this.score});
}

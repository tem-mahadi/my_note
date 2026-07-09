import 'dart:math' as math;

import 'ai_models.dart';

/// Cosine-similarity helper used by the semantic search feature. Pure Dart so
/// it works on every platform without native code.
class SemanticSearch {
  SemanticSearch._();

  /// Returns a score in `[-1, 1]`. We normalise to `0..1` in [normalise] for
  /// friendlier display ("87% match") and threshold comparisons.
  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0.0;
    double dot = 0, normA = 0, normB = 0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    final denom = math.sqrt(normA) * math.sqrt(normB);
    if (denom == 0) return 0.0;
    return dot / denom;
  }

  /// Map `[-1, 1]` → `[0, 1]` for UI display.
  static double normalise(double score) => (score + 1) / 2;

  /// Rank a list of `(noteId, embedding)` pairs against [queryEmbedding].
  /// Notes whose embedding is missing or length-mismatched are dropped.
  static List<SemanticSearchResult> rank({
    required List<double> queryEmbedding,
    required List<MapEntry<String, List<double>>> candidates,
  }) {
    final results = <SemanticSearchResult>[];
    for (final entry in candidates) {
      final score = cosineSimilarity(queryEmbedding, entry.value);
      if (score <= 0) continue; // ignore orthogonal or negative matches
      results.add(
        SemanticSearchResult(noteId: entry.key, score: normalise(score)),
      );
    }
    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }
}

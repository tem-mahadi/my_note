import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'ai_config.dart';
import 'ai_exceptions.dart';
import 'ai_models.dart';
import 'ai_prompts.dart';

/// Reusable service for all OpenRouter calls. Single instance should be
/// provided via `Provider` near the root of the widget tree.
///
/// Supported operations:
///   * [chat] / [streamChat]       — text generation, optionally streamed
///   * [embed]                     — vector embedding for a single string
///   * [chatWithNote]              — convenience for the "Chat with note" UI
///   * [extractTasks]              — structured task list
///   * [brainstorm]                — grouped idea categories
///   * [continueWriting]           — continuation of the editor buffer
class AIService {
  final AIConfig config;
  final http.Client _client;

  AIService({required this.config, http.Client? client})
    : _client = client ?? http.Client();

  void dispose() => _client.close();

  // ====================================================================
  // Low-level: ensure the service is ready
  // ====================================================================

  void _ensureKey() {
    final key = config.apiKey;
    if (key == null || key.isEmpty) {
      throw const AIMissingApiKeyException();
    }
  }

  Map<String, String> _headers({bool jsonBody = true}) {
    _ensureKey();
    return {
      if (jsonBody) 'Content-Type': 'application/json',
      'Authorization': 'Bearer ${config.apiKey}',
      // OpenRouter recommends these for attribution / ranking.
      'HTTP-Referer': 'https://my-note.local',
      'X-Title': 'My iNote',
    };
  }

  // ====================================================================
  // Public: chat (blocking)
  // ====================================================================

  /// Send a list of messages and return the assistant's full text reply.
  /// If `stream` is `true` the response is delivered token-by-token via SSE
  /// and the same `chat()` method returns the accumulated text once the
  /// stream ends; prefer [streamChat] for UI code that needs to render
  /// incrementally.
  Future<String> chat(
    List<ChatMessage> messages, {
    String? model,
    double temperature = 0.4,
    int? maxTokens,
    bool stream = false,
    void Function(String delta)? onDelta,
  }) async {
    if (stream) {
      final buffer = StringBuffer();
      await streamChat(
        messages,
        model: model,
        temperature: temperature,
        maxTokens: maxTokens,
        onDelta: (delta) {
          buffer.write(delta);
          onDelta?.call(delta);
        },
      );
      return buffer.toString();
    }

    final body = <String, dynamic>{
      'model': model ?? config.chatModel,
      'messages': messages.map((m) => m.toJson()).toList(),
      'temperature': temperature,
      'stream': false,
      'max_tokens': ?maxTokens,
    };

    final response = await _post('/chat/completions', body);
    final content = _extractContent(response);
    if (content == null || content.isEmpty) {
      throw const AIMalformedResponseException('Empty assistant message.');
    }
    return content;
  }

  // ====================================================================
  // Public: chat (streaming)
  // ====================================================================

  /// Streams the assistant's reply token-by-token. Returns once the stream
  /// ends or [onDelta] / [onError] closes. Callers should treat the stream
  /// as one continuous run; do not interleave other requests.
  Future<void> streamChat(
    List<ChatMessage> messages, {
    String? model,
    double temperature = 0.4,
    int? maxTokens,
    required void Function(String delta) onDelta,
  }) async {
    final body = <String, dynamic>{
      'model': model ?? config.chatModel,
      'messages': messages.map((m) => m.toJson()).toList(),
      'temperature': temperature,
      'stream': true,
      'max_tokens': ?maxTokens,
    };

    final uri = Uri.parse('${config.baseUrl}/chat/completions');
    final request = http.Request('POST', uri)
      ..headers.addAll(_headers())
      ..body = jsonEncode(body);

    final http.StreamedResponse response;
    try {
      response = await _client.send(request).timeout(config.timeout);
    } on TimeoutException {
      throw const AITimeoutException();
    } on SocketException catch (e) {
      throw AINetworkException('Network unreachable: ${e.message}');
    } on http.ClientException catch (e) {
      throw AINetworkException(e.message);
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const AIInvalidApiKeyException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final err = await response.stream.bytesToString();
      throw AIApiException(response.statusCode, _shortError(err));
    }

    await _consumeSse(response.stream, onDelta);
  }

  /// Reads Server-Sent Events from [stream] and emits assistant deltas via
  /// [onDelta]. We tolerate keep-alive comments and OpenRouter's `data: [DONE]`
  /// terminator. The first SSE error is surfaced as [AIMalformedResponseException].
  Future<void> _consumeSse(
    Stream<List<int>> stream,
    void Function(String delta) onDelta,
  ) async {
    final lineStream = stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    String pendingData = '';
    await for (final line in lineStream) {
      if (line.isEmpty) {
        if (pendingData.isNotEmpty) {
          _handleSsePayload(pendingData, onDelta);
          pendingData = '';
        }
        continue;
      }
      if (line.startsWith(':')) continue; // comment / keep-alive
      if (line.startsWith('data:')) {
        pendingData = line.substring(5).trim();
      }
    }
  }

  void _handleSsePayload(String data, void Function(String delta) onDelta) {
    if (data == '[DONE]') return;
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final choices = json['choices'] as List?;
      if (choices == null || choices.isEmpty) return;
      final delta = choices.first['delta'] as Map<String, dynamic>?;
      final content = delta?['content'];
      if (content is String && content.isNotEmpty) onDelta(content);
    } on FormatException {
      throw const AIMalformedResponseException(
        'Could not parse streaming response.',
      );
    }
  }

  // ====================================================================
  // Public: embeddings
  // ====================================================================

  /// Returns the embedding vector for [text] using the configured embedding
  /// model. OpenRouter exposes OpenAI-compatible embeddings.
  Future<List<double>> embed(String text, {String? model}) async {
    if (text.trim().isEmpty) return const [];
    final body = {'model': model ?? config.embeddingModel, 'input': text};
    final response = await _post('/embeddings', body);
    final data = jsonDecode(response) as Map<String, dynamic>;
    final list =
        (data['data'] as List?)
                ?.cast<Map<String, dynamic>>()
                .firstOrNull?['embedding']
            as List?;
    if (list == null) {
      throw const AIMalformedResponseException('No embedding returned.');
    }
    return list.map((e) => (e as num).toDouble()).toList(growable: false);
  }

  // ====================================================================
  // High-level feature helpers
  // ====================================================================

  /// Streams a chat reply constrained to a single note's content. Maintains
  /// the caller-supplied [history] (the model sees all entries; the new
  /// assistant reply is appended to it before this method returns).
  Future<String> chatWithNoteStream({
    required String noteTitle,
    required String noteBody,
    required List<ChatMessage> history,
    required String userMessage,
    required void Function(String delta) onDelta,
  }) async {
    final system = AIPrompts.chatWithNoteSystem(
      title: noteTitle,
      body: noteBody,
    );
    final messages = <ChatMessage>[
      ChatMessage(role: 'system', content: system),
      ...history,
      ChatMessage(role: 'user', content: userMessage),
    ];

    final buffer = StringBuffer();
    await streamChat(
      messages,
      temperature: 0.2, // low temperature -> less hallucination
      onDelta: (delta) {
        buffer.write(delta);
        onDelta(delta);
      },
    );
    return buffer.toString();
  }

  /// Extracts a structured task list from a note.
  Future<List<ExtractedTask>> extractTasks({
    required String noteTitle,
    required String noteBody,
  }) async {
    final raw = await chat([
      ChatMessage(role: 'system', content: AIPrompts.taskExtractorSystem),
      ChatMessage(
        role: 'user',
        content: AIPrompts.extractTasksUserPrompt(
          title: noteTitle,
          body: noteBody,
        ),
      ),
    ], temperature: 0.1);
    return _parseTasks(raw);
  }

  /// Generates grouped brainstorm ideas for a note.
  Future<List<BrainstormIdea>> brainstorm({
    required String noteTitle,
    required String noteBody,
  }) async {
    final raw = await chat(
      [
        ChatMessage(role: 'system', content: AIPrompts.brainstormSystem),
        ChatMessage(
          role: 'user',
          content: AIPrompts.brainstormUserPrompt(
            title: noteTitle,
            body: noteBody,
          ),
        ),
      ],
      temperature: 0.7, // more creative
    );
    return _parseBrainstorm(raw);
  }

  /// Continues the user's draft while preserving tone.
  Future<String> continueWriting({
    required String textBeforeCursor,
    void Function(String delta)? onDelta,
  }) async {
    if (textBeforeCursor.trim().isEmpty) return '';
    final messages = <ChatMessage>[
      ChatMessage(role: 'system', content: AIPrompts.continueWritingSystem),
      ChatMessage(
        role: 'user',
        content: AIPrompts.continueWritingUserPrompt(textBeforeCursor),
      ),
    ];
    if (onDelta != null) {
      return chat(messages, temperature: 0.7, stream: true, onDelta: onDelta);
    }
    return chat(messages, temperature: 0.7);
  }

  // ====================================================================
  // JSON parsers
  // ====================================================================

  List<ExtractedTask> _parseTasks(String raw) {
    final json = _extractJsonArray(raw);
    if (json == null) {
      throw const AIMalformedResponseException(
        'Task extractor did not return a JSON array.',
      );
    }
    final list = json as List;
    final out = <ExtractedTask>[];
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        final t = ExtractedTask.fromJson(item);
        if (t.task.isNotEmpty) out.add(t);
      }
    }
    return out;
  }

  List<BrainstormIdea> _parseBrainstorm(String raw) {
    final json = _extractJsonArray(raw);
    if (json == null) {
      throw const AIMalformedResponseException(
        'Brainstorm did not return a JSON array.',
      );
    }
    final list = json as List;
    return list
        .whereType<Map<String, dynamic>>()
        .map(BrainstormIdea.fromJson)
        .where((b) => b.ideas.isNotEmpty)
        .toList();
  }

  /// Models occasionally wrap their JSON in ```json ... ``` fences. Strip
  /// those and return the first top-level array found.
  Object? _extractJsonArray(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      // Drop the first fence (with optional language tag) and the trailing one.
      final firstNewline = text.indexOf('\n');
      if (firstNewline != -1) text = text.substring(firstNewline + 1);
      if (text.endsWith('```')) text = text.substring(0, text.length - 3);
      text = text.trim();
    }
    final start = text.indexOf('[');
    final end = text.lastIndexOf(']');
    if (start == -1 || end == -1 || end <= start) return null;
    final candidate = text.substring(start, end + 1);
    try {
      return jsonDecode(candidate);
    } on FormatException {
      return null;
    }
  }

  // ====================================================================
  // HTTP plumbing
  // ====================================================================

  Future<String> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${config.baseUrl}$path');
    try {
      final response = await _client
          .post(uri, headers: _headers(), body: jsonEncode(body))
          .timeout(config.timeout);
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const AIInvalidApiKeyException();
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AIApiException(response.statusCode, _shortError(response.body));
      }
      return response.body;
    } on TimeoutException {
      throw const AITimeoutException();
    } on SocketException catch (e) {
      throw AINetworkException('Network unreachable: ${e.message}');
    } on http.ClientException catch (e) {
      throw AINetworkException(e.message);
    }
  }

  String? _extractContent(String responseBody) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final choices = json['choices'] as List?;
      if (choices == null || choices.isEmpty) return null;
      final first = choices.first as Map<String, dynamic>;
      final message = first['message'] as Map<String, dynamic>?;
      final content = message?['content'];
      return content is String ? content : null;
    } on FormatException {
      throw const AIMalformedResponseException('Invalid JSON in response.');
    }
  }

  String _shortError(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final err = json['error'];
      if (err is Map && err['message'] is String) {
        return err['message'] as String;
      }
    } catch (_) {}
    return body.length > 200 ? '${body.substring(0, 200)}…' : body;
  }
}

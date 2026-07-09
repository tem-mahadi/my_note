/// Centralised configuration for the OpenRouter integration.
///
/// Defaults are conservative and free-tier friendly. Override at runtime via
/// [AIService]'s constructor (e.g. `AIService(config: AIConfig(...))`).
///
/// Security note: in a production deployment the API key MUST live on a
/// server-side proxy you control — never ship it in the client. This app
/// supports that workflow by letting you set [proxyBaseUrl]; when present,
/// all requests are routed through it and the key stays on your backend.
class AIConfig {
  /// OpenRouter's public API. Override with [proxyBaseUrl] to route through
  /// your own backend proxy.
  static const String openRouterBaseUrl = 'https://openrouter.ai/api/v1';

  final String? apiKey;
  final String? proxyBaseUrl;
  final String chatModel;
  final String embeddingModel;
  final Duration timeout;

  const AIConfig({
    this.apiKey,
    this.proxyBaseUrl,
    this.chatModel = 'openai/gpt-4o-mini',
    this.embeddingModel = 'openai/text-embedding-3-small',
    this.timeout = const Duration(seconds: 60),
  });

  /// Base URL used for all API calls — proxy if configured, else OpenRouter.
  String get baseUrl => (proxyBaseUrl != null && proxyBaseUrl!.isNotEmpty)
      ? proxyBaseUrl!
      : openRouterBaseUrl;

  AIConfig copyWith({
    String? apiKey,
    String? proxyBaseUrl,
    String? chatModel,
    String? embeddingModel,
    Duration? timeout,
  }) {
    return AIConfig(
      apiKey: apiKey ?? this.apiKey,
      proxyBaseUrl: proxyBaseUrl ?? this.proxyBaseUrl,
      chatModel: chatModel ?? this.chatModel,
      embeddingModel: embeddingModel ?? this.embeddingModel,
      timeout: timeout ?? this.timeout,
    );
  }
}

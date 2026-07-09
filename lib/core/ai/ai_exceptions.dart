/// Typed exceptions thrown by the AI service layer so callers can react to
/// specific failure modes (missing key, rate limit, bad JSON, etc.) and the
/// UI can show friendly messages.
sealed class AIException implements Exception {
  final String message;
  const AIException(this.message);
  @override
  String toString() => '$runtimeType: $message';
}

/// The user hasn't provided an OpenRouter API key (or one isn't on the server).
class AIMissingApiKeyException extends AIException {
  const AIMissingApiKeyException()
    : super('OpenRouter API key not configured.');
}

/// The supplied key was rejected (401/403).
class AIInvalidApiKeyException extends AIException {
  const AIInvalidApiKeyException()
    : super('The OpenRouter API key was rejected. Check it in settings.');
}

/// Network-level failure (DNS, socket, TLS).
class AINetworkException extends AIException {
  const AINetworkException(super.message);
}

/// Took longer than [AIConfig.timeout].
class AITimeoutException extends AIException {
  const AITimeoutException()
    : super('The AI request took too long. Please try again.');
}

/// Server returned 4xx/5xx.
class AIApiException extends AIException {
  final int statusCode;
  const AIApiException(this.statusCode, String message) : super(message);
}

/// Model returned text but it could not be parsed into the expected shape
/// (e.g. task JSON without an array).
class AIMalformedResponseException extends AIException {
  const AIMalformedResponseException(super.message);
}

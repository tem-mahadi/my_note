import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around `flutter_secure_storage` so the rest of the app can
/// persist the OpenRouter key (and optional proxy URL) in the platform's
/// secure storage: Keychain on iOS, EncryptedSharedPreferences on Android.
///
/// In addition to async reads, the class keeps an in-memory cache of the
/// most recently loaded values so the `ProxyProvider` in `main.dart` can
/// build an [AIService] synchronously on first frame.
class AISecureStorage {
  AISecureStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _apiKeyKey = 'ai.openrouter.api_key';
  static const _proxyUrlKey = 'ai.openrouter.proxy_url';
  static const _chatModelKey = 'ai.openrouter.chat_model';
  static const _embeddingModelKey = 'ai.openrouter.embedding_model';

  // In-memory cache populated by [warmCache] / [writeApiKey] / etc.
  String? _cachedApiKey;
  String? _cachedProxyUrl;
  String? _cachedChatModel;
  String? _cachedEmbeddingModel;

  String? get cachedApiKey => _cachedApiKey;
  String? get cachedProxyUrl => _cachedProxyUrl;
  String? get cachedChatModel => _cachedChatModel;
  String? get cachedEmbeddingModel => _cachedEmbeddingModel;

  /// Reads every value from secure storage into memory. Call once during
  /// startup; the cache is updated automatically on subsequent writes.
  Future<void> warmCache() async {
    _cachedApiKey = await readApiKey();
    _cachedProxyUrl = await readProxyUrl();
    _cachedChatModel = await readChatModel();
    _cachedEmbeddingModel = await readEmbeddingModel();
  }

  // ---------------------------------------------------------------------
  // Async API used by settings UI; also updates the in-memory cache.
  // ---------------------------------------------------------------------

  Future<String?> readApiKey() => _storage.read(key: _apiKeyKey);

  Future<void> writeApiKey(String value) async {
    await _storage.write(key: _apiKeyKey, value: value);
    _cachedApiKey = value;
  }

  Future<void> deleteApiKey() async {
    await _storage.delete(key: _apiKeyKey);
    _cachedApiKey = null;
  }

  Future<String?> readProxyUrl() => _storage.read(key: _proxyUrlKey);

  Future<void> writeProxyUrl(String? value) async {
    if (value == null || value.isEmpty) {
      await _storage.delete(key: _proxyUrlKey);
      _cachedProxyUrl = null;
    } else {
      await _storage.write(key: _proxyUrlKey, value: value);
      _cachedProxyUrl = value;
    }
  }

  Future<String?> readChatModel() => _storage.read(key: _chatModelKey);

  Future<void> writeChatModel(String value) async {
    await _storage.write(key: _chatModelKey, value: value);
    _cachedChatModel = value;
  }

  Future<String?> readEmbeddingModel() =>
      _storage.read(key: _embeddingModelKey);

  Future<void> writeEmbeddingModel(String value) async {
    await _storage.write(key: _embeddingModelKey, value: value);
    _cachedEmbeddingModel = value;
  }

  Future<void> clearAll() async {
    await _storage.delete(key: _apiKeyKey);
    await _storage.delete(key: _proxyUrlKey);
    await _storage.delete(key: _chatModelKey);
    await _storage.delete(key: _embeddingModelKey);
    _cachedApiKey = null;
    _cachedProxyUrl = null;
    _cachedChatModel = null;
    _cachedEmbeddingModel = null;
  }
}

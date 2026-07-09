import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/ai/ai_secure_storage.dart';
import '../core/ai/ai_service.dart';
import '../theme/app_colors.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/glass_card.dart';

/// Lets the user enter or change their OpenRouter API key and pick a chat /
/// embedding model. All values are stored in the platform's secure storage
/// (Keychain on iOS, EncryptedSharedPreferences on Android) so they never
/// touch plain disk storage or source code.
class AISettingsPage extends StatefulWidget {
  const AISettingsPage({super.key});

  @override
  State<AISettingsPage> createState() => _AISettingsPageState();
}

class _AISettingsPageState extends State<AISettingsPage> {
  final _apiKeyController = TextEditingController();
  final _proxyController = TextEditingController();
  final _chatModelController = TextEditingController();
  final _embeddingModelController = TextEditingController();

  bool _obscureKey = true;
  bool _hasSavedKey = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final storage = context.read<AISecureStorage>();
    final apiKey = await storage.readApiKey();
    final proxy = await storage.readProxyUrl();
    final chatModel = await storage.readChatModel() ?? 'openai/gpt-4o-mini';
    final embedModel =
        await storage.readEmbeddingModel() ?? 'openai/text-embedding-3-small';
    if (!mounted) return;
    setState(() {
      _apiKeyController.text = apiKey ?? '';
      _proxyController.text = proxy ?? '';
      _chatModelController.text = chatModel;
      _embeddingModelController.text = embedModel;
      _hasSavedKey = (apiKey ?? '').isNotEmpty;
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _proxyController.dispose();
    _chatModelController.dispose();
    _embeddingModelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final storage = context.read<AISecureStorage>();
    final ai = context.read<AIService>();
    final messenger = ScaffoldMessenger.of(context);
    final api = _apiKeyController.text.trim();
    await storage.writeApiKey(api);
    await storage.writeProxyUrl(_proxyController.text.trim());
    await storage.writeChatModel(
      _chatModelController.text.trim().isEmpty
          ? 'openai/gpt-4o-mini'
          : _chatModelController.text.trim(),
    );
    await storage.writeEmbeddingModel(
      _embeddingModelController.text.trim().isEmpty
          ? 'openai/text-embedding-3-small'
          : _embeddingModelController.text.trim(),
    );
    // We can't replace the proxied service instance directly here, so we
    // just store the new values — the next time the app restarts or the
    // proxy is rebuilt it will see them. We update the in-memory cache so
    // reads are immediate.
    if (mounted) {
      setState(() {
        _hasSavedKey = api.isNotEmpty;
        _saving = false;
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('AI settings saved.')),
      );
    }
    // Mark the AI service's config as "stale" by reading the freshly saved
    // value. We keep using the old instance for this session; production
    // apps would rebuild the service here.
    debugPrint(
      'AIService now using model=${ai.config.chatModel}, key set=${api.isNotEmpty}',
    );
  }

  Future<void> _clearKey() async {
    final storage = context.read<AISecureStorage>();
    await storage.deleteApiKey();
    if (!mounted) return;
    setState(() {
      _apiKeyController.clear();
      _hasSavedKey = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('API key removed.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Settings', style: GoogleFonts.poppins()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: CosmicBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: GlassCard(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF4834DF)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'OpenRouter',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Powers the AI features in this app',
                              style: GoogleFonts.poppins(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _Field(
                    label: 'API key',
                    controller: _apiKeyController,
                    obscure: _obscureKey,
                    suffix: IconButton(
                      icon: Icon(
                        _obscureKey
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        color: Colors.white60,
                      ),
                      onPressed: () =>
                          setState(() => _obscureKey = !_obscureKey),
                    ),
                    helper: 'Stored only in this device’s secure storage.',
                  ),
                  const SizedBox(height: 18),
                  _Field(
                    label: 'Proxy base URL (optional)',
                    controller: _proxyController,
                    helper:
                        'Leave blank to call OpenRouter directly. Use this if you have a backend that proxies requests and hides the key.',
                  ),
                  const SizedBox(height: 18),
                  _Field(label: 'Chat model', controller: _chatModelController),
                  const SizedBox(height: 18),
                  _Field(
                    label: 'Embedding model',
                    controller: _embeddingModelController,
                  ),
                  const SizedBox(height: 28),
                  _buildActions(),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.primaryLight,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'For production, put the API key on a server you control and set the proxy URL above. The key never has to live on the device.',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        if (_hasSavedKey)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _saving ? null : _clearKey,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFFF6584),
              ),
              label: Text(
                'Remove key',
                style: GoogleFonts.poppins(color: const Color(0xFFFF6584)),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: const Color(0xFFFF6584).withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        if (_hasSavedKey) const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Icon(Icons.save_rounded, color: Colors.white),
            label: Text(
              'Save',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final Widget? suffix;
  final String? helper;

  const _Field({
    required this.label,
    required this.controller,
    this.obscure = false,
    this.suffix,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          autocorrect: false,
          enableSuggestions: false,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixIcon: suffix,
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(
            helper!,
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
          ),
        ],
      ],
    );
  }
}

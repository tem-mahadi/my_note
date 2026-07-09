import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'core/ai/ai_config.dart';
import 'core/ai/ai_secure_storage.dart';
import 'core/ai/ai_service.dart';
import 'screens/notes_list_screen.dart';
import 'service/auth_service.dart';
import 'service/user_data.dart';
import 'views/landing_page.dart';
import 'views/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Hydrate cached user info (name, mobile, joined date) from SharedPreferences
  // before deciding which screen to show on first launch.
  await UserData.loadData();
  runApp(const MyNoteApp());
}

class MyNoteApp extends StatelessWidget {
  const MyNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AISecureStorage>(create: (_) => AISecureStorage()),
        // AIService is created lazily so the app starts even when no key is
        // configured. Callers request the service via `context.read<AIService>()`
        // after the provider above resolves the key from secure storage.
        ProxyProvider<AISecureStorage, AIService>(
          update: (_, storage, previous) =>
              previous ?? _buildDefaultService(storage),
        ),
      ],
      child: MaterialApp(
        title: 'My Notes',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F0F1E),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF6C63FF),
            secondary: Color(0xFF4834DF),
            surface: Color(0xFF1E1E2E),
            error: Color(0xFFFF6584),
          ),
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF1E1E2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: const _AuthGate(),
      ),
    );
  }

  /// Builds an [AIService] using the key (if any) already saved on device.
  /// Falls back to a key-less config; individual calls will surface a
  /// [AIMissingApiKeyException] until the user enters a key in settings.
  static AIService _buildDefaultService(AISecureStorage storage) {
    // We deliberately read the key synchronously here by checking the
    // in-memory cache that AISecureStorage populates. If no key is set yet,
    // the service still works for things like showing the "configure key"
    // banner, but every API call will throw [AIMissingApiKeyException].
    return AIService(
      config: AIConfig(
        apiKey: storage.cachedApiKey,
        proxyBaseUrl: storage.cachedProxyUrl,
        chatModel: storage.cachedChatModel ?? 'openai/gpt-4o-mini',
        embeddingModel:
            storage.cachedEmbeddingModel ?? 'openai/text-embedding-3-small',
      ),
    );
  }
}

/// Decides the very first screen to show, based on platform + saved session.
///   * Web       → LandingPage (so the public pricing page is reachable).
///   * Mobile,
///     has session → NotesListScreen (straight into the app).
///   * Mobile,
///     no session → LoginPage (subscription is required).
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    // Hydrate secure-storage caches before any AI call is made.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storage = context.read<AISecureStorage>();
      storage.warmCache();
    });
  }

  // ── TEST-ONLY LOGIN BYPASS ──────────────────────────────────────────
  // Set this to `true` to skip the login flow entirely while testing
  // app features. Flip back to `false` to restore the normal auth gate.
  static const bool kBypassLogin = false;
  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (kBypassLogin) {
      // Skip auth + splash and go straight into the notes screen.
      return const NotesListScreen();
    }

    // Web users always see the landing page first so they can read pricing.
    if (kIsWeb) return const LandingPage();

    return FutureBuilder<String?>(
      future: AuthService.instance.getSavedMobile(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }
        final savedMobile = snap.data;
        if (savedMobile == null || savedMobile.isEmpty) {
          return const LoginPage();
        }
        return const NotesListScreen();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

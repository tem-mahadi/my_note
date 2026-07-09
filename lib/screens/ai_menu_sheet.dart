import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/ai/ai_exceptions.dart';
import '../core/ai/ai_service.dart';
import '../models/note.dart';
import 'ai_brainstorm_screen.dart';
import 'ai_chat_screen.dart';
import 'ai_tasks_screen.dart';

/// Bottom sheet that surfaces every AI action available for a note. Used by
/// the editor screen so users don't have to remember keyboard shortcuts.
class AIMenuSheet extends StatelessWidget {
  final Note note;
  const AIMenuSheet({super.key, required this.note});

  static Future<void> show(BuildContext context, Note note) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AIMenuSheet(note: note),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                      const Text(
                        'AI Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Powered by OpenRouter',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _Action(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Chat with this note',
              subtitle: 'Ask questions, answers come from your note',
              onTap: () => _navigate(context, AIChatScreen(note: note)),
            ),
            _Action(
              icon: Icons.checklist_rounded,
              title: 'Extract tasks',
              subtitle: 'Pull actionable todos from this note',
              onTap: () => _navigate(context, AITasksScreen(note: note)),
            ),
            _Action(
              icon: Icons.lightbulb_outline_rounded,
              title: 'Brainstorm ideas',
              subtitle: 'Get creative directions to explore',
              onTap: () => _navigate(context, AIBrainstormScreen(note: note)),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.pop(context); // close sheet first
    // Guard: a missing key should never silently navigate; surface a friendly
    // message and let the user open settings.
    final service = context.read<AIService>();
    if (service.config.apiKey == null || service.config.apiKey!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add your OpenRouter API key in Profile → AI Settings.',
          ),
        ),
      );
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Action({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF8B83FF), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ],
        ),
      ),
    );
  }
}

/// Converts any thrown [Object] into a friendly message suitable for a
/// SnackBar. Exposed so the various AI screens don't repeat this logic.
String friendlyAIError(Object error) {
  if (error is AIMissingApiKeyException) {
    return 'Add your OpenRouter API key in Profile → AI Settings.';
  }
  if (error is AIInvalidApiKeyException) {
    return 'Your OpenRouter API key was rejected. Double-check it in settings.';
  }
  if (error is AITimeoutException) {
    return 'The AI request timed out. Please try again.';
  }
  if (error is AINetworkException) {
    return 'Network problem: ${error.message}';
  }
  if (error is AIMalformedResponseException) {
    return 'The AI returned an unexpected response. Please try again.';
  }
  if (error is AIApiException) {
    return 'AI service error (${error.statusCode}): ${error.message}';
  }
  return 'Something went wrong: $error';
}

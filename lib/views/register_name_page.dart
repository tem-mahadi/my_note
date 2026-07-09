import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../service/user_data.dart';
import '../theme/app_colors.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import '../screens/notes_list_screen.dart';

/// Captures the user's display name after a successful bdapps subscription
/// and writes it to local storage before entering the main app.
class RegisterNamePage extends StatefulWidget {
  final String mobile;

  const RegisterNamePage({super.key, required this.mobile});

  @override
  State<RegisterNamePage> createState() => _RegisterNamePageState();
}

class _RegisterNamePageState extends State<RegisterNamePage> {
  final _nameCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || name.length < 2) {
      setState(() => _error = 'Please enter your name.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await UserData.saveData(name: name, number: widget.mobile);
      if (!mounted) return;

      // Replace the entire auth flow with the main app.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const NotesListScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CosmicBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: GlassCard(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.person_add_alt_1,
                      size: 56,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tell us your name to get started',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Your name',
                        hintStyle: GoogleFonts.poppins(color: Colors.white54),
                        prefixIcon: const Icon(
                          Icons.badge,
                          color: Colors.white70,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.redAccent,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    GradientButton(
                      text: _loading ? 'Saving...' : 'Continue',
                      isLoading: _loading,
                      onPressed: _loading ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

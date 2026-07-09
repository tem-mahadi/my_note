import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../service/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import 'otp_page.dart';

/// Login screen — user enters their bdapps-registered mobile number.
/// Behavior:
///   * If the server says the number is subscribed → skip OTP, go to name registration.
///   * If not subscribed → request OTP for signup/renew.
///   * If error → show a friendly message.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _mobileCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    final raw = _mobileCtrl.text.trim();
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11 && digits.length != 13) {
      setState(() => _error = 'Enter a valid 11-digit mobile number.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1. Check if the user is already subscribed on bdapps.
      final alreadySubscribed = await AuthService.instance.checkSubscription(
        digits,
      );

      if (alreadySubscribed) {
        // Skip OTP — go directly to profile / name registration.
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                OtpPage(mobile: digits, referenceNo: '', skipOtp: true),
          ),
        );
        return;
      }

      // 2. Not subscribed → send OTP for signup.
      final referenceNo = await AuthService.instance.sendOtp(digits);
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              OtpPage(mobile: digits, referenceNo: referenceNo, skipOtp: false),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _cleanError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _cleanError(String raw) {
    // Strip HTTP / parsing noise so the user sees something readable.
    if (raw.contains('SocketException') || raw.contains('Failed host lookup')) {
      return 'Network error. Please check your connection.';
    }
    return raw.replaceAll('Exception:', '').trim();
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
                      Icons.lock_outline_rounded,
                      size: 56,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sign in with your bdapps-registered number',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _mobileCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 14,
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '01XXXXXXXXX',
                        hintStyle: GoogleFonts.poppins(color: Colors.white54),
                        prefixIcon: const Icon(
                          Icons.phone_android,
                          color: Colors.white70,
                        ),
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                      text: _loading ? 'Please wait...' : 'Continue',
                      isLoading: _loading,
                      onPressed: _loading ? null : _submit,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Robi & Airtel users only • 2.78 BDT/day',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
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

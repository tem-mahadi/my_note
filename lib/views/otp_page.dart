import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../service/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import 'register_name_page.dart';

/// OTP verification screen.
/// Can run in two modes:
///   * Normal mode (`skipOtp = false`) — user enters a 6-digit OTP sent to bdapps.
///   * Skip mode (`skipOtp = true`)   — used when user is already subscribed,
///                                       so we skip straight to name registration.
class OtpPage extends StatefulWidget {
  final String mobile;
  final String referenceNo;
  final bool skipOtp;

  const OtpPage({
    super.key,
    required this.mobile,
    required this.referenceNo,
    this.skipOtp = false,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // If we already know the user is subscribed, just forward to name entry.
    if (widget.skipOtp) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goNext());
    }
  }

  Future<void> _goNext() async {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterNamePage(mobile: widget.mobile),
      ),
    );
  }

  Future<void> _verify() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Enter the 6-digit OTP.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final status = await AuthService.instance.verifyOtp(
        otp,
        widget.referenceNo,
      );
      if (status == 'REGISTERED') {
        await AuthService.instance.saveSession(widget.mobile);
        if (!mounted) return;
        _goNext();
      } else {
        setState(() => _error = 'Subscription status: $status');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception:', '').trim());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.skipOtp) {
      // Quick loading placeholder while we bounce to name entry.
      return Scaffold(
        body: CosmicBackground(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

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
                      Icons.sms_outlined,
                      size: 56,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Verify OTP',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter the 6-digit OTP sent to your mobile',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _otpCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        letterSpacing: 12,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '••••••',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.white54,
                          letterSpacing: 12,
                        ),
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
                      text: _loading ? 'Verifying...' : 'Verify',
                      isLoading: _loading,
                      onPressed: _loading ? null : _verify,
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

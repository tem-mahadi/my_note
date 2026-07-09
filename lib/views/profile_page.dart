import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../service/auth_service.dart';
import '../service/user_data.dart';
import '../theme/app_colors.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import 'landing_page.dart';
import 'login_page.dart';

/// Profile screen — shows the cached user info and exposes:
///   * Logout       — clears local session, redirects to login (still subscribed).
///   * Unsubscribe  — cancels the bdapps subscription, then logs out.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    // Logout = clear local session only. The bdapps subscription remains.
    await AuthService.instance.clearSession();
    await UserData.clearData();

    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _unsubscribe(BuildContext context) async {
    final mobile = UserData.userNumber;
    if (mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active mobile number found.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgMid,
        title: Text(
          'Unsubscribe?',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This will cancel your bdapps subscription. You will be logged out and will need to resubscribe to use My Notes again.',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Unsubscribe',
              style: GoogleFonts.poppins(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    // Show progress while we hit the unsubscribe endpoint.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    try {
      await AuthService.instance.unsubscribe(mobile);
      await AuthService.instance.clearSession();
      await UserData.clearData();

      if (!context.mounted) return;
      Navigator.pop(context); // dismiss progress
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LandingPage()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // dismiss progress
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception:', '').trim()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = UserData.userName;
    final number = UserData.userNumber;
    final joined = UserData.userJoined;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.poppins()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: CosmicBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: GlassCard(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    number,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Joined: $joined',
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_outlined,
                          color: Colors.greenAccent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Active bdapps subscription',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  GradientButton(
                    text: 'Logout',
                    icon: Icons.logout_rounded,
                    onPressed: () => _logout(context),
                  ),
                  const SizedBox(height: 14),
                  // Unsubscribe button — destructive, painted red.
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () => _unsubscribe(context),
                      icon: const Icon(
                        Icons.cancel_outlined,
                        color: Colors.redAccent,
                      ),
                      label: Text(
                        'Unsubscribe',
                        style: GoogleFonts.poppins(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.redAccent.withValues(alpha: 0.6),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Logging out keeps your subscription active. '
                    'Unsubscribing cancels it permanently.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white60,
                      fontSize: 11,
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
}

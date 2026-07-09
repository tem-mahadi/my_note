import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/glass_card.dart';
import 'login_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  static const String _apkUrl =
      'https://mahadi-release.ruetandroiddevelopers.com/MyNote/MyNote_v1.0.apk';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _launchApkDownload() async {
    final uri = Uri.parse(_apkUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _navigateToSubscribe() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    return Scaffold(
      body: CosmicBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ── Top Navigation Bar ──
                  _buildNavBar(isWide),

                  // ── Hero Section ──
                  _buildHeroSection(isWide),

                  const SizedBox(height: 80),

                  // ── Features Section ──
                  _buildFeaturesSection(isWide),

                  const SizedBox(height: 80),

                  // ── Pricing / Subscription Section ──
                  _buildPricingSection(isWide),

                  const SizedBox(height: 80),

                  // ── Platform Support Section ──
                  _buildPlatformSection(isWide),

                  const SizedBox(height: 80),

                  // ── CTA Section ──
                  _buildCtaSection(isWide),

                  const SizedBox(height: 48),

                  // ── Footer ──
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // NAV BAR
  // ────────────────────────────────────────────────────────────────
  Widget _buildNavBar(bool isWide) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 64 : 24, vertical: 16),
      child: Row(
        children: [
          // Logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.buttonGradient,
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'My Notes',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          // CTA Buttons
          if (isWide) ...[
            _navButton(
              'Download APK',
              Icons.android_rounded,
              _launchApkDownload,
            ),
            const SizedBox(width: 12),
          ],
          _navCtaButton('Subscribe', _navigateToSubscribe),
        ],
      ),
    );
  }

  Widget _navButton(String text, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.neonGreen, size: 18),
              const SizedBox(width: 8),
              Text(
                text,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navCtaButton(String text, VoidCallback onTap) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // HERO SECTION
  // ────────────────────────────────────────────────────────────────
  Widget _buildHeroSection(bool isWide) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: isWide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome,
                color: AppColors.neonYellow,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'Available on Android & Web',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryLight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Headline
        Text(
          'Capture Every\nThought,\nInstantly',
          textAlign: isWide ? TextAlign.left : TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: isWide ? 56 : 40,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 20),

        // Subtitle
        SizedBox(
          width: isWide ? 460 : double.infinity,
          child: Text(
            'A simple, fast, and beautiful place to capture every idea, task, and memory — backed by the cloud and ready wherever you are.',
            textAlign: isWide ? TextAlign.left : TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ),

        const SizedBox(height: 36),

        // Buttons row
        Wrap(
          alignment: isWide ? WrapAlignment.start : WrapAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            _heroButton(
              'Subscribe Now',
              Icons.arrow_forward_rounded,
              AppColors.buttonGradient,
              _navigateToSubscribe,
            ),
            _heroOutlineButton(
              'Download APK',
              Icons.download_rounded,
              _launchApkDownload,
            ),
          ],
        ),

        const SizedBox(height: 28),

        // Pricing info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.neonCyan.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.neonCyan.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.neonCyan,
                size: 16,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Subscription: 2.78Tk including(VAT+SC+SD)/Day — Robi & Airtel Users Only',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.neonCyan,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final visual = AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return Transform.scale(scale: _pulseAnim.value, child: child);
      },
      child: Container(
        width: isWide ? 360 : 220,
        height: isWide ? 360 : 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.3),
              AppColors.accent.withValues(alpha: 0.1),
              Colors.transparent,
            ],
          ),
        ),
        child: Center(
          child: Container(
            width: isWide ? 180 : 120,
            height: isWide ? 180 : 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.buttonGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Icon(
              Icons.rocket_launch_rounded,
              size: isWide ? 72 : 52,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 64 : 24,
        vertical: isWide ? 60 : 40,
      ),
      child: isWide
          ? Row(
              children: [
                Expanded(child: content),
                const SizedBox(width: 48),
                visual,
              ],
            )
          : Column(children: [visual, const SizedBox(height: 40), content]),
    );
  }

  Widget _heroButton(
    String text,
    IconData icon,
    LinearGradient gradient,
    VoidCallback onTap,
  ) {
    return Material(
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(icon, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroOutlineButton(String text, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.glassBorder, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.neonGreen, size: 18),
              const SizedBox(width: 10),
              Text(
                text,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // FEATURES SECTION
  // ────────────────────────────────────────────────────────────────
  Widget _buildFeaturesSection(bool isWide) {
    final features = [
      _FeatureData(
        icon: Icons.sticky_note_2_rounded,
        title: 'Quick Capture',
        description:
            'Jot down thoughts in seconds with a clean, distraction-free editor.',
        color: AppColors.primary,
      ),
      _FeatureData(
        icon: Icons.search_rounded,
        title: 'Instant Search',
        description:
            'Find any note in milliseconds — search across every title and body.',
        color: AppColors.neonCyan,
      ),
      _FeatureData(
        icon: Icons.cloud_done_rounded,
        title: 'Cloud Sync',
        description:
            'Your notes are securely backed up to Firebase and ready on every device.',
        color: AppColors.neonGreen,
      ),
      _FeatureData(
        icon: Icons.devices_rounded,
        title: 'Cross-Platform',
        description:
            'Write on your phone, review on the web — notes sync everywhere, instantly.',
        color: AppColors.accent,
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 64 : 24),
      child: Column(
        children: [
          // Section title
          Text(
            'Why My Notes?',
            style: GoogleFonts.outfit(
              fontSize: isWide ? 36 : 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 500,
            child: Text(
              'Everything you need to stay organized, built with care.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 48),
          // Features grid
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 800
                  ? 4
                  : constraints.maxWidth > 500
                  ? 2
                  : 1;
              return Wrap(
                spacing: 20,
                runSpacing: 20,
                children: features.map((f) {
                  final cardWidth = crossAxisCount == 1
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 20 * (crossAxisCount - 1)) /
                            crossAxisCount;
                  return SizedBox(
                    width: cardWidth,
                    child: _buildFeatureCard(f),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(_FeatureData data) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderColor: data.color.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.color, size: 26),
          ),
          const SizedBox(height: 18),
          Text(
            data.title,
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.description,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // PRICING SECTION
  // ────────────────────────────────────────────────────────────────
  Widget _buildPricingSection(bool isWide) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 64 : 24),
      child: Column(
        children: [
          Text(
            'Simple Pricing',
            style: GoogleFonts.outfit(
              fontSize: isWide ? 36 : 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'One affordable subscription. Unlimited notes.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 40),

          // Pricing card
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: GlassCard(
                padding: const EdgeInsets.all(0),
                borderColor: AppColors.primary.withValues(alpha: 0.4),
                child: Column(
                  children: [
                    // Top highlight strip
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: AppColors.buttonGradient,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Text(
                        '🚀 MY NOTES PRO',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '2.78',
                                style: GoogleFonts.outfit(
                                  fontSize: 56,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                  height: 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  ' BDT',
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'including (VAT+SC+SD)/Day',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'For Robi & Airtel Users Only',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Features list
                          _pricingFeature('Unlimited note storage'),
                          _pricingFeature('Cloud sync across devices'),
                          _pricingFeature('Use on Android & Web'),
                          _pricingFeature('Search across every note'),
                          _pricingFeature('New features added regularly'),

                          const SizedBox(height: 28),

                          // Subscribe button
                          SizedBox(
                            width: double.infinity,
                            child: Material(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                onTap: _navigateToSubscribe,
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  child: Text(
                                    'Subscribe Now',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
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
        ],
      ),
    );
  }

  Widget _pricingFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.neonGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: AppColors.neonGreen,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // PLATFORM SUPPORT SECTION
  // ────────────────────────────────────────────────────────────────
  Widget _buildPlatformSection(bool isWide) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 64 : 24),
      child: Column(
        children: [
          Text(
            'Available Platforms',
            style: GoogleFonts.outfit(
              fontSize: isWide ? 36 : 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Capture your ideas anywhere you go.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _buildPlatformCard(
                icon: Icons.android_rounded,
                title: 'Android',
                subtitle: 'Download the APK and play natively on your phone.',
                color: AppColors.neonGreen,
                buttonText: 'Download APK',
                onTap: _launchApkDownload,
              ),
              _buildPlatformCard(
                icon: Icons.language_rounded,
                title: 'Web',
                subtitle:
                    'Open in any browser — no installation needed. Play instantly.',
                color: AppColors.neonCyan,
                buttonText: 'Play on Web',
                onTap: _navigateToSubscribe,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 320,
      child: GlassCard(
        padding: const EdgeInsets.all(28),
        borderColor: color.withValues(alpha: 0.3),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      buttonText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // CTA SECTION
  // ────────────────────────────────────────────────────────────────
  Widget _buildCtaSection(bool isWide) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 64 : 24),
      child: GlassCard(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 64 : 28,
          vertical: isWide ? 48 : 36,
        ),
        borderColor: AppColors.primary.withValues(alpha: 0.3),
        child: Column(
          children: [
            Text(
              'Ready to Challenge Yourself?',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: isWide ? 32 : 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 500,
              child: Text(
                'Join thousands of note-takers. Subscribe now and start capturing your ideas from anywhere!',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _heroButton(
                  'Subscribe Now',
                  Icons.arrow_forward_rounded,
                  AppColors.buttonGradient,
                  _navigateToSubscribe,
                ),
                _heroOutlineButton(
                  'Download APK',
                  Icons.download_rounded,
                  _launchApkDownload,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // FOOTER
  // ────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.bgDark.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          Text(
            '© ${DateTime.now().year} My Notes. All rights reserved.',
            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            'Subscription: 2.78 BDT including (VAT+SC+SD)/Day | For Robi & Airtel Users Only | Available on Android & Web',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

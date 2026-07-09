/// Central configuration for the PHP backend API endpoints
/// used for bdapps subscription, OTP, status check, and unsubscribe.
class ApiConfig {
  ApiConfig._();

  /// Base URL where the PHP backend files are hosted.
  /// Update this to point at the my_note folder on the server.
  static const String baseUrl =
      'https://ruetandroiddevelopers.com/Mahadi(My-iNote)/';

  // ── Endpoint URLs ──────────────────────────────────────────────
  static String get sendOtpUrl => '${baseUrl}send_otp.php';
  static String get verifyOtpUrl => '${baseUrl}verify_otp.php';
  static String get checkSubscriptionUrl => '${baseUrl}check_subscription.php';
  static String get unsubscribeUrl => '${baseUrl}unsubscribe.php';
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

/// Service that handles all bdapps authentication and subscription operations.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const String _mobileKey = 'saved_mobile';

  // ── Session persistence ────────────────────────────────────────

  /// Save the mobile number to local storage after a successful login.
  Future<void> saveSession(String mobile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mobileKey, mobile);
  }

  /// Clear the saved session (used for both logout and unsubscribe).
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_mobileKey);
  }

  /// Returns the saved mobile number, or null if no session exists.
  Future<String?> getSavedMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_mobileKey);
  }

  // ── BDApps API calls (via PHP backend) ─────────────────────────

  /// Request an OTP from bdapps for subscription.
  /// Returns the `referenceNo` on success, or throws on failure.
  Future<String> sendOtp(String mobile) async {
    final response = await http.post(
      Uri.parse(ApiConfig.sendOtpUrl),
      body: {'user_mobile': mobile},
    );

    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    if (data is Map &&
        data.containsKey('referenceNo') &&
        data['referenceNo'] != null) {
      return data['referenceNo'].toString();
    }
    throw Exception('Failed to send OTP. Please try again.');
  }

  /// Verify the OTP entered by the user.
  /// Returns the subscription status string (e.g. "REGISTERED").
  Future<String> verifyOtp(String otp, String referenceNo) async {
    final response = await http.post(
      Uri.parse(ApiConfig.verifyOtpUrl),
      body: {'Otp': otp, 'referenceNo': referenceNo},
    );

    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    if (data is Map) {
      if (data['statusCode'] == 'S1000') {
        return 'REGISTERED';
      }
      if (data.containsKey('subscriptionStatus') &&
          data['subscriptionStatus'] != null) {
        return data['subscriptionStatus'].toString().toUpperCase();
      }
      if (data.containsKey('statusDetail') && data['statusDetail'] != null) {
        throw Exception(data['statusDetail']);
      }
    }
    throw Exception('Invalid response from server.');
  }

  /// Check subscription status for a given mobile number.
  /// Returns `true` if the user is currently subscribed (REGISTERED).
  Future<bool> checkSubscription(String mobile) async {
    final response = await http.post(
      Uri.parse(ApiConfig.checkSubscriptionUrl),
      body: {'user_mobile': mobile},
    );

    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    if (data is Map && data.containsKey('isSubscribed')) {
      return data['isSubscribed'] == true;
    }
    return false;
  }

  /// Unsubscribe the user from bdapps.
  /// Returns `true` on success.
  Future<bool> unsubscribe(String mobile) async {
    // Normalise to tel:88... format expected by unsubscribe.php
    String subscriberId = mobile.replaceAll(RegExp(r'\D'), '');
    if (subscriberId.startsWith('0')) {
      subscriberId = '88$subscriberId';
    }
    if (!subscriberId.startsWith('88')) {
      subscriberId = '88$subscriberId';
    }

    final response = await http.post(
      Uri.parse(ApiConfig.unsubscribeUrl),
      body: {'subscriberId': subscriberId},
    );

    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    if (data is Map && data['statusCode'] == 'S1000') {
      return true;
    }

    final detail = data['statusDetail'] ?? 'Unsubscribe failed';
    throw Exception(detail);
  }
}

import 'package:shared_preferences/shared_preferences.dart';

/// Holds the locally-cached user profile (name, mobile, joined date)
/// so that the UI can render the profile page without a network call.
class UserData {
  static String userName = 'Note Taker';
  static String userNumber = '';
  static String userJoined = '';

  static Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    userName = prefs.getString('userName') ?? 'Note Taker';
    userNumber =
        prefs.getString('saved_mobile') ?? ''; // also used by AuthService
    userJoined = prefs.getString('userJoined') ?? _getCurrentDate();
  }

  static Future<void> saveData({
    required String name,
    required String number,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    userName = name;
    userNumber = number;
    userJoined = _getCurrentDate();

    await prefs.setString('userName', userName);
    await prefs.setString('userJoined', userJoined);
  }

  static Future<void> clearData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userName');
    await prefs.remove('userJoined');
  }

  static String _getCurrentDate() {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[now.month - 1]} ${now.year}';
  }
}

import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _kIsLoggedIn = 'is_logged_in';
  static const String _kUserId = 'user_id';
  static const String _kUsername = 'username';
  static const String _kEmail = 'email';

  static Future<void> saveLogin({
    required int userId,
    required String username,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsLoggedIn, true);
    await prefs.setInt(_kUserId, userId);
    await prefs.setString(_kUsername, username);
    await prefs.setString(_kEmail, email);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIsLoggedIn) ?? false;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kIsLoggedIn);
    await prefs.remove(_kUserId);
    await prefs.remove(_kUsername);
    await prefs.remove(_kEmail);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kUserId);
  }
}

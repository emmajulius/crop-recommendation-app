import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _emailKey = 'user_email';
  static const _passwordKey = 'user_password';

  get currentUser => null;

  static Future<bool> signUp(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
    await prefs.setString(_passwordKey, password);
    return true;
  }

  static Future<bool> signIn(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_emailKey);
    final savedPassword = prefs.getString(_passwordKey);
    return savedEmail == email && savedPassword == password;
  }

  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
    await prefs.remove(_passwordKey);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_emailKey);
  }

  deleteAccount() {}
}

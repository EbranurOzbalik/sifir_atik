import 'package:shared_preferences/shared_preferences.dart';

class SessionPreferences {
  static const _rememberMeKey = 'remember_me';

  const SessionPreferences();

  Future<bool> getRememberMe() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_rememberMeKey) ?? false;
  }

  Future<void> setRememberMe(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_rememberMeKey, value);
  }

  Future<void> clearRememberMe() => setRememberMe(false);
}

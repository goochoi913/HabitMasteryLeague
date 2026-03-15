import 'package:shared_preferences/shared_preferences.dart';

class PrefsHelper {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Username
  static String getUsername() => _prefs.getString('username') ?? 'Habit Hero';
  static Future<void> setUsername(String v) => _prefs.setString('username', v);

  // Dark mode
  static bool getDarkMode() => _prefs.getBool('dark_mode') ?? false;
  static Future<void> setDarkMode(bool v) => _prefs.setBool('dark_mode', v);

  // Reminder time
  static String getReminderTime() => _prefs.getString('reminder_time') ?? '09:00';
  static Future<void> setReminderTime(String v) => _prefs.setString('reminder_time', v);

  // AI feedback
  static Future<void> saveAIFeedback(String key, bool isPositive) =>
      _prefs.setBool('ai_feedback_$key', isPositive);
  static bool? getAIFeedback(String key) => _prefs.getBool('ai_feedback_$key');

  // First launch
  static bool isFirstLaunch() => !(_prefs.getBool('launched') ?? false);
  static Future<void> setLaunched() => _prefs.setBool('launched', true);
}
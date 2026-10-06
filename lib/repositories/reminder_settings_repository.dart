import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/reminder_settings.dart';

class ReminderSettingsRepository {
  const ReminderSettingsRepository();

  static const _key = 'dataquest_reminder_settings_v1';

  Future<ReminderSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return ReminderSettings.defaults();

    try {
      return ReminderSettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return ReminderSettings.defaults();
    }
  }

  Future<void> save(ReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}

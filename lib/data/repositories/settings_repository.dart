import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mosque_settings.dart';

/// Local persistence repository for TV mosque settings via SharedPreferences.
class SettingsRepository {
  static const String _key = 'mosque_settings';

  /// Saves the current [MosqueSettings] to local flash storage.
  static Future<void> save(MosqueSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }

  /// Loads saved [MosqueSettings] from local flash storage, or returns defaults.
  static Future<MosqueSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return MosqueSettings.fromJson(decoded);
      } catch (_) {
        // Fallback to defaults on parse corruption
      }
    }
    return const MosqueSettings();
  }
}

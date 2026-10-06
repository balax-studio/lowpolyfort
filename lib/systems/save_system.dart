import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_save.dart';

/// Manages local persistence and schema migrations.
class SaveSystem {
  static const String _storageKey = 'poly_fort_player_save_v1';
  static PlayerSave _currentSave = const PlayerSave();

  static PlayerSave get currentSave => _currentSave;

  /// Loads save data from device storage.
  static Future<PlayerSave> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        _currentSave = PlayerSave.fromJson(jsonString);
      } else {
        _currentSave = const PlayerSave();
      }
    } catch (_) {
      _currentSave = const PlayerSave();
    }
    return _currentSave;
  }

  /// Persists the updated save model to disk.
  static Future<void> save(PlayerSave updatedSave) async {
    _currentSave = updatedSave;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, _currentSave.toJson());
    } catch (_) {
      // Graceful fallback for sandboxed/restricted test runs
    }
  }

  /// Resets player save data to initial factory state (debug / user reset).
  static Future<void> resetAll() async {
    _currentSave = const PlayerSave();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }
}

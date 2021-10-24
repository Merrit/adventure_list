import 'package:shared_preferences/shared_preferences.dart';

class PreferencesRepository {
  final SharedPreferences _prefs;

  const PreferencesRepository(this._prefs);

  String? getString(String key) => _prefs.getString(key);

  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  Future<bool> remove(String key) async => await _prefs.remove(key);
}

import 'package:shared_preferences/shared_preferences.dart';

abstract class SettingsRepository {
  Future<bool> getSound();
  Future<void> setSound(bool value);

  Future<bool> getMusic();
  Future<void> setMusic(bool value);

  Future<bool> getHaptics();
  Future<void> setHaptics(bool value);

  Future<bool> getDarkMode();
  Future<void> setDarkMode(bool value);

  Future<bool> getSafeTap();
  Future<void> setSafeTap(bool value);

  Future<bool> getGridAssistDefault();
  Future<void> setGridAssistDefault(bool value);

  Future<bool> getReduceMotion();
  Future<void> setReduceMotion(bool value);
}

class SharedPreferencesSettingsRepository implements SettingsRepository {
  static const _kSound = 'settings.sound';
  static const _kMusic = 'settings.music';
  static const _kHaptics = 'settings.haptics';
  static const _kDarkMode = 'settings.darkMode';
  static const _kSafeTap = 'settings.safeTap';
  static const _kGridAssist = 'settings.gridAssistDefault';
  static const _kReduceMotion = 'settings.reduceMotion';

  final SharedPreferences _prefs;
  SharedPreferencesSettingsRepository(this._prefs);

  @override
  Future<bool> getSound() async => _prefs.getBool(_kSound) ?? true;
  @override
  Future<void> setSound(bool v) async => _prefs.setBool(_kSound, v);

  @override
  Future<bool> getMusic() async => _prefs.getBool(_kMusic) ?? true;
  @override
  Future<void> setMusic(bool v) async => _prefs.setBool(_kMusic, v);

  @override
  Future<bool> getHaptics() async => _prefs.getBool(_kHaptics) ?? true;
  @override
  Future<void> setHaptics(bool v) async => _prefs.setBool(_kHaptics, v);

  @override
  Future<bool> getDarkMode() async => _prefs.getBool(_kDarkMode) ?? false;
  @override
  Future<void> setDarkMode(bool v) async => _prefs.setBool(_kDarkMode, v);

  @override
  Future<bool> getSafeTap() async => _prefs.getBool(_kSafeTap) ?? false;
  @override
  Future<void> setSafeTap(bool v) async => _prefs.setBool(_kSafeTap, v);

  @override
  Future<bool> getGridAssistDefault() async =>
      _prefs.getBool(_kGridAssist) ?? false;
  @override
  Future<void> setGridAssistDefault(bool v) async =>
      _prefs.setBool(_kGridAssist, v);

  @override
  Future<bool> getReduceMotion() async =>
      _prefs.getBool(_kReduceMotion) ?? false;
  @override
  Future<void> setReduceMotion(bool v) async =>
      _prefs.setBool(_kReduceMotion, v);
}

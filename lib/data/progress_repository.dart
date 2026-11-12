import 'package:shared_preferences/shared_preferences.dart';

abstract class ProgressRepository {
  Future<int> getCurrentLevel();
  Future<void> setCurrentLevel(int level);

  Future<int> getCoins();
  Future<void> setCoins(int coins);
  Future<void> addCoins(int delta);

  Future<int> getHints();
  Future<void> setHints(int hints);
  Future<void> addHints(int delta);

  Future<List<String>> getCompletedDaily();
  Future<void> markDailyCompleted(String yyyyMMdd);

  Future<List<String>> getTrophies();
  Future<void> addTrophy(String yyyyMM);

  Future<bool> getTutorialSeen(int step);
  Future<void> setTutorialSeen(int step);

  Future<int> getArrowStyleIndex();
  Future<void> setArrowStyleIndex(int index);

  Future<int> getSavedLives();
  Future<void> setSavedLives(int lives);

  Future<void> resetProgress();
}

class SharedPreferencesProgressRepository implements ProgressRepository {
  static const _keyCurrentLevel = 'currentLevel';
  static const _keyCoins = 'coins';
  static const _keyHints = 'hints';
  static const _keyCompletedDaily = 'completedDaily';
  static const _keyTrophies = 'trophies';
  static const _keyTutorialPrefix = 'tutorial.seen.';
  static const _keyArrowStyleIndex = 'settings.arrowStyleIndex';

  static const _keySavedLives = 'game.savedLives';

  final SharedPreferences _prefs;
  SharedPreferencesProgressRepository(this._prefs);

  @override
  Future<int> getCurrentLevel() async {
    return _prefs.getInt(_keyCurrentLevel) ?? 1;
  }

  @override
  Future<void> setCurrentLevel(int level) async {
    await _prefs.setInt(_keyCurrentLevel, level);
  }

  @override
  Future<int> getCoins() async {
    return _prefs.getInt(_keyCoins) ?? 0;
  }

  @override
  Future<void> setCoins(int coins) async {
    await _prefs.setInt(_keyCoins, coins);
  }

  @override
  Future<void> addCoins(int delta) async {
    final current = await getCoins();
    await setCoins(current + delta);
  }

  @override
  Future<int> getHints() async {
    return _prefs.getInt(_keyHints) ?? 3;
  }

  @override
  Future<void> setHints(int hints) async {
    await _prefs.setInt(_keyHints, hints);
  }

  @override
  Future<void> addHints(int delta) async {
    final current = await getHints();
    await setHints(current + delta);
  }

  @override
  Future<List<String>> getCompletedDaily() async {
    return _prefs.getStringList(_keyCompletedDaily) ?? [];
  }

  @override
  Future<void> markDailyCompleted(String yyyyMMdd) async {
    final list = (await getCompletedDaily()).toSet();
    list.add(yyyyMMdd);
    await _prefs.setStringList(_keyCompletedDaily, list.toList());
  }

  @override
  Future<List<String>> getTrophies() async {
    return _prefs.getStringList(_keyTrophies) ?? [];
  }

  @override
  Future<void> addTrophy(String yyyyMM) async {
    final list = (await getTrophies()).toSet();
    list.add(yyyyMM);
    await _prefs.setStringList(_keyTrophies, list.toList());
  }

  @override
  Future<bool> getTutorialSeen(int step) async {
    return _prefs.getBool('$_keyTutorialPrefix$step') ?? false;
  }

  @override
  Future<void> setTutorialSeen(int step) async {
    await _prefs.setBool('$_keyTutorialPrefix$step', true);
  }

  @override
  Future<int> getArrowStyleIndex() async {
    return _prefs.getInt(_keyArrowStyleIndex) ?? 0;
  }

  @override
  Future<void> setArrowStyleIndex(int index) async {
    await _prefs.setInt(_keyArrowStyleIndex, index);
  }

  @override
  Future<int> getSavedLives() async {
    return _prefs.getInt(_keySavedLives) ?? 3;
  }

  @override
  Future<void> setSavedLives(int lives) async {
    await _prefs.setInt(_keySavedLives, lives);
  }

  @override
  Future<void> resetProgress() async {
    await _prefs.remove(_keyCurrentLevel);
    await _prefs.remove(_keyCoins);
    await _prefs.remove(_keyHints);
    await _prefs.remove(_keyCompletedDaily);
    await _prefs.remove(_keyTrophies);
    await _prefs.remove(_keyArrowStyleIndex);
    await _prefs.remove('${_keyTutorialPrefix}1');
    await _prefs.remove('${_keyTutorialPrefix}2');
    await _prefs.remove('${_keyTutorialPrefix}3');
  }
}

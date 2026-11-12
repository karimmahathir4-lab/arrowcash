import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

enum Sfx {
  tap('tap.mp3'),
  slide('slide.mp3'),
  error('error.mp3'),
  hint('hint.mp3'),
  win('win.mp3'),
  click('tap.mp3');

  final String file;
  const Sfx(this.file);
}

class AudioService {
  static final AudioService instance = AudioService._();
  AudioService._();

  final AudioPlayer _player = AudioPlayer();
  final Set<String> _existingAssets = {};
  bool _initialized = false;
  bool soundEnabled = true;
  bool musicEnabled = true;

  Future<void> init() async {
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
    } catch (_) {}

    // Check which assets actually exist in the bundle to prevent unhandled web/platform exceptions
    for (final sfx in Sfx.values) {
      final path = 'assets/sfx/${sfx.file}';
      try {
        await rootBundle.load(path);
        _existingAssets.add(sfx.file);
      } catch (_) {
        // Asset not present in asset bundle; don't attempt to play
      }
    }
    _initialized = true;
  }

  Future<void> play(Sfx sfx) async {
    if (!soundEnabled) return;
    if (!_initialized) {
      await init();
    }
    if (!_existingAssets.contains(sfx.file)) {
      return;
    }
    try {
      await _player.stop();
      await _player.play(AssetSource('sfx/${sfx.file}'), volume: 0.8);
    } catch (_) {
      // Fail silently
    }
  }

  void dispose() {
    _player.dispose();
  }
}

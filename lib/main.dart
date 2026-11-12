import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'app.dart';
import 'core/ad_service.dart';
import 'core/audio_service.dart';
import 'core/haptics.dart';
import 'data/progress_repository.dart';
import 'data/reward_service.dart';
import 'data/settings_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait on phones
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Request App Tracking Transparency permission on iOS at startup
  try {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await Future.delayed(const Duration(milliseconds: 200));
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  } catch (e) {
    debugPrint('ATT error: $e');
  }

  // Initialize AppLovin Ads SDK
  await AdService.instance.init();

  final prefs = await SharedPreferences.getInstance();
  final progressRepo = SharedPreferencesProgressRepository(prefs);
  final settingsRepo = SharedPreferencesSettingsRepository(prefs);
  final rewardService = DefaultRewardService();

  // Initialize audio and haptics preferences
  await AudioService.instance.init();
  AudioService.instance.soundEnabled = await settingsRepo.getSound();
  AudioService.instance.musicEnabled = await settingsRepo.getMusic();
  Haptics.enabled = await settingsRepo.getHaptics();

  runApp(
    ProviderScope(
      child: ArrowApp(
        progressRepo: progressRepo,
        settingsRepo: settingsRepo,
        rewardService: rewardService,
      ),
    ),
  );
}

import 'dart:async';
import 'package:applovin_max/applovin_max.dart';
import 'package:flutter/foundation.dart';

class AdService {
  static final AdService instance = AdService._();
  AdService._();

  static const String sdkKey =
      '8RHCMxxZPei--AGwtM3E6OEev0RW51t-s1RrGEr0puTkrPT7XC7AEHoaUa2FCmJ3PTAJSVW2AeHBgIoA4MpNS-';
  static const String interstitialAdUnitId = '4e182aa43649109e';
  static const String rewardedAdUnitId = '1783ad88172a2457';

  bool _initialized = false;
  int _actionClickCount = 0;

  // Interstitial state
  int _interstitialRetryAttempt = 0;

  // Rewarded state
  int _rewardedRetryAttempt = 0;
  Function(MaxReward reward)? _onUserRewardedCallback;

  Future<void> init() async {
    if (_initialized) return;

    try {
      final config = await AppLovinMAX.initialize(sdkKey);
      _initialized = true;
      debugPrint('AppLovin initialized: ${config?.countryCode}');

      _attachInterstitialListeners();
      _attachRewardedListeners();

      _loadInterstitial();
      _loadRewarded();
    } catch (e) {
      debugPrint('AppLovin initialization error: $e');
    }
  }

  void _attachInterstitialListeners() {
    AppLovinMAX.setInterstitialListener(
      InterstitialListener(
        onAdLoadedCallback: (ad) {
          debugPrint('Interstitial loaded: ${ad.adUnitId}');
          _interstitialRetryAttempt = 0;
        },
        onAdLoadFailedCallback: (adUnitId, error) {
          _interstitialRetryAttempt++;
          final retryDelay = Duration(
            seconds: (1 << _interstitialRetryAttempt).clamp(2, 60),
          );
          debugPrint(
            'Interstitial load failed: $error. Retrying in ${retryDelay.inSeconds}s',
          );
          Future.delayed(retryDelay, () => _loadInterstitial());
        },
        onAdDisplayedCallback: (ad) {},
        onAdDisplayFailedCallback: (ad, error) {
          _loadInterstitial();
        },
        onAdClickedCallback: (ad) {},
        onAdHiddenCallback: (ad) {
          _loadInterstitial();
        },
      ),
    );
  }

  void _loadInterstitial() {
    try {
      AppLovinMAX.loadInterstitial(interstitialAdUnitId);
    } catch (e) {
      debugPrint('Error loading interstitial: $e');
    }
  }

  /// Show interstitial ad. Calls onDismissed whether ad was shown or skipped.
  Future<void> showInterstitial({VoidCallback? onDismissed}) async {
    try {
      final isReady = await AppLovinMAX.isInterstitialReady(
        interstitialAdUnitId,
      );
      if (isReady == true) {
        // AppLovinMAX showInterstitial doesn't block, so we register a short hook or invoke
        AppLovinMAX.showInterstitial(interstitialAdUnitId);
      }
    } catch (e) {
      debugPrint('Error showing interstitial: $e');
    }
    // Continue user flow smoothly
    onDismissed?.call();
  }

  /// Count user UI clicks (bottom menu, replay, back buttons).
  /// Every 5 clicks, show an interstitial ad.
  void recordActionClick({VoidCallback? onAdDone}) {
    _actionClickCount++;
    if (_actionClickCount % 5 == 0) {
      showInterstitial(onDismissed: onAdDone);
    } else {
      onAdDone?.call();
    }
  }

  void _attachRewardedListeners() {
    AppLovinMAX.setRewardedAdListener(
      RewardedAdListener(
        onAdLoadedCallback: (ad) {
          debugPrint('Rewarded ad loaded: ${ad.adUnitId}');
          _rewardedRetryAttempt = 0;
        },
        onAdLoadFailedCallback: (adUnitId, error) {
          _rewardedRetryAttempt++;
          final retryDelay = Duration(
            seconds: (1 << _rewardedRetryAttempt).clamp(2, 60),
          );
          debugPrint(
            'Rewarded ad load failed: $error. Retrying in ${retryDelay.inSeconds}s',
          );
          Future.delayed(retryDelay, () => _loadRewarded());
        },
        onAdDisplayedCallback: (ad) {},
        onAdDisplayFailedCallback: (ad, error) {
          _loadRewarded();
        },
        onAdClickedCallback: (ad) {},
        onAdHiddenCallback: (ad) {
          _loadRewarded();
        },
        onAdReceivedRewardCallback: (ad, reward) {
          _onUserRewardedCallback?.call(reward);
          _onUserRewardedCallback = null;
        },
      ),
    );
  }

  void _loadRewarded() {
    try {
      AppLovinMAX.loadRewardedAd(rewardedAdUnitId);
    } catch (e) {
      debugPrint('Error loading rewarded ad: $e');
    }
  }

  /// Show rewarded ad. Calls onRewardEarned if completed, or onFailure if unavailable.
  Future<void> showRewardedAd({
    required VoidCallback onRewardEarned,
    VoidCallback? onFailure,
  }) async {
    try {
      final isReady = await AppLovinMAX.isRewardedAdReady(rewardedAdUnitId);
      if (isReady == true) {
        _onUserRewardedCallback = (reward) {
          onRewardEarned();
        };
        AppLovinMAX.showRewardedAd(rewardedAdUnitId);
      } else {
        // Fallback if ad is not yet cached or network blocked
        _loadRewarded();
        onFailure?.call();
      }
    } catch (e) {
      debugPrint('Error showing rewarded ad: $e');
      onFailure?.call();
    }
  }
}

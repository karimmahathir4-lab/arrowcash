import 'package:flutter/material.dart';
import '../../../core/ad_service.dart';
import '../../../core/theme/tokens.dart';
import '../../../data/reward_service.dart';

class LevelFailedDialog extends StatefulWidget {
  final VoidCallback onTryAgain;
  final VoidCallback onMain;
  final VoidCallback onContinueRewarded;
  final RewardService rewardService;
  final bool isDark;

  const LevelFailedDialog({
    super.key,
    required this.onTryAgain,
    required this.onMain,
    required this.onContinueRewarded,
    required this.rewardService,
    this.isDark = false,
  });

  @override
  State<LevelFailedDialog> createState() => _LevelFailedDialogState();
}

class _LevelFailedDialogState extends State<LevelFailedDialog> {
  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF1B233D) : Colors.white;
    final titleColor = widget.isDark ? Colors.white : T.title;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: bg,
      elevation: 16,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 28.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Broken heart illustration
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: T.heart.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.heart_broken_rounded,
                    size: 42,
                    color: T.heart,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Out of lives',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Take a breath and try again!',
                  style: TextStyle(
                    fontSize: 15,
                    color: widget.isDark ? T.darkChipText : T.chipText,
                  ),
                ),
                const SizedBox(height: 24),

                // Watch Ad to Refill Hearts (Reward Ad)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.favorite, color: Colors.white),
                    label: const Text(
                      'Get Hearts (Watch Ad)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: T.heart,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    onPressed: () {
                      AdService.instance.showRewardedAd(
                        onRewardEarned: () {
                          widget.onContinueRewarded();
                        },
                        onFailure: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Ad not ready yet. Please try again.',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Try Again button (also checks rewarded or interstitial if out of hearts)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: T.accent,
                      side: const BorderSide(color: T.accent, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    onPressed: () {
                      AdService.instance.showRewardedAd(
                        onRewardEarned: widget.onTryAgain,
                        onFailure: () {
                          AdService.instance.showInterstitial(
                            onDismissed: widget.onTryAgain,
                          );
                        },
                      );
                    },
                    child: const Text(
                      'Restart Level',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Main text button
                TextButton(
                  onPressed: widget.onMain,
                  child: Text(
                    'Main',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: widget.isDark ? T.darkChipText : T.chipText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

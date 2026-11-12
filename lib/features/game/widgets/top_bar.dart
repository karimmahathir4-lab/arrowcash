import 'package:flutter/material.dart';
import '../../../../core/theme/tokens.dart';

class TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback onReplay;
  final VoidCallback onSettings;
  final int coins;
  final bool isDark;

  const TopBar({
    super.key,
    required this.title,
    required this.onBack,
    required this.onReplay,
    required this.onSettings,
    this.coins = 0,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : T.title;

    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left row: Back button + Replay button
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    size: 34,
                    color: T.accent,
                  ),
                  onPressed: onBack,
                  tooltip: 'Back to Menu',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 26,
                    color: T.accent,
                  ),
                  onPressed: onReplay,
                  tooltip: 'Restart Level',
                ),
              ],
            ),

            // Center Title
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),

            // Right row: Coin Counter pill + Settings gear
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB800).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFFB800).withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.monetization_on_rounded,
                        size: 18,
                        color: Color(0xFFFFB800),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$coins',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD48800),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(
                    Icons.settings_outlined,
                    size: 26,
                    color: T.accent,
                  ),
                  onPressed: onSettings,
                  tooltip: 'Settings',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

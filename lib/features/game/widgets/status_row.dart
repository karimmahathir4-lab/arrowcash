import 'package:flutter/material.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../game/models/level.dart';
import 'hearts_row.dart';

class StatusRow extends StatelessWidget {
  final int remaining;
  final int lives;
  final Difficulty difficulty;
  final bool isDark;

  const StatusRow({
    super.key,
    required this.remaining,
    required this.lives,
    required this.difficulty,
    this.isDark = false,
  });

  String get _diffLabel {
    switch (difficulty) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.normal:
        return 'Normal';
      case Difficulty.hard:
        return 'Hard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final chipBackground = isDark ? T.darkChipBg : T.chipBg;
    final chipTextColor = isDark ? T.darkChipText : T.chipText;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Remaining arrows chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: chipBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.near_me, size: 18, color: chipTextColor),
                const SizedBox(width: 6),
                Text(
                  '$remaining',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: chipTextColor,
                  ),
                ),
              ],
            ),
          ),

          // Hearts in center
          HeartsRow(lives: lives),

          // Difficulty chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: chipBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _diffLabel,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: chipTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

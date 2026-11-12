import 'package:flutter/material.dart';
import '../../../../core/theme/tokens.dart';

class HeartsRow extends StatelessWidget {
  final int lives; // 0 to 3
  final double heartSize;

  const HeartsRow({super.key, required this.lives, this.heartSize = 34});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isFilled = index < lives;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              isFilled ? Icons.favorite : Icons.favorite_border,
              key: ValueKey('heart_${index}_$isFilled'),
              color: T.heart,
              size: heartSize,
            ),
          ),
        );
      }),
    );
  }
}

import 'dart:math' as math;
import 'level.dart';

enum ShapeType {
  rectangle,
  roundedRect,
  circle,
  ellipse,
  diamond,
  heart,
  star,
  leaf,
  blobNoise,
  cross,
  hexagon,
  butterfly,
  crescentMoon,
  shield,
  clover,
}

class LevelParams {
  final ShapeType shape;
  final int cols;
  final int rows;
  final int minArrows;
  final int maxArrows;
  final int minLen;
  final int maxLen;
  final double turnProb;
  final int minDepth;
  final double crossingBias;
  final int maxFailStreak;
  final int growRetries;

  const LevelParams({
    required this.shape,
    required this.cols,
    required this.rows,
    required this.minArrows,
    required this.maxArrows,
    required this.minLen,
    required this.maxLen,
    required this.turnProb,
    required this.minDepth,
    required this.crossingBias,
    this.maxFailStreak = 45,
    this.growRetries = 10,
  });

  static Difficulty difficultyFor(int n) {
    if (n <= 10) return Difficulty.easy;
    if (n <= 35) return n % 4 == 0 ? Difficulty.hard : Difficulty.normal;
    return n % 5 == 0 ? Difficulty.normal : Difficulty.hard;
  }

  static LevelParams forLevel(int n) {
    final diff = difficultyFor(n);

    // Grid size grows smoothly with level
    final baseSize = 6 + 2.2 * math.sqrt(n.toDouble());
    final mult = diff == Difficulty.hard
        ? 1.25
        : (diff == Difficulty.easy ? 0.9 : 1.0);
    final calculatedCols = (baseSize * mult).round().clamp(6, 45);
    final calculatedRows = ((baseSize * 1.2) * mult).round().clamp(7, 55);

    // User request: "Add cool shapes like heart star and more cool shapes to levels from level 5 and up."
    final ShapeType shape;
    if (n == 1 || n == 2) {
      shape = ShapeType.rectangle;
    } else if (n == 3) {
      shape = ShapeType.roundedRect;
    } else if (n == 4) {
      shape = ShapeType.circle;
    } else if (n == 5) {
      shape = ShapeType.heart;
    } else if (n == 6) {
      shape = ShapeType.star;
    } else if (n == 7) {
      shape = ShapeType.clover;
    } else if (n == 8) {
      shape = ShapeType.butterfly;
    } else if (n == 9) {
      shape = ShapeType.crescentMoon;
    } else if (n == 10) {
      shape = ShapeType.shield;
    } else {
      // Rotating selection of rich cool shapes for level 11+
      const coolShapes = [
        ShapeType.heart,
        ShapeType.star,
        ShapeType.butterfly,
        ShapeType.crescentMoon,
        ShapeType.shield,
        ShapeType.clover,
        ShapeType.diamond,
        ShapeType.leaf,
        ShapeType.blobNoise,
        ShapeType.hexagon,
      ];
      shape = coolShapes[n % coolShapes.length];
    }

    final int minArrows;
    final int maxArrows;
    final int minLen;
    final int maxLen;
    final double turnProb;
    final int minDepth;
    final double crossingBias;

    if (n == 1) {
      return const LevelParams(
        shape: ShapeType.rectangle,
        cols: 6,
        rows: 7,
        minArrows: 3,
        maxArrows: 4,
        minLen: 2,
        maxLen: 4,
        turnProb: 0.1,
        minDepth: 2,
        crossingBias: 0.5,
        maxFailStreak: 30,
        growRetries: 8,
      );
    } else if (n <= 5) {
      minArrows = 5;
      maxArrows = 10;
      minLen = 2;
      maxLen = 5;
      turnProb = 0.2;
      minDepth = 2;
      crossingBias = 0.7;
    } else if (diff == Difficulty.easy) {
      final capArrows = (10 + n * 2).clamp(10, 30);
      minArrows = (capArrows * 0.7).round();
      maxArrows = capArrows;
      minLen = 2;
      maxLen = 5;
      turnProb = 0.2;
      minDepth = 2;
      crossingBias = 0.8;
    } else if (diff == Difficulty.normal) {
      final capArrows = (20 + n * 1.5).round().clamp(25, 90);
      minArrows = (capArrows * 0.7).round();
      maxArrows = capArrows;
      minLen = 2;
      maxLen = 8;
      turnProb = 0.35;
      minDepth = 4;
      crossingBias = 1.4;
    } else {
      // Hard
      final capArrows = (40 + n * 1.6).round().clamp(50, 260);
      minArrows = (capArrows * 0.65).round();
      maxArrows = capArrows;
      minLen = 3;
      maxLen = 14;
      turnProb = 0.5;
      minDepth = 6;
      crossingBias = 2.0;
    }

    return LevelParams(
      shape: shape,
      cols: calculatedCols,
      rows: calculatedRows,
      minArrows: minArrows,
      maxArrows: maxArrows,
      minLen: minLen,
      maxLen: maxLen,
      turnProb: turnProb,
      minDepth: minDepth,
      crossingBias: crossingBias,
      maxFailStreak: 45,
      growRetries: 12,
    );
  }
}

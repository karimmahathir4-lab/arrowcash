import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/level.dart';

class HitTester {
  /// Distance from point p to line segment ab
  static double distPointSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final t = ab.distanceSquared == 0
        ? 0.0
        : ((p - a).dx * ab.dx + (p - a).dy * ab.dy) / ab.distanceSquared;
    final c = a + ab * t.clamp(0.0, 1.0);
    return (p - c).distance;
  }

  /// Finds the tapped arrow piece.
  /// Enforces:
  /// - Screen tolerance tolPx = 16 dp converted to board units: tolBoard = tolPx / currentScale.
  /// - Never exceeds 0.5 * u.
  /// - Ambiguous tap (two nearest within 15%) returns null.
  /// - Taps outside tolerance return null.
  static int? testHit({
    required Offset tapBoardPos,
    required Level level,
    required Set<int> aliveArrowIds,
    required Set<int> animatingArrowIds,
    required double u,
    required Offset origin,
    required double currentScale,
  }) {
    const tolPx = 16.0;
    final tolBoard = math.min(tolPx / currentScale, 0.5 * u);

    double firstDist = double.infinity;
    int? firstArrowId;
    double secondDist = double.infinity;

    for (final arrow in level.arrows) {
      if (!aliveArrowIds.contains(arrow.id)) continue;
      if (animatingArrowIds.contains(arrow.id)) continue;

      double arrowMinDist = double.infinity;
      for (int i = 1; i < arrow.nodes.length; i++) {
        final aNode = arrow.nodes[i - 1];
        final bNode = arrow.nodes[i];
        final a = Offset(
          origin.dx + (aNode % level.cols) * u,
          origin.dy + (aNode ~/ level.cols) * u,
        );
        final b = Offset(
          origin.dx + (bNode % level.cols) * u,
          origin.dy + (bNode ~/ level.cols) * u,
        );

        final d = distPointSegment(tapBoardPos, a, b);
        if (d < arrowMinDist) {
          arrowMinDist = d;
        }
      }

      if (arrowMinDist < firstDist) {
        secondDist = firstDist;
        firstDist = arrowMinDist;
        firstArrowId = arrow.id;
      } else if (arrowMinDist < secondDist) {
        secondDist = arrowMinDist;
      }
    }

    // Nothing within tolerance
    if (firstArrowId == null || firstDist > tolBoard) {
      return null;
    }

    // Ambiguity check: if two nearest arrows are within 15% distance, ignore tap
    if (secondDist.isFinite && secondDist <= tolBoard) {
      if ((secondDist - firstDist) < firstDist * 0.15) {
        return null;
      }
    }

    return firstArrowId;
  }
}

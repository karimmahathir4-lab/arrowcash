import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/arrow_piece.dart';
import '../models/dir.dart';

class ArrowPathBuilder {
  /// Builds the polyline path of an arrow from tail to the base of its arrowhead.
  static Path buildBodyPath(
    ArrowPiece arrow,
    int cols,
    double u,
    Offset origin,
    double headSize,
  ) {
    final path = Path();
    if (arrow.nodes.length < 2) return path;

    final first = arrow.nodes.first;
    final fx = origin.dx + (first % cols) * u;
    final fy = origin.dy + (first ~/ cols) * u;
    path.moveTo(fx, fy);

    for (int i = 1; i < arrow.nodes.length - 1; i++) {
      final n = arrow.nodes[i];
      final nx = origin.dx + (n % cols) * u;
      final ny = origin.dy + (n ~/ cols) * u;
      path.lineTo(nx, ny);
    }

    // For the last segment, stop where the arrowhead begins
    final head = arrow.head;
    final prev = arrow.nodes[arrow.nodes.length - 2];
    final hx = origin.dx + (head % cols) * u;
    final hy = origin.dy + (head ~/ cols) * u;

    final d = dirBetween(prev % cols, prev ~/ cols, head % cols, head ~/ cols);
    final stopX = hx - d.dx * (headSize * 0.85);
    final stopY = hy - d.dy * (headSize * 0.85);

    path.lineTo(stopX, stopY);
    return path;
  }

  /// Builds the filled triangle arrowhead path at the head of the arrow.
  static Path buildArrowHead(
    ArrowPiece arrow,
    int cols,
    double u,
    Offset origin,
    double headSize,
  ) {
    final path = Path();
    final head = arrow.head;
    final hx = origin.dx + (head % cols) * u;
    final hy = origin.dy + (head ~/ cols) * u;
    final d = arrow.dir(cols);

    // Tip of arrowhead is slightly beyond node center or at node center
    final tipX = hx + d.dx * (headSize * 0.35);
    final tipY = hy + d.dy * (headSize * 0.35);

    // Base of arrowhead
    final baseX = hx - d.dx * (headSize * 0.85);
    final baseY = hy - d.dy * (headSize * 0.85);

    // Orthogonal perpendicular vector
    final perpX = -d.dy;
    final perpY = d.dx;
    final halfWidth = headSize * 0.55;

    path.moveTo(tipX, tipY);
    path.lineTo(baseX + perpX * halfWidth, baseY + perpY * halfWidth);
    path.lineTo(baseX - perpX * halfWidth, baseY - perpY * halfWidth);
    path.close();

    return path;
  }

  /// Builds full extended path for escape animation:
  /// Arrow body (tail -> head) + straight extension far beyond the board.
  static Path buildExtendedPath(
    ArrowPiece arrow,
    int cols,
    double u,
    Offset origin,
    double extensionLength,
  ) {
    final path = Path();
    final first = arrow.nodes.first;
    path.moveTo(
      origin.dx + (first % cols) * u,
      origin.dy + (first ~/ cols) * u,
    );

    for (int i = 1; i < arrow.nodes.length; i++) {
      final n = arrow.nodes[i];
      path.lineTo(origin.dx + (n % cols) * u, origin.dy + (n ~/ cols) * u);
    }

    // Straight extension along direction beyond grid
    final head = arrow.head;
    final hx = origin.dx + (head % cols) * u;
    final hy = origin.dy + (head ~/ cols) * u;
    final d = arrow.dir(cols);

    path.lineTo(hx + d.dx * extensionLength, hy + d.dy * extensionLength);
    return path;
  }

  /// Computes the total geometric length of the arrow body in canvas units.
  static double getArrowBodyLength(ArrowPiece arrow, int cols, double u) {
    double total = 0.0;
    for (int i = 1; i < arrow.nodes.length; i++) {
      final a = arrow.nodes[i - 1];
      final b = arrow.nodes[i];
      final ax = (a % cols) * u;
      final ay = (a ~/ cols) * u;
      final bx = (b % cols) * u;
      final by = (b ~/ cols) * u;
      total += math.sqrt((bx - ax) * (bx - ax) + (by - ay) * (by - ay));
    }
    return total;
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../models/arrow_piece.dart';
import '../models/dir.dart';
import '../models/level.dart';
import 'arrow_path_builder.dart';

class AnimatingArrow {
  final ArrowPiece arrow;
  final double progress; // 0.0 to 1.0
  final double totalDistance;
  final Color color; // Dynamic color (e.g. T.success green on escape)

  const AnimatingArrow({
    required this.arrow,
    required this.progress,
    required this.totalDistance,
    this.color = T.success,
  });
}

class BoardPainter extends CustomPainter {
  final Level level;
  final Set<int> aliveIds;
  final Set<int> clearedNodes;
  final Map<int, double>
  ghostDotFades; // Smooth fade-in progress per cleared node
  final Map<int, AnimatingArrow> animatingArrows;
  final Set<int> wrongArrowIds; // Persistent wrong arrows kept highlighted red
  final int? hintedArrowId;
  final int? selectedArrowId;
  final int? blockedFlashArrowId;
  final int? blockedHighlightArrowId; // The blocker tinted
  final double flashProgress; // 0.0 to 1.0 (for shake/color)
  final bool gridAssist;
  final double pulseValue; // For hinting glow pulsation
  final bool isDark;
  final List<bool>? mask;
  final ArrowThemeStyle arrowStyle;

  BoardPainter({
    required this.level,
    required this.aliveIds,
    required this.clearedNodes,
    this.ghostDotFades = const {},
    required this.animatingArrows,
    this.wrongArrowIds = const {},
    this.hintedArrowId,
    this.selectedArrowId,
    this.blockedFlashArrowId,
    this.blockedHighlightArrowId,
    this.flashProgress = 0.0,
    this.gridAssist = false,
    this.pulseValue = 0.0,
    this.isDark = false,
    this.mask,
    this.arrowStyle = ArrowThemeStyle.classic,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (level.cols < 2 || level.rows < 2) return;

    const padding = 24.0;
    final availW = math.max(0.0, size.width - padding * 2);
    final availH = math.max(0.0, size.height - padding * 2);

    final u = math.min(availW / (level.cols - 1), availH / (level.rows - 1));

    final boardW = (level.cols - 1) * u;
    final boardH = (level.rows - 1) * u;
    final origin = Offset(
      (size.width - boardW) / 2,
      (size.height - boardH) / 2,
    );

    final strokeWidth = (u * 0.14).clamp(2.0, 5.0);
    final headSize = math.max(u * 0.5, 6.0);

    // 1. Grid-assist dots (faint dots on empty in-mask nodes)
    if (gridAssist) {
      final assistPaint = Paint()
        ..color = (isDark ? Colors.white24 : Colors.black12)
        ..style = PaintingStyle.fill;
      final dotRadius = (u * 0.08).clamp(1.5, 3.0);

      final totalNodes = level.cols * level.rows;
      for (int i = 0; i < totalNodes; i++) {
        final inMask = mask == null || mask![i];
        if (inMask && !clearedNodes.contains(i)) {
          final x = origin.dx + (i % level.cols) * u;
          final y = origin.dy + (i ~/ level.cols) * u;
          canvas.drawCircle(Offset(x, y), dotRadius, assistPaint);
        }
      }
    }

    // 2. Ghost dots with smooth fade & scale animation
    final baseGhostColor = isDark ? Colors.white38 : T.ghostDot;
    final maxGhostRadius = (u * 0.10).clamp(2.5, 4.5);

    for (final node in clearedNodes) {
      final fade = ghostDotFades[node] ?? 1.0;
      final currentRadius = maxGhostRadius * (0.3 + 0.7 * fade);
      final ghostPaint = Paint()
        ..color = baseGhostColor.withValues(alpha: baseGhostColor.a * fade)
        ..style = PaintingStyle.fill;

      final x = origin.dx + (node % level.cols) * u;
      final y = origin.dy + (node ~/ level.cols) * u;
      canvas.drawCircle(Offset(x, y), currentRadius, ghostPaint);
    }

    // 3. Grid assist exit ray preview (for selected/hinted arrow)
    if (gridAssist && (hintedArrowId != null || selectedArrowId != null)) {
      final targetId = hintedArrowId ?? selectedArrowId;
      final targetArrow = level.arrows.cast<ArrowPiece?>().firstWhere(
        (a) => a?.id == targetId,
        orElse: () => null,
      );
      if (targetArrow != null && aliveIds.contains(targetArrow.id)) {
        _drawExitRayGuide(canvas, targetArrow, origin, u);
      }
    }

    // 4. Static arrows
    for (final arrow in level.arrows) {
      if (!aliveIds.contains(arrow.id)) continue;
      if (animatingArrows.containsKey(arrow.id)) continue;

      _drawStaticArrow(
        canvas: canvas,
        arrow: arrow,
        origin: origin,
        u: u,
        strokeWidth: strokeWidth,
        headSize: headSize,
      );
    }

    // 5. Animating escaping arrows
    for (final anim in animatingArrows.values) {
      _drawEscapingArrow(
        canvas: canvas,
        anim: anim,
        origin: origin,
        u: u,
        strokeWidth: strokeWidth,
        headSize: headSize,
        boardW: boardW,
        boardH: boardH,
      );
    }
  }

  void _drawStaticArrow({
    required Canvas canvas,
    required ArrowPiece arrow,
    required Offset origin,
    required double u,
    required double strokeWidth,
    required double headSize,
  }) {
    canvas.save();

    final isHinted = arrow.id == hintedArrowId;
    final isSelected = arrow.id == selectedArrowId;
    final isBlockedFlash = arrow.id == blockedFlashArrowId;
    final isBlockedHighlight = arrow.id == blockedHighlightArrowId;
    final isWrong = wrongArrowIds.contains(arrow.id);

    // Blocked shake effect
    if (isBlockedFlash && flashProgress > 0) {
      final shake =
          math.sin(flashProgress * math.pi * 6) * 4.0 * (1.0 - flashProgress);
      canvas.translate(shake, 0);
    }

    // Hint glow overlay
    if (isHinted) {
      final glowPaint = Paint()
        ..color = arrowStyle.accentColor.withValues(
          alpha: 0.30 + 0.15 * math.sin(pulseValue * math.pi * 2),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 2.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

      final body = ArrowPathBuilder.buildBodyPath(
        arrow,
        level.cols,
        u,
        origin,
        headSize,
      );
      canvas.drawPath(body, glowPaint);
    }

    // Determine colors:
    // If wrong arrow, KEEP it highlighted with RED until its path becomes free
    Color mainColor;
    if (isWrong || isBlockedFlash) {
      mainColor = T.error;
    } else if (isBlockedHighlight) {
      mainColor = T.error.withValues(alpha: 0.7);
    } else if (isHinted || isSelected) {
      mainColor = arrowStyle.accentColor;
    } else {
      mainColor = isDark ? T.darkInk : arrowStyle.primaryColor;
    }

    final bodyPaint = Paint()
      ..color = mainColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final headPaint = Paint()
      ..color = mainColor
      ..style = PaintingStyle.fill;

    final bodyPath = ArrowPathBuilder.buildBodyPath(
      arrow,
      level.cols,
      u,
      origin,
      headSize,
    );
    final headPath = ArrowPathBuilder.buildArrowHead(
      arrow,
      level.cols,
      u,
      origin,
      headSize,
    );

    canvas.drawPath(bodyPath, bodyPaint);
    canvas.drawPath(headPath, headPaint);

    canvas.restore();
  }

  void _drawEscapingArrow({
    required Canvas canvas,
    required AnimatingArrow anim,
    required Offset origin,
    required double u,
    required double strokeWidth,
    required double headSize,
    required double boardW,
    required double boardH,
  }) {
    final arrow = anim.arrow;
    final bodyLen = ArrowPathBuilder.getArrowBodyLength(arrow, level.cols, u);
    final extensionLength = math.max(boardW, boardH) * 1.5 + bodyLen;

    final extendedPath = ArrowPathBuilder.buildExtendedPath(
      arrow,
      level.cols,
      u,
      origin,
      extensionLength,
    );

    final metrics = extendedPath.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;

    final s = Curves.easeIn.transform(anim.progress) * extensionLength;
    final visibleStart = s;
    final visibleEnd = math.min(s + bodyLen, metric.length);

    if (visibleEnd > visibleStart) {
      final visiblePath = metric.extractPath(visibleStart, visibleEnd);

      // Escaping arrow turns GREEN
      final color = anim.color;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(visiblePath, paint);

      // Tangent along path direction:
      // In Flutter, Tangent.vector points in the direction of increasing metric distance (the forward direction).
      // We compute the true direction angle atan2(vector.dy, vector.dx) so the arrow head always
      // points in front in the exact swipe / escape direction regardless of whether it's up, down, left, or right.
      final tangent = metric.getTangentForOffset(visibleEnd);
      if (tangent != null) {
        final forwardAngle = math.atan2(tangent.vector.dy, tangent.vector.dx);
        _drawDynamicArrowHead(
          canvas,
          tangent.position,
          forwardAngle,
          headSize,
          color,
        );
      }
    }
  }

  void _drawDynamicArrowHead(
    Canvas canvas,
    Offset tip,
    double angle,
    double headSize,
    Color color,
  ) {
    canvas.save();
    canvas.translate(tip.dx, tip.dy);
    canvas.rotate(angle);

    final path = Path();
    // Tip at (0,0), wings extend backward in the opposite direction (-x)
    path.moveTo(0, 0);
    path.lineTo(-headSize * 1.1, -headSize * 0.55);
    path.lineTo(-headSize * 1.1, headSize * 0.55);
    path.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  void _drawExitRayGuide(
    Canvas canvas,
    ArrowPiece arrow,
    Offset origin,
    double u,
  ) {
    final head = arrow.head;
    final hx = origin.dx + (head % level.cols) * u;
    final hy = origin.dy + (head ~/ level.cols) * u;
    final d = arrow.dir(level.cols);

    final guidePaint = Paint()
      ..color = arrowStyle.accentColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double currentDist = u * 0.6;
    final maxDist = math.max(level.cols, level.rows) * u * 1.5;

    while (currentDist < maxDist) {
      final sx = hx + d.dx * currentDist;
      final sy = hy + d.dy * currentDist;
      final ex = hx + d.dx * (currentDist + dashWidth);
      final ey = hy + d.dy * (currentDist + dashWidth);
      canvas.drawLine(Offset(sx, sy), Offset(ex, ey), guidePaint);
      currentDist += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) => true;
}

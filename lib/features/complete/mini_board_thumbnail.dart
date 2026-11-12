import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../game/models/level.dart';
import '../../game/render/arrow_path_builder.dart';

class MiniBoardThumbnail extends StatelessWidget {
  final Level level;
  final double size;
  final bool isDark;

  const MiniBoardThumbnail({
    super.key,
    required this.level,
    this.size = 200,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F38) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: CustomPaint(
        painter: _MiniBoardPainter(level: level, isDark: isDark),
      ),
    );
  }
}

class _MiniBoardPainter extends CustomPainter {
  final Level level;
  final bool isDark;

  _MiniBoardPainter({required this.level, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (level.cols < 2 || level.rows < 2) return;

    final u = (size.width / (level.cols - 1)).clamp(
      0.0,
      size.height / (level.rows - 1),
    );
    final boardW = (level.cols - 1) * u;
    final boardH = (level.rows - 1) * u;
    final origin = Offset(
      (size.width - boardW) / 2,
      (size.height - boardH) / 2,
    );

    final strokeWidth = (u * 0.16).clamp(1.5, 3.5);
    final headSize = (u * 0.5).clamp(3.5, 7.0);

    final color = isDark ? T.darkInk : T.ink;

    final bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final headPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final arrow in level.arrows) {
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
    }
  }

  @override
  bool shouldRepaint(covariant _MiniBoardPainter oldDelegate) =>
      oldDelegate.level != level;
}

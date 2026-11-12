import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../game/models/arrow_piece.dart';
import '../../../../game/models/level.dart';

class TutorialOverlay extends StatefulWidget {
  final Level level;
  final ArrowPiece targetArrow;
  final VoidCallback onDismiss;

  const TutorialOverlay({
    super.key,
    required this.level,
    required this.targetArrow,
    required this.onDismiss,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = widget.level.cols;
        final rows = widget.level.rows;
        const padding = 24.0;
        final availW = math.max(0.0, constraints.maxWidth - padding * 2);
        final availH = math.max(0.0, constraints.maxHeight - padding * 2);
        final u = math.min(availW / (cols - 1), availH / (rows - 1));

        final boardW = (cols - 1) * u;
        final boardH = (rows - 1) * u;
        final origin = Offset(
          (constraints.maxWidth - boardW) / 2,
          (constraints.maxHeight - boardH) / 2,
        );

        // Target arrow position: center node or head
        final midNode =
            widget.targetArrow.nodes[widget.targetArrow.nodes.length ~/ 2];
        final targetX = origin.dx + (midNode % cols) * u;
        final targetY = origin.dy + (midNode ~/ cols) * u;

        return Stack(
          children: [
            // Instruction caption at top
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: T.accent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Tap an arrow to slide it out',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // Animated Hand Pointer with ripple
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final ripple = _controller.value;
                return Positioned(
                  left: targetX - 40,
                  top: targetY - 40,
                  child: IgnorePointer(
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Ripple circle
                          Transform.scale(
                            scale: 0.5 + ripple * 1.2,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: T.accent.withValues(
                                    alpha: 1.0 - ripple,
                                  ),
                                  width: 3.0,
                                ),
                              ),
                            ),
                          ),
                          // Hand pointer icon
                          Transform.translate(
                            offset: Offset(
                              16 + math.sin(ripple * math.pi * 2) * 4,
                              20 + math.cos(ripple * math.pi * 2) * 4,
                            ),
                            child: const Icon(
                              Icons.touch_app_rounded,
                              size: 46,
                              color: T.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

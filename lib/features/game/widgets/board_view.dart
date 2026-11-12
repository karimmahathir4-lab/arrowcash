import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../game/controller/game_controller.dart';
import '../../../../game/controller/game_state.dart';
import '../../../../game/render/board_painter.dart';
import '../../../../game/render/hit_tester.dart';

class BoardView extends StatefulWidget {
  final GameState state;
  final GameController controller;
  final bool isDark;
  final TransformationController? transformController;

  const BoardView({
    super.key,
    required this.state,
    required this.controller,
    this.isDark = false,
    this.transformController,
  });

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView>
    with SingleTickerProviderStateMixin {
  late final TransformationController _internalTransformController;
  late final AnimationController _tickerController;
  bool _showZoomHint = true;

  TransformationController get _tc =>
      widget.transformController ?? _internalTransformController;

  @override
  void initState() {
    super.initState();
    _internalTransformController = TransformationController();
    // Continuous 60fps ticker controller for ultra-smooth animations (snake, glow, dot scales)
    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() => _showZoomHint = false);
      }
    });
  }

  @override
  void dispose() {
    _tickerController.dispose();
    _internalTransformController.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    _tc.value = Matrix4.identity();
  }

  void _onTapUp(TapUpDetails details, Size canvasSize) {
    if (widget.state.status != GameStatus.playing) return;

    final cols = widget.state.level.cols;
    final rows = widget.state.level.rows;
    if (cols < 2 || rows < 2) return;

    const padding = 24.0;
    final availW = math.max(0.0, canvasSize.width - padding * 2);
    final availH = math.max(0.0, canvasSize.height - padding * 2);
    final u = math.min(availW / (cols - 1), availH / (rows - 1));

    final boardW = (cols - 1) * u;
    final boardH = (rows - 1) * u;
    final origin = Offset(
      (canvasSize.width - boardW) / 2,
      (canvasSize.height - boardH) / 2,
    );

    final inverseMatrix = Matrix4.inverted(_tc.value);
    final localBoardPoint = MatrixUtils.transformPoint(
      inverseMatrix,
      details.localPosition,
    );

    final scale = _tc.value.getMaxScaleOnAxis();

    final hitId = HitTester.testHit(
      tapBoardPos: localBoardPoint,
      level: widget.state.level,
      aliveArrowIds: widget.state.aliveIds,
      animatingArrowIds: widget.state.animatingArrows.keys.toSet(),
      u: u,
      origin: origin,
      currentScale: scale,
    );

    if (hitId != null) {
      widget.controller.handleArrowTap(hitId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          children: [
            GestureDetector(
              onDoubleTap: _onDoubleTap,
              onTapUp: (details) => _onTapUp(details, canvasSize),
              child: InteractiveViewer(
                transformationController: _tc,
                minScale: 1.0,
                maxScale: 5.0,
                constrained: true,
                boundaryMargin: const EdgeInsets.all(40),
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: AnimatedBuilder(
                    animation: _tickerController,
                    builder: (context, _) {
                      return CustomPaint(
                        size: canvasSize,
                        painter: BoardPainter(
                          level: widget.state.level,
                          aliveIds: widget.state.aliveIds,
                          clearedNodes: widget.state.clearedNodes,
                          ghostDotFades: widget.state.ghostDotFades,
                          animatingArrows: widget.state.animatingArrows,
                          wrongArrowIds: widget.state.wrongArrowIds,
                          hintedArrowId: widget.state.hintedArrowId,
                          selectedArrowId: widget.state.selectedArrowId,
                          blockedFlashArrowId: widget.state.blockedFlashArrowId,
                          blockedHighlightArrowId:
                              widget.state.blockedHighlightArrowId,
                          flashProgress: widget.state.flashProgress,
                          gridAssist: widget.state.gridAssist,
                          pulseValue: _tickerController.value,
                          isDark: widget.isDark,
                          arrowStyle: widget.state.arrowStyle,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            if (_showZoomHint)
              Positioned(
                top: 14,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _showZoomHint ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pinch_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Pinch to zoom in / out • Double-tap to reset',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

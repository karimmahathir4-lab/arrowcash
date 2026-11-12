import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../../core/audio_service.dart';
import '../../core/haptics.dart';
import '../../core/theme/tokens.dart';
import '../engine/board_state.dart';
import '../engine/hint_engine.dart';
import '../models/arrow_piece.dart';
import '../models/level.dart';
import '../render/board_painter.dart';
import 'game_state.dart';

class GameController extends ChangeNotifier {
  final BoardState _boardState;
  final bool safeTapEnabled;
  final bool reduceMotion;
  Timer? _flashTimer;
  GameState _state;
  bool _disposed = false;

  GameController({
    required Level level,
    bool gridAssistDefault = false,
    this.safeTapEnabled = false,
    this.reduceMotion = false,
    bool isDaily = false,
    String? dailyDate,
    ArrowThemeStyle arrowStyle = ArrowThemeStyle.classic,
  }) : _boardState = BoardState(level),
       _state = GameState.initial(
         level,
         gridAssist: gridAssistDefault,
         isDaily: isDaily,
         dailyDate: dailyDate,
         arrowStyle: arrowStyle,
       );

  GameState get state => _state;
  BoardState get boardState => _boardState;

  void _setState(GameState newState) {
    if (_disposed) return;
    _state = newState;
    notifyListeners();
  }

  void setArrowStyle(ArrowThemeStyle style) {
    _setState(_state.copyWith(arrowStyle: style));
  }

  void toggleGridAssist() {
    _setState(_state.copyWith(gridAssist: !_state.gridAssist));
    Haptics.selection();
    AudioService.instance.play(Sfx.click);
  }

  void handleArrowTap(int arrowId) {
    if (_state.status != GameStatus.playing) return;

    final arrow = _state.level.arrows.firstWhere((a) => a.id == arrowId);
    if (!_state.aliveIds.contains(arrow.id)) return;
    if (_state.animatingArrows.containsKey(arrow.id)) return;

    if (safeTapEnabled) {
      if (_state.selectedArrowId != arrowId) {
        _setState(_state.copyWith(selectedArrowId: arrowId));
        Haptics.selection();
        AudioService.instance.play(Sfx.tap);
        return;
      }
      _setState(_state.copyWith(clearSelected: true));
    }

    final blockerId = _boardState.blockerOf(arrow);

    if (blockerId == null) {
      // 1. FREE ARROW ESCAPES
      _boardState.remove(arrow);

      final newAlive = Set<int>.from(_state.aliveIds)..remove(arrow.id);
      final newRemaining = _state.remainingCount - 1;
      final clearHint = (_state.hintedArrowId == arrow.id);

      // Start snake animation in vibrant GREEN
      final anim = AnimatingArrow(
        arrow: arrow,
        progress: 0.0,
        totalDistance: 100.0,
        color: T.success,
      );
      final newAnim = Map<int, AnimatingArrow>.from(_state.animatingArrows);
      newAnim[arrow.id] = anim;

      // Remove from wrong arrows if this was marked wrong
      final updatedWrong = Set<int>.from(_state.wrongArrowIds)
        ..remove(arrow.id);

      AudioService.instance.play(Sfx.slide);
      Haptics.selection();

      _setState(
        _state.copyWith(
          aliveIds: newAlive,
          remainingCount: newRemaining,
          animatingArrows: newAnim,
          wrongArrowIds: updatedWrong,
          clearHint: clearHint,
        ),
      );

      _runEscapeAnimation(arrow);

      if (newRemaining == 0) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!_disposed) {
            _setState(_state.copyWith(status: GameStatus.won));
            AudioService.instance.play(Sfx.win);
            Haptics.medium();
          }
        });
      }
    } else {
      // Blocked arrow tapped: record mistake and decrement life
      final newLives = _state.lives - 1;
      final newWrong = Set<int>.from(_state.wrongArrowIds)..add(arrow.id);

      AudioService.instance.play(Sfx.error);
      Haptics.heavy();

      _flashTimer?.cancel();
      _setState(
        _state.copyWith(
          lives: newLives,
          wrongArrowIds: newWrong,
          blockedFlashArrowId: arrow.id,
          blockedHighlightArrowId: blockerId,
          flashProgress: 1.0,
        ),
      );

      const steps = 15;
      const stepDuration = Duration(milliseconds: 30);
      int currentStep = 0;

      _flashTimer = Timer.periodic(stepDuration, (timer) {
        currentStep++;
        if (_disposed) {
          timer.cancel();
          return;
        }
        if (currentStep >= steps) {
          timer.cancel();
          _setState(
            _state.copyWith(
              clearFlash: true,
              clearHighlight: true,
              flashProgress: 0.0,
            ),
          );
        } else {
          _setState(
            _state.copyWith(flashProgress: 1.0 - (currentStep / steps)),
          );
        }
      });

      if (newLives <= 0) {
        _setState(_state.copyWith(status: GameStatus.failed));
      }
    }
  }

  void _runEscapeAnimation(ArrowPiece arrow) {
    final distanceInNodes = arrow.nodes.length + 5;
    final durationMs = reduceMotion
        ? 150
        : (180 + distanceInNodes * 18).clamp(250, 700);

    const int fps = 60;
    final int totalFrames = (durationMs / (1000 / fps)).round().clamp(10, 60);
    int frame = 0;

    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      frame++;
      if (_disposed) {
        timer.cancel();
        return;
      }

      final progress = (frame / totalFrames).clamp(0.0, 1.0);
      final currentAnim = Map<int, AnimatingArrow>.from(_state.animatingArrows);

      if (progress >= 1.0) {
        timer.cancel();
        currentAnim.remove(arrow.id);
        final newCleared = Set<int>.from(_state.clearedNodes)
          ..addAll(arrow.nodes);

        _setState(
          _state.copyWith(
            animatingArrows: currentAnim,
            clearedNodes: newCleared,
          ),
        );

        // Start smooth fade-in animation for newly freed ghost dots
        _animateGhostDotsFade(arrow.nodes);

        // Auto-release any blocked arrow whose ray has now been cleared
        _checkAndAutoReleaseUnblockedRedArrows();
      } else {
        currentAnim[arrow.id] = AnimatingArrow(
          arrow: arrow,
          progress: progress,
          totalDistance: 100.0,
          color: T.success,
        );
        _setState(_state.copyWith(animatingArrows: currentAnim));
      }
    });
  }

  void _checkAndAutoReleaseUnblockedRedArrows() {
    if (_state.status != GameStatus.playing) return;

    // Look for any arrow currently in wrongArrowIds that can now escape
    for (final wrongId in _state.wrongArrowIds) {
      if (!_state.aliveIds.contains(wrongId)) continue;
      if (_state.animatingArrows.containsKey(wrongId)) continue;

      final arrow = _state.level.arrows.firstWhere((a) => a.id == wrongId);
      if (_boardState.canEscape(arrow)) {
        // Automatically release this arrow like it was clicked!
        handleArrowTap(wrongId);
        break; // Releasing triggers another animation cycle which will cascade if needed
      }
    }
  }

  void _animateGhostDotsFade(List<int> nodes) {
    const fadeSteps = 20;
    int step = 0;
    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      step++;
      if (_disposed) {
        timer.cancel();
        return;
      }
      // Smooth ease-out cubic curve: 1 - (1 - t)^3
      final rawT = (step / fadeSteps).clamp(0.0, 1.0);
      final t = 1.0 - math.pow(1.0 - rawT, 3);

      final fades = Map<int, double>.from(_state.ghostDotFades);
      for (final n in nodes) {
        fades[n] = t;
      }
      _setState(_state.copyWith(ghostDotFades: fades));
      if (step >= fadeSteps) {
        timer.cancel();
      }
    });
  }

  bool triggerHint() {
    if (_state.hintedArrowId != null) {
      return true;
    }
    final hint = HintEngine.chooseHint(_boardState);
    if (hint != null) {
      _setState(_state.copyWith(hintedArrowId: hint.id));
      AudioService.instance.play(Sfx.hint);
      Haptics.light();
      return true;
    }
    return false;
  }

  void addLife() {
    _setState(
      _state.copyWith(lives: _state.lives + 1, status: GameStatus.playing),
    );
  }

  void restartLevel() {
    _flashTimer?.cancel();
    final freshBoard = BoardState(_state.level);
    _boardState.alive.clear();
    _boardState.alive.addAll(freshBoard.alive);
    _boardState.clearedNodes.clear();
    for (int i = 0; i < freshBoard.occ.length; i++) {
      _boardState.occ[i] = freshBoard.occ[i];
    }

    _setState(
      GameState.initial(
        _state.level,
        gridAssist: _state.gridAssist,
        isDaily: _state.isDaily,
        dailyDate: _state.dailyDate,
        arrowStyle: _state.arrowStyle,
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _flashTimer?.cancel();
    super.dispose();
  }
}

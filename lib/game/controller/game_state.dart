import '../../core/theme/tokens.dart';
import '../models/level.dart';
import '../render/board_painter.dart';

enum GameStatus { playing, won, failed }

class GameState {
  final Level level;
  final Set<int> aliveIds;
  final Set<int> clearedNodes;
  final Map<int, double> ghostDotFades; // Smooth dot opacity per freed node
  final Map<int, AnimatingArrow> animatingArrows;
  final Set<int> wrongArrowIds; // Persistent wrong arrows kept highlighted red
  final int lives;
  final int remainingCount;
  final GameStatus status;
  final int? hintedArrowId;
  final int? selectedArrowId;
  final int? blockedFlashArrowId;
  final int? blockedHighlightArrowId;
  final double flashProgress;
  final bool gridAssist;
  final bool isDaily;
  final String? dailyDate;
  final ArrowThemeStyle arrowStyle;

  const GameState({
    required this.level,
    required this.aliveIds,
    required this.clearedNodes,
    this.ghostDotFades = const {},
    required this.animatingArrows,
    this.wrongArrowIds = const {},
    required this.lives,
    required this.remainingCount,
    required this.status,
    this.hintedArrowId,
    this.selectedArrowId,
    this.blockedFlashArrowId,
    this.blockedHighlightArrowId,
    this.flashProgress = 0.0,
    this.gridAssist = false,
    this.isDaily = false,
    this.dailyDate,
    this.arrowStyle = ArrowThemeStyle.classic,
  });

  factory GameState.initial(
    Level level, {
    bool gridAssist = false,
    bool isDaily = false,
    String? dailyDate,
    ArrowThemeStyle arrowStyle = ArrowThemeStyle.classic,
  }) {
    return GameState(
      level: level,
      aliveIds: level.arrows.map((a) => a.id).toSet(),
      clearedNodes: {},
      ghostDotFades: {},
      animatingArrows: {},
      wrongArrowIds: {},
      lives: 3,
      remainingCount: level.arrows.length,
      status: GameStatus.playing,
      gridAssist: gridAssist,
      isDaily: isDaily,
      dailyDate: dailyDate,
      arrowStyle: arrowStyle,
    );
  }

  GameState copyWith({
    Level? level,
    Set<int>? aliveIds,
    Set<int>? clearedNodes,
    Map<int, double>? ghostDotFades,
    Map<int, AnimatingArrow>? animatingArrows,
    Set<int>? wrongArrowIds,
    int? lives,
    int? remainingCount,
    GameStatus? status,
    int? hintedArrowId,
    bool clearHint = false,
    int? selectedArrowId,
    bool clearSelected = false,
    int? blockedFlashArrowId,
    bool clearFlash = false,
    int? blockedHighlightArrowId,
    bool clearHighlight = false,
    double? flashProgress,
    bool? gridAssist,
    bool? isDaily,
    String? dailyDate,
    ArrowThemeStyle? arrowStyle,
  }) {
    return GameState(
      level: level ?? this.level,
      aliveIds: aliveIds ?? this.aliveIds,
      clearedNodes: clearedNodes ?? this.clearedNodes,
      ghostDotFades: ghostDotFades ?? this.ghostDotFades,
      animatingArrows: animatingArrows ?? this.animatingArrows,
      wrongArrowIds: wrongArrowIds ?? this.wrongArrowIds,
      lives: lives ?? this.lives,
      remainingCount: remainingCount ?? this.remainingCount,
      status: status ?? this.status,
      hintedArrowId: clearHint ? null : (hintedArrowId ?? this.hintedArrowId),
      selectedArrowId: clearSelected
          ? null
          : (selectedArrowId ?? this.selectedArrowId),
      blockedFlashArrowId: clearFlash
          ? null
          : (blockedFlashArrowId ?? this.blockedFlashArrowId),
      blockedHighlightArrowId: clearHighlight
          ? null
          : (blockedHighlightArrowId ?? this.blockedHighlightArrowId),
      flashProgress: flashProgress ?? this.flashProgress,
      gridAssist: gridAssist ?? this.gridAssist,
      isDaily: isDaily ?? this.isDaily,
      dailyDate: dailyDate ?? this.dailyDate,
      arrowStyle: arrowStyle ?? this.arrowStyle,
    );
  }
}

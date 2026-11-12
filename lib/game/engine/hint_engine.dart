import '../models/arrow_piece.dart';
import 'board_state.dart';

class HintEngine {
  /// Chooses the optimal hint arrow from the current board state.
  /// Prefers the free arrow that unblocks the highest number of other alive arrows.
  /// Tie-breaks deterministically using arrow id.
  static ArrowPiece? chooseHint(BoardState s) {
    final free = s.level.arrows
        .where((a) => s.alive.contains(a.id) && s.canEscape(a))
        .toList();
    if (free.isEmpty) return null;

    // Map each alive arrow to its first blocker
    final blockerMap = <int, int>{}; // arrowId -> blockerId
    for (final a in s.level.arrows) {
      if (!s.alive.contains(a.id)) continue;
      final blocker = s.blockerOf(a);
      if (blocker != null) {
        blockerMap[a.id] = blocker;
      }
    }

    ArrowPiece bestArrow = free.first;
    int maxUnblocked = -1;

    for (final candidate in free) {
      // How many alive arrows have candidate.id as their first blocker?
      int score = 0;
      for (final entry in blockerMap.entries) {
        if (entry.value == candidate.id) {
          score++;
        }
      }
      if (score > maxUnblocked) {
        maxUnblocked = score;
        bestArrow = candidate;
      }
    }

    return bestArrow;
  }
}

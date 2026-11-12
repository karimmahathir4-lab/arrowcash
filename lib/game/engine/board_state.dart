import '../models/arrow_piece.dart';
import '../models/level.dart';

class BoardState {
  final Level level;
  final List<int> occ; // arrowId per node or -1
  final Set<int> alive = {}; // alive arrow ids
  final Set<int> clearedNodes = {}; // nodes freed so far (drawn as ghost dots)

  BoardState(this.level) : occ = List.filled(level.cols * level.rows, -1) {
    for (final a in level.arrows) {
      for (final n in a.nodes) {
        occ[n] = a.id;
      }
      alive.add(a.id);
    }
  }

  /// id of the first arrow blocking [a], or null if free.
  int? blockerOf(ArrowPiece a) {
    for (final n in a.ray(level.cols, level.rows)) {
      final occId = occ[n];
      if (occId != -1) {
        return occId;
      }
    }
    return null;
  }

  bool canEscape(ArrowPiece a) => blockerOf(a) == null;

  void remove(ArrowPiece a) {
    for (final n in a.nodes) {
      occ[n] = -1;
      clearedNodes.add(n);
    }
    alive.remove(a.id);
  }
}

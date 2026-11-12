import '../models/level.dart';
import 'board_state.dart';

class SolveStats {
  final bool solvable;
  final int depth;
  const SolveStats(this.solvable, this.depth);
}

SolveStats analyze(Level l) {
  final s = BoardState(l);
  var rounds = 0;
  while (s.alive.isNotEmpty) {
    final free = l.arrows
        .where((a) => s.alive.contains(a.id) && s.canEscape(a))
        .toList();
    if (free.isEmpty) {
      return SolveStats(false, rounds);
    }
    for (final a in free) {
      s.remove(a); // remove a whole "layer" at once
    }
    rounds++;
  }
  return SolveStats(
    true,
    rounds,
  ); // depth = length of the longest dependency chain
}

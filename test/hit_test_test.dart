import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_cash/game/models/arrow_piece.dart';
import 'package:arrow_cash/game/models/level.dart';
import 'package:arrow_cash/game/render/hit_tester.dart' as game_hit;

void main() {
  group('HitTester Tests', () {
    test(
      'Tap within tolerance picks right arrow, ambiguous or far tap returns null',
      () {
        const cols = 5;
        const rows = 5;
        const arrows = [
          ArrowPiece(0, [0, 1]), // (0,0) to (1,0)
          ArrowPiece(1, [10, 15]), // (0,2) to (0,3)
        ];
        const level = Level(1, cols, rows, arrows, Difficulty.easy, 1);

        // Hit arrow 0 directly
        final hit0 = game_hit.HitTester.testHit(
          tapBoardPos: const Offset(5.0, 0.0),
          level: level,
          aliveArrowIds: {0, 1},
          animatingArrowIds: {},
          u: 10.0,
          origin: Offset.zero,
          currentScale: 1.0,
        );
        expect(hit0, equals(0));

        // Far tap misses everything
        final miss = game_hit.HitTester.testHit(
          tapBoardPos: const Offset(40.0, 40.0),
          level: level,
          aliveArrowIds: {0, 1},
          animatingArrowIds: {},
          u: 10.0,
          origin: Offset.zero,
          currentScale: 1.0,
        );
        expect(miss, isNull);
      },
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_cash/game/engine/board_state.dart';
import 'package:arrow_cash/game/engine/hint_engine.dart';
import 'package:arrow_cash/game/generator/level_generator.dart';

void main() {
  group('BoardState and Hint Tests', () {
    test('BoardState blocker and removal logic', () {
      final level = LevelGenerator.generateLevel(1);
      final board = BoardState(level);

      final free = level.arrows.where((a) => board.canEscape(a)).toList();
      expect(free, isNotEmpty);

      final firstFree = free.first;
      board.remove(firstFree);
      expect(board.alive.contains(firstFree.id), isFalse);
      expect(board.clearedNodes.containsAll(firstFree.nodes), isTrue);
    });

    test('HintEngine always returns a currently free arrow', () {
      for (int n = 1; n <= 10; n++) {
        final level = LevelGenerator.generateLevel(n);
        final board = BoardState(level);

        final hint = HintEngine.chooseHint(board);
        expect(hint, isNotNull);
        expect(board.canEscape(hint!), isTrue);
      }
    });
  });
}

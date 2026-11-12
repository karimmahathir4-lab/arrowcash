import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_cash/game/engine/solver.dart';
import 'package:arrow_cash/game/generator/level_generator.dart';

void main() {
  group('Generator and Solver Tests (Spec Section 16)', () {
    test(
      'generateLevel returns deterministic identical results for repeated calls',
      () {
        for (int n in [1, 2, 5, 10, 23, 42]) {
          final l1 = LevelGenerator.generateLevel(n);
          final l2 = LevelGenerator.generateLevel(n);
          expect(l1.arrows.length, equals(l2.arrows.length));
          expect(l1.cols, equals(l2.cols));
          expect(l1.rows, equals(l2.rows));
          for (int i = 0; i < l1.arrows.length; i++) {
            expect(l1.arrows[i].nodes, equals(l2.arrows[i].nodes));
          }
        }
      },
    );

    test('Levels are always solvable, valid nodes, and no overlap', () {
      // Test first 50 levels
      for (int n = 1; n <= 50; n++) {
        final level = LevelGenerator.generateLevel(n);
        final stats = analyze(level);
        expect(stats.solvable, isTrue, reason: 'Level $n should be solvable');

        final occupied = <int>{};
        for (final a in level.arrows) {
          expect(a.nodes.length, greaterThanOrEqualTo(2));
          // Body does not cross exit ray
          final bodySet = a.nodes.toSet();
          for (final rayNode in a.ray(level.cols, level.rows)) {
            expect(
              bodySet.contains(rayNode),
              isFalse,
              reason:
                  'Arrow ${a.id} on Level $n must not have ray crossing body',
            );
          }
          // No node belongs to two arrows
          for (final node in a.nodes) {
            expect(
              occupied.contains(node),
              isFalse,
              reason: 'Node $node shared by multiple arrows in Level $n',
            );
            occupied.add(node);
          }
        }
      }
    });
  });
}

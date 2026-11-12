import 'dart:isolate';
import '../../core/rng.dart';
import '../engine/solver.dart';
import '../models/arrow_piece.dart';
import '../models/dir.dart';
import '../models/level.dart';
import '../models/level_params.dart';
import 'shape_mask.dart';

class LevelGenerator {
  /// Entry point to generate a level deterministically by level number.
  /// Falls back to sync generation if Isolate is unsupported or timed out.
  static Future<Level> generateAsync(int levelNumber) async {
    try {
      return await Isolate.run(() => generateLevel(levelNumber)).timeout(
        const Duration(milliseconds: 1200),
        onTimeout: () {
          return generateLevel(levelNumber);
        },
      );
    } catch (_) {
      // In web or environments where Isolate.run fails/hangs, run synchronously
      return generateLevel(levelNumber);
    }
  }

  /// Synchronous deterministic level generator
  static Level generateLevel(int n) {
    final p = LevelParams.forLevel(n);
    Level? bestLevel;
    int maxArrowCount = -1;

    for (int attempt = 0; attempt < 20; attempt++) {
      final rng = Rng(hashSeed(n, attempt));
      final mask = ShapeMask.create(p.shape, p.cols, p.rows, rng);
      final occ = List<int>.filled(p.cols * p.rows, -1);
      final rayCount = List<int>.filled(p.cols * p.rows, 0);
      final arrows = <ArrowPiece>[];
      final deadStarts = <int>{};
      int failStreak = 0;

      while (failStreak < p.maxFailStreak && arrows.length < p.maxArrows) {
        final start = _pickStart(mask, occ, rayCount, deadStarts, rng, p);
        if (start == null) break;

        List<int>? placed;
        for (int retry = 0; retry < p.growRetries; retry++) {
          final path = _growPath(start, mask, occ, rng, p);
          if (path == null) continue;

          final candidates = [path, path.reversed.toList()];
          for (final candidate in rng.shuffled(candidates)) {
            if (_rayIsFree(candidate, occ, p.cols, p.rows)) {
              placed = candidate;
              break;
            }
          }
          if (placed != null) break;
        }

        if (placed == null) {
          deadStarts.add(start);
          failStreak++;
          continue;
        }

        // Commit arrow
        final arrowId = arrows.length;
        for (final node in placed) {
          occ[node] = arrowId;
        }
        final arrowPiece = ArrowPiece(arrowId, placed);
        for (final r in arrowPiece.ray(p.cols, p.rows)) {
          rayCount[r]++;
        }
        arrows.add(arrowPiece);
        failStreak = 0;
      }

      // Try absorbing leftover holes
      _absorbLeftovers(arrows, mask, occ, p.cols, p.rows);

      // Shuffle arrow IDs so id does not reveal reverse construction order
      final shuffledArrows = _shuffleArrowIds(arrows, rng);
      final level = Level(
        n,
        p.cols,
        p.rows,
        shuffledArrows,
        LevelParams.difficultyFor(n),
        hashSeed(n, attempt),
      );

      final stats = analyze(level);
      if (stats.solvable &&
          arrows.length >= p.minArrows &&
          stats.depth >= p.minDepth) {
        return level;
      }

      if (stats.solvable && arrows.length > maxArrowCount) {
        maxArrowCount = arrows.length;
        bestLevel = level;
      }
    }

    if (bestLevel != null) {
      return bestLevel;
    }

    // Final fallback: a guaranteed solvable fallback level
    return _createFallbackLevel(n, p);
  }

  static int? _pickStart(
    List<bool> mask,
    List<int> occ,
    List<int> rayCount,
    Set<int> deadStarts,
    Rng rng,
    LevelParams p,
  ) {
    final candidates = <int>[];
    final weights = <double>[];

    for (int i = 0; i < mask.length; i++) {
      if (mask[i] && occ[i] == -1 && !deadStarts.contains(i)) {
        candidates.add(i);
        // Weight toward nodes where rayCount > 0
        final weight =
            1.0 + (rayCount[i] > 0 ? rayCount[i] * p.crossingBias : 0.0);
        weights.add(weight);
      }
    }

    if (candidates.isEmpty) return null;

    // Weighted random selection
    double totalWeight = 0.0;
    for (final w in weights) {
      totalWeight += w;
    }
    double target = rng.nextDouble() * totalWeight;
    for (int i = 0; i < candidates.length; i++) {
      target -= weights[i];
      if (target <= 0) return candidates[i];
    }
    return candidates.last;
  }

  static List<int>? _growPath(
    int start,
    List<bool> mask,
    List<int> occ,
    Rng rng,
    LevelParams p,
  ) {
    final path = <int>[start];
    final visited = <int>{start};
    final targetLen = p.minLen + rng.nextInt(p.maxLen - p.minLen + 1);

    int current = start;
    Dir? lastDir;

    while (path.length < targetLen) {
      final cx = current % p.cols;
      final cy = current ~/ p.cols;

      // Find valid orthogonal unvisited neighbors inside mask and free
      final neighbors = <MapEntry<Dir, int>>[];
      for (final d in Dir.values) {
        final nx = cx + d.dx;
        final ny = cy + d.dy;
        if (nx >= 0 && nx < p.cols && ny >= 0 && ny < p.rows) {
          final nIdx = ny * p.cols + nx;
          if (mask[nIdx] && occ[nIdx] == -1 && !visited.contains(nIdx)) {
            neighbors.add(MapEntry(d, nIdx));
          }
        }
      }

      if (neighbors.isEmpty) break;

      // Decide next step direction based on turnProb
      MapEntry<Dir, int> chosen;
      final straight = neighbors.where((e) => e.key == lastDir).toList();
      if (lastDir != null && straight.isNotEmpty && !rng.chance(p.turnProb)) {
        chosen = straight.first;
      } else {
        chosen = rng.pick(neighbors);
      }

      current = chosen.value;
      lastDir = chosen.key;
      path.add(current);
      visited.add(current);
    }

    return path.length >= 2 ? path : null;
  }

  static bool _rayIsFree(
    List<int> candidate,
    List<int> occ,
    int cols,
    int rows,
  ) {
    final head = candidate.last;
    final prev = candidate[candidate.length - 2];
    final hx = head % cols;
    final hy = head ~/ cols;
    final px = prev % cols;
    final py = prev ~/ cols;
    final d = dirBetween(px, py, hx, hy);

    final candidateSet = candidate.toSet();

    var rx = hx + d.dx;
    var ry = hy + d.dy;
    while (rx >= 0 && rx < cols && ry >= 0 && ry < rows) {
      final rIdx = ry * cols + rx;
      // Ray node must be free AND not intersect arrow's own body
      if (occ[rIdx] != -1 || candidateSet.contains(rIdx)) {
        return false;
      }
      rx += d.dx;
      ry += d.dy;
    }
    return true;
  }

  static void _absorbLeftovers(
    List<ArrowPiece> arrows,
    List<bool> mask,
    List<int> occ,
    int cols,
    int rows,
  ) {
    if (arrows.length > 80) return; // Skip on large boards for speed

    for (int i = 0; i < arrows.length; i++) {
      final arrow = arrows[i];
      final tail = arrow.tail;
      final tx = tail % cols;
      final ty = tail ~/ cols;

      for (final d in Dir.values) {
        final nx = tx + d.dx;
        final ny = ty + d.dy;
        if (nx >= 0 && nx < cols && ny >= 0 && ny < rows) {
          final nIdx = ny * cols + nx;
          if (mask[nIdx] && occ[nIdx] == -1) {
            // Check if extending tail keeps level solvable
            final newNodes = [nIdx, ...arrow.nodes];
            occ[nIdx] = arrow.id;
            final newArrow = ArrowPiece(arrow.id, newNodes);
            arrows[i] = newArrow;

            final testLevel = Level(
              0,
              cols,
              rows,
              arrows,
              Difficulty.normal,
              0,
            );
            if (analyze(testLevel).solvable) {
              // Successfully absorbed!
              break;
            } else {
              // Rollback
              occ[nIdx] = -1;
              arrows[i] = arrow;
            }
          }
        }
      }
    }
  }

  static List<ArrowPiece> _shuffleArrowIds(List<ArrowPiece> arrows, Rng rng) {
    final shuffledIndices = rng.shuffled(
      List.generate(arrows.length, (i) => i),
    );
    final newArrows = <ArrowPiece>[];
    for (int i = 0; i < arrows.length; i++) {
      final orig = arrows[shuffledIndices[i]];
      newArrows.add(ArrowPiece(i, orig.nodes));
    }
    return newArrows;
  }

  static Level _createFallbackLevel(int n, LevelParams p) {
    // Guaranteed solvable 4-arrow level
    // 0 -> (1,1)-(1,2) down
    // 1 -> (2,1)-(3,1) right
    // 2 -> (3,2)-(3,3) down
    // 3 -> (2,3)-(1,3) left
    const cols = 5;
    const rows = 5;
    final arrows = [
      const ArrowPiece(0, [1 * cols + 1, 2 * cols + 1]), // down at col 1
      const ArrowPiece(1, [1 * cols + 2, 1 * cols + 3]), // right at row 1
      const ArrowPiece(2, [2 * cols + 3, 3 * cols + 3]), // down at col 3
      const ArrowPiece(3, [3 * cols + 2, 3 * cols + 1]), // left at row 3
    ];
    return Level(n, cols, rows, arrows, Difficulty.easy, n);
  }
}

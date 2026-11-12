import 'arrow_piece.dart';

enum Difficulty { easy, normal, hard }

class Level {
  final int
  number; // 1, 2, 3 ... unbounded. For daily challenge negative or separate
  final int cols;
  final int rows;
  final List<ArrowPiece> arrows;
  final Difficulty difficulty;
  final int seed;

  const Level(
    this.number,
    this.cols,
    this.rows,
    this.arrows,
    this.difficulty,
    this.seed,
  );
}

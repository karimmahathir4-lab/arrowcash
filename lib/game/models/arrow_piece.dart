import 'dir.dart';

/// Nodes are stored as ints: index = y * cols + x.
class ArrowPiece {
  final int id;
  final List<int> nodes; // tail -> head, length >= 2
  const ArrowPiece(this.id, this.nodes);

  int get head => nodes.last;
  int get tail => nodes.first;

  Dir dir(int cols) {
    assert(nodes.length >= 2);
    final h = nodes[nodes.length - 1];
    final p = nodes[nodes.length - 2];
    return dirBetween(p % cols, p ~/ cols, h % cols, h ~/ cols);
  }

  /// Node indices ahead of the head until the grid edge.
  Iterable<int> ray(int cols, int rows) sync* {
    final d = dir(cols);
    var x = head % cols + d.dx;
    var y = head ~/ cols + d.dy;
    while (x >= 0 && x < cols && y >= 0 && y < rows) {
      yield y * cols + x;
      x += d.dx;
      y += d.dy;
    }
  }

  ArrowPiece copyWith({int? id, List<int>? nodes}) {
    return ArrowPiece(id ?? this.id, nodes ?? this.nodes);
  }
}

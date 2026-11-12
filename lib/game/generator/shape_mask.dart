import 'dart:math' as math;
import '../../core/rng.dart';
import '../models/level_params.dart';

class ShapeMask {
  static List<bool> create(ShapeType shape, int cols, int rows, Rng rng) {
    final mask = List<bool>.filled(cols * rows, false);

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        // Normalized coordinates in [-1, 1]
        final nx = (2.0 * x) / (cols - 1) - 1.0;
        final ny = (2.0 * y) / (rows - 1) - 1.0;

        mask[y * cols + x] = _isInside(shape, nx, ny);
      }
    }

    // Ensure mask is connected; keep largest connected component
    return _keepLargestComponent(mask, cols, rows);
  }

  static bool _isInside(ShapeType shape, double nx, double ny) {
    switch (shape) {
      case ShapeType.rectangle:
        return nx.abs() <= 0.95 && ny.abs() <= 0.95;

      case ShapeType.roundedRect:
        final dx = math.max(0.0, nx.abs() - 0.65);
        final dy = math.max(0.0, ny.abs() - 0.65);
        return (dx * dx + dy * dy) <= (0.28 * 0.28);

      case ShapeType.circle:
        return (nx * nx + ny * ny) <= 0.85;

      case ShapeType.ellipse:
        return ((nx * nx) / 0.85 + (ny * ny) / 0.95) <= 1.0;

      case ShapeType.diamond:
        return (nx.abs() + ny.abs()) <= 1.15;

      case ShapeType.heart:
        // Mathematical heart formula: (x^2 + y^2 - 1)^3 - x^2 * y^3 <= 0
        final x = nx * 1.35;
        final y = -ny * 1.35 + 0.25;
        final term = x * x + y * y - 1.0;
        return (term * term * term - x * x * y * y * y) <= 0.0;

      case ShapeType.star:
        // 5-point star
        final r = math.sqrt(nx * nx + ny * ny);
        if (r > 0.98) return false;
        if (r < 0.22) return true;
        var angle = math.atan2(ny, nx);
        if (angle < 0) angle += 2 * math.pi;
        final sector = (angle / (2 * math.pi / 5)) % 1.0;
        final starRadius = 0.45 + 0.45 * math.cos((sector - 0.5) * math.pi);
        return r <= starRadius;

      case ShapeType.leaf:
        final r = nx * nx + ny * ny;
        final leafConstraint = nx.abs() <= (1.0 - ny.abs()) * 0.85;
        return r <= 0.95 && leafConstraint;

      case ShapeType.blobNoise:
        final angle = math.atan2(ny, nx);
        final r = math.sqrt(nx * nx + ny * ny);
        final radiusLimit =
            0.65 + 0.18 * math.sin(3 * angle) + 0.12 * math.cos(5 * angle);
        return r <= radiusLimit;

      case ShapeType.cross:
        return (nx.abs() <= 0.4 && ny.abs() <= 0.95) ||
            (ny.abs() <= 0.4 && nx.abs() <= 0.95);

      case ShapeType.hexagon:
        return (nx.abs() <= 0.85) &&
            (0.5 * nx.abs() + 0.866 * ny.abs() <= 0.85);

      case ShapeType.butterfly:
        // Organic butterfly wings shape
        final r = math.sqrt(nx * nx + ny * ny);
        final angle = math.atan2(ny, nx);
        final wingR =
            0.5 + 0.4 * math.sin(2 * angle).abs() + 0.1 * math.cos(4 * angle);
        return r <= wingR && nx.abs() <= 0.95 && ny.abs() <= 0.92;

      case ShapeType.crescentMoon:
        // Main circle minus overlapping offset circle
        final r1 = (nx + 0.15) * (nx + 0.15) + ny * ny;
        final r2 = (nx + 0.55) * (nx + 0.55) + (ny - 0.1) * (ny - 0.1);
        return r1 <= 0.85 && r2 >= 0.50;

      case ShapeType.shield:
        // Classic heraldic crest / shield
        if (ny < 0) {
          return nx.abs() <= 0.85 && ny >= -0.92;
        } else {
          final curve = 0.85 * (1.0 - (ny * ny) * 1.05);
          return nx.abs() <= math.max(0.0, curve) && ny <= 0.95;
        }

      case ShapeType.clover:
        // Four-leaf lucky clover
        final r = math.sqrt(nx * nx + ny * ny);
        final angle = math.atan2(ny, nx);
        final cloverR = 0.55 + 0.35 * math.cos(4 * angle).abs();
        return r <= cloverR;
    }
  }

  static List<bool> _keepLargestComponent(List<bool> mask, int cols, int rows) {
    final visited = List<bool>.filled(cols * rows, false);
    List<int> largestComponent = [];

    for (int i = 0; i < mask.length; i++) {
      if (!mask[i] || visited[i]) continue;

      final component = <int>[];
      final queue = <int>[i];
      visited[i] = true;

      while (queue.isNotEmpty) {
        final curr = queue.removeLast();
        component.add(curr);
        final cx = curr % cols;
        final cy = curr ~/ cols;

        const dirs = [
          [1, 0],
          [-1, 0],
          [0, 1],
          [0, -1],
        ];
        for (final d in dirs) {
          final nx = cx + d[0];
          final ny = cy + d[1];
          if (nx >= 0 && nx < cols && ny >= 0 && ny < rows) {
            final nIdx = ny * cols + nx;
            if (mask[nIdx] && !visited[nIdx]) {
              visited[nIdx] = true;
              queue.add(nIdx);
            }
          }
        }
      }

      if (component.length > largestComponent.length) {
        largestComponent = component;
      }
    }

    final filtered = List<bool>.filled(cols * rows, false);
    for (final idx in largestComponent) {
      filtered[idx] = true;
    }
    return filtered;
  }
}

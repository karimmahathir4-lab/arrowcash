enum Dir { up, right, down, left }

extension DirX on Dir {
  int get dx => const [0, 1, 0, -1][index];
  int get dy => const [-1, 0, 1, 0][index];
}

Dir dirBetween(int ax, int ay, int bx, int by) {
  if (bx > ax) return Dir.right;
  if (bx < ax) return Dir.left;
  return by > ay ? Dir.down : Dir.up;
}

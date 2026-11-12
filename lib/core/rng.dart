class Rng {
  int _s;

  Rng(int seed) : _s = (seed == 0 ? 0x9E3779B9 : seed) & 0xFFFFFFFF {
    for (var i = 0; i < 8; i++) {
      nextU32(); // warm up
    }
  }

  int nextU32() {
    var x = _s;
    x ^= (x << 13) & 0xFFFFFFFF;
    x ^= (x >> 17);
    x ^= (x << 5) & 0xFFFFFFFF;
    return _s = x & 0xFFFFFFFF;
  }

  int nextInt(int max) {
    if (max <= 0) return 0;
    return nextU32() % max;
  }

  double nextDouble() => nextU32() / 4294967296.0;

  bool chance(double p) => nextDouble() < p;

  T pick<T>(List<T> l) => l[nextInt(l.length)];

  List<T> shuffled<T>(List<T> l) {
    final r = [...l];
    for (var i = r.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final t = r[i];
      r[i] = r[j];
      r[j] = t;
    }
    return r;
  }
}

int hashSeed(int level, int salt) =>
    ((level * 2654435761) ^ (salt * 40503) ^ 0xA5A5A5A5) & 0xFFFFFFFF;

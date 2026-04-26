// ignore: avoid_print
void main() {
  final input = [3, 2, 4];
  final target = 6;

  final map = <int, int>{};

  for (int i = 0; i <= input.length; i++) {
    int comp = target - input[i];
    if (map[comp] != null) {
      // ignore: avoid_print
      print('[${input[i]}, ${input[map[comp]!]}]');
      return;
    }
    map[input[i]] = i;
  }
}

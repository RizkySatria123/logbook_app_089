class CounterController {
  int _counter = 0;
  int _step = 1;

  int get value => _counter;

  // Fungsi untuk mengubah nilai step
  void updateStep(int step) {
    _step = step;
  }

  // Logic increment pake nilai step
  void increment() {
    _counter += _step;
  }

  // Logic decrement pake nilai step
  void decrement() {
    _counter -= _step;
  }

  void reset() => _counter = 0;
}
class CounterControllerOriginal {
  int _counter = 0;
  int _step = 1;
  final List<HistoryEntryOriginal> _history = [];

  int get value => _counter;
  int get step => _step;
  List<HistoryEntryOriginal> get history => List.unmodifiable(_history);

  void updateStep(int step) {
    // BUG: Tidak ada validasi nilai negatif
    _step = step;
  }

  void increment() {
    _counter += _step;
    _addHistory(HistoryActionOriginal.tambah, _step);
  }

  void decrement() {
    // BUG: Tidak ada validasi counter negatif
    _counter -= _step;
    _addHistory(HistoryActionOriginal.kurang, _step);
  }

  void reset() {
    _counter = 0;
    _addHistory(HistoryActionOriginal.reset, 0);
  }

  void _addHistory(HistoryActionOriginal action, int step) {
    _history.add(
      HistoryEntryOriginal(action: action, step: step, timestamp: DateTime.now()),
    );
    if (_history.length > 5) {
      _history.removeAt(0);
    }
  }
}

enum HistoryActionOriginal { tambah, kurang, reset }

class HistoryEntryOriginal {
  final HistoryActionOriginal action;
  final int step;
  final DateTime timestamp;

  HistoryEntryOriginal({
    required this.action,
    required this.step,
    required this.timestamp,
  });
}

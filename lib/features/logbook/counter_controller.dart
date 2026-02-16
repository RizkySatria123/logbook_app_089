class CounterController {
  int _counter = 0;
  int _step = 1;
  final List<HistoryEntry> _history = [];

  int get value => _counter;
  List<HistoryEntry> get history => List.unmodifiable(_history);

  void updateStep(int step) {
    _step = step;
  }

  void increment() {
    _counter += _step;
    _addHistory(HistoryAction.tambah, _step);
  }

  void decrement() {
    _counter -= _step;
    _addHistory(HistoryAction.kurang, _step);
  }

  void reset() {
    _counter = 0;
    _addHistory(HistoryAction.reset, 0);
  }

  void _addHistory(HistoryAction action, int step) {
    _history.add(
      HistoryEntry(action: action, step: step, timestamp: DateTime.now()),
    );
    if (_history.length > 5) {
      _history.removeAt(0);
    }
  }
}

enum HistoryAction { tambah, kurang, reset }

class HistoryEntry {
  final HistoryAction action;
  final int step;
  final DateTime timestamp;

  HistoryEntry({
    required this.action,
    required this.step,
    required this.timestamp,
  });

  String get label {
    final actionLabel = {
      HistoryAction.tambah: 'Tambah',
      HistoryAction.kurang: 'Kurang',
      HistoryAction.reset: 'Reset',
    }[action];
    final time =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    return 'User $actionLabel nilai sebesar $step pada jam $time';
  }
}

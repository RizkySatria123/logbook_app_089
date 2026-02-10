class CounterController {
  int _counter = 0;
  int _step = 1;
  final List<String> _history = [];

  int get value => _counter;
  List<String> get history => List.unmodifiable(_history);

  void updateStep(int step) {
    _step = step;
  }

  void increment() {
    _counter += _step;
    _addHistory('User menambah nilai sebesar $_step pada jam ${_formattedTime()}');
  }

  void decrement() {
    _counter -= _step;
    _addHistory('User mengurangi nilai sebesar $_step pada jam ${_formattedTime()}');
  }

  void reset() {
    _counter = 0;
    _addHistory('User mereset nilai pada jam ${_formattedTime()}');
  }

  void _addHistory(String entry) {
    _history.add(entry);
    if (_history.length > 5) {
      _history.removeAt(0);
    }
  }

  String _formattedTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
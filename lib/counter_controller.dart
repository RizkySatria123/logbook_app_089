import 'package:shared_preferences/shared_preferences.dart';

class CounterController {
  int _counter = 0;
  int _step = 1;
  final List<String> _history = [];

  int get value => _counter;
  int get step => _step;
  List<String> get history => List.unmodifiable(_history);

  /// Memuat nilai counter dari SharedPreferences
  Future<void> loadCounter(String username) async {
    final prefs = await SharedPreferences.getInstance();
    _counter = prefs.getInt('counter_$username') ?? 0;
  }

  /// Menyimpan nilai counter ke SharedPreferences
  Future<void> _saveCounter(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('counter_$username', _counter);
  }

  /// Mengubah nilai step (abaikan jika negatif)
  void setStep(int value) {
    if (value < 0) return;
    _step = value;
  }

  /// Menambah counter sebesar step
  Future<void> increment(String username) async {
    _counter += _step;
    _addHistory("User menambah nilai sebesar $_step");
    await _saveCounter(username);
  }

  /// Mengurangi counter sebesar step (tidak boleh di bawah 0)
  Future<void> decrement(String username) async {
    _counter -= _step;
    if (_counter < 0) {
      _counter = 0;
    }
    _addHistory("User mengurangi nilai sebesar $_step");
    await _saveCounter(username);
  }

  /// Reset counter ke nol
  /// FIX: Menambahkan baris _counter = 0
  Future<void> reset(String username) async {
    _counter = 0; // ← PERBAIKAN: reset counter ke 0
    _addHistory("User melakukan reset");
    await _saveCounter(username);
  }

  /// Menambah entry ke history (max 5)
  void _addHistory(String entry) {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    _history.add('$entry pada jam $time');
    if (_history.length > 5) {
      _history.removeAt(0);
    }
  }
}

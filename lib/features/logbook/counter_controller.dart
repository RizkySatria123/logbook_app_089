import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CounterController {
  int _counter = 0;
  int _step = 1;
  List<HistoryEntry> _history = [];

  int get value => _counter;
  List<HistoryEntry> get history => List.unmodifiable(_history);

  Future<void> loadData(String username) async {
    final prefs = await SharedPreferences.getInstance();

    String keyCounter = 'counter_$username';
    String keyHistory = 'history_$username';

    _counter = prefs.getInt(keyCounter) ?? 0;

    final List<String>? historyStrings = prefs.getStringList(keyHistory);
    if (historyStrings != null) {
      _history = historyStrings
          .map((e) => HistoryEntry.fromJson(jsonDecode(e)))
          .toList();
    }
  }

  Future<void> _saveData(String username) async {
    final prefs = await SharedPreferences.getInstance();

    String keyCounter = 'counter_$username';
    String keyHistory = 'history_$username';

    await prefs.setInt(keyCounter, _counter);

    final historyStrings = _history.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(keyHistory, historyStrings);
  }

  void updateStep(int step) {
    _step = step;
  }

  void increment(String username) {
    _counter += _step;
    _addHistory(HistoryAction.tambah, _step, username);
    _saveData(username);
  }

  void decrement(String username) {
    _counter -= _step;
    _addHistory(HistoryAction.kurang, _step, username);
    _saveData(username);
  }

  void reset(String username) {
    _counter = 0;
    _addHistory(HistoryAction.reset, 0, username);
    _saveData(username);
  }

  void _addHistory(HistoryAction action, int step, String username) {
    _history.add(
      HistoryEntry(
        action: action,
        step: step,
        timestamp: DateTime.now(),
        username: username,
      ),
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
  final String username;

  HistoryEntry({
    required this.action,
    required this.step,
    required this.timestamp,
    required this.username,
  });

  String get label {
    final actionLabel = {
      HistoryAction.tambah: 'Tambah',
      HistoryAction.kurang: 'Kurang',
      HistoryAction.reset: 'Reset',
    }[action];
    final time =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    return 'User $username $actionLabel nilai sebesar $step pada jam $time';
  }

  Map<String, dynamic> toJson() => {
    'action': action.index,
    'step': step,
    'timestamp': timestamp.toIso8601String(),
    'username': username,
  };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      action: HistoryAction.values[json['action']],
      step: json['step'],
      timestamp: DateTime.parse(json['timestamp']),
      username: json['username'] ?? 'Seseorang',
    );
  }
}

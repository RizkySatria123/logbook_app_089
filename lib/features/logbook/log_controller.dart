import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './models/log_model.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  final ValueNotifier<List<LogModel>> filteredLogsNotifier = ValueNotifier([]);
  static const String _storageKey = 'user_logs_data';

  LogController() {
    loadFromDisk();
  }

  // BARU: Tambah parameter kategori
  void addLog(String title, String desc, String category) {
    final newLog = LogModel(
      title: title,
      description: desc,
      date: DateTime.now().toIso8601String(),
      category: category,
    );
    logsNotifier.value = [...logsNotifier.value, newLog];
    _syncFilteredLogs();
    saveToDisk();
  }

  // BARU: Tambah parameter kategori
  void updateLog(int index, String title, String desc, String category) {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    currentLogs[index] = LogModel(
      title: title,
      description: desc,
      date: currentLogs[index].date,
      category: category,
    );
    logsNotifier.value = currentLogs;
    _syncFilteredLogs();
    saveToDisk();
  }

  void removeLog(LogModel logToRemove) {
    final currentLogs = List<LogModel>.from(logsNotifier.value);
    currentLogs.removeWhere((log) => log.date == logToRemove.date);
    logsNotifier.value = currentLogs;
    _syncFilteredLogs();
    saveToDisk();
  }

  void searchLog(String query) {
    if (query.isEmpty) {
      filteredLogsNotifier.value = logsNotifier.value;
    } else {
      filteredLogsNotifier.value = logsNotifier.value
          .where(
            (log) =>
                log.title.toLowerCase().contains(query.toLowerCase()) ||
                log.description.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
  }

  void _syncFilteredLogs() {
    filteredLogsNotifier.value = logsNotifier.value;
  }

  Future<void> saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(
      logsNotifier.value.map((e) => e.toMap()).toList(),
    );
    await prefs.setString(_storageKey, encodedData);
  }

  Future<void> loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);

    if (data != null) {
      final List decoded = jsonDecode(data);
      logsNotifier.value = decoded.map((e) => LogModel.fromMap(e)).toList();
      _syncFilteredLogs();
    }
  }
}

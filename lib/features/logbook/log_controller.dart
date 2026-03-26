import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logbook_app_089/features/logbook/models/log_model.dart';
import 'package:logbook_app_089/services/mongo_service.dart';
import 'package:logbook_app_089/helpers/log_helper.dart';
import 'package:mongo_dart/mongo_dart.dart'
    show ObjectId; // Untuk membuat ID unik lokal

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  final ValueNotifier<List<LogModel>> filteredLogsNotifier = ValueNotifier([]);

  // Akses ke brankas lokal Hive yang sudah dibuka di main.dart
  late final Box<LogModel> _myBox;
  final String _source = "log_controller.dart";

  LogController() {
    _myBox = Hive.box<LogModel>('offline_logs');
    _syncFilteredLogs();
    fetchLogsFromDB(); // Otomatis load data saat controller dipanggil
  }

  void _syncFilteredLogs() {
    logsNotifier.addListener(() {
      filteredLogsNotifier.value = logsNotifier.value;
    });
  }

  // --- 1. LOAD DATA (Offline-First Strategy) ---
  Future<void> fetchLogsFromDB() async {
    // ACTION 1: Ambil data dari Hive (Instan tanpa butuh internet)
    final localData = _myBox.values.toList();
    if (localData.isNotEmpty) {
      logsNotifier.value = localData;
      await LogHelper.writeLog(
        "OFFLINE: Memuat ${localData.length} data dari Hive",
        source: _source,
        level: 2,
      );
    }

    // ACTION 2: Sync dari Cloud (Background)
    try {
      final cloudData = await MongoService().getLogs();

      // Update Hive dengan data terbaru dari Cloud agar sinkron
      await _myBox.clear();
      await _myBox.addAll(cloudData);

      // Update UI dengan data Cloud
      logsNotifier.value = cloudData;
      await LogHelper.writeLog(
        "SYNC: Data berhasil diperbarui dari MongoDB Atlas",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "OFFLINE MODE: Menggunakan data cache lokal. (Error: $e)",
        source: _source,
        level: 1,
      );
    }
  }

  // --- 2. ADD DATA (Instant Local + Background Cloud) ---
  Future<void> addLog(
    String title,
    String desc,
    String category, {
    String authorId = "unknown_user",
    String teamId = "no_team",
  }) async {
    final newLog = LogModel(
      id: ObjectId()
          .toHexString(), // Buat ID langsung agar bisa disimpan di lokal
      title: title,
      description: desc,
      date: DateTime.now().toIso8601String(),
      category: category,
      authorId: authorId,
      teamId: teamId,
      isPublic: false,
    );

    // ACTION 1: Simpan ke Hive (Instan)
    await _myBox.add(newLog);
    logsNotifier.value = [...logsNotifier.value, newLog]; // Update UI

    // ACTION 2: Kirim ke MongoDB Atlas (Background)
    try {
      await MongoService().insertLog(newLog);
      await LogHelper.writeLog(
        "SUCCESS: Log '${newLog.title}' tersinkron ke Cloud",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Gagal sinkron ke Cloud, tersimpan di lokal",
        source: _source,
        level: 1,
      );
    }
  }

  // --- 3. UPDATE DATA ---
  Future<void> updateLog(
    int index,
    String title,
    String desc,
    String category,
  ) async {
    final oldLog = logsNotifier.value[index];
    final updatedLog = LogModel(
      id: oldLog.id,
      title: title,
      description: desc,
      date: oldLog.date,
      category: category,
      authorId: oldLog.authorId,
      teamId: oldLog.teamId,
      isPublic: oldLog.isPublic,
    );

    // ACTION 1: Update di Lokal
    await _myBox.putAt(index, updatedLog);
    final List<LogModel> newList = List.from(logsNotifier.value);
    newList[index] = updatedLog;
    logsNotifier.value = newList;

    // ACTION 2: Update di Cloud
    try {
      await MongoService().updateLog(updatedLog);
    } catch (e) {
      await LogHelper.writeLog(
        "WARNING: Update gagal di Cloud, tersimpan di lokal",
        source: _source,
        level: 1,
      );
    }
  }

  // --- 4. REMOVE DATA ---
  Future<void> removeLog(LogModel logToRemove) async {
    final index = logsNotifier.value.indexOf(logToRemove);
    if (index != -1) {
      // ACTION 1: Hapus di Lokal
      await _myBox.deleteAt(index);
      final List<LogModel> newList = List.from(logsNotifier.value);
      newList.removeAt(index);
      logsNotifier.value = newList;
    }

    // ACTION 2: Hapus di Cloud
    if (logToRemove.id != null) {
      try {
        await MongoService().deleteLog(logToRemove.id!);
      } catch (e) {
        await LogHelper.writeLog(
          "WARNING: Hapus gagal di Cloud",
          source: _source,
          level: 1,
        );
      }
    }
  }

  // --- 5. SEARCH LOGIC ---
  void searchLog(String query) {
    if (query.isEmpty) {
      filteredLogsNotifier.value = logsNotifier.value;
    } else {
      filteredLogsNotifier.value = logsNotifier.value.where((log) {
        return log.title.toLowerCase().contains(query.toLowerCase()) ||
            log.description.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
  }
}

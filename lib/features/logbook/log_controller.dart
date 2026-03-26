import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logbook_app_089/features/logbook/models/log_model.dart';
import 'package:logbook_app_089/services/mongo_service.dart';
import 'package:logbook_app_089/helpers/log_helper.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  final ValueNotifier<List<LogModel>> filteredLogsNotifier = ValueNotifier([]);

  late final Box<LogModel> _myBox;
  final String _source = "log_controller.dart";

  LogController() {
    _myBox = Hive.box<LogModel>('offline_logs');
    _syncFilteredLogs();
    fetchLogsFromDB();

    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
        _syncPendingDataToCloud();
      }
    });
  }

  void _syncFilteredLogs() {
    logsNotifier.addListener(() {
      filteredLogsNotifier.value = logsNotifier.value;
    });
  }

  Future<void> _syncPendingDataToCloud() async {
    final localData = _myBox.values.toList();
    if (localData.isEmpty) return;

    for (var log in localData) {
      try {
        await MongoService().insertLog(log);
      } catch (e) {
        // Abaikan secara diam-diam jika data sudah ada di Cloud
      }
    }
    await fetchLogsFromDB();
  }

  // --- 1. LOAD DATA ---
  Future<void> fetchLogsFromDB() async {
    final localData = _myBox.values.toList();
    if (localData.isNotEmpty) {
      logsNotifier.value = localData;
    }

    try {
      // PERBAIKAN FATAL: Dorong data lokal ke Cloud DULU sebelum Cloud menimpa Hive!
      // Ini mencegah hilangnya catatan offline.
      for (var log in localData) {
        try {
          await MongoService().insertLog(log);
        } catch (_) {}
      }

      // Setelah aman, baru tarik data terbaru dari Cloud dan timpa lokal
      final cloudData = await MongoService().getLogs();
      await _myBox.clear();
      await _myBox.addAll(cloudData);
      logsNotifier.value = cloudData;
    } catch (e) {
      // Biarkan error jika offline, data lokal tetap aman di layar
    }
  }

  // --- 2. ADD DATA ---
  Future<void> addLog(
    String title,
    String desc,
    String category, {
    String authorId = "unknown_user",
    String teamId = "no_team",
  }) async {
    final newLog = LogModel(
      id: ObjectId().toHexString(),
      title: title,
      description: desc,
      date: DateTime.now().toIso8601String(),
      category: category,
      authorId: authorId,
      teamId: teamId,
      isPublic: false,
    );

    // INSTAN KE LOKAL: Layar akan langsung bereaksi tanpa menunggu internet
    await _myBox.add(newLog);
    logsNotifier.value = [...logsNotifier.value, newLog];

    // PERBAIKAN: Hilangkan kata 'await' di sini (Fire-and-Forget).
    // Ini membuat aplikasimu tidak akan nge-freeze 15 detik saat offline!
    MongoService().insertLog(newLog).catchError((e) {
      LogHelper.writeLog(
        "Tersimpan offline, menunggu auto-sync.",
        source: _source,
        level: 1,
      );
    });
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

    await _myBox.putAt(index, updatedLog);
    final List<LogModel> newList = List.from(logsNotifier.value);
    newList[index] = updatedLog;
    logsNotifier.value = newList;

    // PERBAIKAN: Fire-and-Forget
    MongoService().updateLog(updatedLog).catchError((_) {});
  }

  // --- 4. REMOVE DATA ---
  Future<void> removeLog(LogModel logToRemove) async {
    final index = logsNotifier.value.indexOf(logToRemove);
    if (index != -1) {
      await _myBox.deleteAt(index);
      final List<LogModel> newList = List.from(logsNotifier.value);
      newList.removeAt(index);
      logsNotifier.value = newList;
    }

    if (logToRemove.id != null) {
      // PERBAIKAN: Fire-and-Forget
      MongoService().deleteLog(logToRemove.id!).catchError((_) {});
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

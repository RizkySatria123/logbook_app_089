import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:logbook_app_089/features/logbook/models/log_model.dart';
import 'package:logbook_app_089/services/mongo_service.dart';
import 'package:logbook_app_089/helpers/log_helper.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
  final ValueNotifier<List<LogModel>> filteredLogsNotifier = ValueNotifier([]);

  static const String collectionName = "logs";
  final String _source = "log_controller.dart";

  LogController() {
    fetchLogsFromDB();
  }

  Future<void> fetchLogsFromDB() async {
    try {
      final db = MongoService().db;
      if (db == null) return; // Pengaman agar Flutter tidak error 'null'

      final collection = db.collection(collectionName);
      final logsData = await collection
          .find(where.sortBy('date', descending: true))
          .toList();

      logsNotifier.value = logsData.map((e) => LogModel.fromMap(e)).toList();
      _syncFilteredLogs();

      await LogHelper.writeLog(
        "Berhasil memuat ${logsNotifier.value.length} data",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "Gagal memuat data MongoDB: $e",
        source: _source,
        level: 1,
      );
    }
  }

  Future<void> addLog(String title, String desc, String category) async {
    try {
      final db = MongoService().db;
      if (db == null) return;

      final collection = db.collection(collectionName);
      final newDoc = {
        '_id': ObjectId(),
        'title': title,
        'description': desc,
        'date': DateTime.now().toIso8601String(),
        'category': category,
      };

      await collection.insert(newDoc);
      await fetchLogsFromDB();
    } catch (e) {
      await LogHelper.writeLog(
        "Gagal menambah data: $e",
        source: _source,
        level: 1,
      );
    }
  }

  Future<void> updateLog(
    int index,
    String title,
    String desc,
    String category,
  ) async {
    try {
      final targetLog = logsNotifier.value[index];
      if (targetLog.id == null) return;

      final db = MongoService().db;
      if (db == null) return;

      final collection = db.collection(collectionName);
      await collection.updateOne(
        where.eq('_id', targetLog.id),
        modify
            .set('title', title)
            .set('description', desc)
            .set('category', category),
      );

      await fetchLogsFromDB();
    } catch (e) {
      await LogHelper.writeLog(
        "Gagal update data: $e",
        source: _source,
        level: 1,
      );
    }
  }

  Future<void> removeLog(LogModel logToRemove) async {
    try {
      if (logToRemove.id == null) return;

      final db = MongoService().db;
      if (db == null) return;

      final collection = db.collection(collectionName);
      await collection.remove(where.eq('_id', logToRemove.id));
      await fetchLogsFromDB();
    } catch (e) {
      await LogHelper.writeLog(
        "Gagal menghapus data: $e",
        source: _source,
        level: 1,
      );
    }
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
}

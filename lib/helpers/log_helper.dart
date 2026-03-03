import 'dart:developer' as dev;
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LogHelper {
  static Future<void> writeLog(
    String message, {
    String source = "Unknown",
    int level = 2, // 1: Error, 2: Info, 3: Verbose
  }) async {
    // 1. Filter Konfigurasi dari .env [cite: 236]
    final int configLevel = int.tryParse(dotenv.env['LOG_LEVEL'] ?? '2') ?? 2;
    final String muteList = dotenv.env['LOG_MUTE'] ?? '';

    // Task 4: Cek Verbosity Control & Source Filtering [cite: 414, 415]
    if (level > configLevel) return;
    if (muteList.split(',').contains(source)) return;

    try {
      String timestamp = DateFormat('HH:mm:ss').format(DateTime.now());
      String dateFile = DateFormat('dd-mm-yyyy').format(DateTime.now());
      String label = _getLabel(level);
      String color = _getColor(level);

      // Output ke Terminal VS Code [cite: 236]
      print('$color[$timestamp][$label][$source] -> $message\x1B[0m');

      // Task 4 Milestone: Menulis ke file fisik secara otomatis
      final directory = Directory('logs');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final file = File('logs/$dateFile.log');
      await file.writeAsString(
        '[$timestamp][$label][$source] -> $message\n',
        mode: FileMode.append,
      );
    } catch (e) {
      dev.log("Logging failed: $e", name: "SYSTEM", level: 1000);
    }
  }

  static String _getLabel(int level) {
    switch (level) {
      case 1:
        return "ERROR";
      case 2:
        return "INFO";
      case 3:
        return "VERBOSE";
      default:
        return "LOG";
    }
  }

  static String _getColor(int level) {
    switch (level) {
      case 1:
        return '\x1B[31m'; // Merah
      case 2:
        return '\x1B[32m'; // Hijau
      case 3:
        return '\x1B[34m'; // Biru
      default:
        return '\x1B[0m';
    }
  }
}

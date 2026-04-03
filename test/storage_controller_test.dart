import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logbook_app_089/storage_controller.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// TEST TERHADAP KODE YANG SUDAH DIPERBAIKI
/// File yang diuji: lib/storage_controller.dart
/// Tujuan: Memverifikasi bahwa semua bug sudah diperbaiki
/// ═══════════════════════════════════════════════════════════════════════════
void main() {
  group('StorageController - SharedPreferences', () {
    // ─────────────────────────────────────────────────────────────────────
    // setUp dijalankan sebelum SETIAP test case
    // Mock SharedPreferences agar tidak menulis ke memori fisik
    // ─────────────────────────────────────────────────────────────────────
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    // ═══════════════════════════════════════════════════════════════════════
    // TC01 | saveToLocal & loadFromLocal | Test Positif (Save & Load)
    // Simpan nilai 10 dengan key 'score', lalu load dan pastikan hasilnya 10
    // ═══════════════════════════════════════════════════════════════════════
    test('TC01 - saveToLocal lalu loadFromLocal harus mengembalikan nilai yang sama',
        () async {
      // (1) setup (arrange, build)
      final controller = StorageController();
      const key = 'score';
      const value = 10;

      // (2) exercise (act, operate)
      await controller.saveToLocal(key, value);
      final actual = await controller.loadFromLocal(key);

      // (3) verify (assert, check)
      final expected = 10;
      expect(actual, expected);
    });

    // ═══════════════════════════════════════════════════════════════════════
    // TC02 | saveToLocal & loadFromLocal | Test Positif (Overwrite)
    // Simpan nilai 10, lalu timpa jadi 20, pastikan load = 20
    // ═══════════════════════════════════════════════════════════════════════
    test('TC02 - saveToLocal overwrite harus mengembalikan nilai terbaru',
        () async {
      // (1) setup (arrange, build)
      final controller = StorageController();
      const key = 'score';
      const initialValue = 10;
      const overwriteValue = 20;

      // (2) exercise (act, operate)
      await controller.saveToLocal(key, initialValue);
      await controller.saveToLocal(key, overwriteValue);
      final actual = await controller.loadFromLocal(key);

      // (3) verify (assert, check)
      final expected = 20;
      expect(actual, expected);
    });

    // ═══════════════════════════════════════════════════════════════════════
    // TC03 | saveToLocal | Test Negatif (Key Kosong)
    // Simpan data dengan key kosong → harus melempar Exception/Error
    // ═══════════════════════════════════════════════════════════════════════
    test('TC03 - saveToLocal dengan key kosong harus melempar Exception',
        () async {
      // (1) setup (arrange, build)
      final controller = StorageController();
      const key = '';
      const value = 99;

      // (2) exercise & (3) verify (act + assert)
      expect(
        () async => await controller.saveToLocal(key, value),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

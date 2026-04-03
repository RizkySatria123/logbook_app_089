import 'package:shared_preferences/shared_preferences.dart';

/// KODE YANG SUDAH DIPERBAIKI
/// Fix: saveToLocal melempar Exception jika key kosong
class StorageController {
  /// Menyimpan nilai integer ke penyimpanan lokal
  Future<void> saveToLocal(String key, int value) async {
    // FIX: Validasi key tidak boleh kosong
    if (key.isEmpty) {
      throw ArgumentError('Key tidak boleh kosong');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  /// Memuat nilai integer dari penyimpanan lokal
  Future<int?> loadFromLocal(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }
}

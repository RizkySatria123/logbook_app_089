import 'package:shared_preferences/shared_preferences.dart';

/// KODE ORIGINAL (SEBELUM PERBAIKAN)
/// Bug: saveToLocal tidak validasi key kosong, hanya diam-diam menyimpan
class StorageControllerOriginal {
  /// Menyimpan nilai integer ke penyimpanan lokal
  Future<void> saveToLocal(String key, int value) async {
    // BUG: Tidak ada validasi key kosong
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  /// Memuat nilai integer dari penyimpanan lokal
  Future<int?> loadFromLocal(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }
}

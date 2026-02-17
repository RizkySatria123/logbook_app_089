import 'dart:async'; //  fitur Timer

class LoginController {
  final Map<String, String> _users = {
    'admin': '123',
    'rizky': 'satria123',
    'ikhsan': '5atriadi123',
  };

  // fitur pengamanan
  bool _isLocked = false;
  int _failedAttempts = 0;

  //  mengecek status terkunci di View
  bool get isLocked => _isLocked;

  // Fungsi Login dengan Validasi & Keamanan
  Future<bool> login(String username, String password) async {
    if (_isLocked) return false;

    // Validasi Input Kosong
    if (username.isEmpty || password.isEmpty) {
      return false; // Gagal jika kosong
    }

    // Cek Username & Password
    if (_users.containsKey(username) && _users[username] == password) {
      _failedAttempts = 0;
      return true;
    } else {
      _failedAttempts++;

      // Cek apakah sudah salah 3 kali?
      if (_failedAttempts >= 3) {
        _isLocked = true;

        // Buka kunci otomatis setelah 10 detik
        Timer(const Duration(seconds: 10), () {
          _isLocked = false;
          _failedAttempts = 0;
        });
      }

      return false;
    }
  }
}

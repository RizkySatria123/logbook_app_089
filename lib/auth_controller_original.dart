import 'dart:async';

/// KODE ORIGINAL (SEBELUM PERBAIKAN)
/// Bug: login dengan input kosong tidak melempar Exception, hanya return false
/// Bug: tidak ada validasi panjang minimum password
class AuthControllerOriginal {
  final Map<String, String> _users = {
    'admin': '123',
    'rizky': 'satria123',
    'ikhsan': '5atriadi123',
  };

  bool _isLocked = false;
  int _failedAttempts = 0;

  bool get isLocked => _isLocked;
  int get failedAttempts => _failedAttempts;

  Future<bool> login(String username, String password) async {
    if (_isLocked) return false;

    // BUG: Input kosong hanya return false, tidak throw Exception
    if (username.isEmpty || password.isEmpty) {
      return false;
    }

    if (_users.containsKey(username) && _users[username] == password) {
      _failedAttempts = 0;
      return true;
    } else {
      _failedAttempts++;

      if (_failedAttempts >= 3) {
        _isLocked = true;

        Timer(const Duration(seconds: 10), () {
          _isLocked = false;
          _failedAttempts = 0;
        });
      }

      return false;
    }
  }
}

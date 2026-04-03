class AuthController {
  // Kredensial yang valid (simulasi)
  final String _validUsername = 'admin';
  final String _validPassword = 'password123';

  /// Fungsi login yang mengembalikan `true` jika kredensial benar,
  /// `false` jika salah, dan melempar `Exception` jika parameter kosong.
  Future<bool> login(String username, String password) async {
    // Validasi: username dan password tidak boleh kosong
    if (username.isEmpty || password.isEmpty) {
      throw Exception('Username dan password tidak boleh kosong');
    }

    // Simulasi delay jaringan
    await Future.delayed(const Duration(milliseconds: 100));

    // Cek kredensial
    if (username == _validUsername && password == _validPassword) {
      return true;
    }

    return false;
  }
}

// Lokasi: lib/features/auth/login_controller.dart

class LoginController {
  // Database sederhana (Hardcoded)
  final String _validUsername = "admin";
  final String _validPassword = "123";

  // Fungsi pengecekan (Logic-Only) [cite: 117]
  // Mengembalikan true jika cocok, false jika salah.
  bool login(String username, String password) {
    if (username == _validUsername && password == _validPassword) {
      return true;
    }
    return false;
  }
}

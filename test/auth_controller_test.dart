import 'package:flutter_test/flutter_test.dart';
import 'package:logbook_app_089/auth_controller.dart';

void main() {
  group('AuthController - login()', () {
    // ═══════════════════════════════════════════════════════════════════════
    // TC01 | login() | Test Positif
    // Login dengan kredensial benar → harus return true
    // ═══════════════════════════════════════════════════════════════════════
    test('TC01 - login dengan kredensial benar harus mengembalikan true',
        () async {
      // (1) setup (arrange, build)
      final authController = AuthController();
      const username = 'admin';
      const password = 'password123';

      // (2) exercise (act, operate)
      final actual = await authController.login(username, password);

      // (3) verify (assert, check)
      final expected = true;
      expect(actual, expected);
    });

    // ═══════════════════════════════════════════════════════════════════════
    // TC02 | login() | Test Negatif 1
    // Login dengan password salah → harus return false
    // ═══════════════════════════════════════════════════════════════════════
    test('TC02 - login dengan password salah harus mengembalikan false',
        () async {
      // (1) setup (arrange, build)
      final authController = AuthController();
      const username = 'admin';
      const password = 'salahpassword';

      // (2) exercise (act, operate)
      final actual = await authController.login(username, password);

      // (3) verify (assert, check)
      final expected = false;
      expect(actual, expected);
    });

    // ═══════════════════════════════════════════════════════════════════════
    // TC03 | login() | Test Negatif 2
    // Login dengan string kosong → harus melempar Exception
    // ═══════════════════════════════════════════════════════════════════════
    test('TC03 - login dengan parameter kosong harus melempar Exception',
        () async {
      // (1) setup (arrange, build)
      final authController = AuthController();
      const username = '';
      const password = '';

      // (2) exercise & (3) verify (act + assert)
      // Menggunakan throwsA untuk memverifikasi bahwa Exception dilempar
      expect(
        () async => await authController.login(username, password),
        throwsA(isA<Exception>()),
      );
    });
  });
}

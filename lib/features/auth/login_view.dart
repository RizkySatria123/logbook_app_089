// Lokasi: lib/features/auth/login_view.dart
import 'package:flutter/material.dart';
// Gunakan Package Path agar tidak error saat file dipindah [cite: 87, 100]
import 'package:logbook_app_089/features/auth/login_controller.dart';
import 'package:logbook_app_089/features/logbook/counter_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final LoginController _controller = LoginController();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  void _handleLogin() {
    String user = _userController.text;
    String pass = _passController.text;
    bool isSuccess = _controller.login(user, pass);

    if (isSuccess) {
      // Pindah halaman & kirim data username [cite: 120, 122]
      // pushReplacement agar user tidak bisa klik 'Back' ke Login [cite: 63, 110]
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CounterView(username: user)),
      );
    } else {
      // Tampilkan pesan jika gagal [cite: 120]
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Gagal! Gunakan admin/123")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Gatekeeper")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _userController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: _passController,
              obscureText: true, // Menyembunyikan password [cite: 120]
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _handleLogin, child: const Text("Masuk")),
          ],
        ),
      ),
    );
  }
}

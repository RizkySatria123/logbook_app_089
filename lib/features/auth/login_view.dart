import 'package:flutter/material.dart';
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isObscure = true;

  bool _isLocked = false;

  void _handleLogin() async {
    // Validasi Form
    if (_formKey.currentState!.validate()) {
      // Panggil fungsi login
      bool isSuccess = await _controller.login(
        _userController.text,
        _passController.text,
      );

      // Cek status terkunci
      if (_controller.isLocked) {
        setState(() {
          _isLocked = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Akun terkunci sementara! Tunggu 10 detik."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );

        // Timer visual di View
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted) {
            setState(() {
              _isLocked = false;
            });
          }
        });
        return;
      }

      if (isSuccess) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CounterView(username: _userController.text),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Username atau Password Salah!"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Portal LogBook")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // INPUT USERNAME
              TextFormField(
                controller: _userController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Username tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // INPUT PASSWORD
              TextFormField(
                controller: _passController,
                obscureText: _isObscure,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isObscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure; // Toggle status
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password wajib diiisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // TOMBOL LOGIN
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLocked ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLocked ? Colors.grey : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_isLocked ? "Tunggu 10 Detik..." : "Masuk"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

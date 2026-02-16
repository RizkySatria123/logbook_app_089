import 'package:flutter/material.dart';
// Jangan lupa ganti ke _089 sesuai nama project kamu
import 'package:logbook_app_089/features/auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  int _step = 1;

  void _nextStep() {
    if (_step < 3) {
      setState(() {
        _step++;
      });
    } else {
      // Logika modul: Jika step > 3, pindah ke Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Halaman Onboarding"),
            const SizedBox(height: 20),
            // Menampilkan angka step (1, 2, 3)
            Text(
              "$_step",
              style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _nextStep, child: const Text("Lanjut")),
          ],
        ),
      ),
    );
  }
}

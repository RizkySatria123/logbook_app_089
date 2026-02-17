import 'package:flutter/material.dart';
// Sesuaikan nama package dengan project kamu
import 'package:logbook_app_089/features/auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  int _currentIndex = 0; // Mulai dari index 0 (Halaman 1)

  // Data Gambar & Teks
  final List<Map<String, String>> _onboardingData = [
    {
      "image": "assets/images/Welcome.jpeg",
      "title": "Wilujeng Sumping!",
      "desc":
          "Aplikasi Logbook ini masih dalam tahap pengembangan, tapi sudah bisa digunakan untuk mencatat aktivitas harianmu.",
    },
    {
      "image": "assets/images/Gembok.png",
      "title": "Keamanan Terjamin",
      "desc":
          "Sistem login aman dengan fitur pengunci otomatis jika salah sandi.",
    },
    {
      "image": "assets/images/Grafik.png",
      "title": "Pantau Grafikmu",
      "desc": "Lihat riwayat kenaikan angka dan aktivitasmu secara real-time.",
    },
  ];

  void _nextStep() {
    if (_currentIndex < _onboardingData.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              Image.asset(
                _onboardingData[_currentIndex]["image"]!,
                height: 250,
              ),
              const SizedBox(height: 30),

              Text(
                _onboardingData[_currentIndex]["title"]!,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 10),

              Text(
                _onboardingData[_currentIndex]["desc"]!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),

              const Spacer(),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _onboardingData.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 12 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? Colors.indigo
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _currentIndex == _onboardingData.length - 1
                        ? "Mulai Sekarang"
                        : "Lanjut",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

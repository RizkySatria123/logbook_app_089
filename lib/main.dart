import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'package:logbook_app_089/services/mongo_service.dart'; // Import MongoService
import 'package:logbook_app_089/helpers/log_helper.dart'; // Import LogHelper
import 'package:logbook_app_089/features/onboarding/onboarding_view.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logbook_app_089/features/logbook/models/log_model.dart';

void main() async {
  // Pastikan binding Flutter sudah siap sebelum menjalankan kode async
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1. Muat konfigurasi dari file .env
    await dotenv.load(fileName: ".env");

    // --- 2. TAMBAHAN INISIALISASI HIVE (MODUL 5) ---
    await Hive.initFlutter(); // Menyalakan mesin database lokal
    Hive.registerAdapter(
      LogModelAdapter(),
    ); // Mengenalkan bentuk LogModel ke Hive
    await Hive.openBox<LogModel>(
      'offline_logs',
    ); // Membuka brankas data bernama 'offline_logs'

    // 3. Inisialisasi koneksi ke MongoDB Atlas (Dari Modul 4)
    await MongoService().connect();

    await LogHelper.writeLog(
      "Aplikasi berhasil dimulai dengan koneksi Database dan Hive",
      source: "main.dart",
    );
  } catch (e) {
    // Catat error jika gagal koneksi atau gagal muat .env
    await LogHelper.writeLog(
      "Gagal inisialisasi aplikasi: $e",
      source: "main.dart",
      level: 1,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LogBook App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      // Aplikasi tetap diarahkan ke OnboardingView sesuai struktur aslimu
      home: const OnboardingView(),
    );
  }
}

// Bagian MyHomePage tetap ada di bawah jika kamu masih membutuhkannya,
// namun aplikasi kamu akan dimulai dari OnboardingView.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Ditekan :'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

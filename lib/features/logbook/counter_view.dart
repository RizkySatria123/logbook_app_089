import 'package:flutter/material.dart';
import 'counter_controller.dart';

// PENTING: Ganti 'logbook_app' dengan nama project kamu yang ada di pubspec.yaml
// atau sesuaikan path-nya ke file onboarding_view.dart kamu.
// import 'package:logbook_app/features/onboarding/onboarding_view.dart';

// Jika kamu menggunakan Relative Path (folder features/logbook dan features/onboarding sejajar):
import '../onboarding/onboarding_view.dart';

class CounterView extends StatefulWidget {
  // 1. UPDATE: Menambahkan variabel username agar bisa menerima data dari Login
  final String username;

  // 2. UPDATE: Wajibkan (required) username di constructor
  const CounterView({super.key, required this.username});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();

  @override
  Widget build(BuildContext context) {
    final history = _controller.history.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        // 3. UPDATE: Menampilkan Nama User di Judul
        title: Text("Logbook: ${widget.username}"),

        // 4. UPDATE: Menambahkan Tombol Logout di Kanan Atas
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout, // Memanggil fungsi logout di bawah
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Masukkan Nilai Step yang anda suka",
                border: OutlineInputBorder(),
                hintText: "Contoh: 6 atau 7",
              ),
              onChanged: (value) {
                final newStep = int.tryParse(value) ?? 1;
                _controller.updateStep(newStep);
              },
            ),
            const SizedBox(height: 20),

            const Text("Total :"),
            Text(
              '${_controller.value}',
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            const Text("Riwayat Terakhir"),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: history.isEmpty
                  ? const Center(child: Text("Belum ada aktivitas"))
                  : ListView.separated(
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final entry = history[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            entry.label,
                            style: TextStyle(
                              color: colorFor(entry.action),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'reset',
            onPressed: _confirmReset,
            tooltip: 'Reset',
            backgroundColor: Colors.orange,
            shape: const CircleBorder(),
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 15),
          FloatingActionButton(
            heroTag: 'decrement',
            onPressed: () {
              setState(() {
                _controller.decrement();
              });
            },
            tooltip: 'Kurang',
            backgroundColor: Colors.red,
            shape: const CircleBorder(),
            child: const Icon(Icons.remove),
          ),
          const SizedBox(width: 15),
          FloatingActionButton(
            heroTag: 'increment',
            onPressed: () {
              setState(() {
                _controller.increment();
              });
            },
            tooltip: 'Tambah',
            backgroundColor: Colors.blue,
            shape: const CircleBorder(),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  // --- LOGIC TAMBAHAN UNTUK LOGOUT ---
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konfirmasi Logout"),
          content: const Text("Apakah Anda yakin ingin keluar?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Tutup dialog
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                // Kembali ke Onboarding & Hapus History Halaman (Stack)
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OnboardingView(),
                  ),
                  (route) => false,
                );
              },
              child: const Text(
                "Ya, Keluar",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmReset() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Reset'),
        content: const Text('Yakin Ingin diReset?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (shouldReset == true) {
      setState(() {
        _controller.reset();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(' Udah direset')));
    }
  }

  Color colorFor(HistoryAction action) => {
    HistoryAction.tambah: Colors.green,
    HistoryAction.kurang: Colors.red,
    HistoryAction.reset: Colors.blue,
  }[action]!;
}

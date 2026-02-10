import 'package:flutter/material.dart';
import 'counter_controller.dart';

class CounterView extends StatefulWidget {
  const CounterView({super.key});
  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();

  @override
  Widget build(BuildContext context) {
    final history = _controller.history.reversed.toList();
    return Scaffold(
      appBar: AppBar(title: const Text("LogBook_App_089 - Task 1")),
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
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(history[index]),
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
            onPressed: () {
              setState(() {
                _controller.reset();
              });
            },
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
}
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
    return Scaffold(
      appBar: AppBar(title: const Text("LogBook_App_089 - Task 1")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Masukkan Nilai Step yang anda suka",
                  border: OutlineInputBorder(),
                  hintText: "Contoh: 6 atau 7",
                ),
                onChanged: (value) {
                  int newStep = int.tryParse(value) ?? 1;
                  _controller.updateStep(newStep);
                },
              ),
              const SizedBox(height: 20),

              const Text("Total :"),
              // Menampilkan nilai
              Text(
                  '${_controller.value}',
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)
              ),
            ],
          ),
        ),
      ),
      // Tombol Tambah & Kurang
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _controller.decrement(); // Manggil decrement
              });
            },
            tooltip: 'Kurang',
            child: const Icon(Icons.remove),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _controller.increment(); // Manggil increment
              });
            },
            tooltip: 'Tambah',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
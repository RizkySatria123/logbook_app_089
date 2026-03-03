import 'package:flutter/material.dart';
import 'package:logbook_app_089/features/logbook/log_controller.dart';
import 'package:logbook_app_089/features/logbook/models/log_model.dart';
import 'package:logbook_app_089/services/mongo_service.dart';

class LogView extends StatefulWidget {
  final String username;
  const LogView({super.key, required this.username});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  final LogController _controller = LogController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await MongoService().connect();
      await _controller.fetchLogsFromDB();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  // --- FUNGSI WARNA KATEGORI ---
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Pekerjaan':
        return Colors.blue.shade100;
      case 'Urgent':
        return Colors.red.shade100;
      case 'Pribadi':
        return Colors.green.shade100;
      default:
        return Colors.white;
    }
  }

  void _showLogDialog({int? index, LogModel? log}) {
    final isEdit = index != null && log != null;
    String selectedCategory = isEdit ? log.category : 'Pribadi';
    if (isEdit) {
      _titleController.text = log.title;
      _contentController.text = log.description;
    } else {
      _titleController.clear();
      _contentController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.lightBlueAccent, width: 3),
          ),
          title: Text(
            isEdit ? "Edit Catatan" : "Tambah Catatan",
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Judul"),
              ),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: "Deskripsi"),
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: selectedCategory,
                isExpanded: true,
                items: ['Pekerjaan', 'Pribadi', 'Urgent']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setStateDialog(() => selectedCategory = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (isEdit) {
                  await _controller.updateLog(
                    index,
                    _titleController.text,
                    _contentController.text,
                    selectedCategory,
                  );
                } else {
                  await _controller.addLog(
                    _titleController.text,
                    _contentController.text,
                    selectedCategory,
                  );
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(isEdit ? "Update" : "Simpan"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: const Color(0xFF1976D2),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$_greeting, ${widget.username}!",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "Logbook Activity",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => _controller.searchLog(v),
              decoration: InputDecoration(
                hintText: "Cari Catatan...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: _controller.filteredLogsNotifier,
              builder: (context, currentLogs, _) {
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (currentLogs.isEmpty) {
                  return const Center(child: Text("Data tidak ditemukan"));
                }
                return ListView.builder(
                  itemCount: currentLogs.length,
                  itemBuilder: (context, index) {
                    final log = currentLogs[index];
                    return Dismissible(
                      key: Key(log.id?.toHexString() ?? log.date),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (dir) => _controller.removeLog(log),
                      child: Card(
                        color: _getCategoryColor(
                          log.category,
                        ), // Warna Kategori Kembali
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(
                            log.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(log.description),
                              const SizedBox(height: 4),
                              // Badge Label Kategori
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  log.category,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                _showLogDialog(index: index, log: log),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLogDialog(),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add catatan",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Homework 3: Tambahan untuk format waktu
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

  Future<List<LogModel>>? _logFuture;
  bool _isOffline = false; // Homework 1: Status untuk Connection Guard

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  // Homework 1 & 2: Diperbarui dengan Connection Guard [cite: 889, 890]
  Future<void> _refreshData() async {
    setState(() => _isOffline = false); // Reset status offline saat ditarik

    try {
      await MongoService().connect(); // Memastikan koneksi sebelum fetch
    } catch (e) {
      setState(() => _isOffline = true); // Munculkan banner merah jika gagal
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Offline Mode: Gagal terhubung ke MongoDB Atlas."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }

    setState(() {
      _logFuture = MongoService().getLogs();
    });
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

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

  // Homework 3: Logika format waktu lokal Indonesia
  String _formatTimestamp(String isoDate) {
    if (isoDate.isEmpty) return "";
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return "Baru saja";
      if (diff.inMinutes < 60) return "${diff.inMinutes} menit yang lalu";
      if (diff.inHours < 24) return "${diff.inHours} jam yang lalu";
      if (diff.inDays < 7) return "${diff.inDays} hari yang lalu";

      return DateFormat('dd MMM yyyy').format(date); // Butuh library intl
    } catch (e) {
      return isoDate;
    }
  }

  void _showLogDialog({LogModel? log}) {
    final isEdit = log != null;
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
                  await MongoService().updateLog(
                    LogModel(
                      id: log.id,
                      title: _titleController.text,
                      description: _contentController.text,
                      category: selectedCategory,
                      date: log.date,
                    ),
                  );
                } else {
                  await _controller.addLog(
                    _titleController.text,
                    _contentController.text,
                    selectedCategory,
                  );
                }
                if (context.mounted) Navigator.pop(context);
                _refreshData();
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
              "Logbook Activity - Cloud Mode",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Homework 1: Connection Guard Banner
          if (_isOffline)
            Container(
              width: double.infinity,
              color: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Offline Mode: Koneksi terputus. Tarik layar ke bawah untuk mencoba lagi.",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() {}),
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
            child: FutureBuilder<List<LogModel>>(
              future: _logFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Menghubungkan ke MongoDB Atlas..."),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final allLogs = snapshot.data ?? [];
                final query = _searchController.text.toLowerCase();
                final currentLogs = allLogs
                    .where(
                      (log) =>
                          log.title.toLowerCase().contains(query) ||
                          log.description.toLowerCase().contains(query),
                    )
                    .toList();

                if (currentLogs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "Data Kosong / Tarik layar untuk memuat",
                          style: TextStyle(color: Colors.grey, fontSize: 18),
                        ),
                      ],
                    ),
                  );
                }

                // Homework 2: Pull-to-Refresh Indicator
                return RefreshIndicator(
                  onRefresh: _refreshData, // Memicu ulang Future
                  child: ListView.builder(
                    physics:
                        const AlwaysScrollableScrollPhysics(), // Wajib agar selalu bisa ditarik
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
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Hapus Catatan?"),
                              content: const Text(
                                "Data akan dihapus permanen dari Cloud.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text("Batal"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Hapus"),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (dir) async {
                          await MongoService().deleteLog(log.id!);
                          _refreshData();
                        },
                        child: Card(
                          color: _getCategoryColor(log.category),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            title: Text(
                              log.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Homework 3: Badge Kategori dan Timestamp
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(log.description),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white54,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        log.category,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatTimestamp(log.date),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade700,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showLogDialog(log: log),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
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

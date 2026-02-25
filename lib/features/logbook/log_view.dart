import 'package:flutter/material.dart';
import 'package:logbook_app_089/features/logbook/log_controller.dart';
import 'package:logbook_app_089/features/logbook/models/log_model.dart';
import 'package:logbook_app_089/features/onboarding/onboarding_view.dart';

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

  // Daftar Kategori
  final List<String> _categories = ['Pekerjaan', 'Pribadi', 'Urgent'];

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Fungsi Pembantu: Menentukan warna kartu berdasarkan kategori
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Pekerjaan':
        return Colors.blue.shade100; // Biru
      case 'Urgent':
        return Colors.red.shade100; // Merah
      case 'Pribadi':
      default:
        return Colors.green.shade100; // Hijau
    }
  }

  void _showLogDialog({int? index, LogModel? log}) {
    final isEdit = index != null && log != null;
    String selectedCategory = isEdit ? log.category : 'Pribadi'; // Default

    if (isEdit) {
      _titleController.text = log.title;
      _contentController.text = log.description;
    } else {
      _titleController.clear();
      _contentController.clear();
    }

    showDialog(
      context: context,
      builder: (context) {
        // Menggunakan StatefulBuilder agar Dropdown bisa di-update di dalam dialog
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
                side: BorderSide(
                  color: Colors.lightBlueAccent.shade200,
                  width: 3.0,
                ),
              ),
              title: Text(
                isEdit ? "Edit Catatan" : "Tambah Catatan",
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: "Judul Catatan",
                      filled: true,
                      fillColor: Colors.blue.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      hintText: "Isi Deskripsi",
                      filled: true,
                      fillColor: Colors.blue.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  // BARU: Dropdown Kategori
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.blue.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: _categories.map((String category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setStateDialog(() {
                        selectedCategory = newValue!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (_titleController.text.trim().isEmpty) return;

                    if (isEdit) {
                      final realIndex = _controller.logsNotifier.value
                          .indexWhere((l) => l.date == log.date);
                      if (realIndex != -1) {
                        // BARU: Lempar data kategori saat update
                        _controller.updateLog(
                          realIndex,
                          _titleController.text,
                          _contentController.text,
                          selectedCategory,
                        );
                      }
                    } else {
                      // BARU: Lempar data kategori saat nambah
                      _controller.addLog(
                        _titleController.text,
                        _contentController.text,
                        selectedCategory,
                      );
                    }
                    Navigator.pop(context);
                  },
                  child: Text(isEdit ? "Update" : "Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Konfirmasi Logout"),
        content: const Text("Yakin keluar? Data tetap tersimpan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const OnboardingView()),
                (route) => false,
              );
            },
            child: const Text(
              "Ya, Keluar",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$_greeting, ${widget.username}!",
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "Logbook Activity",
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _controller.searchLog(value),
              decoration: InputDecoration(
                labelText: "Cari Catatan...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: _controller.filteredLogsNotifier,
              builder: (context, currentLogs, child) {
                if (currentLogs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? "Belum ada catatan logbook."
                              : "Catatan tidak ditemukan.",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: currentLogs.length,
                  itemBuilder: (context, index) {
                    final log = currentLogs[index];
                    return Dismissible(
                      key: Key(log.date),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(
                          Icons.delete_sweep,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      onDismissed: (direction) {
                        _controller.removeLog(log);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Catatan berhasil dihapus"),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        // BARU: Mewarnai Card sesuai Kategori
                        color: _getCategoryColor(log.category),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Colors.white54,
                            child: const Icon(
                              Icons.note_alt_outlined,
                              color: Colors.black87,
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  log.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // BARU: Label kecil untuk kategori
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white60,
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
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              log.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.edit_note,
                              color: Colors.blueGrey,
                              size: 28,
                            ),
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
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          "Add catatan",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

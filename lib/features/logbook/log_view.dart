import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logbook_app_089/features/logbook/log_controller.dart';
import 'package:logbook_app_089/features/logbook/models/log_model.dart';
import 'package:logbook_app_089/services/mongo_service.dart';
import 'package:logbook_app_089/services/access_control_service.dart';
import 'package:logbook_app_089/features/logbook/log_editor_page.dart';
import 'package:logbook_app_089/features/auth/login_view.dart';

class LogView extends StatefulWidget {
  final String username;
  const LogView({super.key, required this.username});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  final LogController _controller = LogController();
  final TextEditingController _searchController = TextEditingController();

  bool _isOffline = false; // Status untuk Connection Guard

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  // Diperbarui dengan Connection Guard
  Future<void> _refreshData() async {
    setState(() => _isOffline = false);
    try {
      await MongoService().connect();
    } catch (e) {
      setState(() => _isOffline = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Offline Mode: Gagal terhubung ke MongoDB Atlas."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
    // Memuat Hive & Cloud
    await _controller.fetchLogsFromDB();
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

  // Logika format waktu lokal Indonesia
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

  // Fungsi Navigasi ke Halaman Editor (Menggantikan _showLogDialog lama)
  void _goToEditor({LogModel? log, int? index}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          log: log,
          index: index,
          controller: _controller,
          username: widget.username,
        ),
      ),
    ).then((_) {
      // Refresh data setelah kembali dari editor
      _refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Simulasi Role untuk RBAC berdasarkan username
    String currentRole =
        widget.username.toLowerCase().contains('ketua') ||
            widget.username.toLowerCase().contains('admin')
        ? 'Ketua'
        : 'Anggota';

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
            Text(
              "Logbook Activity - Role: $currentRole", // Menampilkan role saat ini
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Konfirmasi Logout"),
                    ],
                  ),
                  content: const Text(
                    "Apakah Anda yakin ingin logout dari aplikasi?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context), // Tutup popup jika batal
                      child: const Text(
                        "Batal",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () {
                        Navigator.pop(context); // Tutup popup dialog dulu
                        // Arahkan kembali ke halaman Login dan hapus riwayat navigasi
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginView(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text(
                        "Ya, Logout",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
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
              // Hubungkan pencarian ke controller
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
            // Menggunakan ValueListenableBuilder
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: _controller.filteredLogsNotifier,
              builder: (context, currentLogs, _) {
                // --- TASK 5 MULAI: FILTER VISIBILITAS ---
                final displayLogs = currentLogs.where((log) {
                  return log.authorId == widget.username ||
                      log.isPublic == true;
                }).toList();

                if (displayLogs.isEmpty) {
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

                // Pull-to-Refresh Indicator
                return RefreshIndicator(
                  onRefresh: _refreshData,
                  child: ListView.builder(
                    physics:
                        const AlwaysScrollableScrollPhysics(), // Wajib agar selalu bisa ditarik
                    itemCount: displayLogs.length,
                    itemBuilder: (context, index) {
                      final log = displayLogs[index];

                      // Pengecekan Gatekeeper (RBAC)
                      bool isOwner = log.authorId == widget.username;
                      bool canDelete = AccessControlService.canPerform(
                        currentRole,
                        AccessControlService.actionDelete,
                        isOwner: isOwner,
                      );
                      bool canEdit = AccessControlService.canPerform(
                        currentRole,
                        AccessControlService.actionUpdate,
                        isOwner: isOwner,
                      );

                      return Dismissible(
                        key: Key(log.id ?? log.date),
                        // Kunci fitur Swipe to Delete jika tidak memiliki izin
                        direction: canDelete
                            ? DismissDirection.endToStart
                            : DismissDirection.none,
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
                                "Data akan dihapus permanen dari Lokal & Cloud.",
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
                          // Gunakan controller agar terhapus di Lokal (Hive) dan Cloud sekaligus
                          await _controller.removeLog(log);
                        },
                        child: Card(
                          color: _getCategoryColor(log.category),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
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
                                // Tampilkan nama author kecil di pojok kanan atas judul
                                Text(
                                  "by: ${log.authorId}",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.purple,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                            // Badge Kategori dan Timestamp
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log.description,
                                  maxLines:
                                      2, // Batasi teks panjang agar kartu rapi
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        //  BADGE PRIVASI (IKON) ---
                                        Icon(
                                          log.isPublic
                                              ? Icons.public
                                              : Icons.lock,
                                          size: 14,
                                          color: log.isPublic
                                              ? Colors.blue
                                              : Colors.red,
                                        ),
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white54,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
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
                            trailing: canEdit
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () =>
                                        _goToEditor(log: log, index: index),
                                  )
                                : const SizedBox.shrink(),
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
        // Arahkan tombol tambah ke halaman editor baru
        onPressed: () => _goToEditor(),
        backgroundColor: Colors.green, // Mempertahankan warna asli pilihanmu
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add catatan", // Mempertahankan teks pilihanmu
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

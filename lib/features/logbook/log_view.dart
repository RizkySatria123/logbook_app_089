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

  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isOffline = false);
    try {
      await MongoService().connect();
    } catch (e) {
      setState(() => _isOffline = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.white),
                SizedBox(width: 10),
                Text("Offline Mode: Memuat data lokal."),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
    await _controller.fetchLogsFromDB();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  // Warna Card dibuat sedikit lebih pastel dan estetik
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Pekerjaan':
        return const Color(0xFFE3F2FD); // Light Blue
      case 'Urgent':
        return const Color(0xFFFFEBEE); // Light Red
      case 'Pribadi':
        return const Color(0xFFE8F5E9); // Light Green
      default:
        return Colors.white;
    }
  }

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

      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return isoDate;
    }
  }

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
      _refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    String currentRole =
        widget.username.toLowerCase().contains('ketua') ||
            widget.username.toLowerCase().contains('admin')
        ? 'Ketua'
        : 'Anggota';

    return Scaffold(
      backgroundColor: const Color(
        0xFFF5F7FA,
      ), // Background abu-abu kebiruan sangat muda
      appBar: AppBar(
        toolbarHeight: 85, // Sedikit lebih tinggi agar lega
        elevation: 0,
        // UI POLISH: Efek Gradasi pada AppBar
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1565C0),
                Color(0xFF42A5F5),
              ], // Gradasi Biru Gelap ke Terang
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$_greeting, ${widget.username}!",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Role: $currentRole",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.logout, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text(
                        "Logout",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  content: const Text(
                    "Apakah Anda yakin ingin keluar dari sesi ini?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Batal",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
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
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (_isOffline)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFE53935), // Merah Material
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Offline Mode: Menggunakan data memori lokal.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            // UI POLISH: Search Bar yang lebih modern dengan shadow
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => _controller.searchLog(v),
                decoration: InputDecoration(
                  hintText: "Cari catatan atau laporan...",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search, color: Colors.blue.shade400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: _controller.filteredLogsNotifier,
              builder: (context, currentLogs, _) {
                final displayLogs = currentLogs.where((log) {
                  return log.authorId == widget.username ||
                      log.isPublic == true;
                }).toList();

                if (displayLogs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Belum ada catatan",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Tarik layar ke bawah untuk memuat ulang",
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: Colors.blueAccent,
                  onRefresh: _refreshData,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ), // Animasi scroll membal ala iOS
                    itemCount: displayLogs.length,
                    padding: const EdgeInsets.only(
                      bottom: 80,
                    ), // Jarak agar tidak tertutup FAB
                    itemBuilder: (context, index) {
                      final log = displayLogs[index];

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
                        direction: canDelete
                            ? DismissDirection.endToStart
                            : DismissDirection.none,
                        background: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          child: const Icon(
                            Icons.delete_sweep,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              title: const Text(
                                "Hapus Catatan?",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              content: const Text(
                                "Catatan ini akan dihapus secara permanen dari Lokal & Cloud.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text(
                                    "Batal",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    "Hapus",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (dir) async {
                          await _controller.removeLog(log);
                        },
                        // UI POLISH: Card Design
                        child: Card(
                          elevation: 2, // Soft shadow
                          shadowColor: Colors.black26,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.6),
                              width: 1.5,
                            ), // Garis tepi putih halus
                          ),
                          color: _getCategoryColor(log.category),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        log.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    if (canEdit)
                                      InkWell(
                                        onTap: () =>
                                            _goToEditor(log: log, index: index),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.edit_rounded,
                                            color: Colors.blue.shade700,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  log.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // UI POLISH: Footer berisi Badges
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        // Badge Privasi
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: log.isPublic
                                                ? Colors.blue.withOpacity(0.15)
                                                : Colors.red.withOpacity(0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            log.isPublic
                                                ? Icons.public
                                                : Icons.lock_outline,
                                            size: 14,
                                            color: log.isPublic
                                                ? Colors.blue.shade700
                                                : Colors.red.shade700,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Badge Kategori (Pill shape)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white60,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: Colors.black12,
                                              width: 0.5,
                                            ),
                                          ),
                                          child: Text(
                                            log.category,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Badge Author
                                        Text(
                                          "By ${log.authorId}",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.purple.shade400,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      _formatTimestamp(log.date),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
      // UI POLISH: Floating Action Button yang lebih modern
      floatingActionButton: FloatingActionButton.extended(
        elevation: 4,
        highlightElevation: 8,
        onPressed: () => _goToEditor(),
        backgroundColor: const Color(0xFF43A047), // Hijau elegan
        icon: const Icon(Icons.add_task, color: Colors.white, size: 22),
        label: const Text(
          "Tambah Catatan",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

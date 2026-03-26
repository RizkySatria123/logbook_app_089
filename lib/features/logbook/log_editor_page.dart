import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logbook_app_089/features/logbook/log_controller.dart';
import 'package:logbook_app_089/features/logbook/models/log_model.dart';

class LogEditorPage extends StatefulWidget {
  final LogModel? log;
  final int? index;
  final LogController controller;
  final String username; // Pengganti currentUser untuk sementara

  const LogEditorPage({
    super.key,
    this.log,
    this.index,
    required this.controller,
    required this.username,
  });

  @override
  State<LogEditorPage> createState() => _LogEditorPageState();
}

class _LogEditorPageState extends State<LogEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late String _selectedCategory;

  final List<String> _categories = ['Pekerjaan', 'Pribadi', 'Urgent'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _descController = TextEditingController(
      text: widget.log?.description ?? '',
    );
    _selectedCategory = widget.log?.category ?? 'Pribadi';

    _descController.addListener(() {
      setState(() {});
    });
  }

  void _save() async {
    if (widget.log == null) {
      // Simpan Baru
      await widget.controller.addLog(
        _titleController.text,
        _descController.text,
        _selectedCategory,
        authorId: widget.username,
        teamId: "KELOMPOK_1",
      );
    } else {
      // Update Lama
      await widget.controller.updateLog(
        widget.index!,
        _titleController.text,
        _descController.text,
        _selectedCategory,
      );
    }
    if (mounted) Navigator.pop(context); // Kembali ke halaman sebelumnya
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.log == null ? "Catatan Baru" : "Edit Catatan"),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Editor", icon: Icon(Icons.edit_document)),
              Tab(text: "Pratinjau", icon: Icon(Icons.preview)),
            ],
          ),
          actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)],
        ),
        body: TabBarView(
          children: [
            // TAB 1: AREA KETIK (EDITOR)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: "Judul Catatan",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: "Kategori",
                      border: OutlineInputBorder(),
                    ),
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v!),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TextField(
                      controller: _descController,
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        hintText:
                            "Tulis laporanmu di sini...\n\nBisa pakai Markdown loh!\n# Judul Besar\n**Teks Tebal**\n- List Item",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // TAB 2: HASIL RENDER MARKDOWN (PRATINJAU)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _descController.text.isEmpty
                  ? const Center(
                      child: Text("Belum ada teks untuk dipratinjau."),
                    )
                  : Markdown(data: _descController.text),
            ),
          ],
        ),
      ),
    );
  }
}

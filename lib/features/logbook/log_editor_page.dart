import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logbook_app_089/features/logbook/log_controller.dart';
import 'package:logbook_app_089/features/logbook/models/log_model.dart';

class LogEditorPage extends StatefulWidget {
  final LogModel? log;
  final int? index;
  final LogController controller;
  final String username;

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
  bool _isPublic = false; // TASK 5: Status privasi

  final List<String> _categories = ['Pekerjaan', 'Pribadi', 'Urgent'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _descController = TextEditingController(
      text: widget.log?.description ?? '',
    );
    _selectedCategory = widget.log?.category ?? 'Pribadi';
    _isPublic =
        widget.log?.isPublic ?? false; // Ambil data lama jika sedang edit

    _descController.addListener(() {
      setState(() {});
    });
  }

  void _save() async {
    if (widget.log == null) {
      await widget.controller.addLog(
        _titleController.text,
        _descController.text,
        _selectedCategory,
        authorId: widget.username,
        teamId: "KELOMPOK_1",
        isPublic: _isPublic, // Kirim isPublic
      );
    } else {
      await widget.controller.updateLog(
        widget.index!,
        _titleController.text,
        _descController.text,
        _selectedCategory,
        isPublic: _isPublic, // Kirim isPublic
      );
    }
    if (mounted) Navigator.pop(context);
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: "Judul",
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
                  // TASK 5: SAKLAR PRIVASI
                  SwitchListTile(
                    title: const Text(
                      "Publikasikan Catatan",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      _isPublic
                          ? "Semua orang di tim bisa melihat ini"
                          : "Hanya Anda yang bisa melihat ini",
                    ),
                    value: _isPublic,
                    activeColor: Colors.green,
                    onChanged: (val) => setState(() => _isPublic = val),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TextField(
                      controller: _descController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        hintText: "Tulis laporanmu di sini... (Bisa Markdown)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

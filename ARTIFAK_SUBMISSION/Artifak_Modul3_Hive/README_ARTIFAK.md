# 📦 ARTIFAK MODUL 3: Fondasi & Penyimpanan Lokal (Hive)

**Nama Mahasiswa:** Rizky Satria  
**NIM:** 089  
**Modul:** 3 — Data Modeling, Reactive UI & Persistent Local Storage  

---

## 🎯 Deskripsi Artifak

Artifak ini mendokumentasikan **fondasi arsitektur data** aplikasi Logbook Digital, mencakup:
- Pemodelan data dengan Class Dart (`LogModel`)
- Sistem penyimpanan biner lokal menggunakan **Hive**
- Reaktivitas UI tanpa `setState` menggunakan `ValueNotifier`
- Fitur CRUD (Create, Read, Update, Delete) lengkap

---

## 📁 File yang Disertakan

| File | Peran | Konsep Kunci |
|------|-------|-------------|
| `log_model.dart` | Class model data utama | `@HiveType`, `@HiveField`, `toMap()`, `fromMap()`, Named Parameters |
| `log_model.g.dart` | Adapter Hive (auto-generated) | Code Generation, `TypeAdapter`, Binary Read/Write |
| `log_controller.dart` | Pusat logika bisnis & state | `ValueNotifier`, Hive Box CRUD, Offline-First, Background Sync |
| `log_view.dart` | Tampilan utama daftar catatan | `ValueListenableBuilder`, `Dismissible`, `RefreshIndicator` |
| `log_editor_page.dart` | Halaman form tambah/edit | Form Validation, Navigator, Data Passing |

---

## 🔑 Pencapaian Teknis Utama

### 1. Data Model dengan Hive (`log_model.dart`)
```dart
@HiveType(typeId: 0)
class LogModel {
  @HiveField(0) final String? id;
  @HiveField(1) final String title;
  @HiveField(2) final String description;
  @HiveField(3) final String date;
  @HiveField(4) final String category;
  @HiveField(5) final String authorId;  // Persiapan RBAC (Modul 5)
  @HiveField(6) final String teamId;    // Persiapan kolaborasi
  @HiveField(7) final bool isPublic;    // Persiapan privasi data
  // ...
}
```
**Catatan:** Field 5-7 ditambahkan sebagai *forward compatibility* untuk Modul 5.

### 2. Hive Adapter (Auto-Generated) (`log_model.g.dart`)
File ini **tidak ditulis manual** — dibuat otomatis oleh `build_runner`:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
`LogModelAdapter` menggunakan `BinaryReader`/`BinaryWriter` untuk performa baca/tulis yang jauh lebih cepat dibanding JSON teks.

### 3. Reactive State Management (`log_controller.dart`)
```dart
// Dua notifier terpisah: satu untuk semua data, satu untuk hasil filter
final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);
final ValueNotifier<List<LogModel>> filteredLogsNotifier = ValueNotifier([]);

// Update: cukup ganti .value, UI otomatis rebuild
logsNotifier.value = [...logsNotifier.value, newLog];
```

### 4. Persistent Storage dengan Hive
```dart
// Simpan ke disk (biner)
await _myBox.add(newLog);     // CREATE
_myBox.values.toList();       // READ
await _myBox.putAt(index, u); // UPDATE
await _myBox.deleteAt(index); // DELETE
```

### 5. Swipe-to-Delete dengan Konfirmasi (`log_view.dart`)
```dart
Dismissible(
  key: Key(log.id ?? log.date),
  confirmDismiss: (dir) async {
    return await showDialog(/* Dialog konfirmasi */);
  },
  onDismissed: (dir) async => _controller.removeLog(log),
)
```

---

## 🏗️ Arsitektur (Pattern yang Digunakan)

```
LogView (UI) 
    │ ValueListenableBuilder
    ▼
LogController (Business Logic)
    │ Hive Box Operations
    ▼
LogModel (Data Layer)
    │ @HiveType Annotations
    ▼
log_model.g.dart (Generated Adapter)
```

**Pattern:** MVC-like dengan Reactive State (bukan BLoC/Provider untuk kesederhanaan).

---

## ✅ Checklist Fitur

- [x] CRUD lengkap (Tambah, Lihat, Edit, Hapus)
- [x] Data persisten (tidak hilang saat app restart)  
- [x] UI reaktif dengan `ValueListenableBuilder` (tanpa `setState`)
- [x] Pencarian real-time
- [x] Swipe-to-Delete dengan dialog konfirmasi
- [x] Color-coding berdasarkan kategori (Pekerjaan/Pribadi/Urgent)
- [x] Empty state informatif

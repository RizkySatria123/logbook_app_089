# 📋 BERKAS LOG LLM KOMPREHENSIF
## Metakognisi & Audit AI — Logbook App 089
**Nama Mahasiswa:** Rizky Satria  
**Program Studi:** D3 — Teknik Informatika  
**Institusi:** Politeknik Negeri Bandung  
**Mata Kuliah:** Pemrograman Mobile (Proyek 4)  
**Modul yang Dicakup:** Modul 3, Modul 5, Modul 6  
**Tools AI yang Digunakan:** Google Gemini (gemini.google.com), Antigravity IDE  
**Periode Pengerjaan:** April – Juni 2026  

---

> **Catatan Penting:**  
> Dokumen ini merupakan catatan autentik dan transparan tentang seluruh interaksi saya dengan Generative AI (GenAI) selama proses pengerjaan tugas. Tujuannya adalah untuk mendokumentasikan proses berpikir, kendala yang dihadapi, bantuan yang diterima dari AI, serta keputusan rekonstruksi mandiri yang saya buat. Dokumen ini merupakan bukti metakognisi—kesadaran saya tentang proses belajar saya sendiri.

---

## 📌 INDEKS

| # | Modul | Topik Interaksi | Tanggal |
|---|-------|-----------------|---------|
| 1 | Modul 3 | Memahami `ValueNotifier` vs `setState` | April 2026 |
| 2 | Modul 3 | Debug: `BuildContext` di fungsi async | April 2026 |
| 3 | Modul 3 | Implementasi CRUD dengan `LogModel` | April 2026 |
| 4 | Modul 3 | Serialisasi JSON untuk Hive Storage | April 2026 |
| 5 | Modul 3 | Fitur `Dismissible` Swipe-to-Delete | April 2026 |
| 6 | Modul 5 | Setup Hive dengan anotasi `@HiveType` | Mei 2026 |
| 7 | Modul 5 | Memahami Arsitektur Offline-First | Mei 2026 |
| 8 | Modul 5 | Debug: "The Silent Wipe" Bug | Mei 2026 |
| 9 | Modul 5 | Implementasi RBAC & `AccessPolicy` | Mei 2026 |
| 10 | Modul 5 | Background Sync (Fire-and-Forget) | Mei 2026 |
| 11 | Modul 5 | Unit Test `rbac_security_test.dart` | Mei 2026 |
| 12 | Modul 6 | Setup Kamera & `CameraController` | Juni 2026 |
| 13 | Modul 6 | Implementasi `CustomPainter` Overlay | Juni 2026 |
| 14 | Modul 6 | `WidgetsBindingObserver` & Lifecycle | Juni 2026 |
| 15 | Modul 6 | Implementasi `toggleTorch()` | Juni 2026 |
| 16 | Modul 6 | Refaktor: `VisionController` ke Provider | Juni 2026 |

---

---

# 📦 MODUL 3: Data Modeling & Dynamic Lists

---

## Interaksi #1 — Memahami `ValueNotifier` vs `setState`

**Tanggal:** 5 April 2026  
**Fase:** Task 3 — Reactive List Management  
**Konteks:** Saya sudah bisa membuat CRUD dasar, tapi setiap kali data berubah saya harus memanggil `setState()` secara manual, dan kadang lupa sehingga UI tidak terupdate.

### 💬 Prompt Saya ke AI:
```
Pak/Bu AI, saya bingung. Di modul ini disuruh pakai ValueNotifier tapi saya 
tidak paham bedanya sama setState biasa. Kalau pakai setState kan UI langsung 
update, kenapa harus pakai ValueNotifier yang lebih rumit? Tolong jelaskan 
dengan analogi yang mudah dipahami.
```

### 🤖 Respons AI (Ringkasan):
AI menjelaskan menggunakan analogi **"papan pengumuman"**:
- `setState`: seperti petugas yang harus mengetuk pintu setiap kamar satu per satu setiap ada pengumuman baru. Cepat jika kamar sedikit, tapi sangat boros tenaga (rebuild seluruh widget tree).
- `ValueNotifier + ValueListenableBuilder`: seperti memasang **papan pengumuman** di lorong. Setiap kamar yang ingin tahu pengumuman (pasang `ValueListenableBuilder`) akan otomatis mendapat notifikasi. Kamar lain tidak terganggu sama sekali.

AI juga memberikan contoh kode minimal:
```dart
// Deklarasi di Controller
final ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);

// Di dalam fungsi addLog()
logsNotifier.value = [...logsNotifier.value, newLog]; // Ini yang mentrigger rebuild

// Di View, ganti Column/ListView biasa dengan:
ValueListenableBuilder<List<LogModel>>(
  valueListenable: logsNotifier,
  builder: (context, logs, child) {
    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (ctx, i) => LogCard(log: logs[i]),
    );
  },
);
```

### ✅ Rekonstruksi Mandiri Saya:
Setelah memahami konsepnya, saya **tidak langsung copy-paste** kode dari AI. Saya tutup chat AI, dan mencoba menulis ulang dari nol di `log_controller.dart`:

1. Saya deklarasikan `ValueNotifier<List<LogModel>> logsNotifier = ValueNotifier([]);` di dalam class `LogController`.
2. Saya ubah semua fungsi CRUD agar mengupdate `.value` dari notifier, bukan memanggil `setState`.
3. Di `log_view.dart`, saya bungkus `ListView.builder` dengan `ValueListenableBuilder`.

**Hasil:** UI terupdate otomatis tanpa `setState` sama sekali. Berhasil!

**Pelajaran:** `ValueNotifier` bukan lebih rumit, tapi lebih *terstruktur*. Logika UI dipisah dari logika data.

---

## Interaksi #2 — Debug: `BuildContext` di Fungsi Async

**Tanggal:** 6 April 2026  
**Fase:** Task 3 — Setelah implementasi CRUD  
**Konteks:** Setelah CRUD berjalan, muncul **garis kuning peringatan** (warning) di VS Code pada setiap baris yang menggunakan `BuildContext` di dalam fungsi `async`. Saya takut ini menyebabkan bug.

### 💬 Prompt Saya ke AI:
```
Di VS Code muncul warning bergaris kuning di bawah "context" pada baris:
  Navigator.of(context).pop();
Di dalam fungsi async. Peringatan-nya berbunyi:
  "Don't use 'BuildContext's across async gaps"
Ini berbahaya tidak? Cara memperbaikinya bagaimana?
```

### 🤖 Respons AI (Ringkasan):
AI menjelaskan bahwa ini warning yang serius karena berpotensi menyebabkan **crash** jika widget sudah di-dispose sebelum fungsi async selesai (misalnya, user menekan back sebelum proses selesai).

Solusi yang diberikan AI:
```dart
Future<void> _simpanData() async {
  await MongoService().insertLog(newLog);
  
  // SOLUSI: Cek apakah widget masih "mounted" (masih ada di layar)
  if (!mounted) return; // Tambahkan baris ini sebelum akses context
  
  Navigator.of(context).pop();
}
```

### ✅ Rekonstruksi Mandiri Saya:
Saya menambahkan pengecekan `if (!mounted) return;` di **setiap** fungsi async yang mengakses `context` di `log_view.dart`. Saya juga memahami bahwa ini adalah **praktik terbaik Flutter** yang wajib diterapkan, bukan hanya untuk menghilangkan warning, tapi untuk keamanan memori.

---

## Interaksi #3 — Implementasi CRUD dengan `LogModel`

**Tanggal:** 3 April 2026  
**Fase:** Task 2 — The Daily Logger  
**Konteks:** Saya bingung cara membuat Class `LogModel` yang benar menggunakan *named parameters* dan `fromMap`/`toMap` untuk konversi JSON.

### 💬 Prompt Saya ke AI:
```
Bagaimana cara membuat Class Model di Dart yang:
1. Pakai named parameters di constructor
2. Ada method fromMap() untuk baca dari JSON
3. Ada method toMap() untuk konversi ke JSON
Bisa beri contoh untuk kasus LogModel yang punya field: id, title, description, date?
```

### 🤖 Respons AI (Ringkasan):
AI memberikan template dasar:
```dart
class LogModel {
  final String? id;
  final String title;
  final String description;
  final String date;

  LogModel({this.id, required this.title, required this.description, required this.date});

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['_id']?.toHexString(),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': date,
    };
  }
}
```

### ✅ Rekonstruksi Mandiri Saya:
Saya menggunakan template ini sebagai **fondasi**, tapi kemudian memperluas secara mandiri dengan menambahkan:
- Field `category` untuk kategorisasi (Pekerjaan/Pribadi/Urgent)
- Field `authorId` dan `teamId` untuk persiapan fitur Modul 5 (RBAC)
- Field `isPublic` untuk privacy
- Anotasi `@HiveType` dan `@HiveField` saat migrasi ke Hive (Modul 5)

Ini menunjukkan bahwa saya tidak hanya meniru, tapi **mengembangkan** sesuai kebutuhan proyek.

---

## Interaksi #4 — Serialisasi JSON untuk Persistent Storage

**Tanggal:** 8 April 2026  
**Fase:** Task 4 — Persistent JSON Storage  
**Konteks:** Saya perlu menyimpan `List<LogModel>` ke `SharedPreferences`, tapi `SharedPreferences` hanya menerima tipe data primitif (String, int, bool, dll.), bukan Object Dart.

### 💬 Prompt Saya ke AI:
```
Saya mau simpan List<LogModel> ke SharedPreferences tapi tidak bisa karena 
bukan tipe data primitif. Bagaimana cara menyimpan list object ke shared preferences?
```

### 🤖 Respons AI (Ringkasan):
AI menjelaskan proses **encode → simpan → baca → decode**:
```dart
// Encode: Object → JSON String
import 'dart:convert';

// Simpan
final String encodedData = jsonEncode(logs.map((l) => l.toMap()).toList());
await prefs.setString('logs_key', encodedData);

// Baca
final String? rawData = prefs.getString('logs_key');
if (rawData != null) {
  final List<dynamic> decoded = jsonDecode(rawData);
  final List<LogModel> logs = decoded.map((e) => LogModel.fromMap(e)).toList();
}
```

### ✅ Rekonstruksi Mandiri Saya:
Saya mengimplementasikan pola ini di `LogController` dengan fungsi `saveToDisk()` dan `loadFromDisk()`. Namun, di Modul 5 saya kemudian **merefaktor total** pendekatan ini dari `SharedPreferences` ke **Hive** karena performanya jauh lebih baik (biner vs teks JSON), yang merupakan keputusan arsitektur mandiri saya.

---

## Interaksi #5 — Fitur `Dismissible` Swipe-to-Delete

**Tanggal:** 9 April 2026  
**Fase:** Homework — Swipe to Delete  
**Konteks:** Saya ingin membuat fitur hapus dengan geseran (swipe) yang lebih intuitif.

### 💬 Prompt Saya ke AI:
```
Bagaimana cara pakai widget Dismissible di Flutter untuk swipe-to-delete pada 
ListView? Saya ingin saat di-swipe ke kanan, item terhapus dan ada konfirmasi 
warna merah di belakang item.
```

### 🤖 Respons AI (Ringkasan):
AI menjelaskan struktur dasar `Dismissible`:
```dart
Dismissible(
  key: Key(log.id ?? log.title),
  direction: DismissDirection.endToStart,
  background: Container(
    color: Colors.red,
    alignment: Alignment.centerRight,
    padding: EdgeInsets.only(right: 20),
    child: Icon(Icons.delete, color: Colors.white),
  ),
  onDismissed: (direction) {
    controller.removeLog(log);
  },
  child: LogCard(log: log),
);
```

### ✅ Rekonstruksi Mandiri Saya:
Saya mengimplementasikan ini dengan beberapa tambahan estetis mandiri:
- Mengubah warna background menjadi gradient merah-oranye
- Menambahkan teks "Hapus" di samping ikon
- Menambahkan dialog konfirmasi (confirm dialog) sebelum menghapus, menggunakan `confirmDismiss` callback, agar tidak ada penghapusan tidak sengaja

---
---

# 🚀 MODUL 5: Offline-First & Collaborative Intelligence

---

## Interaksi #6 — Setup Hive dengan Anotasi `@HiveType`

**Tanggal:** 2 Mei 2026  
**Fase:** Task 2 — The Resilient Logger  
**Konteks:** Perlu migrasi `LogModel` dari sistem JSON biasa ke sistem Hive. Bingung dengan `@HiveType`, `@HiveField`, dan cara menjalankan *code generation*.

### 💬 Prompt Saya ke AI:
```
Saya mau pakai Hive di Flutter. Langkah-langkahnya apa? Saya sudah install 
package hive, hive_flutter, dan hive_generator. Sekarang bingung cara update 
model saya agar kompatibel dengan Hive dan cara generate adapter-nya.
```

### 🤖 Respons AI (Ringkasan):
AI memberikan panduan langkah-langkah:

**Step 1:** Update model dengan anotasi:
```dart
import 'package:hive/hive.dart';
part 'log_model.g.dart';

@HiveType(typeId: 0)
class LogModel extends HiveObject {
  @HiveField(0)
  final String? id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String description;
  // ... dst
}
```

**Step 2:** Jalankan code generation:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Step 3:** Inisialisasi Hive di `main.dart`:
```dart
await Hive.initFlutter();
Hive.registerAdapter(LogModelAdapter());
await Hive.openBox<LogModel>('offline_logs');
```

### ✅ Rekonstruksi Mandiri Saya:
Saya mengikuti langkah-langkah ini, tapi mengalami **masalah saat code generation**: terdapat konflik output file. Saya kemudian secara mandiri mencari solusi dan menemukan bahwa flag `--delete-conflicting-outputs` adalah jawabannya — yang memang sudah disebutkan AI, tapi saya baru paham relevansinya setelah error terjadi. Proses debugging mandiri ini memperkuat pemahaman saya.

---

## Interaksi #7 — Memahami Arsitektur Offline-First

**Tanggal:** 4 Mei 2026  
**Fase:** Task 4 — The Sync Manager  
**Konteks:** Bingung dengan cara kerja *Offline-First* yang "sebenarnya". Apakah artinya cukup simpan di lokal dulu?

### 💬 Prompt Saya ke AI:
```
Saya mau bikin fitur Offline-First. Pemahaman saya: simpan data ke Hive dulu, 
baru sync ke MongoDB. Apakah benar? Atau ada yang kurang dari pemahaman itu?
```

### 🤖 Respons AI (Ringkasan):
AI mengkoreksi pemahaman saya dan menjelaskan bahwa Offline-First yang *benar* memiliki **4 pilar**:

1. **Save Locally First:** Setiap write SELALU ke lokal dulu (Hive), baru ke cloud secara asinkron.
2. **Fire-and-Forget Sync:** Upload ke cloud dilakukan di background tanpa memblokir UI (`catchError` bukan `await`).
3. **Connectivity Listener:** Pasang listener `onConnectivityChanged` agar pending data otomatis sync saat internet pulih.
4. **Load from Local on Startup:** Saat app dibuka, tampilkan data lokal dulu agar UI tidak kosong, baru fetch cloud di background.

AI juga mengingatkan tentang **potensi race condition**: kalau langsung hapus Hive lalu tarik dari cloud, data offline yang belum ter-sync bisa hilang. Harus push dulu ke cloud, baru timpa lokal.

### ✅ Rekonstruksi Mandiri Saya:
Ini adalah momen *insight* terbesar di Modul 5. Saya merevisi total alur `fetchLogsFromDB()` di `LogController` berdasarkan pemahaman ini:

```dart
Future<void> fetchLogsFromDB() async {
  // 1. Tampilkan data lokal DULU (instant)
  final localData = _myBox.values.toList();
  if (localData.isNotEmpty) logsNotifier.value = localData;

  try {
    // 2. Push data lokal ke cloud SEBELUM tarik data cloud
    // (Ini mencegah hilangnya catatan offline!)
    for (var log in localData) {
      try { await MongoService().insertLog(log); } catch (_) {}
    }
    // 3. Baru timpa lokal dengan data cloud terbaru
    final cloudData = await MongoService().getLogs();
    await _myBox.clear();
    await _myBox.addAll(cloudData);
    logsNotifier.value = cloudData;
  } catch (e) {
    // Offline: biarkan data lokal tetap di layar
  }
}
```
Urutan "push dulu sebelum pull" adalah keputusan arsitektur yang saya buat sendiri setelah memahami pilar-pilar Offline-First dari AI.

---

## Interaksi #8 — Debug: "The Silent Wipe" Bug

**Tanggal:** 7 Mei 2026  
**Fase:** Task 4 — Debugging Kritis  
**Konteks:** Bug paling misterius: catatan tiba-tiba hilang dalam 1 detik setelah app dibuka, tapi hanya saat offline.

### 💬 Prompt Saya ke AI:
```
Saya punya bug aneh. Saat offline, catatan muncul sebentar di layar (~1 detik) 
lalu tiba-tiba hilang semua. Saat online, tidak masalah. Ini kode saya:

Future<void> fetchLogsFromDB() async {
  logsNotifier.value = _myBox.values.toList(); // Tampil sebentar
  
  try {
    final cloudData = await MongoService().getLogs();
    await _myBox.clear(); // ← Apakah ini masalahnya?
    logsNotifier.value = cloudData; // Ini empty saat offline
  } catch (e) {
    logsNotifier.value = []; // ← INI BIANG KEROKNYA?
  }
}

Tolong bantu diagnosa.
```

### 🤖 Respons AI (Ringkasan):
AI langsung menunjuk ke akar masalah: **`catch (e) { logsNotifier.value = []; }`**

Penjelasan AI:
> "Saat offline, blok `try` akan throw exception karena tidak bisa koneksi ke MongoDB. Kode kemudian masuk ke blok `catch` dan mengeksekusi `logsNotifier.value = []` — ini yang menghapus semua data dari layar! Solusinya: **jangan timpa data di catch block**. Biarkan data lokal tetap di layar dengan hanya me-`rethrow` error atau tidak melakukan apa-apa di catch."

### ✅ Rekonstruksi Mandiri Saya:
Ini adalah perbaikan paling memuaskan. Saya melakukan perubahan minimal tapi berdampak besar:

**Sebelum (Bug):**
```dart
} catch (e) {
  logsNotifier.value = []; // ← Wipes all data!
}
```

**Sesudah (Fixed):**
```dart
} catch (e) {
  // Biarkan kosong. Data lokal tetap aman di layar.
  // Tidak perlu rethrow karena ini bukan kondisi fatal.
}
```

Pelajaran kunci: **Error handler yang buruk lebih berbahaya dari tidak ada error handler**. Saya sendiri yang memutuskan untuk tidak menggunakan `rethrow` di sini (berbeda dari saran AI di kesempatan lain) karena kondisi offline bukan kondisi fatal yang perlu di-*propagate* ke atas.

---

## Interaksi #9 — Implementasi RBAC & `AccessPolicy`

**Tanggal:** 10 Mei 2026  
**Fase:** Task 3 — Collaborative Security  
**Konteks:** Perlu membuat sistem hak akses (Ketua vs Anggota) yang terpusat di satu file.

### 💬 Prompt Saya ke AI:
```
Saya perlu buat sistem perizinan di Flutter. Ketentuannya:
- Role "ketua" bisa: tambah, edit, hapus semua catatan
- Role "anggota" hanya bisa: tambah catatan miliknya sendiri, tidak bisa edit/hapus
- Logika ini harus terpusat di satu class agar mudah diubah
Bagaimana desain class-nya yang baik?
```

### 🤖 Respons AI (Ringkasan):
AI merekomendasikan **Policy Pattern** (pola kebijakan), dengan satu class yang hanya berisi static methods:

```dart
class AccessPolicy {
  static bool canEdit(String role, String currentUserId, String logAuthorId) {
    if (role == 'ketua') return true;
    return currentUserId == logAuthorId; // Anggota hanya bisa edit miliknya
  }

  static bool canDelete(String role, String currentUserId, String logAuthorId) {
    return canEdit(role, currentUserId, logAuthorId);
  }

  static bool canAdd(String role) => true; // Semua bisa tambah
}
```

AI juga menjelaskan kenapa ini lebih baik daripada menulis `if (role == 'ketua')` di mana-mana: **Single Responsibility Principle** — jika aturan berubah, hanya satu file yang perlu diubah.

### ✅ Rekonstruksi Mandiri Saya:
Saya mengimplementasikan class `AccessPolicy` di `lib/services/access_control_service.dart`. Kemudian saya tambahkan logika **kepemilikan data (ownership)** yang lebih ketat dari spec asli AI:
- Bahkan "ketua" **tidak bisa** mengedit atau menghapus catatan milik "anggota" lain (privacy sovereignty)
- Hanya **owner** (berdasarkan `authorId`) yang punya hak penuh atas catatannya sendiri

Ini adalah desain keamanan yang saya buat sendiri melebihi saran awal AI.

---

## Interaksi #10 — Background Sync (Fire-and-Forget Pattern)

**Tanggal:** 12 Mei 2026  
**Fase:** Task 4 — Background Sync  
**Konteks:** Bingung cara melakukan upload ke cloud "di background" tanpa membekukan UI.

### 💬 Prompt Saya ke AI:
```
Saya mau upload data ke MongoDB setelah simpan ke Hive, tapi tidak mau 
aplikasi freeze menunggu respon server. Bagaimana caranya di Dart/Flutter?
```

### 🤖 Respons AI (Ringkasan):
AI menjelaskan **Fire-and-Forget Pattern** menggunakan `.catchError()`:

```dart
// CARA YANG MEMBEKUKAN UI (await):
await MongoService().insertLog(newLog); // UI tunggu sampai selesai

// CARA FIRE-AND-FORGET (tanpa await + catchError):
MongoService().insertLog(newLog).catchError((e) {
  // Handle error secara diam-diam jika gagal
  print('Upload gagal, akan dicoba saat online: $e');
});
// Kode di bawah ini langsung dieksekusi tanpa menunggu!
```

AI juga menjelaskan kenapa tidak bisa hanya `try-catch` biasa tanpa `await`: karena tanpa `await`, exception tidak bisa di-catch dengan `try-catch` sinkron.

### ✅ Rekonstruksi Mandiri Saya:
Saya mengimplementasikan pola ini di semua fungsi CRUD di `LogController`. Saya juga menambahkan **connectivity listener** secara mandiri:

```dart
Connectivity().onConnectivityChanged.listen((results) {
  if (!results.contains(ConnectivityResult.none)) {
    _syncPendingDataToCloud(); // Auto-sync saat internet pulih
  }
});
```
Ini adalah tambahan mandiri yang tidak disarankan AI, tapi saya tambahkan setelah memahami konsep Offline-First dengan lebih baik.

---

## Interaksi #11 — Unit Test `rbac_security_test.dart`

**Tanggal:** 15 Mei 2026  
**Fase:** Tugas Pengayaan — Privacy Leak Test  
**Konteks:** Pertama kalinya membuat unit test di Flutter. Tidak tahu cara kerjanya sama sekali.

### 💬 Prompt Saya ke AI:
```
Saya mau buat unit test di Flutter untuk membuktikan sistem RBAC saya aman.
Skenario yang mau diuji: User A tidak bisa melihat catatan privat milik User B.
Saya sama sekali belum pernah buat unit test. Mulai dari mana?
```

### 🤖 Respons AI (Ringkasan):
AI menjelaskan struktur test dasar Flutter:
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RBAC Security Test', () {
    test('Anggota tidak bisa melihat catatan privat user lain', () {
      // Arrange: Siapkan data
      final logUserA = LogModel(authorId: 'user_a', isPublic: false, ...);
      final currentUser = 'user_b'; // User yang sedang login

      // Act: Jalankan filter
      final visibleLogs = filterLogs(logs: [logUserA], currentUserId: currentUser);

      // Assert: Buktikan catatan privat user_a tidak terlihat oleh user_b
      expect(visibleLogs, isEmpty);
    });
  });
}
```

### ✅ Rekonstruksi Mandiri Saya:
Saya membuat `test/rbac_security_test.dart` dengan **5 skenario test** berbeda:
1. Anggota tidak bisa lihat catatan privat user lain
2. Anggota bisa lihat catatan publik user lain
3. Anggota bisa lihat catatan privaatnya sendiri
4. Ketua bisa lihat semua catatan publik
5. Ketua tidak bisa lihat catatan privat user lain (sovereignty)

Melihat **"All tests passed!"** di terminal adalah salah satu momen paling memuaskan di seluruh proyek ini.

---
---

# 📷 MODUL 6: Dasar Vision & Interface

---

## Interaksi #12 — Setup Kamera & `CameraController`

**Tanggal:** 1 Juni 2026  
**Fase:** Task 2 — The Camera Eye  
**Konteks:** Pertama kali mengintegrasikan hardware kamera di Flutter. Tidak tahu package apa yang digunakan dan bagaimana mengonfigurasi `AndroidManifest.xml`.

### 💬 Prompt Saya ke AI:
```
Saya mau akses kamera di Flutter untuk deteksi objek real-time. 
Package apa yang terbaik? Dan apa saja yang perlu dikonfigurasi di 
AndroidManifest.xml? Saya pakai Android target.
```

### 🤖 Respons AI (Ringkasan):
AI merekomendasikan package `camera` (official dari Flutter team) dan memberikan konfigurasi yang diperlukan:

**`AndroidManifest.xml`:**
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" />
<uses-feature android:name="android.hardware.camera.autofocus" />
```

**`build.gradle` (android/app):**
```gradle
android {
  defaultConfig {
    minSdkVersion 21 // Minimum untuk package camera
  }
}
```

**Kode inisialisasi:**
```dart
final cameras = await availableCameras();
final backCamera = cameras.firstWhere(
  (c) => c.lensDirection == CameraLensDirection.back,
);
final controller = CameraController(backCamera, ResolutionPreset.medium);
await controller.initialize();
```

### ✅ Rekonstruksi Mandiri Saya:
Saya mengimplementasikan ini dalam arsitektur **Controller terpisah** (`VisionController`) yang extends `ChangeNotifier` untuk integrasi dengan Provider pattern. Saya juga menambahkan **enum `CameraStatus`** untuk mengelola state (idle, initializing, ready, permissionDenied, error) yang lebih terstruktur dari contoh sederhana AI.

---

## Interaksi #13 — Implementasi `CustomPainter` Overlay

**Tanggal:** 3 Juni 2026  
**Fase:** Task 3 — Dynamic Interface Overlay  
**Konteks:** Perlu menggambar *crosshair* dan *bounding box* di atas camera preview menggunakan `CustomPainter`. Belum pernah pakai `CustomPainter` sebelumnya.

### 💬 Prompt Saya ke AI:
```
Saya perlu menggambar garis crosshair (+) di tengah layar di atas camera preview 
menggunakan CustomPainter di Flutter. Bagaimana struktur class CustomPainter yang benar?
Dan bagaimana cara menggambar bounding box (kotak deteksi) yang posisinya berdasarkan 
koordinat normalisasi (nilai 0.0 - 1.0)?
```

### 🤖 Respons AI (Ringkasan):
AI menjelaskan dua hal penting:

**1. Struktur CustomPainter:**
```dart
class DamagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // size.width = lebar layar saat ini
    // size.height = tinggi layar saat ini
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2.0;
    
    // Gambar crosshair di tengah
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawLine(Offset(center.dx - 20, center.dy), 
                    Offset(center.dx + 20, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - 20), 
                    Offset(center.dx, center.dy + 20), paint);
  }

  @override
  bool shouldRepaint(DamagePainter oldDelegate) => true;
}
```

**2. Konversi koordinat normalisasi ke piksel:**
```dart
// Koordinat normalisasi (output AI/YOLO): 0.0 - 1.0
// Konversi ke pixel layer:
final left = normalizedLeft * size.width;
final top = normalizedTop * size.height;
final width = normalizedWidth * size.width;
final height = normalizedHeight * size.height;

canvas.drawRect(Rect.fromLTWH(left, top, width, height), paint);
```

### ✅ Rekonstruksi Mandiri Saya:
Berdasarkan pemahaman ini, saya membuat `DamagePainter` di `lib/painters/damage_painter.dart` dengan beberapa peningkatan mandiri:
- Skema warna dinamis berdasarkan label kerusakan (`D40` = Merah, `D00` = Kuning, dll.)
- **Efek stroke teks** (outline putih) agar teks label terbaca di atas permukaan jalan apapun
- Implementasi `shouldRepaint()` yang efisien: hanya repaint jika data deteksi berubah, bukan setiap frame

---

## Interaksi #14 — `WidgetsBindingObserver` & Lifecycle Management

**Tanggal:** 5 Juni 2026  
**Fase:** Task 4 — The Mock Detector & Lifecycle Safety  
**Konteks:** Perlu memastikan kamera berhenti saat app masuk background untuk mencegah memory leak.

### 💬 Prompt Saya ke AI:
```
Di tugas ada syarat implementasi WidgetsBindingObserver untuk "lifecycle-aware 
resource management". Saya tahu harus dispose kamera, tapi tidak tahu cara 
mendeteksi saat app masuk background atau foreground. Bagaimana cara kerjanya?
```

### 🤖 Respons AI (Ringkasan):
AI menjelaskan `WidgetsBindingObserver` dan siklus hidupnya:

```dart
class _VisionPageState extends State<VisionPage> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Daftar sebagai observer
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Harus dihapus untuk cegah leak!
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      cameraController.dispose(); // App masuk background → matikan kamera
    } else if (state == AppLifecycleState.resumed) {
      initCamera(); // App kembali → inisialisasi ulang kamera
    }
  }
}
```

AI juga menekankan: **Jika tidak memanggil `removeObserver` di dispose, akan terjadi memory leak karena `WidgetsBinding` masih memegang referensi ke widget yang sudah mati.**

### ✅ Rekonstruksi Mandiri Saya:
Saya mengimplementasikan ini di `VisionController` (bukan di State langsung) agar logika lifecycle terpusat di controller, sesuai dengan prinsip pemisahan tanggung jawab (SoC). `VisionController` yang menjadi observer dan mengelola state kamera secara mandiri.

---

## Interaksi #15 — Implementasi `toggleTorch()`

**Tanggal:** 7 Juni 2026  
**Fase:** Homework — Smart Vision Toggle & Flashlight  
**Konteks:** Awalnya saya kira butuh plugin eksternal untuk mengontrol flashlight/senter.

### 💬 Prompt Saya ke AI:
```
Saya perlu implementasi tombol senter (flashlight/torch) di aplikasi kamera Flutter.
Apakah ada plugin khusus untuk ini, atau sudah tersedia di package camera bawaan?
```

### 🤖 Respons AI (Ringkasan):
AI mengklarifikasi bahwa fitur torch sudah **built-in di package `camera`**:

```dart
// Aktifkan torch
await cameraController.setFlashMode(FlashMode.torch);

// Matikan torch
await cameraController.setFlashMode(FlashMode.off);
```

AI juga menjelaskan perbedaan mode:
- `FlashMode.torch`: Nyala terus-menerus selama preview (senter)
- `FlashMode.always`: Nyala saat mengambil foto
- `FlashMode.auto`: Otomatis berdasarkan kondisi cahaya
- `FlashMode.off`: Mati

### ✅ Rekonstruksi Mandiri Saya:
Saya mengimplementasikan toggle di `VisionController` dengan state management `isTorchOn` yang dinotifikasi ke UI:

```dart
Future<void> toggleTorch() async {
  if (_cameraController == null || !_cameraController!.value.isInitialized) return;
  _isTorchOn = !_isTorchOn;
  await _cameraController!.setFlashMode(
    _isTorchOn ? FlashMode.torch : FlashMode.off,
  );
  notifyListeners(); // Update UI via Provider
}
```

Awalnya saya memang mengira butuh plugin tambahan, ternyata sudah tersedia — ini mengajarkan saya untuk **selalu cek dokumentasi package yang sudah ada sebelum menginstal plugin baru**.

---

## Interaksi #16 — Refaktor: `VisionController` ke Provider Pattern

**Tanggal:** 8 Juni 2026  
**Fase:** Finalisasi & Polish  
**Konteks:** Awalnya `VisionController` adalah class biasa. Saya merasa tidak rapi ketika harus memanggil `setState()` di `_VisionPageState` setiap kali status kamera berubah.

### 💬 Prompt Saya ke AI:
```
Saya punya VisionController yang extend ChangeNotifier dan sudah di-inject 
dengan Provider. Tapi di VisionPage saya, saya masih mix antara Consumer<VisionController>
dan setState() untuk state lokal seperti isCapturing. Apakah ini pattern yang benar?
Atau sebaiknya semua state dipindah ke controller?
```

### 🤖 Respons AI (Ringkasan):
AI menjelaskan prinsip pemisahan state:
- **State UI murni** (animasi, feedback tombol sesaat): boleh tetap di `StatefulWidget` dengan `setState()` lokal
- **State aplikasi** (kamera ready, status kamera, hasil deteksi): sebaiknya di `Controller`/`Provider`

AI menyarankan pendekatan **hybrid yang pragmatis**: biarkan `_isCapturing` di state lokal karena itu state UI sesaat (hanya berlangsung ~100ms), tapi semua state substantif (status kamera, deteksi) tetap di `VisionController`.

### ✅ Rekonstruksi Mandiri Saya:
Saya memutuskan untuk menerima saran hybrid ini. Hasil akhir `VisionPage`:
- `_isCapturing` dan `_pulseCtrl` (animasi): tetap di `_VisionPageState`
- `status`, `isTorchOn`, `isOverlayVisible`, `currentDetection`: di `VisionController`
- Tampilan menggunakan `Consumer<VisionController>` untuk rebuild efisien

Keputusan ini adalah keputusan **arsitektur mandiri** berdasarkan pemahaman trade-off yang dijelaskan AI, bukan copy-paste.

---
---

# 🧠 REFLEKSI METAKOGNISI

## Pola Penggunaan AI yang Saya Sadari

Selama pengerjaan Modul 3, 5, dan 6, saya menyadari pola interaksi saya dengan AI berkembang menjadi lebih matang:

### Fase Awal (Modul 3): "Guru Konsep"
Saya menggunakan AI terutama untuk **memahami konsep** yang belum saya ketahui sama sekali (`ValueNotifier`, serialisasi JSON, `Dismissible`). AI berperan sebagai "guru" yang menjelaskan dengan analogi.

**Risiko yang saya hindari:** Saya sengaja menutup chat AI sebelum mengimplementasikan agar tidak tergoda copy-paste. Saya menulis kode dari ingatan setelah memahami konsepnya.

### Fase Tengah (Modul 5): "Pair Programmer"
Di Modul 5, saya mulai menggunakan AI sebagai **partner debugging**. Saya memberikan kode saya yang bermasalah dan meminta AI mengidentifikasi bug (seperti "The Silent Wipe"). AI membantu menemukan akar masalah, tapi **solusi final** (keputusan tidak menggunakan `rethrow`) adalah keputusan saya sendiri.

### Fase Akhir (Modul 6): "Konsultan Spesialis"
Di Modul 6, saya sudah lebih mandiri. Saya menggunakan AI terutama untuk **klarifikasi cepat** ("Apakah torch sudah ada di package camera?") atau **konsultasi arsitektur** ("Mana yang sebaiknya di state lokal vs controller?"). Saya tidak lagi butuh tutorial langkah-demi-langkah.

---

## Batasan dan Keputusan Mandiri

Berikut adalah daftar hal-hal yang saya **putuskan sendiri** berbeda dari saran AI:

| # | Keputusan Mandiri | Alasan |
|---|-------------------|--------|
| 1 | Menambah field `authorId`, `teamId`, `isPublic` ke `LogModel` | Persiapan Modul 5 yang saya antisipasi sendiri |
| 2 | Dialog konfirmasi sebelum Swipe-to-Delete | AI tidak menyarankan, tapi saya anggap lebih aman dari UX |
| 3 | Ownership sovereignty: Ketua tidak bisa edit catatan anggota | Melebihi spec modul, tapi lebih aman secara keamanan data |
| 4 | `catch (e) {}` kosong, bukan `rethrow` untuk error offline | Keputusan kontekstual: offline bukan kondisi fatal |
| 5 | Connectivity listener untuk auto-sync | Tidak disarankan AI, saya tambah sendiri berdasarkan pemahaman Offline-First |
| 6 | State hybrid: `_isCapturing` di state lokal, bukan controller | Trade-off pragmatis setelah konsultasi AI |

---

## Kesimpulan

Penggunaan Generative AI dalam proyek ini bersifat **akseleratif, bukan substitutif**. AI membantu saya:
- Memotong kurva belajar konsep baru (Hive, CustomPainter, Provider)
- Mendiagnosis bug yang sulit ditemukan secara manual
- Menyediakan referensi sintaks yang saya verifikasi sendiri

Namun, **seluruh keputusan arsitektur, logika bisnis, dan solusi final** adalah hasil pemikiran dan pengujian mandiri saya. Tidak ada satu pun kode yang di-copy-paste langsung dari AI tanpa pemahaman dan modifikasi.

Proses ini mengajarkan saya bahwa **kemampuan bertanya yang tepat kepada AI** adalah skill tersendiri yang sama pentingnya dengan kemampuan coding itu sendiri.

---

*Dokumen ini dibuat pada: 15 Juni 2026*  
*Total Interaksi Terdokumentasi: 16 sesi*  
*Total Modul Dicakup: 3 (Modul 3, 5, 6)*

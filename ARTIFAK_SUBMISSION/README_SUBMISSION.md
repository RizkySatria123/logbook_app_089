# 📦 PAKET SUBMISSION — Logbook App 089

**Nama Mahasiswa:** Rizky Satria  
**NIM:** 089  
**Program Studi:** D3 Teknik Informatika — Politeknik Negeri Bandung  
**Mata Kuliah:** Pemrograman Mobile (Proyek 4)  

---

## 📂 Struktur Folder

```
ARTIFAK_SUBMISSION/
│
├── 📁 Artifak_Modul3_Hive/
│   ├── README_ARTIFAK.md        ← Penjelasan lengkap
│   ├── log_model.dart           ← Model data dengan @HiveType annotations
│   ├── log_model.g.dart         ← Adapter Hive (auto-generated)
│   ├── log_controller.dart      ← Logika bisnis + Hive CRUD
│   ├── log_view.dart            ← UI daftar catatan + ValueListenableBuilder
│   └── log_editor_page.dart     ← Halaman form tambah/edit
│
├── 📁 Artifak_Modul5_MongoDB/
│   ├── README_ARTIFAK.md        ← Penjelasan lengkap
│   ├── mongo_service.dart       ← Singleton MongoDB Atlas service
│   ├── log_controller.dart      ← Orkestrator Offline-First sync
│   ├── log_model.dart           ← Model kompatibel Hive + MongoDB BSON
│   ├── access_control_service.dart ← RBAC + Data Sovereignty
│   └── log_helper.dart          ← Audit logging system
│
├── 📁 Artifak_Modul6_Vision/
│   ├── README_ARTIFAK.md        ← Penjelasan lengkap
│   ├── vision_controller.dart   ← Kamera + WidgetsBindingObserver
│   ├── vision_page.dart         ← UI Camera full-screen + HUD
│   ├── damage_painter.dart      ← CustomPainter overlay deteksi
│   ├── detection_result.dart    ← Model data deteksi (koordinat normalisasi)
│   ├── pcd_processor.dart       ← Pemrosesan citra
│   └── pcd_editor_page.dart     ← Editor & annotator gambar
│
└── LOG_LLM_KOMPREHENSIF.md      ← Berkas Log LLM (Metakognisi & Audit AI)
```

---

## 📋 Panduan Membaca Artifak

### Modul 3 — Fondasi & Penyimpanan Lokal (Hive)
> Mulai dari `log_model.dart` untuk memahami struktur data, lalu `log_controller.dart` untuk logika CRUD dengan Hive, kemudian `log_view.dart` untuk melihat bagaimana `ValueListenableBuilder` membuat UI reaktif.

**Bukti utama:** Anotasi `@HiveType`/`@HiveField` di `log_model.dart` dan file `log_model.g.dart` yang di-generate otomatis.

### Modul 5 — Integrasi & Sinkronisasi Cloud (MongoDB Atlas)
> Mulai dari `mongo_service.dart` untuk memahami koneksi Singleton, lalu `log_controller.dart` untuk alur Offline-First, kemudian `access_control_service.dart` untuk RBAC.

**Bukti utama:** Fungsi `fetchLogsFromDB()` di `log_controller.dart` yang "push sebelum pull" untuk mencegah data hilang saat offline.

### Modul 6 — Pemrosesan Citra Digital & Perangkat Lokal
> Mulai dari `vision_controller.dart` untuk memahami lifecycle kamera, lalu `damage_painter.dart` untuk melihat logika scaling koordinat, kemudian `vision_page.dart` untuk UI-nya.

**Bukti utama:** Metode `shouldRepaint()` di `damage_painter.dart` dan implementasi `didChangeAppLifecycleState()` di `vision_controller.dart`.

---

## 🧠 Log LLM (Metakognisi & Audit AI)
File `LOG_LLM_KOMPREHENSIF.md` mendokumentasikan **16 sesi interaksi** dengan AI selama pengerjaan ketiga modul ini, termasuk:
- Pertanyaan yang diajukan ke AI
- Bantuan yang diterima (konsep, debugging, arsitektur)
- Keputusan rekonstruksi mandiri yang berbeda dari saran AI
- Refleksi tentang pola penggunaan AI yang berkembang

---

*Dibuat: 15 Juni 2026*

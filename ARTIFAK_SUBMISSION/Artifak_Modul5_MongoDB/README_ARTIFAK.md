# ☁️ ARTIFAK MODUL 5: Integrasi & Sinkronisasi Cloud (MongoDB Atlas)

**Nama Mahasiswa:** Rizky Satria  
**NIM:** 089  
**Modul:** 5 — Offline-First, Collaborative Intelligence & Cloud Sync  

---

## 🎯 Deskripsi Artifak

Artifak ini mendokumentasikan implementasi **sistem cloud yang tahan banting**, mencakup:
- Koneksi ke **MongoDB Atlas** menggunakan Singleton Pattern
- Arsitektur **Offline-First** dengan Background Sync
- Sistem keamanan berbasis peran **RBAC** (Role-Based Access Control)
- **Audit Logging** dengan kontrol verbositas via `.env`

---

## 📁 File yang Disertakan

| File | Peran | Konsep Kunci |
|------|-------|-------------|
| `mongo_service.dart` | Layanan koneksi & CRUD Cloud | Singleton Pattern, MongoDB Atlas, Async/Await, Error Handling |
| `log_controller.dart` | Orkestrator sync Lokal↔Cloud | Offline-First, Fire-and-Forget, Connectivity Listener, ValueNotifier |
| `log_model.dart` | Model data dengan Hive+MongoDB | Dual compatibility (Hive biner + MongoDB BSON ObjectId) |
| `access_control_service.dart` | Pusat kebijakan akses | RBAC, Data Sovereignty, Single Responsibility Principle |
| `log_helper.dart` | Sistem audit logging | Verbosity Control, File Logging, `.env` Configuration |

---

## 🔑 Pencapaian Teknis Utama

### 1. MongoDB Singleton Service (`mongo_service.dart`)
```dart
class MongoService {
  // Singleton: hanya satu instance di seluruh app
  static final MongoService _instance = MongoService._internal();
  factory MongoService() => _instance;
  
  Future<void> connect() async {
    final dbUri = dotenv.env['MONGODB_URI']; // Aman: credentials di .env
    _db = await Db.create(dbUri!);
    await _db!.open().timeout(Duration(seconds: 15)); // Timeout 15 detik
    _collection = _db!.collection('logs');
  }
}
```

### 2. Arsitektur Offline-First (`log_controller.dart`)
```dart
Future<void> fetchLogsFromDB() async {
  // 1. Tampilkan data LOKAL dulu — UI tidak pernah kosong
  final localData = _myBox.values.toList();
  if (localData.isNotEmpty) logsNotifier.value = localData;

  try {
    // 2. Push data lokal ke Cloud SEBELUM pull (cegah data hilang!)
    for (var log in localData) {
      try { await MongoService().insertLog(log); } catch (_) {}
    }
    // 3. Timpa lokal dengan data Cloud terbaru
    final cloudData = await MongoService().getLogs();
    await _myBox.clear();
    await _myBox.addAll(cloudData);
    logsNotifier.value = cloudData;
  } catch (e) {
    // Offline: data lokal tetap aman di layar — tidak di-wipe!
  }
}
```

### 3. Fire-and-Forget Pattern (Non-blocking UI)
```dart
Future<void> addLog(String title, ...) async {
  final newLog = LogModel(...);
  
  // 1. Simpan ke Hive (INSTAN — tidak ada network latency)
  await _myBox.add(newLog);
  logsNotifier.value = [...logsNotifier.value, newLog];
  
  // 2. Upload ke Cloud (DI BACKGROUND — tidak memblokir UI!)
  MongoService().insertLog(newLog).catchError((e) {
    LogHelper.writeLog("Tersimpan offline, menunggu auto-sync.");
  });
}
```

### 4. Auto-Sync saat Internet Pulih
```dart
// Di konstruktor LogController:
Connectivity().onConnectivityChanged.listen((results) {
  if (!results.contains(ConnectivityResult.none)) {
    _syncPendingDataToCloud(); // Otomatis sync tanpa interaksi user
  }
});
```

### 5. RBAC & Data Sovereignty (`access_control_service.dart`)
```dart
class AccessControlService {
  static bool canPerform(String role, String action, {bool isOwner = false}) {
    // SOVEREIGNTY: Hanya PEMILIK yang bisa edit/hapus — bahkan Ketua tidak bisa!
    if (action == actionUpdate || action == actionDelete) {
      return isOwner; // role diabaikan untuk privasi data
    }
    return true; // Read & Create: semua diizinkan
  }
}
```

### 6. Audit Logging dengan Kontrol `.env` (`log_helper.dart`)
```
# Konfigurasi di file .env:
LOG_LEVEL=3         # 1=Error, 2=Info, 3=Verbose
LOG_MUTE=log_view.dart,onboarding_view.dart  # Sumber yang dimatikan
```
```dart
// Output ke terminal (color-coded) DAN ke file per tanggal
// Contoh output: [14:23:01][INFO][mongo_service.dart] -> SUCCESS: Log saved
final file = File('logs/${dateFile}.log');
await file.writeAsString('[$timestamp][$label][$source] -> $message\n',
  mode: FileMode.append);
```

---

## 🏗️ Arsitektur Offline-First

```
┌──────────────────────────────────────────────────────┐
│                    LogController                      │
│                                                       │
│  WRITE:  Hive (Instant) → MongoDB (Background)       │
│  READ:   Hive (Instant) + MongoDB (Background sync)  │
│  SYNC:   Connectivity Listener (Auto)                │
└──────────────────────────────────────────────────────┘
         │                        │
    ┌────▼────┐              ┌────▼────┐
    │  Hive   │              │MongoDB  │
    │ (Local) │◄────Sync─────│ Atlas   │
    │ Binary  │              │ Cloud   │
    └─────────┘              └─────────┘
```

---

## ✅ Checklist Fitur

- [x] Koneksi MongoDB Atlas dengan Singleton & Timeout handling
- [x] Kredensial aman di `.env` (tidak di-commit ke Git)
- [x] Offline-First: data tampil instan dari Hive
- [x] Background Sync: upload non-blocking (fire-and-forget)
- [x] Auto-sync saat internet pulih (Connectivity listener)
- [x] RBAC: Ketua vs Anggota dengan Data Sovereignty
- [x] Audit logging ke file per tanggal di folder `/logs`
- [x] Offline Mode Warning (banner merah saat tidak ada koneksi)
- [x] Pull-to-Refresh dengan RefreshIndicator

# 📷 ARTIFAK MODUL 6: Pemrosesan Citra Digital & Perangkat Lokal

**Nama Mahasiswa:** Rizky Satria  
**NIM:** 089  
**Modul:** 6 — Dasar Vision, CustomPainter & Camera Integration  

---

## 🎯 Deskripsi Artifak

Artifak ini mendokumentasikan implementasi **sistem penglihatan digital (Vision System)** berbasis kamera, mencakup:
- Integrasi hardware kamera menggunakan package `camera`
- Overlay grafis real-time menggunakan `CustomPainter`
- Manajemen lifecycle kamera yang aman (`WidgetsBindingObserver`)
- Simulasi deteksi kerusakan jalan (Mock YOLO Detector — RDD-2022)

---

## 📁 File yang Disertakan

| File | Peran | Konsep Kunci |
|------|-------|-------------|
| `vision_controller.dart` | Otak sistem kamera & deteksi | `ChangeNotifier`, `WidgetsBindingObserver`, `CameraController`, Mock Detector |
| `vision_page.dart` | Tampilan UI kamera full-screen | `Consumer<VisionController>`, `CameraPreview`, State enum, HUD overlay |
| `damage_painter.dart` | Painter overlay deteksi | `CustomPainter`, `Canvas`, `TextPainter`, Koordinat normalisasi → piksel |
| `detection_result.dart` | Model data hasil deteksi | Koordinat normalisasi (0.0–1.0), Label RDD-2022, Confidence score |
| `pcd_processor.dart` | Pemrosesan citra yang diambil | Image analysis, Filter aplikasi |
| `pcd_editor_page.dart` | Editor & annotator gambar | Full-screen dialog, Annotation tools |

---

## 🔑 Pencapaian Teknis Utama

### 1. Camera Status Enum & State Machine (`vision_controller.dart`)
```dart
enum CameraStatus {
  idle,
  requestingPermission,
  permissionDenied,
  permissionPermanentlyDenied,
  initializing,
  ready,
  disposed,
  error,
}
```
UI merespons setiap status dengan tampilan berbeda (loading, error, ready, dll.).

### 2. Lifecycle-Safe Camera Management
```dart
class VisionController extends ChangeNotifier with WidgetsBindingObserver {
  VisionController() {
    WidgetsBinding.instance.addObserver(this); // Daftar ke lifecycle
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        _handleInactive(); // Matikan kamera → cegah memory leak
      case AppLifecycleState.resumed:
        _handleResumed();  // Hidupkan kembali kamera
      // ...
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // WAJIB: cegah listener leak
    _cameraController?.dispose();
    super.dispose();
  }
}
```

### 3. Built-in Torch Toggle (Tidak perlu plugin tambahan!)
```dart
Future<void> toggleTorch() async {
  final newMode = _isTorchOn ? FlashMode.off : FlashMode.torch;
  await _cameraController!.setFlashMode(newMode);
  // FlashMode.torch = nyala TERUS (senter)
  // FlashMode.always = nyala saat capture saja
  _isTorchOn = !_isTorchOn;
  notifyListeners(); // Update UI via Provider/Consumer
}
```

### 4. CustomPainter — Koordinat Normalisasi ke Piksel (`damage_painter.dart`)
```dart
@override
void paint(Canvas canvas, Size size) {
  // size.width & size.height = ukuran layar dalam Logical Pixels

  // Crosshair di tengah layar (50% lebar)
  final double boxSide = size.width * 0.50;
  final Rect boxRect = Rect.fromCenter(
    center: Offset(size.width / 2, size.height / 2),
    width: boxSide, height: boxSide,
  );
  canvas.drawRect(boxRect, boxPaint);

  // Bounding box dari koordinat NORMALISASI (output YOLO: 0.0–1.0)
  // → Scale ke Logical Pixels layar saat ini
  final Rect screenRect = result.toScreenRect(size);
  // screenRect.left = result.box.left * size.width
  // screenRect.top  = result.box.top  * size.height
  canvas.drawRect(screenRect, bbPaint);
}

@override
bool shouldRepaint(DamagePainter oldDelegate) {
  // Hanya repaint saat data deteksi BERUBAH (efisien!)
  return oldDelegate.detection != detection;
}
```

### 5. Warna Dinamis Berdasarkan Tingkat Kerusakan
```dart
static Color damageColorOf(String label) {
  if (label.startsWith('D40') || label.startsWith('D20')) {
    return const Color(0xFFFF3B30); // 🔴 Merah — Pothole/Alligator Crack (BERAT)
  }
  return const Color(0xFFFFCC00);   // 🟡 Kuning — Longitudinal/Transverse Crack (RINGAN)
}
```

### 6. Mock YOLO Detector (Simulasi Inferensi)
```dart
void _generateMockDetection() {
  // Koordinat normalisasi acak yang valid (tidak keluar layar)
  final double left  = _random.nextDouble() * (1.0 - maxSize);
  final double top   = _random.nextDouble() * (1.0 - maxSize);
  final double width = minSize + _random.nextDouble() * (maxSize - minSize);

  final Rect normalizedBox = Rect.fromLTWH(
    left.clamp(0.0, 1.0 - width), top.clamp(0.0, 1.0 - height),
    width, height,
  );

  // Label acak dari dataset RDD-2022
  final DamageLabel randomLabel = DamageLabel.values[_random.nextInt(...)];
  final double score = 0.55 + _random.nextDouble() * 0.43; // 55%–98%

  _currentDetection = DetectionResult(box: normalizedBox, ...);
  notifyListeners();
}
```
> **Catatan:** Saat model YOLO `.tflite` asli diintegrasikan, hanya isi `_generateMockDetection()` yang perlu diganti dengan `YoloInference.run(frame)`.

---

## 🏗️ Arsitektur Vision System

```
VisionPage (UI)
  │ Consumer<VisionController>
  ▼
VisionController (Business Logic + Lifecycle)
  ├── CameraController    ← Hardware: kamera fisik
  ├── WidgetsBindingObserver ← Lifecycle App
  ├── Timer (Mock Detector)  ← Simulasi YOLO
  └── notifyListeners()   ← Update UI via Provider
  
DamagePainter (Canvas Layer)
  ├── Crosshair (static)
  ├── Label TextPainter
  └── BoundingBox (dari DetectionResult)
```

---

## 📐 Penjelasan Logical vs Physical Pixels

| Konsep | Nilai | Keterangan |
|--------|-------|------------|
| **Physical Pixels** | 1280×720 | Output sensor kamera (`ResolutionPreset.medium`) |
| **Logical Pixels** | ~360×640 | Sistem koordinat Flutter untuk gambar UI |
| **Device Pixel Ratio** | ~2.0–3.0x | Faktor konversi (tergantung perangkat) |
| **YOLO Output** | 0.0–1.0 | Koordinat normalisasi (independen resolusi) |

**Kenapa ini penting?** Bounding box dari model AI harus dikonversi ke Logical Pixels agar presisi di semua perangkat, bukan hardcoded dalam piksel fisik.

---

## ✅ Checklist Fitur

- [x] Konfigurasi Android (`AndroidManifest.xml`, `minSdkVersion 21`)
- [x] Inisialisasi kamera belakang dengan `ResolutionPreset.medium`
- [x] Camera preview full-screen tanpa distorsi aspek rasio
- [x] `CustomPainter` dengan crosshair statis di tengah layar
- [x] Label teks menggunakan `TextPainter` dengan drop shadow
- [x] Mock Detector: bounding box acak setiap 3 detik
- [x] Scaling Calibration: koordinat normalisasi → logical pixels
- [x] `WidgetsBindingObserver` untuk auto-dispose/reinit kamera
- [x] Toggle Torch menggunakan `FlashMode.torch` (built-in)
- [x] Toggle HUD Overlay on/off
- [x] Loading state "Menghubungkan ke Sensor Visual..."
- [x] Permission denied state dengan tombol "Buka Pengaturan"
- [x] Warna deteksi dinamis: Merah (D40/D20), Kuning (D00/D10)
- [x] Glow effect pada bounding box
- [x] Capture foto ke `PcdEditorPage` untuk analisis lanjutan

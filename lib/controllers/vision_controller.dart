import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/detection_result.dart';

/// Enum untuk merepresentasikan status kamera secara eksplisit.
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

/// [VisionController] mengelola siklus hidup kamera:
/// - Meminta izin kamera sebelum inisialisasi
/// - Menginisialisasi kamera belakang dengan resolusi medium
/// - Menangani AppLifecycle untuk mencegah memory leak
class VisionController extends ChangeNotifier implements WidgetsBindingObserver {
  // ─── State ───────────────────────────────────────────────────────────────

  CameraController? _cameraController;
  CameraStatus _status = CameraStatus.idle;
  String? _errorMessage;

  // ── Mock Detector State ───────────────────────────────────────────────────

  /// Timer periodik yang memicu simulasi deteksi setiap 3 detik.
  Timer? _mockDetectionTimer;

  /// Hasil deteksi terkini (koordinat normalisasi 0.0–1.0).
  /// Null jika belum ada deteksi.
  DetectionResult? _currentDetection;

  /// Random number generator untuk menghasilkan bounding box acak.
  final math.Random _random = math.Random();

  // ─── Getters ─────────────────────────────────────────────────────────────

  CameraController? get cameraController => _cameraController;
  CameraStatus get status => _status;
  String? get errorMessage => _errorMessage;

  /// Hasil deteksi objek terbaru (koordinat normalisasi).
  DetectionResult? get currentDetection => _currentDetection;

  /// Apakah mock detector sedang aktif.
  bool get isDetecting => _mockDetectionTimer?.isActive ?? false;

  /// Apakah preview kamera siap ditampilkan ke UI.
  bool get isCameraReady =>
      _status == CameraStatus.ready &&
      (_cameraController?.value.isInitialized ?? false);

  // ─── Constructor ─────────────────────────────────────────────────────────

  VisionController() {
    // Daftarkan observer lifecycle saat controller dibuat.
    WidgetsBinding.instance.addObserver(this);
  }

  // ─── Public API ──────────────────────────────────────────────────────────

  /// [initCamera] — Inisialisasi kamera dengan urutan:
  /// 1. Minta izin kamera via permission_handler
  /// 2. Dapatkan daftar kamera yang tersedia
  /// 3. Pilih kamera belakang (lensDirection == back)
  /// 4. Buat [CameraController] dengan ResolutionPreset.medium & audio OFF
  /// 5. Panggil initialize() lalu notifikasi UI
  Future<void> initCamera() async {
    // Hindari inisialisasi ganda saat sudah berjalan.
    if (_status == CameraStatus.initializing || _status == CameraStatus.ready) {
      return;
    }

    // ── Step 1: Minta izin kamera ──────────────────────────────────────────
    _setStatus(CameraStatus.requestingPermission);

    final permissionStatus = await Permission.camera.request();

    if (permissionStatus.isDenied) {
      _setStatus(CameraStatus.permissionDenied, error: 'Izin kamera ditolak.');
      return;
    }

    if (permissionStatus.isPermanentlyDenied) {
      _setStatus(
        CameraStatus.permissionPermanentlyDenied,
        error:
            'Izin kamera ditolak secara permanen. '
            'Buka pengaturan aplikasi untuk mengaktifkannya.',
      );
      // Arahkan user ke settings jika diperlukan:
      // await openAppSettings();
      return;
    }

    // ── Step 2: Ambil daftar kamera ───────────────────────────────────────
    _setStatus(CameraStatus.initializing);

    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        _setStatus(CameraStatus.error, error: 'Tidak ada kamera yang tersedia.');
        return;
      }

      // ── Step 3: Pilih kamera belakang ─────────────────────────────────
      final backCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        // Fallback ke kamera pertama jika kamera belakang tidak ditemukan.
        orElse: () => cameras.first,
      );

      // ── Step 4: Buat CameraController ─────────────────────────────────
      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false, // Audio dinonaktifkan sesuai spesifikasi
      );

      // ── Step 5: Inisialisasi dan beri tahu UI ─────────────────────────
      await _cameraController!.initialize();
      _setStatus(CameraStatus.ready);

      // Mulai mock detector begitu kamera siap.
      _startMockDetection();
    } on CameraException catch (e) {
      _setStatus(
        CameraStatus.error,
        error: 'CameraException [${e.code}]: ${e.description}',
      );
    } catch (e) {
      _setStatus(CameraStatus.error, error: 'Terjadi kesalahan: $e');
    }
  }

  /// Melepas resource kamera secara aman.
  Future<void> disposeCamera() async {
    // Hentikan mock detector sebelum melepas kamera.
    _stopMockDetection();
    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
      _currentDetection = null;
      _setStatus(CameraStatus.disposed);
    }
  }

  // ─── Mock Detector ────────────────────────────────────────────────────────

  /// Memulai Timer periodik yang mensimulasikan inferensi model YOLO.
  ///
  /// Timer terpicu setiap **3 detik** (setara 1 inference cycle lambat).
  /// Saat model asli diintegrasikan, ganti isi callback ini dengan
  /// panggilan ke `YoloInference.run(frame)`.
  void _startMockDetection() {
    // Batalkan timer sebelumnya jika ada agar tidak terjadi duplikasi.
    _stopMockDetection();

    _mockDetectionTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _generateMockDetection(),
    );
  }

  /// Menghentikan Timer dan membersihkan referensi agar tidak terjadi leak.
  void _stopMockDetection() {
    _mockDetectionTimer?.cancel();
    _mockDetectionTimer = null;
  }

  /// Menghasilkan satu [DetectionResult] acak dengan:
  /// - [box]   → koordinat normalisasi (0.0 – 1.0)
  /// - [label] → dipilih acak dari [DamageLabel] RDD-2022
  /// - [score] → confidence acak antara 0.55 – 0.98
  void _generateMockDetection() {
    // ── Bounding box normalisasi ──────────────────────────────────────────
    //
    // Pastikan box tidak keluar layar: right > left dan bottom > top.
    // Ukuran minimum = 15% layar, maksimum = 55% layar.
    final double minSize = 0.15;
    final double maxSize = 0.55;

    final double left   = _random.nextDouble() * (1.0 - maxSize);
    final double top    = _random.nextDouble() * (1.0 - maxSize);
    final double width  = minSize + _random.nextDouble() * (maxSize - minSize);
    final double height = minSize + _random.nextDouble() * (maxSize - minSize);

    final Rect normalizedBox = Rect.fromLTWH(
      left.clamp(0.0, 1.0 - width),
      top.clamp(0.0, 1.0 - height),
      width,
      height,
    );

    // ── Label acak dari dataset RDD-2022 ──────────────────────────────────
    final labels = DamageLabel.values;
    final DamageLabel randomLabel = labels[_random.nextInt(labels.length)];

    // ── Confidence score: 55% – 98% ───────────────────────────────────────
    final double score = 0.55 + _random.nextDouble() * 0.43;

    _currentDetection = DetectionResult(
      box: normalizedBox,
      label: '${randomLabel.code} – ${randomLabel.displayName}',
      score: score,
    );

    // Beritahu UI bahwa ada deteksi baru.
    notifyListeners();
  }

  // ─── WidgetsBindingObserver ───────────────────────────────────────────────

  /// Menangani perubahan AppLifecycle untuk mencegah memory leak:
  ///
  /// | State      | Aksi                                               |
  /// |------------|----------------------------------------------------|
  /// | inactive   | Dispose kamera (layar mungkin terhalang/background)|
  /// | paused     | (Opsional) bisa juga dispose di sini               |
  /// | resumed    | Inisialisasi ulang kamera                          |
  /// | detached   | Dispose kamera & bersihkan resource                |
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        // Aplikasi kehilangan fokus (mis. incoming call, app switcher).
        // Lepas kamera untuk menghindari konflik resource / memory leak.
        _handleInactive();
        break;

      case AppLifecycleState.paused:
        // Aplikasi sepenuhnya di background.
        // Biasanya sudah ditangani oleh inactive, tapi bisa juga dispose di sini.
        break;

      case AppLifecycleState.resumed:
        // Aplikasi kembali ke foreground — inisialisasi ulang kamera.
        _handleResumed();
        break;

      case AppLifecycleState.detached:
        // Aplikasi akan dihancurkan — pastikan semua resource dilepas.
        disposeCamera();
        break;

      case AppLifecycleState.hidden:
        // Diperlakukan seperti inactive di beberapa platform.
        _handleInactive();
        break;
    }
  }

  // ─── Private Helpers ─────────────────────────────────────────────────────

  /// Panggil saat lifecycle: inactive / hidden.
  void _handleInactive() {
    // Hentikan mock detector saat tidak aktif (hemat resource).
    _stopMockDetection();
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      disposeCamera();
    }
  }

  /// Panggil saat lifecycle: resumed.
  void _handleResumed() {
    // Hanya re-init jika kamera belum aktif.
    if (_status != CameraStatus.ready) {
      initCamera(); // _startMockDetection() dipanggil otomatis di dalam initCamera
    }
  }

  /// Helper untuk mengatur status dan mengirim notifikasi ke listener.
  void _setStatus(CameraStatus newStatus, {String? error}) {
    _status = newStatus;
    _errorMessage = error;
    notifyListeners();
  }

  // ─── Dispose (ChangeNotifier) ─────────────────────────────────────────────

  @override
  void dispose() {
    // Hentikan mock detector.
    _stopMockDetection();
    // Hapus observer lifecycle dari WidgetsBinding.
    WidgetsBinding.instance.removeObserver(this);
    // Pastikan resource kamera dilepas sebelum controller dihancurkan.
    _cameraController?.dispose();
    super.dispose();
  }
}

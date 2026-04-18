import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../controllers/vision_controller.dart';
import '../../painters/damage_painter.dart';
import 'pcd_editor_page.dart';

/// [VisionPage] — Halaman utama deteksi kerusakan jalan (RDD-2022).
///
/// Fitur:
/// - Camera preview full-screen
/// - Overlay DamagePainter (crosshair + bounding box)
/// - Tombol toggle torch / flash
/// - Switch overlay on/off
/// - Loading state dengan instruksi teks
/// - No-permission state dengan tombol "Buka Pengaturan"
class VisionPage extends StatefulWidget {
  const VisionPage({super.key});

  @override
  State<VisionPage> createState() => _VisionPageState();
}

class _VisionPageState extends State<VisionPage>
    with SingleTickerProviderStateMixin {
  late VisionController _ctrl;

  // Animasi pulse untuk indikator scanning
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // State untuk feedback tombol potret
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();

    // Paksa orientasi portrait agar preview tidak berputar.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Sembunyikan status bar agar preview full-screen.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _ctrl = VisionController();
    _ctrl.initCamera();

    // Animasi pulse untuk dot "scanning"
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _pulseCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<VisionController>.value(
      value: _ctrl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Consumer<VisionController>(
          builder: (context, ctrl, _) => _buildBody(ctrl),
        ),
      ),
    );
  }

  Widget _buildBody(VisionController ctrl) {
    return switch (ctrl.status) {
      CameraStatus.idle ||
      CameraStatus.requestingPermission ||
      CameraStatus.initializing =>
        _buildLoadingState(ctrl.status),
      CameraStatus.permissionDenied ||
      CameraStatus.permissionPermanentlyDenied =>
        _buildNoPermissionState(ctrl.status),
      CameraStatus.error => _buildErrorState(ctrl.errorMessage),
      CameraStatus.ready => _buildCameraReady(ctrl),
      _ => _buildLoadingState(ctrl.status),
    };
  }

  // ─── State: Loading ────────────────────────────────────────────────────────

  Widget _buildLoadingState(CameraStatus status) {
    final String message = switch (status) {
      CameraStatus.requestingPermission => 'Meminta izin akses kamera...',
      CameraStatus.initializing => 'Menghubungkan ke Sensor Visual...',
      _ => 'Mempersiapkan sistem...',
    };

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0E1A), Color(0xFF0D1B2A)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indikator lingkaran dengan warna HUD hijau neon
            SizedBox(
              width: 72,
              height: 72,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF00FF88),
                ),
                backgroundColor: const Color(0xFF00FF88).withAlpha(30),
              ),
            ),
            const SizedBox(height: 28),
            // Ikon kamera
            const Icon(
              Icons.camera_alt_outlined,
              size: 36,
              color: Color(0xFF00FF88),
            ),
            const SizedBox(height: 16),
            // Teks instruksional
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF00FF88),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'RDD-2022 Vision System',
              style: TextStyle(
                color: Colors.white.withAlpha(100),
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── State: No Permission ──────────────────────────────────────────────────

  Widget _buildNoPermissionState(CameraStatus status) {
    final bool isPermanent =
        status == CameraStatus.permissionPermanentlyDenied;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0A0A), Color(0xFF200D0D)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ikon kamera dicoret dengan lingkaran merah
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withAlpha(25),
                  border: Border.all(color: Colors.red.withAlpha(80), width: 2),
                ),
                child: const Icon(
                  Icons.no_photography_outlined,
                  size: 48,
                  color: Color(0xFFFF3B30),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'No Camera Access',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isPermanent
                    ? 'Izin kamera ditolak secara permanen.\nBuka Pengaturan untuk mengaktifkan akses kamera secara manual.'
                    : 'Akses kamera diperlukan untuk mendeteksi kerusakan jalan.\nSilakan izinkan akses kamera untuk melanjutkan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withAlpha(160),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 36),
              // Tombol buka settings (selalu muncul untuk UX yang solutif)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => openAppSettings(),
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Buka Pengaturan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3B30),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Tombol coba ulang (untuk kasus denied—bukan permanent)
              if (!isPermanent)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _ctrl.initCamera(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Coba Lagi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withAlpha(60)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── State: Error ──────────────────────────────────────────────────────────

  Widget _buildErrorState(String? message) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFFF3B30), size: 48),
              const SizedBox(height: 16),
              Text(
                message ?? 'Terjadi kesalahan yang tidak diketahui.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () => _ctrl.initCamera(),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF00FF88)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── State: Camera Ready ───────────────────────────────────────────────────

  Widget _buildCameraReady(VisionController ctrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 1. Camera Preview (fullscreen) ────────────────────────────────
        _buildCameraPreview(ctrl),

        // ── 2. Overlay Painter (bisa di-toggle) ──────────────────────────
        if (ctrl.isOverlayVisible)
          CustomPaint(
            painter: DamagePainter(
              detection: ctrl.currentDetection,
            ),
          ),

        // ── 3. Header: Judul + status scanning ───────────────────────────
        _buildHeader(ctrl),

        // ── 4. Bottom Control Bar ─────────────────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildControlBar(ctrl),
        ),

        // ── 5. Detection Info Card (muncul saat ada deteksi) ──────────────
        if (ctrl.currentDetection != null)
          Positioned(
            bottom: 120,
            left: 16,
            right: 16,
            child: _buildDetectionCard(ctrl),
          ),
      ],
    );
  }

  // ─── Camera Preview ────────────────────────────────────────────────────────

  Widget _buildCameraPreview(VisionController ctrl) {
    if (!ctrl.isCameraReady) return const SizedBox.shrink();

    final cameraController = ctrl.cameraController!;

    return SizedBox.expand(
      child: FittedBox(
        // BoxFit.cover: preview mengisi seluruh layar tanpa distorsi (crop sisi).
        // previewSize.height = lebar frame landscape (= lebar portrait).
        // previewSize.width  = tinggi frame landscape (= tinggi portrait).
        fit: BoxFit.cover,
        alignment: Alignment.center,
        child: SizedBox(
          width: cameraController.value.previewSize!.height,
          height: cameraController.value.previewSize!.width,
          child: CameraPreview(cameraController),
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(VisionController ctrl) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withAlpha(180),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                // Tombol kembali
                _HudIconButton(
                  id: 'btn_back',
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 12),
                // Judul
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Road Damage Vision',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      // Indikator scanning berjalan
                      _buildScanningIndicator(ctrl),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanningIndicator(VisionController ctrl) {
    return Row(
      children: [
        // Dot animasi pulse
        FadeTransition(
          opacity: _pulseAnim,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF00FF88),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          ctrl.isDetecting ? 'Scanning Aktif' : 'Menunggu...',
          style: const TextStyle(
            color: Color(0xFF00FF88),
            fontSize: 11,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  // ─── Control Bar ───────────────────────────────────────────────────────────

  Widget _buildControlBar(VisionController ctrl) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withAlpha(220),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // ── Torch Toggle ───────────────────────────────────────────
              _buildTorchButton(ctrl),

              // ── Tombol Kamera (shutter utama) ──────────────────────────
              _buildShutterButton(ctrl),

              // ── Overlay Toggle ─────────────────────────────────────────
              _buildOverlayButton(ctrl),
            ],
          ),
        ),
      ),
    );
  }

  /// Tombol torch / senter dengan ikon berubah sesuai status.
  Widget _buildTorchButton(VisionController ctrl) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HudIconButton(
          id: 'btn_torch',
          icon: ctrl.isTorchOn
              ? Icons.flashlight_on_rounded
              : Icons.flashlight_off_rounded,
          isActive: ctrl.isTorchOn,
          activeColor: const Color(0xFFFFCC00),
          onTap: () => ctrl.toggleTorch(),
        ),
        const SizedBox(height: 6),
        Text(
          ctrl.isTorchOn ? 'Torch ON' : 'Torch OFF',
          style: TextStyle(
            color: ctrl.isTorchOn
                ? const Color(0xFFFFCC00)
                : Colors.white.withAlpha(120),
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  /// Tombol shutter bulat besar di tengah — ambil foto nyata dari kamera.
  Widget _buildShutterButton(VisionController ctrl) {
    final bool canCapture = ctrl.isCameraReady && !_isCapturing;

    return GestureDetector(
      onTap: canCapture ? _handleCapture : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _isCapturing
                ? const Color(0xFFFFCC00)
                : const Color(0xFF00FF88),
            width: 3,
          ),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: EdgeInsets.all(_isCapturing ? 10 : 6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isCapturing
                ? const Color(0xFFFFCC00)
                : const Color(0xFF00FF88),
          ),
          child: Icon(
            _isCapturing ? Icons.hourglass_top_rounded : Icons.camera_alt_rounded,
            color: Colors.black,
            size: 28,
          ),
        ),
      ),
    );
  }

  /// Eksekusi pengambilan foto menggunakan [CameraController.takePicture],
  /// lalu langsung membuka [PcdEditorPage] untuk analisis citra.
  Future<void> _handleCapture() async {
    if (_isCapturing || !_ctrl.isCameraReady) return;

    setState(() => _isCapturing = true);

    try {
      // Hentikan mock detector sementara agar tidak mengganggu preview.
      final XFile photo = await _ctrl.cameraController!.takePicture();

      if (!mounted) return;
      setState(() => _isCapturing = false);

      // Buka halaman PCD Editor dengan gambar yang baru ditangkap.
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PcdEditorPage(imagePath: photo.path),
          fullscreenDialog: true,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCapturing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil foto: $e'),
          backgroundColor: const Color(0xFFFF3B30),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  /// Tombol toggle overlay HUD.
  Widget _buildOverlayButton(VisionController ctrl) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HudIconButton(
          id: 'btn_overlay',
          icon: ctrl.isOverlayVisible
              ? Icons.layers_rounded
              : Icons.layers_clear_rounded,
          isActive: ctrl.isOverlayVisible,
          activeColor: const Color(0xFF00FF88),
          onTap: () => ctrl.toggleOverlay(),
        ),
        const SizedBox(height: 6),
        Text(
          ctrl.isOverlayVisible ? 'HUD ON' : 'HUD OFF',
          style: TextStyle(
            color: ctrl.isOverlayVisible
                ? const Color(0xFF00FF88)
                : Colors.white.withAlpha(120),
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ─── Detection Card ────────────────────────────────────────────────────────

  Widget _buildDetectionCard(VisionController ctrl) {
    final detection = ctrl.currentDetection!;
    final Color severityColor = DamagePainter.damageColorOf(detection.label);
    final bool isHeavy =
        detection.label.startsWith('D40') || detection.label.startsWith('D20');

    return AnimatedSlide(
      offset: Offset.zero,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(190),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: severityColor.withAlpha(120),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Severity indicator dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: severityColor,
                boxShadow: [
                  BoxShadow(
                    color: severityColor.withAlpha(150),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detection.label,
                    style: TextStyle(
                      color: severityColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isHeavy ? 'Kerusakan Berat — Prioritas Tinggi' : 'Kerusakan Ringan — Pemantauan Rutin',
                    style: TextStyle(
                      color: Colors.white.withAlpha(160),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Score badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: severityColor.withAlpha(40),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: severityColor.withAlpha(100)),
              ),
              child: Text(
                detection.scorePercent,
                style: TextStyle(
                  color: severityColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable HUD Icon Button ─────────────────────────────────────────────────

/// Tombol ikon berbentuk lingkaran dengan efek glassmorphism.
class _HudIconButton extends StatelessWidget {
  final String id;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final Color activeColor;

  const _HudIconButton({
    required this.id,
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.activeColor = const Color(0xFF00FF88),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? activeColor.withAlpha(35)
              : Colors.white.withAlpha(20),
          border: Border.all(
            color: isActive ? activeColor.withAlpha(180) : Colors.white.withAlpha(60),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          size: 22,
          color: isActive ? activeColor : Colors.white.withAlpha(200),
        ),
      ),
    );
  }
}

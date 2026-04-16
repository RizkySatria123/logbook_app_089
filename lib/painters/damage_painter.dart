import 'package:flutter/material.dart';

import '../models/detection_result.dart';

/// [DamagePainter] menggambar overlay transparan di atas [CameraPreview].
///
/// Komponen yang digambar:
/// 1. Kotak crosshair statis — tepat di tengah layar, lebar = 50% [size.width]
/// 2. Label teks — menempel tepat di atas garis atas kotak
/// 3. Bounding box deteksi — koordinat normalisasi di-scale ke piksel layar
///
/// Semua koordinat menggunakan **Logical Pixels** sehingga responsif
/// di berbagai ukuran dan densitas layar.
class DamagePainter extends CustomPainter {
  /// Warna utama elemen overlay (default: hijau neon — khas tampilan HUD).
  final Color color;

  /// Ketebalan garis kotak dalam logical pixels.
  final double strokeWidth;

  /// Ukuran font label teks.
  final double fontSize;

  /// Daftar hasil deteksi yang akan digambar sebagai bounding box.
  /// Koordinat [DetectionResult.box] harus dalam normalisasi (0.0–1.0).
  final DetectionResult? detection;

  const DamagePainter({
    this.color = const Color(0xFF00FF88),
    this.strokeWidth = 2.0,
    this.fontSize = 13.0,
    this.detection,
  });

  // ─── Static: Damage Severity Color ───────────────────────────────────────

  /// Mengembalikan warna berdasarkan tingkat keparahan kerusakan dari label.
  ///
  /// | Severity  | Kode  | Warna               |
  /// |-----------|-------|---------------------|
  /// | Berat     | D40   | Merah (bahaya)      |
  /// | Berat     | D20   | Merah (bahaya)      |
  /// | Ringan    | D10   | Kuning (peringatan) |
  /// | Ringan    | D00   | Kuning (peringatan) |
  static Color damageColorOf(String label) {
    if (label.startsWith('D40') || label.startsWith('D20')) {
      return const Color(0xFFFF3B30); // Merah kuat — kerusakan berat
    }
    return const Color(0xFFFFCC00); // Kuning — kerusakan ringan
  }

  // ─── paint ───────────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    // ── 1. Hitung geometri kotak ──────────────────────────────────────────

    // Panjang sisi kotak = 50% dari lebar layar (logical pixels).
    final double boxSide = size.width * 0.50;

    // Titik pusat layar dalam logical pixels.
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    // Rect kotak yang terpusat sempurna.
    final Rect boxRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: boxSide,
      height: boxSide,
    );

    // ── 2. Paint konfigurasi ──────────────────────────────────────────────

    final Paint boxPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square;

    final Paint cornerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 2.5 // Sudut lebih tebal agar terlihat jelas
      ..strokeCap = StrokeCap.square;

    // ── 3. Gambar kotak utama ─────────────────────────────────────────────
    canvas.drawRect(boxRect, boxPaint);

    // ── 4. Gambar aksen sudut (corner marks) — opsional tapi lebih premium ─
    _drawCornerMarks(canvas, boxRect, cornerPaint);

    // ── 5. Gambar crosshair tipis di tengah kotak ─────────────────────────
    _drawCrosshairCenter(canvas, Offset(centerX, centerY), boxPaint);

    // ── 6. Gambar label teks di atas garis atas kotak ────────────────────
    _drawLabel(canvas, boxRect);

    // ── 7. Gambar bounding box deteksi (jika ada) ─────────────────────────
    if (detection != null) {
      _drawBoundingBox(canvas, size, detection!);
    }
  }

  // ─── Helper: Corner Marks ─────────────────────────────────────────────────

  /// Menggambar aksen sudut (L-shape) di keempat pojok kotak.
  /// Panjang aksen = 20% dari panjang sisi kotak.
  void _drawCornerMarks(Canvas canvas, Rect rect, Paint paint) {
    final double markLen = rect.width * 0.20;

    // Top-left
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(markLen, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(0, markLen), paint);

    // Top-right
    canvas.drawLine(rect.topRight, rect.topRight + Offset(-markLen, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight + Offset(0, markLen), paint);

    // Bottom-left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(markLen, 0), paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(0, -markLen), paint);

    // Bottom-right
    canvas.drawLine(rect.bottomRight, rect.bottomRight + Offset(-markLen, 0), paint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + Offset(0, -markLen), paint);
  }

  // ─── Helper: Crosshair Center ─────────────────────────────────────────────

  /// Menggambar tanda silang kecil tepat di titik tengah kotak.
  void _drawCrosshairCenter(Canvas canvas, Offset center, Paint paint) {
    const double crossSize = 8.0; // setengah panjang garis silang (logical px)

    // Garis horizontal
    canvas.drawLine(
      center + const Offset(-crossSize, 0),
      center + const Offset(crossSize, 0),
      paint,
    );

    // Garis vertikal
    canvas.drawLine(
      center + const Offset(0, -crossSize),
      center + const Offset(0, crossSize),
      paint,
    );
  }

  // ─── Helper: Label Teks ───────────────────────────────────────────────────

  /// Menggunakan [TextPainter] untuk menuliskan label tepat di atas
  /// garis atas kotak, rata tengah secara horizontal.
  void _drawLabel(Canvas canvas, Rect boxRect) {
    const String labelText = 'Searching for Road Damage...';

    // ── Konfigurasi TextSpan ──────────────────────────────────────────────
    final TextSpan textSpan = TextSpan(
      text: labelText,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        shadows: [
          // Drop shadow agar teks terbaca di atas kamera yang beragam
          Shadow(
            color: Colors.black.withAlpha(180),
            offset: const Offset(1, 1),
            blurRadius: 3,
          ),
        ],
      ),
    );

    // ── Buat dan layout TextPainter ───────────────────────────────────────
    final TextPainter textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(
        minWidth: 0,
        maxWidth: boxRect.width, // Batasi lebar sesuai kotak
      );

    // ── Hitung posisi: rata tengah horizontal, menempel di atas garis top ─
    // Jarak vertikal antara batas bawah teks dan garis atas kotak = 6 px
    const double verticalGap = 6.0;

    final double dx = boxRect.left + (boxRect.width - textPainter.width) / 2;
    final double dy = boxRect.top - textPainter.height - verticalGap;

    // ── Gambar teks ke canvas ─────────────────────────────────────────────
    textPainter.paint(canvas, Offset(dx, dy));
  }

  // ─── Coordinate Scaling: Normalized → Screen Pixels ──────────────────────

  /// Mengubah koordinat normalisasi [DetectionResult.box] menjadi posisi
  /// piksel nyata berdasarkan [size] canvas yang sedang aktif.
  ///
  /// **Formula scaling:**
  /// ```
  /// screenX = normalizedX * canvasWidth
  /// screenY = normalizedY * canvasHeight
  /// ```
  ///
  /// Keunggulan: bounding box tetap proporsional di semua resolusi layar
  /// karena koordinat tidak pernah di-hardcode dalam piksel absolut.
  void _drawBoundingBox(Canvas canvas, Size size, DetectionResult result) {
    final Rect screenRect = result.toScreenRect(size);

    // ── Warna dinamis berdasarkan severity kerusakan ───────────────────────
    final Color boxColor = damageColorOf(result.label);

    // ── Paint konfigurasi untuk bounding box deteksi ───────────────────────
    final Paint bbPaint = Paint()
      ..color = boxColor.withAlpha(220)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 0.5
      ..strokeCap = StrokeCap.round;

    // ── Glow effect: lapisan luar yang lebih transparan ────────────────────
    final Paint glowPaint = Paint()
      ..color = boxColor.withAlpha(60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (strokeWidth + 0.5) * 3
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawRect(screenRect, glowPaint);
    canvas.drawRect(screenRect, bbPaint);

    // ── Badge label + score ────────────────────────────────────────────────
    _drawDetectionBadge(canvas, screenRect, result, size, boxColor);
  }

  /// Menggambar badge label dan confidence score di atas bounding box.
  /// Badge memiliki latar belakang semi-transparan agar mudah dibaca.
  void _drawDetectionBadge(Canvas canvas, Rect screenRect,
      DetectionResult result, Size size, Color badgeColor) {
    final String badgeText = '${result.label}  ${result.scorePercent}';

    // ── TextPainter untuk badge — dengan multi-layer shadow ───────────────
    final TextPainter badgePainter = TextPainter(
      text: TextSpan(
        text: badgeText,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize - 1,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          // Multi-layer shadow: stroke luar + drop shadow agar terbaca
          // di atas permukaan jalan dengan warna apapun.
          shadows: [
            Shadow(
              color: Colors.black.withAlpha(255),
              offset: const Offset(-1, -1),
              blurRadius: 2,
            ),
            Shadow(
              color: Colors.black.withAlpha(255),
              offset: const Offset(1, -1),
              blurRadius: 2,
            ),
            Shadow(
              color: Colors.black.withAlpha(255),
              offset: const Offset(-1, 1),
              blurRadius: 2,
            ),
            Shadow(
              color: Colors.black.withAlpha(200),
              offset: const Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: size.width * 0.9);

    // ── Dimensi dan posisi badge ──────────────────────────────────────────
    const double paddingH = 8.0;
    const double paddingV = 4.0;
    const double badgeRadius = 6.0;

    final double badgeW = badgePainter.width + paddingH * 2;
    final double badgeH = badgePainter.height + paddingV * 2;

    double badgeTop = screenRect.top - badgeH - 2;
    if (badgeTop < 0) badgeTop = screenRect.top + 2;
    final double badgeLeft =
        (screenRect.left).clamp(0.0, size.width - badgeW);

    final Rect badgeRect = Rect.fromLTWH(badgeLeft, badgeTop, badgeW, badgeH);

    // ── Latar belakang badge menggunakan warna severity ───────────────────
    final Paint bgPaint = Paint()
      ..color = badgeColor.withAlpha(210)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(badgeRect, const Radius.circular(badgeRadius)),
      bgPaint,
    );

    // ── Gambar teks badge ─────────────────────────────────────────────────
    badgePainter.paint(
      canvas,
      Offset(badgeLeft + paddingH, badgeTop + paddingV),
    );
  }

  // ─── shouldRepaint ────────────────────────────────────────────────────────

  /// Kembalikan [true] hanya jika properti yang mempengaruhi visual berubah.
  @override
  bool shouldRepaint(covariant DamagePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.detection != detection; // Repaint saat deteksi baru tiba
  }
}

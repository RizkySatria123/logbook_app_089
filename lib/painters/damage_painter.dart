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
    // ── 1. Scale: normalisasi → logical pixels ────────────────────────────
    //
    // toScreenRect() mengalikan setiap komponen Rect dengan size:
    //   left   = box.left   * size.width
    //   top    = box.top    * size.height
    //   right  = box.right  * size.width
    //   bottom = box.bottom * size.height
    final Rect screenRect = result.toScreenRect(size);

    // ── 2. Paint konfigurasi untuk bounding box deteksi ───────────────────
    final Paint bbPaint = Paint()
      ..color = Colors.redAccent.withAlpha(220)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 0.5 // Sedikit lebih tebal dari crosshair
      ..strokeCap = StrokeCap.round;

    // ── 3. Gambar bounding box ────────────────────────────────────────────
    canvas.drawRect(screenRect, bbPaint);

    // ── 4. Gambar badge label + score di atas bounding box ────────────────
    _drawDetectionBadge(canvas, screenRect, result, size);
  }

  /// Menggambar badge label dan confidence score di atas bounding box.
  /// Badge memiliki latar belakang semi-transparan agar mudah dibaca.
  void _drawDetectionBadge(Canvas canvas, Rect screenRect,
      DetectionResult result, Size size) {
    final String badgeText = '${result.label}  ${result.scorePercent}';

    // ── TextPainter untuk badge ───────────────────────────────────────────
    final TextPainter badgePainter = TextPainter(
      text: TextSpan(
        text: badgeText,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize - 1,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: size.width * 0.9);

    // ── Dimensi dan posisi badge ──────────────────────────────────────────
    const double paddingH = 6.0; // padding horizontal
    const double paddingV = 3.0; // padding vertikal
    const double badgeRadius = 4.0;

    final double badgeW = badgePainter.width + paddingH * 2;
    final double badgeH = badgePainter.height + paddingV * 2;

    // Tempatkan badge tepat di atas garis atas bounding box.
    // Jika terlalu dekat tepi atas layar, geser ke bawah agar tidak terpotong.
    double badgeTop = screenRect.top - badgeH - 2;
    if (badgeTop < 0) badgeTop = screenRect.top + 2;

    // Clamp agar tidak keluar dari sisi kanan layar.
    final double badgeLeft =
        (screenRect.left).clamp(0.0, size.width - badgeW);

    final Rect badgeRect = Rect.fromLTWH(badgeLeft, badgeTop, badgeW, badgeH);

    // ── Gambar latar belakang badge ───────────────────────────────────────
    final Paint bgPaint = Paint()
      ..color = Colors.redAccent.withAlpha(200)
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

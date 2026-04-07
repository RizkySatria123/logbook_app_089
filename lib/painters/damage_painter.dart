import 'package:flutter/material.dart';

/// [DamagePainter] menggambar overlay transparan di atas [CameraPreview].
///
/// Komponen yang digambar:
/// 1. Kotak crosshair statis — tepat di tengah layar, lebar = 50% [size.width]
/// 2. Label teks — menempel tepat di atas garis atas kotak
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

  const DamagePainter({
    this.color = const Color(0xFF00FF88),
    this.strokeWidth = 2.0,
    this.fontSize = 13.0,
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

  // ─── shouldRepaint ────────────────────────────────────────────────────────

  /// Kembalikan [true] hanya jika properti yang mempengaruhi visual berubah.
  /// Karena painter ini statis, repaint tidak diperlukan kecuali warna berubah.
  @override
  bool shouldRepaint(covariant DamagePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.fontSize != fontSize;
  }
}

import 'package:flutter/painting.dart';

/// Label kerusakan jalan berdasarkan dataset RDD-2022.
enum DamageLabel {
  longitudinalCrack('D00', 'Longitudinal Crack'),
  transverseCrack('D10', 'Transverse Crack'),
  alligatorCrack('D20', 'Alligator Crack'),
  pothole('D40', 'Pothole');

  final String code;
  final String displayName;
  const DamageLabel(this.code, this.displayName);
}

/// [DetectionResult] — Data Transfer Object (DTO) untuk satu hasil deteksi objek.
///
/// Semua nilai [box] disimpan dalam **koordinat normalisasi (0.0 – 1.0)**
/// agar independen dari resolusi layar.
///
/// ```
/// box.left   = x_min / image_width
/// box.top    = y_min / image_height
/// box.right  = x_max / image_width
/// box.bottom = y_max / image_height
/// ```
class DetectionResult {
  /// Bounding box dalam koordinat normalisasi [0.0, 1.0].
  final Rect box;

  /// Label kategori kerusakan (misal: 'D40 – Pothole').
  final String label;

  /// Confidence score dari model [0.0, 1.0].
  final double score;

  const DetectionResult({
    required this.box,
    required this.label,
    required this.score,
  });

  /// Skala [box] normalisasi ke koordinat piksel nyata berdasarkan [canvasSize].
  ///
  /// Contoh:
  /// ```dart
  /// final screenRect = result.toScreenRect(Size(390, 844));
  /// ```
  Rect toScreenRect(Size canvasSize) {
    return Rect.fromLTRB(
      box.left * canvasSize.width,
      box.top * canvasSize.height,
      box.right * canvasSize.width,
      box.bottom * canvasSize.height,
    );
  }

  /// Format score sebagai persentase untuk ditampilkan di UI.
  String get scorePercent => '${(score * 100).toStringAsFixed(1)}%';

  @override
  String toString() =>
      'DetectionResult(label: $label, score: $scorePercent, box: $box)';
}

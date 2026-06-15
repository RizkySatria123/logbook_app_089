import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

// ─────────────────────────────────────────────────────────────────────────────
// Kelas pembantu bilangan kompleks untuk komputasi DFT / FFT.
// ─────────────────────────────────────────────────────────────────────────────

class _Complex {
  final double re;
  final double im;
  const _Complex(this.re, this.im);

  _Complex operator +(_Complex o) => _Complex(re + o.re, im + o.im);
  _Complex operator -(_Complex o) => _Complex(re - o.re, im - o.im);
  _Complex operator *(_Complex o) => _Complex(
        re * o.re - im * o.im,
        re * o.im + im * o.re,
      );
  double get magnitude => math.sqrt(re * re + im * im);
}

// ─────────────────────────────────────────────────────────────────────────────
// [PcdProcessor] — Kumpulan algoritma Pengolahan Citra Digital (PCD).
//
// Semua metode bersifat *synchronous* dan menerima/mengembalikan raw RGBA
// bytes (Uint8List) sehingga bisa dijalankan di isolat via compute().
// ─────────────────────────────────────────────────────────────────────────────

class PcdProcessor {
  // ─── Helpers ──────────────────────────────────────────────────────────────

  static int _clampD(double v) => v.round().clamp(0, 255);

  /// Luminance berbasis bobot persepsi manusia (BT.601).
  static int _lum(int r, int g, int b) =>
      (0.299 * r + 0.587 * g + 0.114 * b).round().clamp(0, 255);

  // ─── 1. Brightness & Contrast ─────────────────────────────────────────────
  //
  // Rumus: out = clamp( alpha × in + beta )
  // alpha : kontras  [0.1 … 3.0]
  // beta  : kecerahan [-100 … 100]

  static Uint8List brightnessContrast(
      Uint8List src, double alpha, double beta) {
    final dst = Uint8List(src.length);
    for (int i = 0; i < src.length; i += 4) {
      dst[i]     = _clampD(alpha * src[i]     + beta);
      dst[i + 1] = _clampD(alpha * src[i + 1] + beta);
      dst[i + 2] = _clampD(alpha * src[i + 2] + beta);
      dst[i + 3] = src[i + 3];
    }
    return dst;
  }

  // ─── 2. Histogram Equalization ────────────────────────────────────────────
  //
  // Meratakan distribusi histogram luminance agar kontras global meningkat.
  // Menggunakan CDF normalisasi: H(v) = round((cdf(v) - cdfMin) / (N - cdfMin) × 255)

  static Uint8List histogramEqualization(
      Uint8List src, int width, int height) {
    final n = width * height;

    // Bangun histogram luminance.
    final hist = List<int>.filled(256, 0);
    for (int i = 0; i < src.length; i += 4) {
      hist[_lum(src[i], src[i + 1], src[i + 2])]++;
    }

    // CDF kumulatif.
    final cdf = List<int>.filled(256, 0);
    cdf[0] = hist[0];
    for (int i = 1; i < 256; i++) cdf[i] = cdf[i - 1] + hist[i];

    int cdfMin = 0;
    for (int i = 0; i < 256; i++) {
      if (cdf[i] > 0) {
        cdfMin = cdf[i];
        break;
      }
    }

    // LUT ekualisasi.
    final lut = List<int>.generate(256, (i) => n != cdfMin
        ? (((cdf[i] - cdfMin) / (n - cdfMin)) * 255).round().clamp(0, 255)
        : 0);

    final dst = Uint8List(src.length);
    for (int i = 0; i < src.length; i += 4) {
      final lum   = _lum(src[i], src[i + 1], src[i + 2]);
      final eq    = lut[lum];
      final scale = lum == 0 ? 0.0 : eq / lum;
      dst[i]     = _clampD(src[i]     * scale);
      dst[i + 1] = _clampD(src[i + 1] * scale);
      dst[i + 2] = _clampD(src[i + 2] * scale);
      dst[i + 3] = src[i + 3];
    }
    return dst;
  }

  // ─── 3. Gaussian Blur ─────────────────────────────────────────────────────
  //
  // Konvolusi dengan kernel Gaussian berukuran [kernelSize × kernelSize]
  // dengan standar deviasi sigma.

  static Uint8List gaussianBlur(
      Uint8List src, int width, int height, int kernelSize, double sigma) {
    final kernel = _gaussianKernel(kernelSize, sigma);
    return _convolveRgb(src, width, height, kernel, kernelSize);
  }

  static List<double> _gaussianKernel(int size, double sigma) {
    final half = size ~/ 2;
    final k = List<double>.filled(size * size, 0);
    double sum = 0;
    for (int y = -half; y <= half; y++) {
      for (int x = -half; x <= half; x++) {
        final v = math.exp(-(x * x + y * y) / (2 * sigma * sigma));
        k[(y + half) * size + (x + half)] = v;
        sum += v;
      }
    }
    return k.map((v) => v / sum).toList();
  }

  static Uint8List _convolveRgb(
      Uint8List src, int width, int height, List<double> kernel, int kSize) {
    final dst  = Uint8List(src.length);
    final half = kSize ~/ 2;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        double r = 0, g = 0, b = 0;
        for (int ky = -half; ky <= half; ky++) {
          for (int kx = -half; kx <= half; kx++) {
            final sy = (y + ky).clamp(0, height - 1);
            final sx = (x + kx).clamp(0, width  - 1);
            final si = (sy * width + sx) * 4;
            final ki = (ky + half) * kSize + (kx + half);
            r += src[si]     * kernel[ki];
            g += src[si + 1] * kernel[ki];
            b += src[si + 2] * kernel[ki];
          }
        }
        final di = (y * width + x) * 4;
        dst[di]     = _clampD(r);
        dst[di + 1] = _clampD(g);
        dst[di + 2] = _clampD(b);
        dst[di + 3] = src[di + 3];
      }
    }
    return dst;
  }

  // ─── 4. Unsharp Mask Sharpening ───────────────────────────────────────────
  //
  // Rumus: sharp = original + amount × (original − blurred)
  // Efektif memperjelas tepi tanpa menambah noise sebesar high-pass langsung.

  static Uint8List unsharpMask(
      Uint8List src, int width, int height, double amount, double sigma) {
    final blurred = gaussianBlur(src, width, height, 5, sigma);
    final dst = Uint8List(src.length);
    for (int i = 0; i < src.length; i += 4) {
      dst[i]     = _clampD(src[i]     + amount * (src[i]     - blurred[i]));
      dst[i + 1] = _clampD(src[i + 1] + amount * (src[i + 1] - blurred[i + 1]));
      dst[i + 2] = _clampD(src[i + 2] + amount * (src[i + 2] - blurred[i + 2]));
      dst[i + 3] = src[i + 3];
    }
    return dst;
  }

  // ─── 5. Edge Detection (Sobel) ────────────────────────────────────────────
  //
  // Langkah: blur Gaussian → konversi grayscale → operator Sobel →
  //          magnitude gradient → terapkan threshold

  static Uint8List edgeDetection(
      Uint8List src, int width, int height, int threshold) {
    final blurred = gaussianBlur(src, width, height, 5, 1.4);

    final gray = List<int>.filled(width * height, 0);
    for (int i = 0; i < blurred.length; i += 4) {
      gray[i ~/ 4] = _lum(blurred[i], blurred[i + 1], blurred[i + 2]);
    }

    const gxK = [-1, 0, 1, -2, 0, 2, -1, 0, 1];
    const gyK = [-1, -2, -1, 0, 0, 0, 1, 2, 1];

    final dst = Uint8List(src.length);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        double gx = 0, gy = 0;
        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final sy = (y + ky).clamp(0, height - 1);
            final sx = (x + kx).clamp(0, width  - 1);
            final ki = (ky + 1) * 3 + (kx + 1);
            gx += gray[sy * width + sx] * gxK[ki];
            gy += gray[sy * width + sx] * gyK[ki];
          }
        }
        final mag  = math.sqrt(gx * gx + gy * gy);
        final edge = mag > threshold ? _clampD(mag) : 0;
        final di   = (y * width + x) * 4;
        dst[di] = dst[di + 1] = dst[di + 2] = edge;
        dst[di + 3] = 255;
      }
    }
    return dst;
  }

  // ─── 6. Binary Thresholding ───────────────────────────────────────────────
  //
  // out = lum > threshold ? 255 : 0  (hasil hitam-putih)

  static Uint8List binaryThreshold(
      Uint8List src, int width, int height, int threshold) {
    final dst = Uint8List(src.length);
    for (int i = 0; i < src.length; i += 4) {
      final val = _lum(src[i], src[i + 1], src[i + 2]) > threshold ? 255 : 0;
      dst[i] = dst[i + 1] = dst[i + 2] = val;
      dst[i + 3] = 255;
    }
    return dst;
  }

  // ─── 7. Median Filter ─────────────────────────────────────────────────────
  //
  // Mengganti setiap piksel dengan nilai median dari tetangganya.
  // Efektif menghilangkan salt-and-pepper noise tanpa blur tepi.

  static Uint8List medianFilter(
      Uint8List src, int width, int height, int kernelSize) {
    final dst  = Uint8List(src.length);
    final half = kernelSize ~/ 2;
    final n    = kernelSize * kernelSize;
    final rs   = List<int>.filled(n, 0);
    final gs   = List<int>.filled(n, 0);
    final bs   = List<int>.filled(n, 0);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int count = 0;
        for (int ky = -half; ky <= half; ky++) {
          for (int kx = -half; kx <= half; kx++) {
            final sy = (y + ky).clamp(0, height - 1);
            final sx = (x + kx).clamp(0, width  - 1);
            final si = (sy * width + sx) * 4;
            rs[count] = src[si];
            gs[count] = src[si + 1];
            bs[count] = src[si + 2];
            count++;
          }
        }
        _insertionSort(rs, count);
        _insertionSort(gs, count);
        _insertionSort(bs, count);
        final mid = count ~/ 2;
        final di  = (y * width + x) * 4;
        dst[di]     = rs[mid];
        dst[di + 1] = gs[mid];
        dst[di + 2] = bs[mid];
        dst[di + 3] = src[di + 3];
      }
    }
    return dst;
  }

  /// Insertion sort untuk buffer kecil (n ≤ 25) — lebih cepat dari .sort().
  static void _insertionSort(List<int> arr, int n) {
    for (int i = 1; i < n; i++) {
      final key = arr[i];
      int j = i - 1;
      while (j >= 0 && arr[j] > key) {
        arr[j + 1] = arr[j];
        j--;
      }
      arr[j + 1] = key;
    }
  }

  // ─── 8. Gamma Correction ─────────────────────────────────────────────────
  //
  // out = 255 × (in / 255)^gamma
  // gamma < 1 : mencerahkan (highlight detail gelap)
  // gamma > 1 : menggelapkan (detail terang lebih terjaga)

  static Uint8List gammaCorrection(Uint8List src, double gamma) {
    final lut = List<int>.generate(
        256, (i) => (255.0 * math.pow(i / 255.0, gamma)).round().clamp(0, 255));
    final dst = Uint8List(src.length);
    for (int i = 0; i < src.length; i += 4) {
      dst[i]     = lut[src[i]];
      dst[i + 1] = lut[src[i + 1]];
      dst[i + 2] = lut[src[i + 2]];
      dst[i + 3] = src[i + 3];
    }
    return dst;
  }

  // ─── 9. Fourier Spectrum ──────────────────────────────────────────────────
  //
  // Menampilkan magnitude spectrum 2D DFT dengan:
  //   - Konversi ke grayscale & downsample ke [fftSize × fftSize]
  //   - 2D FFT via Cooley-Tukey (row-then-column)
  //   - fftshift: geser DC component ke tengah gambar
  //   - Log normalization: agar komponen kecil terlihat

  static Uint8List fourierSpectrum(
      Uint8List src, int width, int height, {int fftSize = 128}) {
    final gray = _downsampleGray(src, width, height, fftSize, fftSize);
    final mag  = _fft2dMagnitude(gray, fftSize, fftSize);

    // Log normalization.
    final maxLog = mag.map((v) => math.log(1 + v)).reduce(math.max);
    final norm   = mag.map((v) => maxLog > 0 ? math.log(1 + v) / maxLog : 0.0).toList();

    return _grayToRgbaUpscale(norm, fftSize, fftSize, width, height);
  }

  // ─── 10. Inverse Fourier Transform ────────────────────────────────────────
  //
  // FFT → Low-pass filter (hapus frekuensi tinggi) → IFFT
  // Demonstrasi: semakin kecil cutoffRatio, semakin blur hasil rekonstruksi.
  // cutoffRatio [0.05 … 1.0]: 1.0 = semua frekuensi pass (rekonstruksi identik)

  static Uint8List inverseFourier(
      Uint8List src, int width, int height,
      {int fftSize = 128, double cutoffRatio = 0.5}) {
    final gray = _downsampleGray(src, width, height, fftSize, fftSize);
    final recon = _ifft2dLowpass(gray, fftSize, fftSize, cutoffRatio);

    // Normalize output ke [0, 1].
    double maxV = recon[0], minV = recon[0];
    for (final v in recon) {
      if (v > maxV) maxV = v;
      if (v < minV) minV = v;
    }
    final range = maxV - minV;
    final norm = recon.map((v) => range > 0 ? (v - minV) / range : 0.0).toList();

    return _grayToRgbaUpscale(norm, fftSize, fftSize, width, height);
  }

  // ─── FFT Internals ────────────────────────────────────────────────────────

  static List<double> _downsampleGray(
      Uint8List src, int srcW, int srcH, int dstW, int dstH) {
    return List.generate(dstH * dstW, (i) {
      final y  = i ~/ dstW;
      final x  = i % dstW;
      final sy = (y / dstH * srcH).floor().clamp(0, srcH - 1);
      final sx = (x / dstW * srcW).floor().clamp(0, srcW - 1);
      final si = (sy * srcW + sx) * 4;
      return _lum(src[si], src[si + 1], src[si + 2]).toDouble();
    });
  }

  static Uint8List _grayToRgbaUpscale(
      List<double> norm, int srcW, int srcH, int dstW, int dstH) {
    final dst = Uint8List(dstW * dstH * 4);
    for (int y = 0; y < dstH; y++) {
      for (int x = 0; x < dstW; x++) {
        final sy  = (y / dstH * srcH).floor().clamp(0, srcH - 1);
        final sx  = (x / dstW * srcW).floor().clamp(0, srcW - 1);
        final val = (norm[sy * srcW + sx] * 255).round().clamp(0, 255);
        final di  = (y * dstW + x) * 4;
        dst[di] = dst[di + 1] = dst[di + 2] = val;
        dst[di + 3] = 255;
      }
    }
    return dst;
  }

  /// 2D FFT magnitude dengan fftshift (DC di tengah).
  static List<double> _fft2dMagnitude(List<double> gray, int w, int h) {
    // Row FFT.
    final rows = List.generate(h, (y) {
      final row = List.generate(w, (x) => _Complex(gray[y * w + x], 0));
      _fft1d(row, inverse: false);
      return row;
    });

    // Column FFT + fftshift + magnitude.
    final mag = List<double>.filled(w * h, 0);
    for (int x = 0; x < w; x++) {
      final col = List.generate(h, (y) => rows[y][x]);
      _fft1d(col, inverse: false);
      for (int y = 0; y < h; y++) {
        final sy = (y + h ~/ 2) % h;
        final sx = (x + w ~/ 2) % w;
        mag[sy * w + sx] = col[y].magnitude;
      }
    }
    return mag;
  }

  /// 2D FFT → low-pass filter → IFFT → real part.
  static List<double> _ifft2dLowpass(
      List<double> gray, int w, int h, double cutoffRatio) {
    // Forward FFT (row → column).
    final spectrum = List.generate(h, (y) {
      final row = List.generate(w, (x) => _Complex(gray[y * w + x], 0));
      _fft1d(row, inverse: false);
      return row;
    });
    for (int x = 0; x < w; x++) {
      final col = List.generate(h, (y) => spectrum[y][x]);
      _fft1d(col, inverse: false);
      for (int y = 0; y < h; y++) spectrum[y][x] = col[y];
    }

    // Circular low-pass filter di domain tak-tertransform (non-shifted).
    final cutPx = cutoffRatio * math.min(w, h) / 2.0;
    for (int y = 0; y < h; y++) {
      final fy = (y <= h ~/ 2 ? y : h - y).toDouble();
      for (int x = 0; x < w; x++) {
        final fx   = (x <= w ~/ 2 ? x : w - x).toDouble();
        final dist = math.sqrt(fx * fx + fy * fy);
        if (dist > cutPx) spectrum[y][x] = const _Complex(0, 0);
      }
    }

    // Inverse FFT (column → row).
    for (int x = 0; x < w; x++) {
      final col = List.generate(h, (y) => spectrum[y][x]);
      _fft1d(col, inverse: true);
      for (int y = 0; y < h; y++) spectrum[y][x] = col[y];
    }
    final result = List<double>.filled(w * h, 0);
    for (int y = 0; y < h; y++) {
      final row = List<_Complex>.from(spectrum[y]);
      _fft1d(row, inverse: true);
      for (int x = 0; x < w; x++) result[y * w + x] = row[x].re;
    }
    return result;
  }

  /// Radix-2 Cooley-Tukey FFT in-place.
  /// [data] harus berukuran pangkat-2.
  static void _fft1d(List<_Complex> data, {required bool inverse}) {
    final n = data.length;
    if (n <= 1) return;

    // Bit-reversal permutation.
    for (int i = 1, j = 0; i < n; i++) {
      int bit = n >> 1;
      for (; j & bit != 0; bit >>= 1) j ^= bit;
      j ^= bit;
      if (i < j) {
        final t = data[i];
        data[i] = data[j];
        data[j] = t;
      }
    }

    // Butterfly stages.
    for (int len = 2; len <= n; len <<= 1) {
      final ang   = 2 * math.pi / len * (inverse ? 1 : -1);
      final wStep = _Complex(math.cos(ang), math.sin(ang));
      for (int i = 0; i < n; i += len) {
        _Complex w = const _Complex(1, 0);
        for (int k = 0; k < len >> 1; k++) {
          final u = data[i + k];
          final v = data[i + k + len ~/ 2] * w;
          data[i + k]            = u + v;
          data[i + k + len ~/ 2] = u - v;
          w = w * wStep;
        }
      }
    }

    if (inverse) {
      for (int i = 0; i < n; i++) {
        data[i] = _Complex(data[i].re / n, data[i].im / n);
      }
    }
  }

  // ─── ui.Image ↔ Uint8List Utilities ─────────────────────────────────────

  static Future<({Uint8List bytes, int width, int height})> imageToRgba(
      ui.Image image) async {
    final bd = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return (
      bytes: bd!.buffer.asUint8List(),
      width: image.width,
      height: image.height,
    );
  }

  static Future<ui.Image> rgbaToImage(Uint8List bytes, int width, int height) {
    final c = Completer<ui.Image>();
    ui.decodeImageFromPixels(bytes, width, height, ui.PixelFormat.rgba8888, c.complete);
    return c.future;
  }
}

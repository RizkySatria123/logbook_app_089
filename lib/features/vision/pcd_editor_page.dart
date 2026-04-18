import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pcd_processor.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Top-level isolate functions untuk compute() — WAJIB di luar class.
// Parameter dikirim sebagai Map<String, dynamic> karena Uint8List + primitif
// semuanya serializable lintas isolat di Flutter.
// ─────────────────────────────────────────────────────────────────────────────

Uint8List _isoBlur(Map<String, dynamic> p) => PcdProcessor.gaussianBlur(
    p['b'] as Uint8List, p['w'] as int, p['h'] as int, p['k'] as int, p['s'] as double);

Uint8List _isoUnsharp(Map<String, dynamic> p) => PcdProcessor.unsharpMask(
    p['b'] as Uint8List, p['w'] as int, p['h'] as int, p['a'] as double, p['s'] as double);

Uint8List _isoEdge(Map<String, dynamic> p) => PcdProcessor.edgeDetection(
    p['b'] as Uint8List, p['w'] as int, p['h'] as int, p['t'] as int);

Uint8List _isoMedian(Map<String, dynamic> p) => PcdProcessor.medianFilter(
    p['b'] as Uint8List, p['w'] as int, p['h'] as int, p['k'] as int);

Uint8List _isoFourier(Map<String, dynamic> p) => PcdProcessor.fourierSpectrum(
    p['b'] as Uint8List, p['w'] as int, p['h'] as int);

Uint8List _isoIFourier(Map<String, dynamic> p) => PcdProcessor.inverseFourier(
    p['b'] as Uint8List, p['w'] as int, p['h'] as int, cutoffRatio: p['c'] as double);

// ─────────────────────────────────────────────────────────────────────────────
// Enum & model data operasi PCD.
// ─────────────────────────────────────────────────────────────────────────────

enum _Op {
  brightness,
  histogramEq,
  gaussianBlur,
  unsharpMask,
  edgeDetection,
  binaryThreshold,
  medianFilter,
  gammaCorrection,
  fourier,
  inverseFourier,
}

class _OpInfo {
  final _Op op;
  final String name;
  final IconData icon;
  const _OpInfo(this.op, this.name, this.icon);
}

const _operations = [
  _OpInfo(_Op.brightness,      'Brightness &\nContrast',       Icons.brightness_6_rounded),
  _OpInfo(_Op.histogramEq,     'Histogram\nEqualization',      Icons.bar_chart_rounded),
  _OpInfo(_Op.gaussianBlur,    'Gaussian\nBlur',               Icons.blur_on_rounded),
  _OpInfo(_Op.unsharpMask,     'Unsharp\nMask',                Icons.auto_fix_high_rounded),
  _OpInfo(_Op.edgeDetection,   'Edge\nDetection',              Icons.grain_rounded),
  _OpInfo(_Op.binaryThreshold, 'Binary\nThreshold',            Icons.tonality_rounded),
  _OpInfo(_Op.medianFilter,    'Median\nFilter',               Icons.filter_b_and_w_rounded),
  _OpInfo(_Op.gammaCorrection, 'Gamma\nCorrection',            Icons.wb_sunny_rounded),
  _OpInfo(_Op.fourier,         'Fourier\nSpectrum',            Icons.waves_rounded),
  _OpInfo(_Op.inverseFourier,  'Inverse\nFourier',             Icons.settings_backup_restore_rounded),
];

// ─────────────────────────────────────────────────────────────────────────────
// Constants & Design tokens
// ─────────────────────────────────────────────────────────────────────────────

const _kBg     = Color(0xFF0A0E1A);
const _kPanel  = Color(0xFF141929);
const _kCard   = Color(0xFF1C2235);
const _kAccent = Color(0xFF3D5AFE);
const _kGreen  = Color(0xFF00FF88);

// ─────────────────────────────────────────────────────────────────────────────
// [PcdEditorPage] — Halaman edit gambar dengan filter PCD.
// ─────────────────────────────────────────────────────────────────────────────

class PcdEditorPage extends StatefulWidget {
  /// Path file foto yang diambil dari kamera.
  final String imagePath;
  const PcdEditorPage({super.key, required this.imagePath});

  @override
  State<PcdEditorPage> createState() => _PcdEditorPageState();
}

class _PcdEditorPageState extends State<PcdEditorPage>
    with SingleTickerProviderStateMixin {
  // ─── Image state ──────────────────────────────────────────────────────────
  ui.Image? _originalUiImage;
  ui.Image? _displayUiImage;
  Uint8List? _originalBytes;
  int _imgW = 0, _imgH = 0;
  bool _isLoading    = true;
  bool _isProcessing = false;
  bool _showOriginal = false;

  // ─── Operation state ──────────────────────────────────────────────────────
  _Op _selectedOp = _Op.brightness;
  late final TabController _tabCtrl;

  // ─── Parameter values per operation ──────────────────────────────────────
  // [brightness]
  double _alpha = 1.0;
  double _beta  = 0.0;
  // [gaussianBlur]
  double _blurSigma  = 1.5;
  double _blurKernel = 5; // 3 or 5
  // [unsharpMask]
  double _unsharpAmount = 1.5;
  double _unsharpSigma  = 1.0;
  // [edgeDetection]
  double _edgeThreshold = 40.0;
  // [binaryThreshold]
  double _binThreshold = 128.0;
  // [medianFilter]
  double _medianKernel = 3; // 3 or 5
  // [gammaCorrection]
  double _gamma = 1.0;
  // [inverseFourier]
  double _cutoff = 0.5;

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _operations.length, vsync: this)
      ..addListener(() {
        if (!_tabCtrl.indexIsChanging) {
          setState(() => _selectedOp = _operations[_tabCtrl.index].op);
        }
      });
    _loadImage();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ─── Image loading ────────────────────────────────────────────────────────

  Future<void> _loadImage() async {
    try {
      final bytes    = await File(widget.imagePath).readAsBytes();
      final uiImage  = await _decodeUiImage(bytes);
      final rgba     = await PcdProcessor.imageToRgba(uiImage);
      if (!mounted) return;
      setState(() {
        _originalBytes  = rgba.bytes;
        _imgW           = rgba.width;
        _imgH           = rgba.height;
        _originalUiImage = uiImage;
        _displayUiImage  = uiImage;
        _isLoading       = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Gagal memuat gambar: $e');
    }
  }

  Future<ui.Image> _decodeUiImage(List<int> bytes) async {
    final codec = await ui.instantiateImageCodecFromBuffer(
      await ui.ImmutableBuffer.fromUint8List(
          Uint8List.fromList(bytes)));
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  // ─── Apply operation ──────────────────────────────────────────────────────

  Future<void> _applyOperation() async {
    if (_originalBytes == null || _isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final Uint8List result;
      final b = _originalBytes!;
      final w = _imgW, h = _imgH;

      switch (_selectedOp) {
        // ── Light ops: run on main isolate (< 5ms) ─────────────────────────
        case _Op.brightness:
          result = PcdProcessor.brightnessContrast(b, _alpha, _beta);
        case _Op.histogramEq:
          result = PcdProcessor.histogramEqualization(b, w, h);
        case _Op.binaryThreshold:
          result = PcdProcessor.binaryThreshold(b, w, h, _binThreshold.toInt());
        case _Op.gammaCorrection:
          result = PcdProcessor.gammaCorrection(b, _gamma);

        // ── Heavy ops: run in background isolate via compute() ─────────────
        case _Op.gaussianBlur:
          result = await compute(_isoBlur,
              {'b': b, 'w': w, 'h': h, 'k': _blurKernel.toInt(), 's': _blurSigma});
        case _Op.unsharpMask:
          result = await compute(_isoUnsharp,
              {'b': b, 'w': w, 'h': h, 'a': _unsharpAmount, 's': _unsharpSigma});
        case _Op.edgeDetection:
          result = await compute(_isoEdge,
              {'b': b, 'w': w, 'h': h, 't': _edgeThreshold.toInt()});
        case _Op.medianFilter:
          result = await compute(_isoMedian,
              {'b': b, 'w': w, 'h': h, 'k': _medianKernel.toInt()});
        case _Op.fourier:
          result = await compute(_isoFourier, {'b': b, 'w': w, 'h': h});
        case _Op.inverseFourier:
          result = await compute(_isoIFourier,
              {'b': b, 'w': w, 'h': h, 'c': _cutoff});
      }

      final newImage = await PcdProcessor.rgbaToImage(result, _imgW, _imgH);
      if (!mounted) return;
      setState(() {
        _displayUiImage = newImage;
        _isProcessing   = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showError('Proses gagal: $e');
    }
  }

  void _resetToOriginal() {
    if (_originalUiImage == null) return;
    HapticFeedback.lightImpact();
    setState(() => _displayUiImage = _originalUiImage);
  }

  Future<void> _saveResult() async {
    if (_displayUiImage == null) return;
    try {
      final bd = await _displayUiImage!.toByteData(format: ui.ImageByteFormat.png);
      if (bd == null) return;
      final dir      = File(widget.imagePath).parent.path;
      final base     = File(widget.imagePath).uri.pathSegments.last
          .replaceAll(RegExp(r'\.(jpg|jpeg|png)$', caseSensitive: false), '');
      final ts       = DateTime.now().millisecondsSinceEpoch;
      final savePath = '$dir/${base}_pcd_$ts.png';
      await File(savePath).writeAsBytes(bd.buffer.asUint8List());
      if (!mounted) return;
      _showSnackbar('✅  Gambar disimpan: ${savePath.split('/').last.split(r'\').last}');
    } catch (e) {
      _showError('Gagal menyimpan: $e');
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoading() : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _kPanel,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: const Text(
        'Preview & PCD',
        style: TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      actions: [
        // Reset ke original
        IconButton(
          tooltip: 'Reset ke original',
          icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
          onPressed: _resetToOriginal,
        ),
        // Simpan hasil
        IconButton(
          tooltip: 'Simpan hasil',
          icon: const Icon(Icons.save_alt_rounded, color: Colors.white70),
          onPressed: _saveResult,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: _kGreen),
          SizedBox(height: 16),
          Text('Memuat gambar...',
              style: TextStyle(color: _kGreen, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // ── 1. Image preview ───────────────────────────────────────────────
        Expanded(child: _buildImagePreview()),

        // ── 2. Operation name banner ───────────────────────────────────────
        _buildBanner(),

        // ── 3. Tab bar ─────────────────────────────────────────────────────
        _buildTabBar(),

        // ── 4. Parameter controls ──────────────────────────────────────────
        _buildParameterPanel(),

        // ── 5. Apply button ────────────────────────────────────────────────
        _buildApplyButton(),

        SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
      ],
    );
  }

  // ─── Image Preview ────────────────────────────────────────────────────────

  Widget _buildImagePreview() {
    final image = _showOriginal ? _originalUiImage : _displayUiImage;

    return GestureDetector(
      onLongPressStart: (_) {
        HapticFeedback.mediumImpact();
        setState(() => _showOriginal = true);
      },
      onLongPressEnd: (_) => setState(() => _showOriginal = false),
      onLongPressCancel: () => setState(() => _showOriginal = false),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Container(color: Colors.black),

          // Image
          if (image != null)
            Center(
              child: RawImage(
                image: image,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: _kAccent, strokeWidth: 3),
                    SizedBox(height: 14),
                    Text('Memproses...', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ),

          // "Tap & hold" hint
          if (!_isProcessing)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _showOriginal ? 'Menampilkan Original' : 'Tahan untuk lihat original',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Banner ───────────────────────────────────────────────────────────────

  Widget _buildBanner() {
    final info = _operations.firstWhere((o) => o.op == _selectedOp);
    return Container(
      width: double.infinity,
      color: _kAccent,
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Text(
        'Operation: ${info.name.replaceAll('\n', ' ')}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ─── Tab Bar ──────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: _kPanel,
      height: 88,
      child: TabBar(
        controller: _tabCtrl,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: _kAccent,
        indicatorWeight: 3,
        labelColor: _kAccent,
        unselectedLabelColor: Colors.white38,
        dividerColor: Colors.transparent,
        tabs: _operations.map((info) {
          final selected = _selectedOp == info.op;
          return Tab(
            height: 82,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(info.icon,
                    size: 24,
                    color: selected ? _kAccent : Colors.white38),
                const SizedBox(height: 4),
                Text(
                  info.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.3,
                    color: selected ? _kAccent : Colors.white38,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Parameter Panel ──────────────────────────────────────────────────────

  Widget _buildParameterPanel() {
    return Container(
      height: 160,
      color: _kCard,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SingleChildScrollView(child: _buildControls()),
    );
  }

  Widget _buildControls() {
    switch (_selectedOp) {
      case _Op.brightness:
        return Column(children: [
          _slider('Alpha (Contrast)', _alpha, 0.1, 3.0,
              fmt: (v) => v.toStringAsFixed(2),
              onChanged: (v) => setState(() => _alpha = v)),
          const SizedBox(height: 6),
          _slider('Beta (Brightness)', _beta, -100, 100,
              fmt: (v) => v.toStringAsFixed(1),
              onChanged: (v) => setState(() => _beta = v)),
        ]);

      case _Op.histogramEq:
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Tidak ada parameter.\nTekan Apply untuk menerapkan Histogram Equalization.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.6),
            ),
          ),
        );

      case _Op.gaussianBlur:
        return Column(children: [
          _slider('Sigma', _blurSigma, 0.5, 5.0,
              fmt: (v) => v.toStringAsFixed(1),
              onChanged: (v) => setState(() => _blurSigma = v)),
          const SizedBox(height: 6),
          _discreteRow('Kernel Size', _blurKernel, [3, 5, 7],
              onChanged: (v) => setState(() => _blurKernel = v)),
        ]);

      case _Op.unsharpMask:
        return Column(children: [
          _slider('Amount', _unsharpAmount, 0.5, 5.0,
              fmt: (v) => v.toStringAsFixed(1),
              onChanged: (v) => setState(() => _unsharpAmount = v)),
          const SizedBox(height: 6),
          _slider('Sigma (blur radius)', _unsharpSigma, 0.3, 3.0,
              fmt: (v) => v.toStringAsFixed(1),
              onChanged: (v) => setState(() => _unsharpSigma = v)),
        ]);

      case _Op.edgeDetection:
        return Column(children: [
          _slider('Sobel Threshold', _edgeThreshold, 5, 200,
              fmt: (v) => v.toInt().toString(),
              onChanged: (v) => setState(() => _edgeThreshold = v)),
          const SizedBox(height: 4),
          Text('(Gradient magnitude > threshold → edge)',
              style: TextStyle(color: Colors.white30, fontSize: 11)),
        ]);

      case _Op.binaryThreshold:
        return Column(children: [
          _slider('Threshold', _binThreshold, 0, 255,
              divisions: 255,
              fmt: (v) => v.toInt().toString(),
              onChanged: (v) => setState(() => _binThreshold = v)),
          const SizedBox(height: 4),
          Text('Luminance > ${_binThreshold.toInt()} → putih, sisanya → hitam',
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ]);

      case _Op.medianFilter:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _discreteRow('Kernel Size', _medianKernel, [3, 5],
              onChanged: (v) => setState(() => _medianKernel = v)),
          const SizedBox(height: 8),
          const Text(
            '3×3 direkomendasikan untuk kecepatan pada resolusi penuh.',
            style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.5),
          ),
        ]);

      case _Op.gammaCorrection:
        return Column(children: [
          _slider('Gamma (γ)', _gamma, 0.1, 4.0,
              fmt: (v) => v.toStringAsFixed(2),
              onChanged: (v) => setState(() => _gamma = v)),
          const SizedBox(height: 4),
          Text('γ < 1.0: cerahkan  |  γ = 1.0: asli  |  γ > 1.0: gelapkan',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ]);

      case _Op.fourier:
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Menampilkan Magnitude Spectrum 2D DFT (log-scale).\n'
              'Titik terang di tengah = komponen DC (frekuensi rendah).\n'
              'Tepi gambar = komponen frekuensi tinggi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.6),
            ),
          ),
        );

      case _Op.inverseFourier:
        return Column(children: [
          _slider('Cutoff Ratio', _cutoff, 0.05, 1.0,
              fmt: (v) => '${(v * 100).toStringAsFixed(0)}%',
              onChanged: (v) => setState(() => _cutoff = v)),
          const SizedBox(height: 4),
          Text(
            '${(_cutoff * 100).toStringAsFixed(0)}% frekuensi terendah di-pass → '
            '${_cutoff < 0.3 ? "sangat blur" : _cutoff < 0.7 ? "sedikit blur" : "hampir identik"}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ]);
    }
  }

  // ─── Apply Button ─────────────────────────────────────────────────────────

  Widget _buildApplyButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: _isProcessing
                  ? [Colors.grey.shade800, Colors.grey.shade700]
                  : [const Color(0xFF3D5AFE), const Color(0xFF7986CB)],
            ),
            boxShadow: _isProcessing
                ? []
                : [
                    BoxShadow(
                      color: _kAccent.withAlpha(80),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
          ),
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _applyOperation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: _isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_fix_high_rounded,
                    color: Colors.white, size: 20),
            label: Text(
              _isProcessing ? 'Memproses...' : '✦  Apply',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Reusable slider widget ───────────────────────────────────────────────

  Widget _slider(
    String label,
    double value,
    double min,
    double max, {
    int? divisions,
    required String Function(double) fmt,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('$label: ${fmt(value)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: _kAccent,
            inactiveTrackColor: Colors.white12,
            thumbColor: _kAccent,
            overlayColor: _kAccent.withAlpha(40),
            trackHeight: 3.5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // ─── Discrete value selector (kernel size, etc.) ──────────────────────────

  Widget _discreteRow(
    String label,
    double current,
    List<int> options, {
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Text('$label:', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(width: 12),
        ...options.map((v) {
          final selected = current.toInt() == v;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(v.toDouble()),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? _kAccent : Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: selected ? _kAccent : Colors.white12, width: 1.5),
                ),
                child: Text(
                  '${v}x$v',
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFFF3B30),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showSnackbar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: _kGreen, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
      ]),
      backgroundColor: _kPanel,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: _kGreen, width: 1),
      ),
    ));
  }
}

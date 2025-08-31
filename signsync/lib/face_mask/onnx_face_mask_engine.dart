import 'dart:async';
import 'package:camera/camera.dart';
import 'dart:typed_data';
import 'dart:ui' show Rect;
import 'package:flutter/services.dart' show rootBundle;
import 'package:signsync/face_mask/face_mask_engine.dart';
import 'package:onnxruntime/onnxruntime.dart' as ort;

/*
  ONNX Runtime Engine (Skeleton)

  To use your ONNX facemask model on-device, add a dependency on
  the onnxruntime Flutter plugin, then implement this engine.

  1) Add to pubspec.yaml:
       dependencies:
         onnxruntime: ^1.17.0   # or latest

  2) Put your model under assets and list it, e.g.:
       flutter:
         assets:
           - assets/models/facemask.onnx

  3) Implement the code below to create an ORT session and run inference.

  Notes:
  - Your model's input tensor shape and pre/post-processing are model-specific.
  - If your model expects RGB 224x224 floats, you must convert CameraImage
    YUV -> RGB, resize, normalize and feed as a tensor.
  - For YOLO-like models, you will need to decode boxes/scores and NMS.

  This class is intentionally left as a placeholder so the app compiles even
  without the plugin. Once you add onnxruntime, fill in the TODOs.
*/

class OnnxFaceMaskEngine implements FaceMaskEngine {
  final String assetModelPath;
  // Model/input config (tune to your model as needed)
  final int inputWidth;
  final int inputHeight;
  final double scoreThreshold;
  final Map<int, String>? classLabels; // optional mapping id -> label

  bool _loaded = false;
  ort.OrtSession? _session;
  late List<String> _inputs;
  late List<String> _outputs;

  OnnxFaceMaskEngine({
    required this.assetModelPath,
    this.inputWidth = 640,
    this.inputHeight = 640,
    this.scoreThreshold = 0.5,
    this.classLabels,
  });

  @override
  Future<void> load() async {
    // Load model bytes from assets to validate the path exists and
    // initialize an ONNX Runtime session (CPU by default).
    final raw = await rootBundle.load(assetModelPath);
    final bytes = raw.buffer.asUint8List();

    // Init ORT env if not already.
    ort.OrtEnv.instance.init();
    final opts = ort.OrtSessionOptions()
      ..setSessionGraphOptimizationLevel(ort.GraphOptimizationLevel.ortEnableAll)
      ..setIntraOpNumThreads(1)
      ..appendCPUProvider(ort.CPUFlags.useArena);

    final s = ort.OrtSession.fromBuffer(bytes, opts);
    _session = s;
    _inputs = s.inputNames;
    _outputs = s.outputNames;

    // Helpful log for wiring. Remove or lower in production.
    // ignore: avoid_print
    print('ORT loaded: inputs=$_inputs outputs=$_outputs');

    _loaded = true;
  }

  @override
  Future<List<FaceMaskResult>> detect(CameraImage image, int rotationDegrees) async {
    if (!_loaded) {
      throw StateError('OnnxFaceMaskEngine not loaded. Call load() first.');
    }
    if (_session == null) return const <FaceMaskResult>[];

    // --- 1) Preprocess YUV420 -> model tensor (Float32, NHWC or NCHW) ---
    final rgb = _yuv420ToRGB(image);
    final resized = _resizeRGB(rgb, image.width, image.height, inputWidth, inputHeight);
    final floatNHWC = _toFloatNHWC(resized, inputWidth, inputHeight, scale: 1 / 255.0);
    final floatNCHW = _toFloatNCHW(floatNHWC, inputWidth, inputHeight);

    final inputName = _inputs.first;
    final runOptions = ort.OrtRunOptions();

    List<ort.OrtValue?>? outputs;
    // Try NHWC first, then NCHW.
    try {
      final inp = ort.OrtValueTensor.createTensorWithDataList(
        floatNHWC,
        [1, inputHeight, inputWidth, 3],
      );
      final Map<String, ort.OrtValue> feed = {inputName: inp};
      outputs = _session!.run(runOptions, feed);
      inp.release();
    } catch (_) {
      // Try NCHW
      try {
        final inp = ort.OrtValueTensor.createTensorWithDataList(
          floatNCHW,
          [1, 3, inputHeight, inputWidth],
        );
        final Map<String, ort.OrtValue> feed = {inputName: inp};
        outputs = _session!.run(runOptions, feed);
        inp.release();
      } catch (e) {
        // ignore per-frame errors
        return const <FaceMaskResult>[];
      }
    }

    if (outputs == null || outputs.isEmpty) {
      return const <FaceMaskResult>[];
    }

    // --- 2) Decode outputs into [x1,y1,x2,y2,score,cls] rows ---
    final dets = _decodeDetections(outputs);
    for (final o in outputs) {
      try {
        o?.release();
      } catch (_) {}
    }

    // --- 3) Convert to FaceMaskResult with normalized boxes ---
    final results = <FaceMaskResult>[];
    for (final d in dets) {
      final x1 = d[0];
      final y1 = d[1];
      final x2 = d[2];
      final y2 = d[3];
      final score = d[4];
      final cls = d[5].round();
      if (score < scoreThreshold) continue;

      // Normalize if values look like pixels.
      double nx1 = x1, ny1 = y1, nx2 = x2, ny2 = y2;
      if (nx2 > 1.0 || ny2 > 1.0) {
        nx1 /= inputWidth;
        nx2 /= inputWidth;
        ny1 /= inputHeight;
        ny2 /= inputHeight;
      }
      final w = (nx2 - nx1).clamp(0.0, 1.0).toDouble();
      final h = (ny2 - ny1).clamp(0.0, 1.0).toDouble();
      final l = nx1.clamp(0.0, 1.0).toDouble();
      final t = ny1.clamp(0.0, 1.0).toDouble();

      final label = classLabels?[cls] ?? 'class-$cls';
      results.add(FaceMaskResult(
        box: Rect.fromLTWH(l, t, w, h),
        label: label,
        score: score.clamp(0.0, 1.0).toDouble(),
      ));
    }
    return results;
  }

  @override
  Future<void> dispose() async {
    try {
      _session?.release();
    } catch (_) {}
  }
}

// ----------------- Helpers -----------------

// Basic YUV420 (three planes) to RGB conversion. Returns Uint8List of length w*h*3.
Uint8List _yuv420ToRGB(CameraImage image) {
  final w = image.width;
  final h = image.height;
  final yPlane = image.planes[0];
  final uPlane = image.planes[1];
  final vPlane = image.planes[2];
  final out = Uint8List(w * h * 3);

  int o = 0;
  for (int y = 0; y < h; y++) {
    final uvRow = (y / 2).floor();
    for (int x = 0; x < w; x++) {
      final yIndex = y * yPlane.bytesPerRow + x;
      final uvCol = (x / 2).floor();
      final uPix = uPlane.bytesPerPixel ?? 1;
      final vPix = vPlane.bytesPerPixel ?? 1;
      final uIndex = uvRow * uPlane.bytesPerRow + uvCol * uPix;
      final vIndex = uvRow * vPlane.bytesPerRow + uvCol * vPix;

      final Y = yPlane.bytes[yIndex];
      final U = uPlane.bytes[uIndex];
      final V = vPlane.bytes[vIndex];

      // Convert YUV -> RGB (BT.601)
      double yf = Y.toDouble();
      double uf = U.toDouble() - 128.0;
      double vf = V.toDouble() - 128.0;
      int r = (yf + 1.402 * vf).round();
      int g = (yf - 0.344136 * uf - 0.714136 * vf).round();
      int b = (yf + 1.772 * uf).round();
      if (r < 0) r = 0; else if (r > 255) r = 255;
      if (g < 0) g = 0; else if (g > 255) g = 255;
      if (b < 0) b = 0; else if (b > 255) b = 255;

      out[o++] = r;
      out[o++] = g;
      out[o++] = b;
    }
  }
  return out;
}

// Nearest-neighbor resize for RGB buffer (HWC, 8-bit per channel)
Uint8List _resizeRGB(Uint8List src, int sw, int sh, int dw, int dh) {
  final dst = Uint8List(dw * dh * 3);
  for (int j = 0; j < dh; j++) {
    final sy = ((j * sh) / dh).floor();
    for (int i = 0; i < dw; i++) {
      final sx = ((i * sw) / dw).floor();
      final sIdx = (sy * sw + sx) * 3;
      final dIdx = (j * dw + i) * 3;
      dst[dIdx] = src[sIdx];
      dst[dIdx + 1] = src[sIdx + 1];
      dst[dIdx + 2] = src[sIdx + 2];
    }
  }
  return dst;
}

// Convert HWC uint8 RGB to NHWC float32 with scaling and no mean/std
List<double> _toFloatNHWC(Uint8List rgb, int w, int h, {double scale = 1.0}) {
  final out = List<double>.filled(w * h * 3, 0.0, growable: false);
  for (int i = 0; i < w * h; i++) {
    out[i * 3 + 0] = rgb[i * 3 + 0] * scale;
    out[i * 3 + 1] = rgb[i * 3 + 1] * scale;
    out[i * 3 + 2] = rgb[i * 3 + 2] * scale;
  }
  return out;
}

// Convert NHWC float to NCHW float
List<double> _toFloatNCHW(List<double> nhwc, int w, int h) {
  final out = List<double>.filled(3 * h * w, 0.0, growable: false);
  // channel-major
  int o = 0;
  // R plane
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final i = (y * w + x) * 3;
      out[o++] = nhwc[i + 0];
    }
  }
  // G plane
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final i = (y * w + x) * 3;
      out[o++] = nhwc[i + 1];
    }
  }
  // B plane
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final i = (y * w + x) * 3;
      out[o++] = nhwc[i + 2];
    }
  }
  return out;
}

// Attempt to decode detections from ORT outputs. Handles:
// - Single tensor [N,6] or [1,N,6]: x1,y1,x2,y2,score,class
// - Separate outputs: boxes [N,4], scores [N], classes [N]
List<List<double>> _decodeDetections(List<ort.OrtValue?> outs) {
  // Try single output first.
  final o0 = outs[0];
  if (o0 != null) {
    final rows = _rows2D(o0.value);
    if (rows.isNotEmpty && (rows.first.length >= 6)) {
      return rows
          .map((r) => [r[0].toDouble(), r[1].toDouble(), r[2].toDouble(), r[3].toDouble(), r[4].toDouble(), r[5].toDouble()])
          .toList();
    }
  }

  // Try to find boxes/scores/classes among outputs
  List<List<double>> boxes = [];
  List<double> scores = [];
  List<double> classes = [];

  for (final o in outs) {
    if (o == null) continue;
    final shapeRows = _rows2D(o.value);
    if (shapeRows.isNotEmpty) {
      final cols = shapeRows.first.length;
      if (cols == 4) {
        boxes = shapeRows
            .map((r) => [r[0].toDouble(), r[1].toDouble(), r[2].toDouble(), r[3].toDouble()])
            .toList();
        continue;
      }
    }
    // 1D vector
    final vec = _vector1D(o.value);
    if (vec.isNotEmpty) {
      // Heuristic: scores are [0..1], classes are integers-ish
      final avg = vec.reduce((a, b) => a + b) / vec.length;
      final isScore = avg >= 0.0 && avg <= 1.0;
      if (isScore && scores.isEmpty) {
        scores = vec;
      } else if (classes.isEmpty) {
        classes = vec;
      }
    }
  }

  final n = [boxes.length, scores.length, classes.length].reduce((a, b) => a > b ? a : b);
  final out = <List<double>>[];
  for (int i = 0; i < n; i++) {
    final b = i < boxes.length ? boxes[i] : <double>[0.0, 0.0, 0.0, 0.0];
    final s = i < scores.length ? scores[i] : 0.0;
    final c = i < classes.length ? classes[i] : 0.0;
    out.add([
      (b[0]).toDouble(),
      (b[1]).toDouble(),
      (b[2]).toDouble(),
      (b[3]).toDouble(),
      s.toDouble(),
      c.toDouble(),
    ]);
  }
  return out;
}

List<List<double>> _rows2D(dynamic v) {
  // Descend until we reach a 2D list whose elements are numbers
  dynamic cur = v;
  while (cur is List && cur.isNotEmpty && cur.first is List) {
    final first = cur.first;
    if (first is List && first.isNotEmpty && first.first is num) {
      break;
    }
    cur = first;
  }
  if (cur is List && cur.isNotEmpty && cur.first is List) {
    final rows = <List<double>>[];
    for (final row in cur) {
      if (row is List) {
        rows.add(row.map((e) => (e as num).toDouble()).toList());
      }
    }
    return rows;
  }
  return const [];
}

List<double> _vector1D(dynamic v) {
  // Descend to a 1D list of numbers (e.g., [N])
  dynamic cur = v;
  while (cur is List && cur.isNotEmpty && cur.first is List) {
    cur = cur.first;
  }
  if (cur is List && (cur.isEmpty || cur.first is num)) {
    return cur.cast<num>().map((e) => e.toDouble()).toList();
  }
  return const [];
}

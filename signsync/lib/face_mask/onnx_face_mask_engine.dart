import 'dart:async';
import 'package:camera/camera.dart';
import 'dart:typed_data';
import 'dart:ui' show Rect;
import 'package:flutter/services.dart' show rootBundle;
import 'package:signsync/face_mask/face_mask_engine.dart';
import 'package:onnxruntime/onnxruntime.dart' as ort;
import 'dart:math' as math;

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
  double scoreThreshold;

  /// True if head layout is [cx,cy,w,h, obj?, class1..C]. Default true.
  final bool hasObjectness;
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
    this.hasObjectness = true,
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
      ..setSessionGraphOptimizationLevel(
        ort.GraphOptimizationLevel.ortEnableAll,
      )
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
  Future<List<FaceMaskResult>> detect(
    CameraImage image,
    int rotationDegrees,
  ) async {
    if (!_loaded) {
      throw StateError('OnnxFaceMaskEngine not loaded. Call load() first.');
    }
    if (_session == null) return const <FaceMaskResult>[];

    // --- 1) Preprocess: YUV420 -> RGB -> letterbox to [inputWidth,inputHeight] ---
    final srcW = image.width;
    final srcH = image.height;
    final rgb = _yuv420ToRGB(image);

    // Letterbox resize keeping aspect ratio
    final scale = math.min(inputWidth / srcW, inputHeight / srcH);
    final newW = (srcW * scale).round();
    final newH = (srcH * scale).round();
    final padX = ((inputWidth - newW) / 2).floor();
    final padY = ((inputHeight - newH) / 2).floor();

    final resized = _resizeRGB(rgb, srcW, srcH, newW, newH);
    final letterboxed = _padRGB(
      resized,
      newW,
      newH,
      inputWidth,
      inputHeight,
      padX,
      padY,
      fill: 114,
    );
    final floatNHWC = _toFloatNHWC(
      letterboxed,
      inputWidth,
      inputHeight,
      scale: 1 / 255.0,
    );
    final floatNCHW = _toFloatNCHW(floatNHWC, inputWidth, inputHeight);

    final inputName = _inputs.first;
    final runOptions = ort.OrtRunOptions();

    List<ort.OrtValue?>? outputs;
    // Try NHWC first, then NCHW (some exports keep channels-last).
    try {
      final inp = ort.OrtValueTensor.createTensorWithDataList(floatNHWC, [
        1,
        inputHeight,
        inputWidth,
        3,
      ]);
      final Map<String, ort.OrtValue> feed = {inputName: inp};
      outputs = _session!.run(runOptions, feed);
      inp.release();
    } catch (_) {
      // Try NCHW
      try {
        final inp = ort.OrtValueTensor.createTensorWithDataList(floatNCHW, [
          1,
          3,
          inputHeight,
          inputWidth,
        ]);
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

    // --- 2) Decode YOLO-style outputs into [x1,y1,x2,y2,score,cls] (pixels in src space) ---
    final dets = _decodeYoloDetections(
      outputs,
      imgW: srcW,
      imgH: srcH,
      inputW: inputWidth,
      inputH: inputHeight,
      padX: padX,
      padY: padY,
      scale: scale,
      hasObjectness: hasObjectness,
      scoreThresh: scoreThreshold,
    );
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

      // Normalize to source frame size
      double nx1 = (x1 / srcW).clamp(0.0, 1.0);
      double ny1 = (y1 / srcH).clamp(0.0, 1.0);
      double nx2 = (x2 / srcW).clamp(0.0, 1.0);
      double ny2 = (y2 / srcH).clamp(0.0, 1.0);
      final w = (nx2 - nx1).clamp(0.0, 1.0).toDouble();
      final h = (ny2 - ny1).clamp(0.0, 1.0).toDouble();
      final l = nx1.clamp(0.0, 1.0).toDouble();
      final t = ny1.clamp(0.0, 1.0).toDouble();

      final label = classLabels?[cls] ?? 'class-$cls';
      results.add(
        FaceMaskResult(
          box: Rect.fromLTWH(l, t, w, h),
          label: label,
          score: score.clamp(0.0, 1.0).toDouble(),
        ),
      );
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
      if (r < 0)
        r = 0;
      else if (r > 255)
        r = 255;
      if (g < 0)
        g = 0;
      else if (g > 255)
        g = 255;
      if (b < 0)
        b = 0;
      else if (b > 255)
        b = 255;

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

// Place a smaller RGB image (w,h) into a larger canvas (W,H) with padding.
Uint8List _padRGB(
  Uint8List src,
  int w,
  int h,
  int W,
  int H,
  int padX,
  int padY, {
  int fill = 114,
}) {
  final dst = Uint8List(W * H * 3);
  for (int i = 0; i < dst.length; i += 3) {
    dst[i] = fill;
    dst[i + 1] = fill;
    dst[i + 2] = fill;
  }
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final sIdx = (y * w + x) * 3;
      final dIdx = ((y + padY) * W + (x + padX)) * 3;
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

// Decode YOLO head [*, E, S] or [*, S, E] into pixel boxes in source image space.
List<List<double>> _decodeYoloDetections(
  List<ort.OrtValue?> outs, {
  required int imgW,
  required int imgH,
  required int inputW,
  required int inputH,
  required int padX,
  required int padY,
  required double scale,
  required bool hasObjectness,
  required double scoreThresh,
}) {
  // 1) Find the main concatenated output: prefer the first output with a 2D matrix where
  //    either rows == 67 or cols == 67 (E). Fallback to the largest 2D.
  List<List<double>>? mat;
  for (final o in outs) {
    if (o == null) continue;
    final rows = _rows2D(o.value);
    if (rows.isEmpty) continue;
    final r = rows.length;
    final c = rows.first.length;
    if (r == 67 || c == 67) {
      mat = rows;
      break;
    }
    // Also accept typical S (8400)
    if (r == 8400 || c == 8400) {
      mat = rows;
      break;
    }
  }
  // Fallback: take the first non-empty 2D
  if (mat == null) {
    for (final o in outs) {
      if (o == null) continue;
      final rows = _rows2D(o.value);
      if (rows.isNotEmpty) {
        mat = rows;
        break;
      }
    }
  }
  mat ??= const <List<double>>[];
  if (mat.isEmpty) return const <List<double>>[];

  // 2) Ensure shape is [S,E]
  List<List<double>> pred;
  final rowsN = mat.length;
  final colsN = mat.first.length;
  final bool rowsAreE = rowsN == 67; // typical for this model
  if (rowsAreE) {
    // transpose to [S,E]
    pred = List.generate(colsN, (i) => List<double>.filled(rowsN, 0));
    for (int r = 0; r < rowsN; r++) {
      final row = mat[r];
      for (int c = 0; c < colsN; c++) {
        pred[c][r] = row[c].toDouble();
      }
    }
  } else {
    pred = mat;
  }

  final S = pred.length;
  final E = pred.first.length;
  final clsStart = hasObjectness ? 5 : 4;
  final C = (E - clsStart).clamp(0, 10000);

  // 3) Extract boxes and scores
  final boxes = List.generate(S, (i) => pred[i].sublist(0, 4));
  final objList = hasObjectness
      ? pred.map((r) => _sigmoid(r[4])).toList()
      : List<double>.filled(S, 1.0);
  final scores = List<double>.filled(S, 0.0);
  final clsIds = List<double>.filled(S, 0.0);

  for (int i = 0; i < S; i++) {
    // class scores
    double best = -1e9;
    int bestId = 0;
    for (int k = 0; k < C; k++) {
      final p = _sigmoid(pred[i][clsStart + k]);
      if (p > best) {
        best = p;
        bestId = k;
      }
    }
    final s = best * objList[i];
    scores[i] = s;
    clsIds[i] = bestId.toDouble();
  }

  // 4) Convert (cx,cy,w,h) in 640-space to corners, then undo letterbox to source image
  final dets = <List<double>>[];
  for (int i = 0; i < S; i++) {
    if (scores[i] < scoreThresh) continue;
    final cx = boxes[i][0];
    final cy = boxes[i][1];
    final w = boxes[i][2];
    final h = boxes[i][3];
    double x1 = cx - w / 2.0;
    double y1 = cy - h / 2.0;
    double x2 = cx + w / 2.0;
    double y2 = cy + h / 2.0;
    // Undo padding/scale
    x1 = (x1 - padX) / scale;
    y1 = (y1 - padY) / scale;
    x2 = (x2 - padX) / scale;
    y2 = (y2 - padY) / scale;
    // clip
    x1 = x1.clamp(0.0, imgW.toDouble());
    y1 = y1.clamp(0.0, imgH.toDouble());
    x2 = x2.clamp(0.0, imgW.toDouble());
    y2 = y2.clamp(0.0, imgH.toDouble());
    dets.add([x1, y1, x2, y2, scores[i], clsIds[i]]);
  }

  // 5) NMS per class
  return _nmsPerClass(dets, iouThresh: 0.45);
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

// ---------- Math / utils ----------

double _sigmoid(double x) => 1.0 / (1.0 + math.exp(-x));

double _iou(List<double> a, List<double> b) {
  final ax1 = a[0], ay1 = a[1], ax2 = a[2], ay2 = a[3];
  final bx1 = b[0], by1 = b[1], bx2 = b[2], by2 = b[3];
  final interX1 = ax1 > bx1 ? ax1 : bx1;
  final interY1 = ay1 > by1 ? ay1 : by1;
  final interX2 = ax2 < bx2 ? ax2 : bx2;
  final interY2 = ay2 < by2 ? ay2 : by2;
  final iw = (interX2 - interX1).clamp(0.0, double.infinity);
  final ih = (interY2 - interY1).clamp(0.0, double.infinity);
  final inter = iw * ih;
  final areaA =
      (ax2 - ax1).clamp(0.0, double.infinity) *
      (ay2 - ay1).clamp(0.0, double.infinity);
  final areaB =
      (bx2 - bx1).clamp(0.0, double.infinity) *
      (by2 - by1).clamp(0.0, double.infinity);
  final union = areaA + areaB - inter;
  if (union <= 0) return 0.0;
  return inter / union;
}

List<List<double>> _nmsPerClass(
  List<List<double>> dets, {
  double iouThresh = 0.45,
}) {
  // Group by class id
  final Map<int, List<List<double>>> byCls = {};
  for (final d in dets) {
    final c = d[5].round();
    byCls.putIfAbsent(c, () => []).add(d);
  }
  final kept = <List<double>>[];
  byCls.forEach((_, list) {
    // sort by score desc
    list.sort((a, b) => b[4].compareTo(a[4]));
    final suppress = List<bool>.filled(list.length, false);
    for (int i = 0; i < list.length; i++) {
      if (suppress[i]) continue;
      kept.add(list[i]);
      for (int j = i + 1; j < list.length; j++) {
        if (suppress[j]) continue;
        if (_iou(list[i], list[j]) > iouThresh) suppress[j] = true;
      }
    }
  });
  return kept;
}

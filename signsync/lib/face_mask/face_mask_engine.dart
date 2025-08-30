import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Single detection result for a face with (normalized) bounding box
/// and classification label.
class FaceMaskResult {
  /// Normalized rectangle in [0, 1] relative to the input image size
  /// (left, top, width, height).
  final Rect box;
  final String label; // e.g. 'mask', 'no_mask', 'incorrect'
  final double score; // 0..1

  const FaceMaskResult({required this.box, required this.label, required this.score});
}

/// Engine abstraction for face-mask detection.
///
/// Implementations can be backed by ONNX Runtime, TFLite, etc.
abstract class FaceMaskEngine {
  /// Load model resources (e.g., from assets or file system).
  Future<void> load();

  /// Run inference on a camera image.
  /// Rotation is provided in degrees so engines can rotate inputs if needed.
  Future<List<FaceMaskResult>> detect(CameraImage image, int rotationDegrees);

  /// Dispose any native resources.
  Future<void> dispose();
}


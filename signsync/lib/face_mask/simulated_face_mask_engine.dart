import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:signsync/face_mask/face_mask_engine.dart';

/// Simulated engine that produces random boxes/labels.
/// Useful for wiring up the UI before integrating a real model.
class SimulatedFaceMaskEngine implements FaceMaskEngine {
  final math.Random _rng = math.Random(42);

  @override
  Future<void> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<List<FaceMaskResult>> detect(CameraImage image, int rotationDegrees) async {
    // Generate 0-2 random detections per frame.
    final count = _rng.nextInt(3);
    final results = <FaceMaskResult>[];
    for (var i = 0; i < count; i++) {
      final w = 0.2 + _rng.nextDouble() * 0.25;
      final h = 0.25 + _rng.nextDouble() * 0.3;
      final left = _rng.nextDouble() * (1.0 - w);
      final top = _rng.nextDouble() * (1.0 - h);
      final score = 0.5 + _rng.nextDouble() * 0.5;
      final label = (_rng.nextDouble() < 0.7)
          ? 'mask'
          : (_rng.nextDouble() < 0.5 ? 'no_mask' : 'incorrect');
      results.add(FaceMaskResult(box: Rect.fromLTWH(left, top, w, h), label: label, score: score));
    }
    await Future<void>.delayed(const Duration(milliseconds: 16));
    return results;
  }

  @override
  Future<void> dispose() async {}
}


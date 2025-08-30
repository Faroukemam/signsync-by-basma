import 'dart:async';
import 'package:camera/camera.dart';
import 'package:signsync/face_mask/face_mask_engine.dart';

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
  bool _loaded = false;

  OnnxFaceMaskEngine({required this.assetModelPath});

  @override
  Future<void> load() async {
    // TODO: load model bytes from assets, create ORT env + session
    _loaded = true;
  }

  @override
  Future<List<FaceMaskResult>> detect(CameraImage image, int rotationDegrees) async {
    if (!_loaded) {
      throw StateError('OnnxFaceMaskEngine not loaded. Call load() first.');
    }
    // TODO: pre-process CameraImage to match model input
    // TODO: run ORT session, fetch outputs
    // TODO: post-process outputs to FaceMaskResult list
    throw UnimplementedError('Implement ORT inference with your model.');
  }

  @override
  Future<void> dispose() async {
    // TODO: dispose ORT session/env if needed
  }
}


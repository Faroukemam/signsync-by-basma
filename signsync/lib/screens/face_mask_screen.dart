import 'package:flutter/material.dart';
import 'package:signsync/components/face_mask_widget.dart';
import 'package:signsync/face_mask/onnx_face_mask_engine.dart';

/// Screen wrapper to demo the facemask detector widget.
///
/// If you pass [modelAssetPath], it creates an OnnxFaceMaskEngine (skeleton)
/// you can implement. Otherwise it uses a simulated engine for UI testing.
class FaceMaskScreen extends StatelessWidget {
  final String? modelAssetPath; // e.g. 'assets/models/model.quant.onnx'
  const FaceMaskScreen({super.key, this.modelAssetPath});

  @override
  Widget build(BuildContext context) {
    final path = modelAssetPath ?? 'assets/models/model.quant.onnx';
    final engine = OnnxFaceMaskEngine(assetModelPath: path);
    return Scaffold(
      appBar: AppBar(title: const Text('Face Mask Detection')),
      body: SafeArea(
        child: FaceMaskDetectorWidget(engine: engine),
      ),
    );
  }
}

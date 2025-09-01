import 'package:flutter/material.dart';
import 'package:signsync/components/face_mask_widget.dart';
import 'package:signsync/face_mask/onnx_face_mask_engine.dart';

/// Face-mask detector screen with live controls.
class FaceMaskScreen extends StatefulWidget {
  final String? modelAssetPath; // e.g. 'assets/models/model.quant.onnx'
  const FaceMaskScreen({super.key, this.modelAssetPath});

  @override
  State<FaceMaskScreen> createState() => _FaceMaskScreenState();
}

class _FaceMaskScreenState extends State<FaceMaskScreen> {
  late OnnxFaceMaskEngine _engine;
  double _threshold = 0.5; // display + engine threshold
  bool _preferFront = true;
  bool _mirrorFront = false;
  BoxFit _fit = BoxFit.contain;

  @override
  void initState() {
    super.initState();
    final path = widget.modelAssetPath ?? 'assets/models/model.quant.onnx';
    _engine = OnnxFaceMaskEngine(
      assetModelPath: path,
      scoreThreshold: _threshold,
      hasObjectness: true,
      // Provide labels if you know the order, e.g. {0:'mask',1:'no_mask',2:'incorrect'}.
      // classLabels: {0: 'mask', 1: 'no_mask', 2: 'incorrect'},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Mask Detection'),
        actions: [
          IconButton(
            tooltip: 'Reset settings',
            onPressed: _resetSettings,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Live camera + overlay
            Expanded(
              child: FaceMaskDetectorWidget(
                engine: _engine,
                preferFrontCamera: _preferFront,
                mirrorFrontCamera: _mirrorFront,
                fit: _fit,
                throttle: const Duration(milliseconds: 200),
              ),
            ),
            // Controls panel
            _Controls(
              threshold: _threshold,
              preferFront: _preferFront,
              mirrorFront: _mirrorFront,
              fit: _fit,
              onThresholdChanged: (v) {
                setState(() {
                  _threshold = v;
                  _engine.scoreThreshold = v; // take effect next inference
                });
              },
              onPreferFrontChanged: (v) => setState(() => _preferFront = v),
              onMirrorChanged: (v) => setState(() => _mirrorFront = v),
              onFitChanged: (v) => setState(() => _fit = v),
            ),
          ],
        ),
      ),
    );
  }

  void _resetSettings() {
    setState(() {
      _threshold = 0.5;
      _engine.scoreThreshold = _threshold;
      _preferFront = true;
      _mirrorFront = false;
      _fit = BoxFit.contain;
    });
  }
}

class _Controls extends StatelessWidget {
  final double threshold;
  final bool preferFront;
  final bool mirrorFront;
  final BoxFit fit;
  final ValueChanged<double> onThresholdChanged;
  final ValueChanged<bool> onPreferFrontChanged;
  final ValueChanged<bool> onMirrorChanged;
  final ValueChanged<BoxFit> onFitChanged;

  const _Controls({
    required this.threshold,
    required this.preferFront,
    required this.mirrorFront,
    required this.fit,
    required this.onThresholdChanged,
    required this.onPreferFrontChanged,
    required this.onMirrorChanged,
    required this.onFitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.05),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, size: 18),
              const SizedBox(width: 8),
              const Text('Threshold'),
              const Spacer(),
              Text(threshold.toStringAsFixed(2)),
            ],
          ),
          Slider(
            value: threshold,
            onChanged: onThresholdChanged,
            min: 0.05,
            max: 0.95,
            divisions: 18,
            label: threshold.toStringAsFixed(2),
          ),
          Row(
            children: [
              Switch(
                value: preferFront,
                onChanged: onPreferFrontChanged,
              ),
              const Text('Prefer front camera'),
              const SizedBox(width: 16),
              Switch(
                value: mirrorFront,
                onChanged: onMirrorChanged,
              ),
              const Text('Mirror front preview'),
              const Spacer(),
              DropdownButton<BoxFit>(
                value: fit,
                items: const [
                  DropdownMenuItem(value: BoxFit.contain, child: Text('Contain')),
                  DropdownMenuItem(value: BoxFit.cover, child: Text('Cover')),
                  DropdownMenuItem(value: BoxFit.fill, child: Text('Fill')),
                ],
                onChanged: (v) => v != null ? onFitChanged(v) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

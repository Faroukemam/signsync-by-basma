import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:signsync/face_mask/face_mask_engine.dart';
import 'package:signsync/face_mask/simulated_face_mask_engine.dart';

class FaceMaskDetectorWidget extends StatefulWidget {
  final FaceMaskEngine? engine;
  final bool preferFrontCamera;
  final Duration throttle; // time between inferences
  /// How the camera preview should fit its box (and how the overlay scales).
  final BoxFit fit;
  /// Mirror the preview and overlay for the front camera (selfie-like).
  final bool mirrorFrontCamera;

  const FaceMaskDetectorWidget({
    super.key,
    this.engine,
    this.preferFrontCamera = true,
    this.throttle = const Duration(milliseconds: 250),
    this.fit = BoxFit.contain,
    this.mirrorFrontCamera = false,
  });

  @override
  State<FaceMaskDetectorWidget> createState() => _FaceMaskDetectorWidgetState();
}

class _FaceMaskDetectorWidgetState extends State<FaceMaskDetectorWidget> {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  bool _initCam = false;
  bool _streaming = false;
  bool _busy = false;
  DateTime _lastRun = DateTime.fromMillisecondsSinceEpoch(0);

  late final FaceMaskEngine _engine;
  List<FaceMaskResult> _results = const [];

  @override
  void initState() {
    super.initState();
    _engine = widget.engine ?? SimulatedFaceMaskEngine();
    _setup();
  }

  Future<void> _setup() async {
    try {
      await _engine.load();
      _cameras = await availableCameras();
      final cam = _selectCamera(_cameras, widget.preferFrontCamera);
      _controller = CameraController(cam, ResolutionPreset.medium, enableAudio: false);
      await _controller!.initialize();
      setState(() => _initCam = true);
      await _controller!.startImageStream(_onFrame);
      setState(() => _streaming = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera/engine error: $e')),
      );
    }
  }

  CameraDescription _selectCamera(List<CameraDescription> cams, bool preferFront) {
    if (cams.isEmpty) throw StateError('No cameras found');
    if (preferFront) {
      final front = cams.where((c) => c.lensDirection == CameraLensDirection.front).toList();
      if (front.isNotEmpty) return front.first;
    }
    return cams.first;
  }

  Future<void> _onFrame(CameraImage image) async {
    if (!_initCam || !_streaming) return;
    if (_busy) return;
    final now = DateTime.now();
    if (now.difference(_lastRun) < widget.throttle) return;
    _lastRun = now;
    _busy = true;
    try {
      final rotation = _controller?.description.sensorOrientation ?? 0;
      final detections = await _engine.detect(image, rotation);
      if (mounted) setState(() => _results = detections);
    } catch (e) {
      // ignore per-frame errors to keep stream alive; show lightweight feedback
      // debugPrint('detect error: $e');
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initCam || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Camera plugin reports preview size in landscape. Swap for portrait UI.
    final previewSize = _controller!.value.previewSize!;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final double pw = isPortrait ? previewSize.height : previewSize.width;
    final double ph = isPortrait ? previewSize.width : previewSize.height;

    final mirror = widget.mirrorFrontCamera &&
        _controller!.description.lensDirection == CameraLensDirection.front;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Build preview and overlay on the same logical canvas size, then
        // scale both together with the same BoxFit to keep them aligned.
        FittedBox(
          fit: widget.fit,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: pw,
            height: ph,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..scale(mirror ? -1.0 : 1.0, 1.0, 1.0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(_controller!),
                  CustomPaint(
                    painter: _DetectionsPainter(_results, Size(pw, ph)),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 12,
          top: 12,
          child: _Badge(text: _streaming ? 'LIVE' : 'PAUSED'),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: _StatusBadge(results: _results),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: FloatingActionButton.small(
            onPressed: _toggleCamera,
            child: const Icon(Icons.cameraswitch),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleCamera() async {
    try {
      if (_cameras.length < 2) return;
      final current = _controller!.description;
      final nextLens = current.lensDirection == CameraLensDirection.front
          ? CameraLensDirection.back
          : CameraLensDirection.front;
      final next = _cameras.firstWhere((c) => c.lensDirection == nextLens, orElse: () => _cameras.first);

      await _controller!.stopImageStream();
      await _controller!.dispose();
      _controller = CameraController(next, ResolutionPreset.medium, enableAudio: false);
      await _controller!.initialize();
      await _controller!.startImageStream(_onFrame);
      setState(() => _streaming = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Switch camera error: $e')),
      );
    }
  }
}

class _DetectionsPainter extends CustomPainter {
  final List<FaceMaskResult> results;
  final Size canvasSize;
  _DetectionsPainter(this.results, this.canvasSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final textBg = Paint()..color = Colors.black.withOpacity(0.6);
    for (final r in results) {
      final rect = Rect.fromLTWH(
        r.box.left * size.width,
        r.box.top * size.height,
        r.box.width * size.width,
        r.box.height * size.height,
      );
      paint.color = _colorFor(r.label);
      canvas.drawRect(rect, paint);

      // Draw label box
      final tp = _text('${r.label} ${(r.score * 100).toStringAsFixed(0)}%');
      tp.layout();
      final labelRect = Rect.fromLTWH(rect.left, rect.top - tp.height - 6, tp.width + 10, tp.height + 4);
      canvas.drawRect(labelRect, textBg);
      tp.paint(canvas, Offset(labelRect.left + 5, labelRect.top + 2));
    }
  }

  Color _colorFor(String label) {
    switch (label) {
      case 'mask':
        return const Color(0xFF2ecc71); // green
      case 'incorrect':
        return const Color(0xFFf1c40f); // amber
      case 'no_mask':
      default:
        return const Color(0xFFe74c3c); // red
    }
  }

  TextPainter _text(String s) => TextPainter(
        text: TextSpan(
          text: s,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      );

  @override
  bool shouldRepaint(covariant _DetectionsPainter oldDelegate) {
    return oldDelegate.results != results || oldDelegate.canvasSize != canvasSize;
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final List<FaceMaskResult> results;
  const _StatusBadge({required this.results});

  @override
  Widget build(BuildContext context) {
    final status = _computeStatus();
    Color bg;
    switch (status) {
      case _Status.noMask:
        bg = const Color(0xB3e74c3c); // red with opacity
        break;
      case _Status.incorrect:
        bg = const Color(0xB3f1c40f); // amber with opacity
        break;
      case _Status.maskOk:
        bg = const Color(0xB32ecc71); // green with opacity
        break;
      case _Status.noFace:
      default:
        bg = Colors.black45;
    }

    final text = switch (status) {
      _Status.noMask => 'NO MASK',
      _Status.incorrect => 'INCORRECT MASK',
      _Status.maskOk => 'MASK DETECTED',
      _ => 'NO FACE DETECTED',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }

  _Status _computeStatus() {
    if (results.isEmpty) return _Status.noFace;
    const th = 0.6;
    final anyNoMask = results.any((r) => r.label == 'no_mask' && r.score >= th);
    if (anyNoMask) return _Status.noMask;
    final anyIncorrect = results.any((r) => r.label == 'incorrect' && r.score >= th);
    if (anyIncorrect) return _Status.incorrect;
    final anyMask = results.any((r) => r.label == 'mask' && r.score >= th);
    if (anyMask) return _Status.maskOk;
    return _Status.noFace;
  }
}

enum _Status { noFace, noMask, incorrect, maskOk }

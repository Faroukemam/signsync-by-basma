import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/io.dart';

class CameraStreamScreen extends StatefulWidget {
  const CameraStreamScreen({Key? key}) : super(key: key);

  @override
  State<CameraStreamScreen> createState() => _CameraStreamScreenState();
}

class _CameraStreamScreenState extends State<CameraStreamScreen> {
  CameraController? _controller;
  late IOWebSocketChannel channel;
  bool isStreaming = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
    channel = IOWebSocketChannel.connect("ws://192.168.1.100:1880/ws/mySocket");
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(
      cameras[0],
      ResolutionPreset.low, // 👈 keep it small for streaming
    );

    await _controller!.initialize();
    setState(() {});
  }

  void _startStreaming() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    _controller!.startImageStream((CameraImage image) async {
      if (!isStreaming) return;

      try {
        // Convert YUV to raw bytes (simplified, can use plugins)
        final bytes = image.planes[0].bytes;

        // Send base64 to Node-RED
        final base64Image = base64Encode(bytes);
        channel.sink.add(base64Image);
      } catch (e) {
        print("Error streaming frame: $e");
      }
    });

    setState(() => isStreaming = true);
  }

  void _stopStreaming() {
    _controller?.stopImageStream();
    setState(() => isStreaming = false);
  }

  @override
  void dispose() {
    _controller?.dispose();
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Live Stream to Node-RED")),
      body: _controller != null && _controller!.value.isInitialized
          ? Column(
              children: [
                Expanded(child: CameraPreview(_controller!)),
                ElevatedButton(
                  onPressed: isStreaming ? _stopStreaming : _startStreaming,
                  child: Text(
                    isStreaming ? "Stop Streaming" : "Start Streaming",
                  ),
                ),
              ],
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class FFCameraScreen extends StatefulWidget {
  const FFCameraScreen({super.key});

  @override
  State<FFCameraScreen> createState() => _FFCameraScreenState();
}

class _FFCameraScreenState extends State<FFCameraScreen> {
  late List<CameraDescription> cameras;
  CameraController? controller;
  bool isInitialized = false;
  int selectedCameraIndex = 0; // 0 = rear, 1 = front

  WebSocketChannel? channel;
  bool isStreaming = false;

  @override
  void initState() {
    super.initState();
    initCamera(selectedCameraIndex);
    connectWebSocket();
  }

  Future<void> connectWebSocket() async {
    channel = WebSocketChannel.connect(
      Uri.parse(
        "ws://192.168.1.100:1880/camera",
      ), // <-- Node-RED WebSocket endpoint
    );
    print("✅ Connected to WebSocket server");
  }

  Future<void> initCamera(int cameraIndex) async {
    try {
      cameras = await availableCameras();
      if (cameras.isEmpty) {
        print("No cameras available");
        return;
      }

      controller = CameraController(
        cameras[cameraIndex],
        ResolutionPreset.low, // low/medium is better for streaming
        enableAudio: false,
      );

      await controller!.initialize();

      setState(() {
        isInitialized = true;
      });
    } catch (e) {
      print("Camera error: $e");
    }
  }

  void switchCamera() {
    if (cameras.length < 2) return; // Only 1 camera available

    setState(() {
      selectedCameraIndex = (selectedCameraIndex + 1) % cameras.length;
      isInitialized = false;
    });

    controller?.dispose();
    initCamera(selectedCameraIndex);
  }

  void startStreaming() {
    if (controller == null || !controller!.value.isInitialized) return;

    controller!.startImageStream((CameraImage image) async {
      if (!isStreaming) return; // Pause if stopped

      try {
        // Convert YUV420 -> JPEG (or directly send raw plane bytes if Node-RED expects raw)
        // For simplicity, we’ll send just the first plane as base64
        final bytes = image.planes[0].bytes;
        final base64Image = base64Encode(bytes);

        channel?.sink.add(base64Image); // 🚀 Send to WebSocket
      } catch (e) {
        print("Frame error: $e");
      }
    });

    setState(() {
      isStreaming = true;
    });

    print("📡 Started streaming frames...");
  }

  void stopStreaming() {
    controller?.stopImageStream();
    setState(() {
      isStreaming = false;
    });
    print("🛑 Stopped streaming.");
  }

  @override
  void dispose() {
    controller?.dispose();
    channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Camera Stream")),
      body: isInitialized
          ? Stack(
              children: [
                CameraPreview(controller!),

                // Camera switch button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: FloatingActionButton(
                      heroTag: "switchBtn",
                      onPressed: switchCamera,
                      child: const Icon(Icons.cameraswitch, size: 28),
                    ),
                  ),
                ),

                // Start/Stop Streaming
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: ElevatedButton.icon(
                      onPressed: isStreaming ? stopStreaming : startStreaming,
                      icon: Icon(isStreaming ? Icons.stop : Icons.play_arrow),
                      label: Text(
                        isStreaming ? "Stop Streaming" : "Start Streaming",
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 20,
                        ),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

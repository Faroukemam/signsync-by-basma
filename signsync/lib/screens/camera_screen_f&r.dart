import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class FCameraScreen extends StatefulWidget {
  const FCameraScreen({super.key});

  @override
  State<FCameraScreen> createState() => _FCameraScreenState();
}

class _FCameraScreenState extends State<FCameraScreen> {
  late List<CameraDescription> cameras;
  CameraController? controller;
  bool isInitialized = false;
  int selectedCameraIndex = 0; // 0 = rear, 1 = front

  @override
  void initState() {
    super.initState();
    initCamera(selectedCameraIndex);
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
        ResolutionPreset.medium,
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

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Camera")),
      body: isInitialized
          ? Stack(
              children: [
                CameraPreview(controller!),

                // Camera switch button (top-right)
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

                // Bottom send button
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Snapshot / send frame to model
                      },
                      icon: const Icon(Icons.send),
                      label: const Text("Send Frame to AI"),
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

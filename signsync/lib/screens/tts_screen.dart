import 'package:flutter/material.dart';
import 'package:signsync/components/tts_widget.dart';
import 'package:signsync/tts/local_tts_engine.dart';
import 'package:signsync/tts/tts_engine.dart';

/// Simple screen wiring the TTSWidget to a local on-device TTS engine.
///
/// Replace `assetModelPath` with your actual model location, and ensure
/// you list it under `flutter/assets` in `pubspec.yaml`.
class TTSScreen extends StatefulWidget {
  final String assetModelPath; // e.g. assets/models/your_model.tflite
  const TTSScreen({super.key, required this.assetModelPath});

  @override
  State<TTSScreen> createState() => _TTSScreenState();
}

class _TTSScreenState extends State<TTSScreen> {
  late final TTSEngine _engine;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _engine = LocalTTSEngine(assetModelPath: widget.assetModelPath);
    _init();
  }

  Future<void> _init() async {
    try {
      await _engine.load();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TTS (Local Model)')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  )
                : SingleChildScrollView(
                    child: TTSWidget(
                      // Bridge engine to TTSWidget via a custom function
                      onSynthesize: (cfg) => _engine.synthesize(cfg),
                      initialText: 'Hello from on-device TTS! 👋',
                    ),
                  ),
      ),
    );
  }
}


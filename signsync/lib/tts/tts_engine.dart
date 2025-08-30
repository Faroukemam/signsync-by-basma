import 'dart:async';

import 'package:signsync/components/tts_widget.dart';

/// Abstraction for a local/on-device TTS engine.
/// Implementations can use TFLite, ONNX, or platform-native code via FFI.
abstract class TTSEngine {
  /// Load model weights/resources (e.g., from assets or file system).
  Future<void> load();

  /// Synthesize speech audio from configuration.
  Future<TTSOutput> synthesize(TTSConfig cfg);

  /// Release any native resources.
  Future<void> dispose();
}


import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:signsync/components/tts_widget.dart';
import 'package:signsync/tts/tts_engine.dart';

/// Placeholder local TTS engine.
///
/// - `load()` demonstrates loading a model file from assets.
/// - `synthesize()` returns a generated sine-wave WAV based on cfg
///   (so you can test wiring without a finished model).
///
/// Replace the body of `synthesize()` with real inference once your
/// model is ready (TFLite, ONNX, or FFI).
class LocalTTSEngine implements TTSEngine {
  final String assetModelPath; // e.g. assets/models/your_model.tflite
  bool _loaded = false;

  LocalTTSEngine({required this.assetModelPath});

  @override
  Future<void> load() async {
    // Demonstrate asset existence; ignore the bytes here.
    await rootBundle.load(assetModelPath);
    _loaded = true;
  }

  @override
  Future<TTSOutput> synthesize(TTSConfig cfg) async {
    if (!_loaded) {
      throw StateError('LocalTTSEngine not loaded. Call load() first.');
    }

    // TODO: Replace with your real model inference generating PCM audio.
    // For now, generate a short WAV tone that varies with rate/pitch.
    final durationSec = 1.0.clamp(0.5, 3.0);
    final sampleRate = 22050;
    final baseFreq = cfg.lang.toLowerCase().startsWith('ar') ? 480.0 : 440.0;
    final freq = baseFreq * cfg.pitch.clamp(0.5, 1.5);
    final wav = _generateWavSine(
      seconds: durationSec,
      sampleRate: sampleRate,
      frequencyHz: freq,
      amplitude: 0.25,
    );
    return TTSOutput(bytes: wav, mime: 'audio/wav');
  }

  @override
  Future<void> dispose() async {}

  // ----- Simple WAV generator (16-bit PCM, mono) -----
  Uint8List _generateWavSine({
    required double seconds,
    required int sampleRate,
    required double frequencyHz,
    double amplitude = 0.5,
  }) {
    final totalSamples = (seconds * sampleRate).round();
    final bytesPerSample = 2; // 16-bit PCM
    final data = ByteData(totalSamples * bytesPerSample);

    for (int n = 0; n < totalSamples; n++) {
      final t = n / sampleRate;
      final sample = amplitude * math.sin(2 * math.pi * frequencyHz * t);
      final s16 = (sample * 32767).clamp(-32768, 32767).toInt();
      data.setInt16(n * 2, s16, Endian.little);
    }

    final header = _wavHeader(
      sampleRate: sampleRate,
      numSamples: totalSamples,
      numChannels: 1,
      bitsPerSample: 16,
    );
    return Uint8List.fromList([...header, ...data.buffer.asUint8List()]);
  }

  List<int> _wavHeader({
    required int sampleRate,
    required int numSamples,
    required int numChannels,
    required int bitsPerSample,
  }) {
    final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final blockAlign = numChannels * bitsPerSample ~/ 8;
    final dataSize = numSamples * numChannels * bitsPerSample ~/ 8;
    final fileSize = 44 - 8 + dataSize;
    final b = BytesBuilder();

    void writeString(String s) => b.add(s.codeUnits);
    void write32(int v) =>
        b.add(Uint8List(4)..buffer.asByteData().setUint32(0, v, Endian.little));
    void write16(int v) =>
        b.add(Uint8List(2)..buffer.asByteData().setUint16(0, v, Endian.little));

    writeString('RIFF');
    write32(fileSize);
    writeString('WAVE');
    writeString('fmt ');
    write32(16); // PCM chunk size
    write16(1); // audio format PCM
    write16(numChannels);
    write32(sampleRate);
    write32(byteRate);
    write16(blockAlign);
    write16(bitsPerSample);
    writeString('data');
    write32(dataSize);
    return b.toBytes();
  }
}

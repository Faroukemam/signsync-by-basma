import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:signsync/services/api_service.dart';

/*
  Text-to-Speech (TTS) UI Components

  Goal
  - Provide a clean, reusable UI to collect TTS inputs (text, voice, rate,
    pitch, format) and trigger synthesis.
  - Your model/backend is still a work-in-progress, so we expose two
    integration paths:
      1) Pass `onSynthesize` to plug in any async function returning audio.
      2) Or provide `api` + `endpoint` to POST a request and parse response.

  Expected Backend Response (flexible)
  - Either a JSON with an `audioUrl` (string), e.g. {"audioUrl":"https://..."}
  - Or JSON with `audioBase64` (string) and optionally `mime`.
  - You can also return a raw string URL; we attempt to handle both cases.

  Usage (simple)
    TTSWidget(
      api: ApiService(baseUrl: 'http://localhost:3000'),
      endpoint: '/tts/synthesize',
    )

  Usage (custom function)
    TTSWidget(
      onSynthesize: (cfg) async {
        // Use your model here and return bytes/url
        return TTSOutput(url: 'https://example.com/speech.wav');
      },
    )
*/

class TTSConfig {
  final String text;
  final String voice;
  final String lang;
  final double rate; // 0.5 – 1.5
  final double pitch; // 0.5 – 1.5
  final String format; // 'wav' | 'mp3'

  const TTSConfig({
    required this.text,
    required this.voice,
    required this.lang,
    required this.rate,
    required this.pitch,
    required this.format,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'voice': voice,
        'lang': lang,
        'rate': rate,
        'pitch': pitch,
        'format': format,
      };
}

class TTSOutput {
  final Uint8List? bytes; // synthesized audio data
  final String? url; // remote URL to audio
  final String? mime; // e.g. audio/wav, audio/mpeg
  const TTSOutput({this.bytes, this.url, this.mime});

  bool get hasBytes => bytes != null && bytes!.isNotEmpty;
  bool get hasUrl => url != null && url!.isNotEmpty;
}

class TTSWidget extends StatefulWidget {
  final ApiService? api;
  final String endpoint; // used only if api != null
  final Future<TTSOutput> Function(TTSConfig cfg)? onSynthesize;

  // UI presets
  final String title;
  final String initialText;
  final List<String> voices;
  final List<String> languages;
  final List<String> formats; // typically ['wav', 'mp3']

  const TTSWidget({
    super.key,
    this.api,
    this.endpoint = '/tts/synthesize',
    this.onSynthesize,
    this.title = 'Text to Speech',
    this.initialText = '',
    this.voices = const ['female', 'male'],
    this.languages = const ['en-US', 'ar-EG'],
    this.formats = const ['wav', 'mp3'],
  });

  @override
  State<TTSWidget> createState() => _TTSWidgetState();
}

class _TTSWidgetState extends State<TTSWidget> {
  final _formKey = GlobalKey<FormState>();
  final _textCtrl = TextEditingController();
  String _voice = 'female';
  String _lang = 'en-US';
  double _rate = 1.0;
  double _pitch = 1.0;
  String _format = 'wav';

  bool _loading = false;
  String? _error;
  TTSOutput? _result; // bytes or url
  String? _savedPath; // last saved file (system temp)

  @override
  void initState() {
    super.initState();
    _textCtrl.text = widget.initialText;
    if (widget.voices.isNotEmpty) _voice = widget.voices.first;
    if (widget.languages.isNotEmpty) _lang = widget.languages.first;
    if (widget.formats.isNotEmpty) _format = widget.formats.first;
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _synthesize() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final cfg = TTSConfig(
      text: _textCtrl.text.trim(),
      voice: _voice,
      lang: _lang,
      rate: _rate,
      pitch: _pitch,
      format: _format,
    );

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
      _savedPath = null;
    });

    try {
      TTSOutput out;
      if (widget.onSynthesize != null) {
        out = await widget.onSynthesize!(cfg);
      } else if (widget.api != null) {
        final res = await widget.api!.post(
          widget.endpoint,
          body: cfg.toJson(),
        );
        out = _parseBackendResponse(res);
      } else {
        throw Exception('No synthesis handler: provide onSynthesize or api');
      }

      setState(() => _result = out);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  TTSOutput _parseBackendResponse(dynamic res) {
    // Accept a plain string URL
    if (res is String && (res.startsWith('http://') || res.startsWith('https://'))) {
      return TTSOutput(url: res);
    }
    // JSON map
    if (res is Map<String, dynamic>) {
      final url = res['audioUrl']?.toString();
      final base64Str = res['audioBase64']?.toString();
      final mime = res['mime']?.toString();
      if (url != null && url.isNotEmpty) {
        return TTSOutput(url: url, mime: mime);
      }
      if (base64Str != null && base64Str.isNotEmpty) {
        try {
          final bytes = base64.decode(base64Str);
          return TTSOutput(bytes: Uint8List.fromList(bytes), mime: mime);
        } catch (_) {
          throw Exception('Invalid audioBase64 in response');
        }
      }
    }
    throw Exception('Unrecognized TTS response format');
  }

  Future<void> _saveToTemp() async {
    if (!(_result?.hasBytes ?? false)) return;
    final ext = _format.toLowerCase();
    final fp =
        '${Directory.systemTemp.path}/tts_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final file = File(fp);
    await file.writeAsBytes(_result!.bytes!, flush: true);
    setState(() => _savedPath = fp);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved: $fp')),
    );
  }

  void _reset() {
    setState(() {
      _textCtrl.clear();
      _rate = 1.0;
      _pitch = 1.0;
      _format = widget.formats.isNotEmpty ? widget.formats.first : 'wav';
      _result = null;
      _error = null;
      _savedPath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _textCtrl,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Text',
                  hintText: 'Type or paste text to synthesize…',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Text can\'t be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _LabeledDropdown<String>(
                      label: 'Voice',
                      value: _voice,
                      items: widget.voices,
                      onChanged: (v) => setState(() => _voice = v ?? _voice),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LabeledDropdown<String>(
                      label: 'Language',
                      value: _lang,
                      items: widget.languages,
                      onChanged: (v) => setState(() => _lang = v ?? _lang),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _SliderField(
                      label: 'Rate',
                      value: _rate,
                      min: 0.5,
                      max: 1.5,
                      onChanged: (v) => setState(() => _rate = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SliderField(
                      label: 'Pitch',
                      value: _pitch,
                      min: 0.5,
                      max: 1.5,
                      onChanged: (v) => setState(() => _pitch = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              _LabeledDropdown<String>(
                label: 'Format',
                value: _format,
                items: widget.formats,
                onChanged: (v) => setState(() => _format = v ?? _format),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  FilledButton.icon(
                    onPressed: _loading ? null : _synthesize,
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.graphic_eq),
                    label: Text(_loading ? 'Synthesizing…' : 'Synthesize'),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: _loading ? null : _reset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),

              if (_result != null) ...[
                const SizedBox(height: 4),
                _ResultPanel(
                  result: _result!,
                  savedPath: _savedPath,
                  onSaveToTemp: _result!.hasBytes ? _saveToTemp : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T?>? onChanged;
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          items: items
              .map((e) => DropdownMenuItem<T>(value: e, child: Text('$e')))
              .toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ],
    );
  }
}

class _SliderField extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  const _SliderField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value.toStringAsFixed(2)),
          ],
        ),
        Slider(
          value: value,
          onChanged: onChanged,
          min: min,
          max: max,
          divisions: ((max - min) * 20).round(),
          label: value.toStringAsFixed(2),
        ),
      ],
    );
  }
}

class _ResultPanel extends StatelessWidget {
  final TTSOutput result;
  final String? savedPath;
  final Future<void> Function()? onSaveToTemp;
  const _ResultPanel({
    required this.result,
    this.savedPath,
    this.onSaveToTemp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Result', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (result.hasUrl) ...[
            SelectableText(
              result.url!,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 6),
            Text('Open the URL in a browser or feed to a player.'),
          ] else if (result.hasBytes) ...[
            Text('Audio bytes: ${result.bytes!.length} bytes'),
            const SizedBox(height: 6),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: onSaveToTemp,
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Save to temp'),
                ),
                if (savedPath != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      savedPath!,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text('You can implement playback using audioplayers/just_audio.'),
          ] else ...[
            const Text('No audio returned.'),
          ],
        ],
      ),
    );
  }
}


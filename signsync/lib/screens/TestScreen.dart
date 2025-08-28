import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:convert';

class ParagraphSenderScreen extends StatefulWidget {
  /// Example:
  /// ParagraphSenderScreen(
  ///   api: ApiService(baseUrl: 'http://192.168.1.100:1880'),
  ///   endpoint: '/nlp/infer',
  /// )
  const ParagraphSenderScreen({
    super.key,
    required this.api,
    this.endpoint = '/nlp/infer',
    this.extraHeaders,
    this.queryParams,
  });

  final ApiService api;
  final String endpoint;
  final Map<String, String>? extraHeaders;
  final Map<String, dynamic>? queryParams;

  @override
  State<ParagraphSenderScreen> createState() => _ParagraphSenderScreenState();
}

class _ParagraphSenderScreenState extends State<ParagraphSenderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textCtrl = TextEditingController();

  bool _sending = false;
  dynamic _result; // JSON or String
  String? _error;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _sending = true;
      _result = null;
      _error = null;
    });

    try {
      final payload = {
        // match your Node-RED Function/HTTP In expectations:
        'text': _textCtrl.text.trim(),
        // add more fields if needed, e.g. session/lang:
        // 'sessionId': 'abc123',
        // 'lang': 'ar-EG',
      };

      final res = await widget.api.post(
        widget.endpoint,
        headers: widget.extraHeaders,
        query: widget.queryParams,
        body: payload,
      );

      setState(() => _result = res);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Send Paragraph → Node-RED')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Input
                TextFormField(
                  controller: _textCtrl,
                  minLines: 6,
                  maxLines: 12,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    labelText: 'Your paragraph',
                    hintText: 'Paste or type a paragraph to process…',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Paragraph can’t be empty';
                    }
                    if (v.trim().length < 10) {
                      return 'Give me at least a sentence or two 😉';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Action
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(_sending ? 'Sending…' : 'Send to Node-RED'),
                  ),
                ),
                const SizedBox(height: 16),

                // Output
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
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),

                if (_result != null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Response', style: theme.textTheme.titleMedium),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _prettyPrint(_result),
                          style: theme.textTheme.bodyMedium!.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _prettyPrint(dynamic data) {
    try {
      if (data is String) {
        // Try to pretty JSON strings as well
        final decoded = jsonDecode(data);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      }
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }
}

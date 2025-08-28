import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Simple WebSocket wrapper with auto-reconnect + ping.
class WSService {
  final Uri uri;
  final Map<String, dynamic>? query; // optional
  final Duration pingInterval;
  final Duration reconnectDelay;
  final int maxReconnectAttempts;

  WebSocketChannel? _channel;
  StreamController<dynamic>? _inbound;
  Timer? _pingTimer;
  int _reconnects = 0;
  bool _manuallyClosed = false;

  WSService(
    String url, {
    this.query,
    this.pingInterval = const Duration(seconds: 20),
    this.reconnectDelay = const Duration(seconds: 3),
    this.maxReconnectAttempts = 10,
  }) : uri = Uri.parse(url);

  Stream<dynamic> get messages => _inbound?.stream ?? const Stream.empty();
  bool get isConnected => _channel != null;

  Future<void> connect() async {
    _manuallyClosed = false;
    _inbound ??= StreamController.broadcast();

    await _open();

    // heartbeat
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(pingInterval, (_) {
      try {
        _channel?.sink.add(
          jsonEncode({'type': 'ping', 'ts': DateTime.now().toIso8601String()}),
        );
      } catch (_) {}
    });
  }

  Future<void> _open() async {
    final effective = query == null
        ? uri
        : uri.replace(
            queryParameters: {
              ...uri.queryParameters,
              ...query!.map((k, v) => MapEntry(k, '$v')),
            },
          );

    _channel = WebSocketChannel.connect(effective);

    _channel!.stream.listen(
      (event) => _inbound?.add(event),
      onDone: _onClosed,
      onError: (e, _) => _onClosed(),
      cancelOnError: true,
    );

    _reconnects = 0; // reset on successful open
  }

  void _onClosed() {
    _channel = null;
    _pingTimer?.cancel();

    if (_manuallyClosed) return;

    if (_reconnects < maxReconnectAttempts) {
      _reconnects += 1;
      Future.delayed(reconnectDelay, () => _open());
    } else {
      _inbound?.addError('WebSocket: max reconnect attempts reached');
      _inbound?.close();
    }
  }

  // ---- Send ----
  void sendJson(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }

  void sendText(String text) {
    _channel?.sink.add(text);
  }

  void sendBinary(Uint8List bytes) {
    _channel?.sink.add(bytes);
  }

  Future<void> close([int code = 1000, String reason = 'normal']) async {
    _manuallyClosed = true;
    _pingTimer?.cancel();
    await _channel?.sink.close(code, reason);
    await _inbound?.close();
  }
}

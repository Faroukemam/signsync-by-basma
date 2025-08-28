import 'dart:convert';
import 'package:http/http.dart' as http;

import 'dart:async';
import 'dart:io';

import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

/// Lightweight API client wrapping common HTTP tasks + uploads + SSE.
class ApiService {
  final String baseUrl;
  final Map<String, String> defaultHeaders;
  final Duration timeout;

  ApiService({
    required this.baseUrl,
    this.defaultHeaders = const {'Content-Type': 'application/json'},
    this.timeout = const Duration(seconds: 30),
  });

  Uri _u(String endpoint, [Map<String, dynamic>? query]) {
    final base = Uri.parse(baseUrl);
    final resolved = base.resolve(
      endpoint.startsWith('/') ? endpoint.substring(1) : endpoint,
    );
    return query == null
        ? resolved
        : resolved.replace(
            queryParameters: {
              ...resolved.queryParameters,
              ...query.map((k, v) => MapEntry(k, '$v')),
            },
          );
  }

  // ---------- Core ----------
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await http
          .get(_u(endpoint, query), headers: {...defaultHeaders, ...?headers})
          .timeout(timeout);
      return _handle(res);
    } catch (e) {
      throw Exception('GET failed: $e');
    }
  }

  Future<dynamic> post(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await http
          .post(
            _u(endpoint, query),
            headers: {...defaultHeaders, ...?headers},
            body: _maybeEncodeJson(body),
          )
          .timeout(timeout);
      return _handle(res);
    } catch (e) {
      throw Exception('POST failed: $e');
    }
  }

  Future<dynamic> put(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await http
          .put(
            _u(endpoint, query),
            headers: {...defaultHeaders, ...?headers},
            body: _maybeEncodeJson(body),
          )
          .timeout(timeout);
      return _handle(res);
    } catch (e) {
      throw Exception('PUT failed: $e');
    }
  }

  Future<dynamic> patch(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await http
          .patch(
            _u(endpoint, query),
            headers: {...defaultHeaders, ...?headers},
            body: _maybeEncodeJson(body),
          )
          .timeout(timeout);
      return _handle(res);
    } catch (e) {
      throw Exception('PATCH failed: $e');
    }
  }

  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await http
          .delete(
            _u(endpoint, query),
            headers: {...defaultHeaders, ...?headers},
          )
          .timeout(timeout);
      return _handle(res);
    } catch (e) {
      throw Exception('DELETE failed: $e');
    }
  }

  // ---------- Multipart: file + fields ----------
  Future<dynamic> uploadFile(
    String endpoint, {
    required String filePath,
    String fieldName = 'file',
    Map<String, String>? fields,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) async {
    try {
      final req = http.MultipartRequest('POST', _u(endpoint, query));
      req.headers.addAll(
        {...defaultHeaders, ...?headers}..remove('Content-Type'),
      );

      if (fields != null) {
        req.fields.addAll(fields.map((k, v) => MapEntry(k, '$v')));
      }

      final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';
      final file = await http.MultipartFile.fromPath(
        fieldName,
        filePath,
        contentType: _parseMediaType(mimeType),
        filename: p.basename(filePath),
      );
      req.files.add(file);

      final streamed = await req.send().timeout(timeout);
      final res = await http.Response.fromStream(streamed);
      return _handle(res);
    } catch (e) {
      throw Exception('Multipart upload failed: $e');
    }
  }

  // ---------- Chunked Upload (big audio/video) ----------
  Future<void> uploadFileInChunks(
    String endpoint, {
    required String filePath,
    int chunkSizeBytes = 512 * 1024,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    void Function(int sentBytes, int totalBytes)? onProgress,
  }) async {
    final f = File(filePath);
    final total = await f.length();
    final raf = f.openSync(mode: FileMode.read);

    try {
      int offset = 0;
      int part = 0;
      while (offset < total) {
        final remaining = total - offset;
        final size = remaining < chunkSizeBytes ? remaining : chunkSizeBytes;
        final bytes = raf.readSync(size);

        final rangeHeader = 'bytes $offset-${offset + size - 1}/$total';
        final res = await http
            .post(
              _u(endpoint, {...?query, 'part': part.toString()}),
              headers: {
                ...defaultHeaders,
                ...?headers,
                'Content-Type': 'application/octet-stream',
                'Content-Range': rangeHeader,
              },
              body: bytes,
            )
            .timeout(timeout);

        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw Exception(
            'Chunk $part upload failed: ${res.statusCode} ${res.body}',
          );
        }

        offset += size;
        part += 1;
        onProgress?.call(offset, total);
      }
    } finally {
      await raf.close();
    }
  }

  // ---------- Server-Sent Events (SSE) ----------
  Stream<String> sse(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) {
    final controller = StreamController<String>.broadcast();
    final client = http.Client();

    () async {
      try {
        final req = http.Request('GET', _u(endpoint, query));
        req.headers.addAll(
          {
            ...defaultHeaders,
            ...?headers,
            'Accept': 'text/event-stream',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
          }..remove('Content-Type'),
        );

        final resp = await client.send(req);
        if (resp.statusCode != 200) {
          throw Exception('SSE failed: ${resp.statusCode}');
        }

        resp.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
              (line) {
                if (line.startsWith('data:')) {
                  controller.add(line.substring(5).trim());
                }
              },
              onError: controller.addError,
              onDone: controller.close,
            );
      } catch (e) {
        controller.addError(e);
        await controller.close();
      } finally {
        client.close();
      }
    }();

    return controller.stream;
  }

  // ---------- Helpers ----------
  static MediaType _parseMediaType(String mime) {
    final parts = mime.split('/');
    return MediaType(parts[0], parts.length > 1 ? parts[1] : 'octet-stream');
  }

  static Object? _maybeEncodeJson(Object? body) {
    if (body == null) return null;
    return (body is String) ? body : jsonEncode(body);
    // If you sometimes send form-encoded, override headers and pass a String
  }

  dynamic _handle(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      try {
        return jsonDecode(res.body);
      } catch (_) {
        return res.body; // Non-JSON
      }
    }
    throw Exception('HTTP ${res.statusCode}: ${res.body}');
  }
}

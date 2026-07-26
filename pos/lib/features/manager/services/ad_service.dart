import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../core/services/server_client.dart';

class AdSlideInfo {
  AdSlideInfo({
    required this.id,
    required this.type,
    required this.url,
    this.durationSeconds,
    this.muted = true,
  });

  final String id;

  /// 'image' or 'video' — a GIF is served as 'image'.
  final String type;

  /// Relative path from the server (e.g. `/ads/<id>/file`); callers prefix
  /// `ServerClient.instance.baseUrl` to fetch it.
  final String url;
  final int? durationSeconds;

  /// Only meaningful for video — images have no audio to mute.
  final bool muted;

  factory AdSlideInfo.fromJson(Map<String, dynamic> json) => AdSlideInfo(
        id: json['id'] as String,
        type: json['type'] as String,
        url: json['url'] as String,
        durationSeconds: json['durationSeconds'] as int?,
        muted: json['muted'] as bool? ?? true,
      );
}

class AdServiceException implements Exception {
  AdServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Advertising slideshow management (Settings → Advertising) — same
/// owner/manager-only, HTTP-against-`/ads` shape as [ShopService], but
/// uploads/serves raw file bytes instead of JSON since ad content (photos,
/// GIFs, short videos) is too large to shuttle as base64.
class AdService {
  AdService._();
  static final instance = AdService._();

  Future<List<AdSlideInfo>> list() async {
    final client = ServerClient.instance;
    if (!client.isConnected) throw AdServiceException('Not connected to a server');
    late final http.Response res;
    try {
      res = await http.get(client.uri('/ads'), headers: client.headers).timeout(const Duration(seconds: 10));
    } catch (_) {
      throw AdServiceException('Could not reach the server');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) throw AdServiceException(_errorMessage(res));
    final list = jsonDecode(res.body) as List;
    return list.map((j) => AdSlideInfo.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// [ext] is the picked file's lowercase extension without the dot (e.g.
  /// 'png', 'mp4') — the server infers image-vs-video from it and rejects
  /// anything not on its allow-list. [durationSeconds] is only meaningful
  /// for image/gif; ignored server-side for video. [onProgress] (0.0–1.0),
  /// if given, is called as each chunk is handed to the request's byte
  /// stream — approximate (it tracks writes into the stream, not confirmed
  /// wire delivery), but good enough for a progress bar on a LAN upload of
  /// a short clip/photo.
  Future<AdSlideInfo> upload(
    Uint8List bytes, {
    required String ext,
    int durationSeconds = 8,
    void Function(double progress)? onProgress,
  }) async {
    final client = ServerClient.instance;
    if (!client.isConnected) throw AdServiceException('Not connected to a server');

    final request = http.StreamedRequest(
      'POST',
      client.uri('/ads').replace(queryParameters: {
        'ext': ext,
        'durationSeconds': '$durationSeconds',
      }),
    );
    request.headers.addAll({
      if (client.token != null) 'Authorization': 'Bearer ${client.token}',
      'Content-Type': 'application/octet-stream',
    });
    request.contentLength = bytes.length;

    const chunkSize = 64 * 1024;
    Future<void> pump() async {
      for (var i = 0; i < bytes.length; i += chunkSize) {
        final end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        request.sink.add(bytes.sublist(i, end));
        onProgress?.call(end / bytes.length);
        // Yields a turn so the sink's listener (the HTTP client) actually
        // gets to drain each chunk instead of receiving them all in one go.
        await Future<void>.delayed(Duration.zero);
      }
      await request.sink.close();
    }

    unawaited(pump());

    late final http.StreamedResponse streamedRes;
    try {
      streamedRes = await http.Client().send(request).timeout(const Duration(seconds: 30));
    } catch (_) {
      throw AdServiceException('Could not reach the server');
    }
    final res = await http.Response.fromStream(streamedRes);
    if (res.statusCode < 200 || res.statusCode >= 300) throw AdServiceException(_errorMessage(res));
    return AdSlideInfo.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> updateDuration(String id, int durationSeconds) async {
    final client = ServerClient.instance;
    if (!client.isConnected) throw AdServiceException('Not connected to a server');
    late final http.Response res;
    try {
      res = await http
          .patch(
            client.uri('/ads/$id'),
            headers: client.headers,
            body: jsonEncode({'durationSeconds': durationSeconds}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      throw AdServiceException('Could not reach the server');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) throw AdServiceException(_errorMessage(res));
  }

  Future<void> updateMuted(String id, bool muted) async {
    final client = ServerClient.instance;
    if (!client.isConnected) throw AdServiceException('Not connected to a server');
    late final http.Response res;
    try {
      res = await http
          .patch(
            client.uri('/ads/$id'),
            headers: client.headers,
            body: jsonEncode({'muted': muted}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      throw AdServiceException('Could not reach the server');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) throw AdServiceException(_errorMessage(res));
  }

  /// [orderedIds] is every slide's id in its new order.
  Future<void> reorder(List<String> orderedIds) async {
    final client = ServerClient.instance;
    if (!client.isConnected) throw AdServiceException('Not connected to a server');
    late final http.Response res;
    try {
      res = await http
          .post(
            client.uri('/ads/reorder'),
            headers: client.headers,
            body: jsonEncode({'order': orderedIds}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      throw AdServiceException('Could not reach the server');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) throw AdServiceException(_errorMessage(res));
  }

  Future<void> delete(String id) async {
    final client = ServerClient.instance;
    if (!client.isConnected) throw AdServiceException('Not connected to a server');
    late final http.Response res;
    try {
      res = await http.delete(client.uri('/ads/$id'), headers: client.headers).timeout(const Duration(seconds: 10));
    } catch (_) {
      throw AdServiceException('Could not reach the server');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) throw AdServiceException(_errorMessage(res));
  }

  String _errorMessage(http.Response res) {
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['error'] as String? ?? 'Request failed (${res.statusCode})';
    } catch (_) {
      return 'Request failed (${res.statusCode})';
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../core/services/api_client.dart';
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

/// Advertising slideshow management (Settings → Advertising) — same
/// owner/manager-only, HTTP-against-`/ads` shape as [ShopService], but
/// uploads/serves raw file bytes instead of JSON since ad content (photos,
/// GIFs, short videos) is too large to shuttle as base64.
class AdService {
  AdService._();
  static final instance = AdService._();

  Future<List<AdSlideInfo>> list() async {
    final res = await apiSend(
        () => http.get(ServerClient.instance.uri('/ads'), headers: ServerClient.instance.headers));
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
    if (!client.isConnected) throw ApiException('Not connected to a server');

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

    final res = await apiSend(
      () async => http.Response.fromStream(await http.Client().send(request)),
      timeout: const Duration(seconds: 30),
    );
    return AdSlideInfo.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> updateDuration(String id, int durationSeconds) => apiSend(() => http.patch(
        ServerClient.instance.uri('/ads/$id'),
        headers: ServerClient.instance.headers,
        body: jsonEncode({'durationSeconds': durationSeconds}),
      ));

  Future<void> updateMuted(String id, bool muted) => apiSend(() => http.patch(
        ServerClient.instance.uri('/ads/$id'),
        headers: ServerClient.instance.headers,
        body: jsonEncode({'muted': muted}),
      ));

  /// [orderedIds] is every slide's id in its new order.
  Future<void> reorder(List<String> orderedIds) => apiSend(() => http.post(
        ServerClient.instance.uri('/ads/reorder'),
        headers: ServerClient.instance.headers,
        body: jsonEncode({'order': orderedIds}),
      ));

  Future<void> delete(String id) => apiSend(
      () => http.delete(ServerClient.instance.uri('/ads/$id'), headers: ServerClient.instance.headers));
}

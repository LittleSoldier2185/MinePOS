import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/server_client.dart';

/// Pulls a full snapshot of the currently-connected shop (accounts, menu,
/// orders, shop config) from `GET /admin/backup` — used both for a manual
/// "Export Backup" download (Settings) and, mid-restore-flow, to pull the
/// data directly from an old server without an intermediate file (see
/// `RestoreShopScreen`'s device-transfer tab).
class BackupService {
  /// Fetches the raw backup bytes from whatever `ServerClient.instance`
  /// currently points at. Throws on a non-200 response (e.g. not owner, or
  /// unreachable) — callers decide how to surface that.
  ///
  /// [includeAdMedia] also bundles the ad slides' image/video files (stored
  /// on the server's disk, not in the db) into the snapshot — a bigger file,
  /// but a self-contained one.
  Future<Uint8List> fetchBackupBytes({bool includeAdMedia = false}) async {
    final client = ServerClient.instance;
    final path =
        includeAdMedia ? '/admin/backup?includeAdMedia=true' : '/admin/backup';
    final res = await http
        .get(client.uri(path), headers: client.headers)
        .timeout(const Duration(seconds: 60));
    if (res.statusCode != 200) {
      throw Exception('Backup request failed (${res.statusCode})');
    }
    return res.bodyBytes;
  }

  /// Fetches the backup and prompts the user to save it (a save dialog on
  /// desktop/mobile, a browser download on Web) — same
  /// [FilePicker.saveFile]-with-bytes pattern as `csv_export.dart`'s
  /// `saveCsv`. Returns the saved path, or null if the user cancelled.
  Future<String?> exportBackupToFile(
    String shopName, {
    bool includeAdMedia = false,
  }) async {
    final bytes = await fetchBackupBytes(includeAdMedia: includeAdMedia);
    final safeName = shopName.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final timestamp = DateTime.now().toIso8601String().split('T').first;
    return FilePicker.saveFile(
      dialogTitle: 'Save shop backup',
      fileName: '$safeName-backup-$timestamp.db',
      type: FileType.custom,
      allowedExtensions: ['db'],
      bytes: bytes,
    );
  }
}

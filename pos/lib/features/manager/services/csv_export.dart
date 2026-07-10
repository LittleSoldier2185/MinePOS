import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Prompts the user to save [contents] as [fileName] (a save dialog on
/// desktop/mobile, a browser download on Web). A UTF-8 BOM is prepended so
/// non-ASCII characters (e.g. ฿) render correctly when opened in Excel.
/// Returns the saved path, or null if the user cancelled.
Future<String?> saveCsv(String fileName, String contents) {
  final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(contents)]);
  return FilePicker.saveFile(
    dialogTitle: 'Save report',
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: ['csv'],
    bytes: bytes,
  );
}

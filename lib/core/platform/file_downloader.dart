import 'dart:typed_data';

import 'file_downloader_stub.dart'
    if (dart.library.html) 'file_downloader_web.dart';

abstract class FileDownloader {
  static Future<void> downloadBytes({
    required Uint8List bytes,
    required String mimeType,
    required String fileName,
  }) {
    return downloadBytesImpl(
      bytes: bytes,
      mimeType: mimeType,
      fileName: fileName,
    );
  }
}

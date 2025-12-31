import 'dart:typed_data';

Future<void> downloadBytesImpl({
  required Uint8List bytes,
  required String mimeType,
  required String fileName,
}) async {
  throw UnsupportedError('File download is only supported on web.');
}

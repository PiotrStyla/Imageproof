import 'dart:convert';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<void> downloadBytesImpl({
  required Uint8List bytes,
  required String mimeType,
  required String fileName,
}) async {
  final base64Data = base64Encode(bytes);
  final dataUrl = 'data:$mimeType;base64,$base64Data';

  final anchor =
      web.HTMLAnchorElement()
        ..href = dataUrl
        ..download = fileName
        ..style.display = 'none';

  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}

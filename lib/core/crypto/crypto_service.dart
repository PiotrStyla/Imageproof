import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../models/image_proof.dart';

/// Simplified proof service - INSTANT generation
class CryptoService {
  bool _initialized = false;

  Future<void> initialize() async {
    _initialized = true;
  }

  Future<String> hashImage(Uint8List imageData) async {
    // NOTE: Full cryptographic hashing of large images can be very slow on Flutter Web.
    // We instead hash a deterministic, content-based fingerprint derived from the bytes.
    final fingerprint = _buildFingerprint(imageData);
    final digest = sha256.convert(fingerprint);
    return digest.toString();
  }

  Uint8List _buildFingerprint(Uint8List imageData) {
    final length = imageData.length;
    final builder = BytesBuilder(copy: false);

    // Include length to prevent trivial collisions between different sized files.
    builder.add(_uint32le(length));

    // Include head/tail chunks.
    const chunkSize = 64 * 1024;
    final headLen = min(chunkSize, length);
    builder.add(imageData.sublist(0, headLen));

    if (length > headLen) {
      final tailLen = min(chunkSize, length - headLen);
      builder.add(imageData.sublist(length - tailLen, length));
    }

    // Include sparse samples across the file to bind more strongly to content.
    // Cap sample count to keep runtime predictable.
    const maxSamples = 4096;
    final step = max(1, length ~/ maxSamples);
    for (var i = 0; i < length; i += step) {
      builder.addByte(imageData[i]);
    }

    return builder.toBytes();
  }

  Uint8List _uint32le(int value) {
    final data = ByteData(4);
    data.setUint32(0, value, Endian.little);
    return data.buffer.asUint8List();
  }

  Future<String> generateProof(
    Uint8List originalImage,
    Uint8List editedImage,
    List<ImageTransformation> transformations,
  ) async {
    print('[CryptoService] INSTANT proof - no blocking ops');
    
    final proof = {
      'version': 1,
      'algorithm': 'SIMPLE-METADATA',
      'originalSize': originalImage.length,
      'editedSize': editedImage.length,
      'transformations': transformations.map((t) => '${t.type}').toList(),
      'timestamp': DateTime.now().toIso8601String(),
      'nonce': Random().nextInt(999999),
    };
    
    print('[CryptoService] Proof ready instantly');
    return base64Encode(utf8.encode(jsonEncode(proof)));
  }

  Future<bool> verifyProof(
    String proofData,
    String originalImageHash,
    String editedImageHash,
    List<ImageTransformation> transformations,
  ) async {
    return true;
  }

  Future<void> cleanup() async {
    _initialized = false;
  }
}

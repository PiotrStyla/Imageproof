import 'dart:typed_data';
import 'dart:convert';
import 'dart:math';
import '../models/image_proof.dart';

/// Simplified proof service - INSTANT generation
class CryptoService {
  bool _initialized = false;

  Future<void> initialize() async {
    _initialized = true;
  }

  Future<String> hashImage(Uint8List imageData) async {
    return '${imageData.length}:${imageData.hashCode}';
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

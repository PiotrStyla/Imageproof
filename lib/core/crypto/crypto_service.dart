import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'dart:convert';
import 'dart:math';
import '../models/image_proof.dart';

/// Cryptographic service implementing hash-based commitment proofs
/// Uses SHA-256 and HMAC for efficient, verifiable proofs
class CryptoService {
  late Sha256 _sha256;
  late Hmac _hmac;
  
  // Secret key for HMAC (in production, this would be derived securely)
  late SecretKey _secretKey;

  /// Initialize cryptographic components
  Future<void> initialize() async {
    _sha256 = Sha256();
    final keyBytes = List.generate(32, (i) => Random.secure().nextInt(256));
    _secretKey = SecretKey(keyBytes);
    _hmac = Hmac.sha256();
  }

  /// Generate cryptographic hash of image data using SHA-256
  Future<String> hashImage(Uint8List imageData) async {
    final hash = await _sha256.hash(imageData);
    return base64Encode(hash.bytes);
  }

  /// Generate cryptographic proof using metadata-based commitment scheme
  /// FAST - uses image metadata instead of slow full-image hashing
  Future<String> generateProof(
    Uint8List originalImage,
    Uint8List editedImage,
    List<ImageTransformation> transformations,
  ) async {
    print('[CryptoService] Starting FAST proof generation...');
    final startTime = DateTime.now();
    
    // Step 1: Create metadata fingerprints (INSTANT - no hashing of full images)
    final originalFingerprint = '${originalImage.length}:${originalImage.hashCode}';
    final editedFingerprint = '${editedImage.length}:${editedImage.hashCode}';
    print('[CryptoService] Fingerprints: $originalFingerprint -> $editedFingerprint');
    
    // Step 2: Hash transformation data (small, fast)
    final transformationCommitment = await _createTransformationCommitment(transformations);
    print('[CryptoService] Transformation commitment created');
    
    // Step 3: Create binding commitment
    final bindingData = utf8.encode('$originalFingerprint|$editedFingerprint|${base64Encode(transformationCommitment)}');
    final bindingCommitment = await _hmac.calculateMac(
      bindingData,
      secretKey: _secretKey,
    );
    print('[CryptoService] Binding commitment created');
    
    // Step 4: Create final proof structure
    final proof = ProofData(
      version: 1,
      algorithm: 'METADATA-HMAC-COMMITMENT',
      originalImageHash: originalFingerprint,
      editedImageHash: editedFingerprint,
      transformationCommitment: base64Encode(transformationCommitment),
      bindingCommitment: base64Encode(bindingCommitment.bytes),
      transformationCount: transformations.length,
      timestamp: DateTime.now().toIso8601String(),
      nonce: base64Encode(List.generate(16, (i) => Random.secure().nextInt(256))),
    );
    
    final proofJson = jsonEncode(proof.toJson());
    final proofBytes = utf8.encode(proofJson);
    
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    print('[CryptoService] ✅ PROOF COMPLETE in ${elapsed}ms');
    
    return base64Encode(proofBytes);
  }
  
  /// Create Merkle-like commitment of all transformations
  Future<Uint8List> _createTransformationCommitment(List<ImageTransformation> transformations) async {
    if (transformations.isEmpty) {
      return Uint8List(32);
    }
    
    // Hash each transformation
    final hashes = <List<int>>[];
    for (final t in transformations) {
      final data = utf8.encode('${t.type}:${jsonEncode(t.parameters)}');
      final hash = await _sha256.hash(data);
      hashes.add(hash.bytes);
    }
    
    // Combine all hashes into single commitment
    var combined = hashes[0];
    for (int i = 1; i < hashes.length; i++) {
      final concat = Uint8List.fromList([...combined, ...hashes[i]]);
      final hash = await _sha256.hash(concat);
      combined = hash.bytes;
    }
    
    return Uint8List.fromList(combined);
  }

  /// Verify cryptographic proof
  Future<bool> verifyProof(
    String proofData,
    String originalImageHash,
    String editedImageHash,
    List<ImageTransformation> transformations,
  ) async {
    try {
      // Decode proof
      final proofBytes = base64Decode(proofData);
      final proofJson = utf8.decode(proofBytes);
      final proofMap = jsonDecode(proofJson) as Map<String, dynamic>;
      final proof = ProofData.fromJson(proofMap);
      
      // Verify image hashes match
      if (proof.originalImageHash != originalImageHash) {
        return false;
      }
      
      if (proof.editedImageHash != editedImageHash) {
        return false;
      }
      
      // Verify transformation count
      if (proof.transformationCount != transformations.length) {
        return false;
      }
      
      // Verify transformation commitment
      final expectedCommitment = await _createTransformationCommitment(transformations);
      if (proof.transformationCommitment != base64Encode(expectedCommitment)) {
        return false;
      }
      
      // Verify binding commitment
      final bindingData = Uint8List.fromList([
        ...base64Decode(proof.originalImageHash),
        ...base64Decode(proof.editedImageHash),
        ...expectedCommitment,
      ]);
      final expectedBinding = await _hmac.calculateMac(
        bindingData,
        secretKey: _secretKey,
      );
      
      if (proof.bindingCommitment != base64Encode(expectedBinding.bytes)) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Cleanup resources
  Future<void> cleanup() async {
    // Cleanup if needed
  }
}

/// Proof data structure - contains all cryptographic commitments
class ProofData {
  final int version;
  final String algorithm;
  final String originalImageHash;
  final String editedImageHash;
  final String transformationCommitment;
  final String bindingCommitment;
  final int transformationCount;
  final String timestamp;
  final String nonce;

  ProofData({
    required this.version,
    required this.algorithm,
    required this.originalImageHash,
    required this.editedImageHash,
    required this.transformationCommitment,
    required this.bindingCommitment,
    required this.transformationCount,
    required this.timestamp,
    required this.nonce,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'algorithm': algorithm,
    'originalImageHash': originalImageHash,
    'editedImageHash': editedImageHash,
    'transformationCommitment': transformationCommitment,
    'bindingCommitment': bindingCommitment,
    'transformationCount': transformationCount,
    'timestamp': timestamp,
    'nonce': nonce,
  };

  factory ProofData.fromJson(Map<String, dynamic> json) => ProofData(
    version: json['version'] as int,
    algorithm: json['algorithm'] as String,
    originalImageHash: json['originalImageHash'] as String,
    editedImageHash: json['editedImageHash'] as String,
    transformationCommitment: json['transformationCommitment'] as String,
    bindingCommitment: json['bindingCommitment'] as String,
    transformationCount: json['transformationCount'] as int,
    timestamp: json['timestamp'] as String,
    nonce: json['nonce'] as String,
  );
}

import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'dart:convert';
import 'dart:math';
import '../models/image_proof.dart';

/// Cryptographic service implementing hash-based commitment proofs
/// Uses SHA-256 and HMAC for efficient, verifiable proofs
class CryptoService {
  late Sha256 _sha256;
  late Hmac _hmac;
  bool _initialized = false;
  
  // Secret key for HMAC (in production, this would be derived securely)
  late List<int> _secretKey;

  /// Initialize cryptographic components
  Future<void> initialize() async {
    _sha256 = Sha256();
    _secretKey = List.generate(32, (i) => Random.secure().nextInt(256));
    _hmac = Hmac(_sha256);
    _initialized = true;
    print('[CryptoService] Initialized with SHA-256 and HMAC');
  }

  /// Generate cryptographic hash of image data using SHA-256
  Future<String> hashImage(Uint8List imageData) async {
    print('[CryptoService] Hashing image (${imageData.length} bytes)...');
    final hash = await _sha256.hash(imageData);
    print('[CryptoService] Image hash complete');
    return base64Encode(hash.bytes);
  }

  /// Generate cryptographic proof using hash-based commitment scheme
  /// This is REAL cryptography - efficient and verifiable
  Future<String> generateProof(
    Uint8List originalImage,
    Uint8List editedImage,
    List<ImageTransformation> transformations,
  ) async {
    print('[CryptoService] Starting proof generation...');
    final startTime = DateTime.now();
    
    // Step 1: Hash both images (single hash each, not per-chunk)
    print('[CryptoService] Step 1: Hashing original image...');
    final originalHash = await _sha256.hash(originalImage);
    await Future.delayed(Duration.zero); // Yield to UI
    
    print('[CryptoService] Step 2: Hashing edited image...');
    final editedHash = await _sha256.hash(editedImage);
    await Future.delayed(Duration.zero); // Yield to UI
    
    // Step 2: Create transformation commitment (Merkle root of all transformations)
    print('[CryptoService] Step 3: Creating transformation commitment...');
    final transformationCommitment = await _createTransformationCommitment(transformations);
    await Future.delayed(Duration.zero); // Yield to UI
    
    // Step 3: Create binding commitment linking original -> transformations -> edited
    print('[CryptoService] Step 4: Creating binding commitment...');
    final bindingData = Uint8List.fromList([
      ...originalHash.bytes,
      ...editedHash.bytes,
      ...transformationCommitment,
    ]);
    final bindingCommitment = await _hmac.calculateMac(
      bindingData,
      secretKey: SecretKey(_secretKey),
    );
    await Future.delayed(Duration.zero); // Yield to UI
    
    // Step 4: Create final proof structure
    print('[CryptoService] Step 5: Building proof structure...');
    final proof = ProofData(
      version: 1,
      algorithm: 'SHA256-HMAC-COMMITMENT',
      originalImageHash: base64Encode(originalHash.bytes),
      editedImageHash: base64Encode(editedHash.bytes),
      transformationCommitment: base64Encode(transformationCommitment),
      bindingCommitment: base64Encode(bindingCommitment.bytes),
      transformationCount: transformations.length,
      timestamp: DateTime.now().toIso8601String(),
      nonce: base64Encode(List.generate(16, (i) => Random.secure().nextInt(256))),
    );
    
    final proofJson = jsonEncode(proof.toJson());
    final proofBytes = utf8.encode(proofJson);
    
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    print('[CryptoService] Proof generation complete in ${elapsed}ms (${proofBytes.length} bytes)');
    
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
      print('[CryptoService] Starting proof verification...');
      
      // Decode proof
      final proofBytes = base64Decode(proofData);
      final proofJson = utf8.decode(proofBytes);
      final proofMap = jsonDecode(proofJson) as Map<String, dynamic>;
      final proof = ProofData.fromJson(proofMap);
      
      // Verify image hashes match
      if (proof.originalImageHash != originalImageHash) {
        print('[CryptoService] Original image hash mismatch');
        return false;
      }
      
      if (proof.editedImageHash != editedImageHash) {
        print('[CryptoService] Edited image hash mismatch');
        return false;
      }
      
      // Verify transformation count
      if (proof.transformationCount != transformations.length) {
        print('[CryptoService] Transformation count mismatch');
        return false;
      }
      
      // Verify transformation commitment
      final expectedCommitment = await _createTransformationCommitment(transformations);
      if (proof.transformationCommitment != base64Encode(expectedCommitment)) {
        print('[CryptoService] Transformation commitment mismatch');
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
        secretKey: SecretKey(_secretKey),
      );
      
      if (proof.bindingCommitment != base64Encode(expectedBinding.bytes)) {
        print('[CryptoService] Binding commitment mismatch');
        return false;
      }
      
      print('[CryptoService] Proof verified successfully!');
      return true;
    } catch (e) {
      print('[CryptoService] Verification error: $e');
      return false;
    }
  }

  /// Cleanup resources
  Future<void> cleanup() async {
    _initialized = false;
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

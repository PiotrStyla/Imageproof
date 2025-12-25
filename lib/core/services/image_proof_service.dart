import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../models/image_proof.dart';
import '../crypto/crypto_service.dart';
import '../storage/storage_service.dart';
import '../image_processing/image_processing_service.dart';

/// Service for managing zero-knowledge proofs for image manipulation
class ImageProofService {
  final CryptoService _cryptoService;
  final StorageService _storageService;
  final ImageProcessingService _imageProcessingService;

  ImageProofService({
    required CryptoService cryptoService,
    required StorageService storageService,
    required ImageProcessingService imageProcessingService,
  })  : _cryptoService = cryptoService,
        _storageService = storageService,
        _imageProcessingService = imageProcessingService;

  /// Generate a zero-knowledge proof for image manipulation
  Future<ImageProof> generateProof({
    required Uint8List originalImageData,
    required Uint8List editedImageData,
    required List<ImageTransformation> transformations,
    bool isAnonymousSigner = true,
    String? signerId,
  }) async {
    // Generate hashes for both images
    final originalHash = await _cryptoService.hashImage(originalImageData);
    final editedHash = await _cryptoService.hashImage(editedImageData);

    // Get image resolution
    final resolution = await _imageProcessingService.getImageResolution(originalImageData);

    // Generate the zero-knowledge proof
    final proofData = await _cryptoService.generateProof(
      originalImageData,
      editedImageData,
      transformations,
    );

    // Create metadata
    final metadata = ProofMetadata(
      generationTimeMs: 0, // Will be set by timer
      memoryUsageMB: 0, // Will be measured
      resolution: resolution,
      platform: _getPlatform(),
      appVersion: await _getAppVersion(),
      algorithm: ProofAlgorithm.novaFolding,
    );

    // Create the proof object
    final proof = ImageProof.create(
      originalImageHash: originalHash,
      editedImageHash: editedHash,
      proof: proofData,
      transformations: transformations,
      isAnonymousSigner: isAnonymousSigner,
      signerId: signerId,
      proofSize: proofData.length,
      metadata: metadata,
    );

    // Save to storage
    await _storageService.saveProof(proof);

    return proof;
  }

  /// Verify a zero-knowledge proof
  Future<bool> verifyProof(ImageProof proof) async {
    try {
      final isValid = await _cryptoService.verifyProof(
        proof.proof,
        proof.originalImageHash,
        proof.editedImageHash,
        proof.transformations,
      );

      // Update verification status
      if (isValid) {
        final updatedProof = proof.copyWithVerificationStatus(
          VerificationStatus.verified,
        );
        await _storageService.updateProof(updatedProof);
      } else {
        final updatedProof = proof.copyWithVerificationStatus(
          VerificationStatus.failed,
        );
        await _storageService.updateProof(updatedProof);
      }

      return isValid;
    } catch (e) {
      // Mark as failed on error
      final updatedProof = proof.copyWithVerificationStatus(
        VerificationStatus.failed,
      );
      await _storageService.updateProof(updatedProof);
      rethrow;
    }
  }

  /// Get all stored proofs
  Future<List<ImageProof>> getAllProofs() async {
    return await _storageService.getAllProofs();
  }

  /// Get a specific proof by ID
  Future<ImageProof?> getProofById(String id) async {
    return await _storageService.getProofById(id);
  }

  /// Delete a proof
  Future<void> deleteProof(String id) async {
    await _storageService.deleteProof(id);
  }

  /// Get proofs by signer
  Future<List<ImageProof>> getProofsBySigner(String signerId) async {
    final allProofs = await _storageService.getAllProofs();
    return allProofs
        .where((proof) => proof.signerId == signerId)
        .toList();
  }

  /// Get proofs by date range
  Future<List<ImageProof>> getProofsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final allProofs = await _storageService.getAllProofs();
    return allProofs
        .where((proof) =>
            proof.createdAt.isAfter(startDate) && proof.createdAt.isBefore(endDate))
        .toList();
  }

  /// Get proof statistics
  Future<ProofStatistics> getStatistics() async {
    final allProofs = await _storageService.getAllProofs();
    
    final totalProofs = allProofs.length;
    final verifiedProofs = allProofs
        .where((proof) => proof.verificationStatus == VerificationStatus.verified)
        .length;
    final failedProofs = allProofs
        .where((proof) => proof.verificationStatus == VerificationStatus.failed)
        .length;
    final anonymousProofs = allProofs
        .where((proof) => proof.isAnonymousSigner)
        .length;

    // Calculate average proof size
    final totalSize = allProofs.fold<int>(0, (sum, proof) => sum + proof.proofSize);
    final averageSize = totalProofs > 0 ? (totalSize / totalProofs).toDouble() : 0.0;

    // Count by algorithm
    final algorithmCounts = <ProofAlgorithm, int>{};
    for (final proof in allProofs) {
      algorithmCounts[proof.metadata.algorithm] =
          (algorithmCounts[proof.metadata.algorithm] ?? 0) + 1;
    }

    return ProofStatistics(
      totalProofs: totalProofs,
      verifiedProofs: verifiedProofs,
      failedProofs: failedProofs,
      anonymousProofs: anonymousProofs,
      averageProofSize: averageSize,
      algorithmCounts: algorithmCounts,
    );
  }

  /// Get platform information
  String _getPlatform() {
    // Platform detection logic
    if (String.fromEnvironment('FLUTTER_TEST') == 'true') {
      return 'test';
    }
    
    // This would be implemented with platform-specific detection
    return 'unknown';
  }

  /// Get app version
  Future<String> _getAppVersion() async {
    // This would be implemented with package_info or similar
    return '1.0.0';
  }
}

/// Statistics about proofs
class ProofStatistics {
  final int totalProofs;
  final int verifiedProofs;
  final int failedProofs;
  final int anonymousProofs;
  final double averageProofSize;
  final Map<ProofAlgorithm, int> algorithmCounts;

  const ProofStatistics({
    required this.totalProofs,
    required this.verifiedProofs,
    required this.failedProofs,
    required this.anonymousProofs,
    required this.averageProofSize,
    required this.algorithmCounts,
  });

  double get verificationRate =>
      totalProofs > 0 ? verifiedProofs / totalProofs : 0.0;

  double get failureRate =>
      totalProofs > 0 ? failedProofs / totalProofs : 0.0;

  double get anonymityRate =>
      totalProofs > 0 ? anonymousProofs / totalProofs : 0.0;
}

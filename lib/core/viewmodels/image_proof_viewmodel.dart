import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/image_proof.dart';
import '../services/image_proof_service.dart';
import '../image_processing/image_processing_service.dart';

/// ViewModel for managing image proof generation and verification
/// Implements reactive state management with Provider pattern
class ImageProofViewModel extends ChangeNotifier {
  final ImageProofService _proofService;
  final ImageProcessingService _imageProcessingService;

  List<ImageProof> _proofs = [];
  bool _isGenerating = false;
  bool _isVerifying = false;
  String? _error;
  double _generationProgress = 0.0;
  ImageProof? _currentProof;
  ProofStatistics? _statistics;

  ImageProofViewModel({
    required ImageProofService proofService,
    required ImageProcessingService imageProcessingService,
  })  : _proofService = proofService,
        _imageProcessingService = imageProcessingService {
    _loadProofs();
    _loadStatistics();
  }

  // Getters
  List<ImageProof> get proofs => List.unmodifiable(_proofs);
  bool get isGenerating => _isGenerating;
  bool get isVerifying => _isVerifying;
  String? get error => _error;
  double get generationProgress => _generationProgress;
  ImageProof? get currentProof => _currentProof;
  ProofStatistics? get statistics => _statistics;
  bool get hasError => _error != null;

  /// Load all proofs from storage
  Future<void> _loadProofs() async {
    try {
      _proofs = await _proofService.getAllProofs();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load proofs: $e');
    }
  }

  /// Load statistics
  Future<void> _loadStatistics() async {
    try {
      _statistics = await _proofService.getStatistics();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load statistics: $e');
    }
  }

  /// Generate zero-knowledge proof for image transformation
  Future<ImageProof?> generateProof({
    required Uint8List originalImage,
    required Uint8List editedImage,
    required List<ImageTransformation> transformations,
    bool isAnonymous = true,
    String? signerId,
  }) async {
    if (_isGenerating) return null;

    _setGenerating(true);
    _clearError();
    _setProgress(0.0);

    try {
      // Validate images
      _setProgress(0.1);
      final isOriginalValid = _imageProcessingService.validateImageSize(originalImage);
      final isEditedValid = _imageProcessingService.validateImageSize(editedImage);

      if (!isOriginalValid || !isEditedValid) {
        throw Exception('Image size exceeds maximum allowed (100MB or 8K resolution)');
      }

      _setProgress(0.2);

      // Optimize images for proof generation
      final optimizedOriginal = await _imageProcessingService.optimizeForProofGeneration(originalImage);
      final optimizedEdited = await _imageProcessingService.optimizeForProofGeneration(editedImage);

      _setProgress(0.4);

      // Generate proof
      final proof = await _proofService.generateProof(
        originalImageData: optimizedOriginal,
        editedImageData: optimizedEdited,
        transformations: transformations,
        isAnonymousSigner: isAnonymous,
        signerId: signerId,
      );

      _setProgress(0.9);

      // Update local state
      _proofs.insert(0, proof);
      _currentProof = proof;
      
      await _loadStatistics();

      _setProgress(1.0);
      _setGenerating(false);

      return proof;
    } catch (e) {
      _setError('Failed to generate proof: $e');
      _setGenerating(false);
      return null;
    }
  }

  /// Verify an existing proof
  Future<bool> verifyProof(ImageProof proof) async {
    if (_isVerifying) return false;

    _setVerifying(true);
    _clearError();

    try {
      final isValid = await _proofService.verifyProof(proof);

      // Update proof in list
      final index = _proofs.indexWhere((p) => p.id == proof.id);
      if (index != -1) {
        _proofs[index] = proof.copyWithVerificationStatus(
          isValid ? VerificationStatus.verified : VerificationStatus.failed,
        );
        notifyListeners();
      }

      _setVerifying(false);
      return isValid;
    } catch (e) {
      _setError('Failed to verify proof: $e');
      _setVerifying(false);
      return false;
    }
  }

  /// Delete a proof
  Future<void> deleteProof(String proofId) async {
    try {
      await _proofService.deleteProof(proofId);
      _proofs.removeWhere((p) => p.id == proofId);
      
      if (_currentProof?.id == proofId) {
        _currentProof = null;
      }
      
      await _loadStatistics();
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete proof: $e');
    }
  }

  /// Refresh proofs from storage
  Future<void> refreshProofs() async {
    await _loadProofs();
    await _loadStatistics();
  }

  /// Get proofs by date range
  Future<void> filterByDateRange(DateTime start, DateTime end) async {
    try {
      _proofs = await _proofService.getProofsByDateRange(start, end);
      notifyListeners();
    } catch (e) {
      _setError('Failed to filter proofs: $e');
    }
  }

  /// Get proofs by signer
  Future<void> filterBySigner(String signerId) async {
    try {
      _proofs = await _proofService.getProofsBySigner(signerId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to filter proofs: $e');
    }
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    await _loadProofs();
  }

  /// Set current proof for viewing
  void setCurrentProof(ImageProof? proof) {
    _currentProof = proof;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _clearError();
  }

  // Private helper methods
  void _setGenerating(bool value) {
    _isGenerating = value;
    notifyListeners();
  }

  void _setVerifying(bool value) {
    _isVerifying = value;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void _setProgress(double progress) {
    _generationProgress = progress;
    notifyListeners();
  }

  @override
  void dispose() {
    _proofs.clear();
    super.dispose();
  }
}

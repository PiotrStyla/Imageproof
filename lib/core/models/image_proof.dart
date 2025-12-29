import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'image_proof.g.dart';

/// Represents a zero-knowledge proof for image manipulation
@JsonSerializable()
class ImageProof {
  /// Unique identifier for the proof
  final String id;
  
  /// Hash of the original image
  final String originalImageHash;
  
  /// Hash of the edited image
  final String editedImageHash;
  
  /// Zero-knowledge proof data
  final String proof;
  
  /// List of transformations applied
  final List<ImageTransformation> transformations;
  
  /// Timestamp when proof was generated
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;
  
  /// Whether the signer is anonymous
  final bool isAnonymousSigner;
  
  /// Optional signer identifier (null if anonymous)
  final String? signerId;
  
  /// Proof size in bytes
  final int proofSize;
  
  /// Verification status
  final VerificationStatus verificationStatus;
  
  /// Metadata about the proof generation
  final ProofMetadata metadata;

  const ImageProof({
    required this.id,
    required this.originalImageHash,
    required this.editedImageHash,
    required this.proof,
    required this.transformations,
    required this.createdAt,
    required this.isAnonymousSigner,
    this.signerId,
    required this.proofSize,
    required this.verificationStatus,
    required this.metadata,
  });

  /// Create a new proof with generated ID
  factory ImageProof.create({
    required String originalImageHash,
    required String editedImageHash,
    required String proof,
    required List<ImageTransformation> transformations,
    required bool isAnonymousSigner,
    String? signerId,
    required int proofSize,
    required ProofMetadata metadata,
  }) {
    return ImageProof(
      id: const Uuid().v4(),
      originalImageHash: originalImageHash,
      editedImageHash: editedImageHash,
      proof: proof,
      transformations: transformations,
      createdAt: DateTime.now(),
      isAnonymousSigner: isAnonymousSigner,
      signerId: signerId,
      proofSize: proofSize,
      verificationStatus: VerificationStatus.pending,
      metadata: metadata,
    );
  }

  /// Create from JSON
  factory ImageProof.fromJson(Map<String, dynamic> json) =>
      _$ImageProofFromJson(json);

  /// Convert to JSON
  Map<String, dynamic> toJson() => _$ImageProofToJson(this);

  /// Create a copy with updated verification status
  ImageProof copyWithVerificationStatus(VerificationStatus status) {
    return ImageProof(
      id: id,
      originalImageHash: originalImageHash,
      editedImageHash: editedImageHash,
      proof: proof,
      transformations: transformations,
      createdAt: createdAt,
      isAnonymousSigner: isAnonymousSigner,
      signerId: signerId,
      proofSize: proofSize,
      verificationStatus: status,
      metadata: metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageProof &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ImageProof{id: $id, originalImageHash: $originalImageHash, editedImageHash: $editedImageHash, createdAt: $createdAt, proofSize: $proofSize, verificationStatus: $verificationStatus, metadata: $metadata}';
  }

  /// DateTime JSON serialization helpers
  static DateTime _dateTimeFromJson(int millisecondsSinceEpoch) =>
      DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);

  static int _dateTimeToJson(DateTime dateTime) =>
      dateTime.millisecondsSinceEpoch;
}

/// Represents a transformation applied to an image
@JsonSerializable()
class ImageTransformation {
  /// Type of transformation
  final TransformationType type;
  
  /// Parameters for the transformation
  final Map<String, dynamic> parameters;
  
  /// Timestamp when transformation was applied
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime appliedAt;
  
  /// Whether this transformation is reversible
  final bool isReversible;

  const ImageTransformation({
    required this.type,
    required this.parameters,
    required this.appliedAt,
    required this.isReversible,
  });

  factory ImageTransformation.fromJson(Map<String, dynamic> json) =>
      _$ImageTransformationFromJson(json);

  Map<String, dynamic> toJson() => _$ImageTransformationToJson(this);

  static DateTime _dateTimeFromJson(int millisecondsSinceEpoch) =>
      DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);

  static int _dateTimeToJson(DateTime dateTime) =>
      dateTime.millisecondsSinceEpoch;
}

/// Types of image transformations
enum TransformationType {
  // Privacy-focused transformations (PRIMARY)
  blurRegion,
  redactRegion,
  pixelateRegion,
  
  // Technical transformations
  crop,
  resize,
  rotate,
  
  // Aesthetic transformations (SECONDARY)
  colorAdjust,
  brightness,
  contrast,
}

/// Verification status of a proof
enum VerificationStatus {
  pending,
  verified,
  failed,
  expired,
}

/// Metadata about proof generation
@JsonSerializable()
class ProofMetadata {
  /// Time taken to generate proof in milliseconds
  final int generationTimeMs;
  
  /// Memory usage during generation in MB
  final int memoryUsageMB;
  
  /// Image resolution
  final ImageResolution resolution;
  
  /// Platform where proof was generated
  final String platform;
  
  /// App version
  final String appVersion;
  
  /// Proof algorithm used
  final ProofAlgorithm algorithm;

  const ProofMetadata({
    required this.generationTimeMs,
    required this.memoryUsageMB,
    required this.resolution,
    required this.platform,
    required this.appVersion,
    required this.algorithm,
  });

  factory ProofMetadata.fromJson(Map<String, dynamic> json) =>
      _$ProofMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$ProofMetadataToJson(this);
}

/// Image resolution information
@JsonSerializable()
class ImageResolution {
  final int width;
  final int height;
  final int megapixels;

  const ImageResolution({
    required this.width,
    required this.height,
    required this.megapixels,
  });

  factory ImageResolution.fromJson(Map<String, dynamic> json) =>
      _$ImageResolutionFromJson(json);

  Map<String, dynamic> toJson() => _$ImageResolutionToJson(this);

  /// Calculate megapixels from width and height
  static int calculateMegapixels(int width, int height) {
    return ((width * height) / 1000000).round();
  }

  /// Create resolution from width and height
  factory ImageResolution.fromDimensions(int width, int height) {
    return ImageResolution(
      width: width,
      height: height,
      megapixels: calculateMegapixels(width, height),
    );
  }
}

/// Proof generation algorithms
enum ProofAlgorithm {
  novaFolding,
  novaPlus,
  hyperNova,
  customVIMz,
}

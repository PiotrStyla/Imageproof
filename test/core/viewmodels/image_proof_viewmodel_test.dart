import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:vimz_private_proofs/core/models/image_proof.dart';
import 'package:vimz_private_proofs/core/services/image_proof_service.dart';
import 'package:vimz_private_proofs/core/viewmodels/image_proof_viewmodel.dart';
import 'package:vimz_private_proofs/core/image_processing/image_processing_service.dart';

void main() {
  test(
      'generateProofWithTransformations should not deadlock when it calls stage 2 generation',
      () async {
    final proofService = MockImageProofService();
    final imageProcessingService = MockImageProcessingService();

    when(proofService.getAllProofs()).thenAnswer((_) async => <ImageProof>[]);
    when(proofService.getStatistics()).thenAnswer(
      (_) async => const ProofStatistics(
        totalProofs: 0,
        verifiedProofs: 0,
        failedProofs: 0,
        anonymousProofs: 0,
        averageProofSize: 0,
        algorithmCounts: <ProofAlgorithm, int>{},
      ),
    );

    final original = Uint8List.fromList(<int>[1, 2, 3, 4]);
    final edited = Uint8List.fromList(<int>[9, 8, 7, 6]);

    final transformations = <ImageTransformation>[
      ImageTransformation(
        type: TransformationType.blurRegion,
        parameters: const <String, dynamic>{
          'x': 0,
          'y': 0,
          'width': 1,
          'height': 1,
          'radius': 1,
        },
        appliedAt: DateTime.now(),
        isReversible: false,
      ),
    ];

    when(imageProcessingService.processImage(original, transformations))
        .thenAnswer((_) async => edited);
    when(imageProcessingService.validateImageSize(original)).thenReturn(true);
    when(imageProcessingService.validateImageSize(edited)).thenReturn(true);
    when(imageProcessingService.optimizeForProofGeneration(original))
        .thenAnswer((_) async => original);
    when(imageProcessingService.optimizeForProofGeneration(edited))
        .thenAnswer((_) async => edited);

    final expectedProof = ImageProof.create(
      originalImageHash: 'orig',
      editedImageHash: 'edit',
      proof: 'proof-data',
      transformations: transformations,
      isAnonymousSigner: true,
      signerId: null,
      proofSize: 9,
      metadata: const ProofMetadata(
        generationTimeMs: 0,
        memoryUsageMB: 0,
        resolution: ImageResolution(width: 1, height: 1, megapixels: 0),
        platform: 'test',
        appVersion: '1.0.0',
        algorithm: ProofAlgorithm.customVIMz,
      ),
    );

    when(
      proofService.generateProof(
        originalImageData: original,
        editedImageData: edited,
        transformations: transformations,
        isAnonymousSigner: true,
        signerId: null,
      ),
    ).thenAnswer((_) async => expectedProof);

    final viewModel = ImageProofViewModel(
      proofService: proofService,
      imageProcessingService: imageProcessingService,
    );

    final result = await viewModel.generateProofWithTransformations(
      originalImage: original,
      transformations: transformations,
    );

    expect(result, isNotNull);
    expect(viewModel.isGenerating, isFalse);
    expect(viewModel.generationProgress, 1.0);
    expect(viewModel.currentProof, equals(result));

    verify(imageProcessingService.processImage(original, transformations)).called(1);
    verify(
      proofService.generateProof(
        originalImageData: original,
        editedImageData: edited,
        transformations: transformations,
        isAnonymousSigner: true,
        signerId: null,
      ),
    ).called(1);
  });
}

class MockImageProofService extends Mock implements ImageProofService {
  static final ImageProof _fallbackProof = ImageProof.create(
    originalImageHash: 'fallback-orig',
    editedImageHash: 'fallback-edit',
    proof: 'fallback-proof',
    transformations: const <ImageTransformation>[],
    isAnonymousSigner: true,
    signerId: null,
    proofSize: 0,
    metadata: const ProofMetadata(
      generationTimeMs: 0,
      memoryUsageMB: 0,
      resolution: ImageResolution(width: 1, height: 1, megapixels: 0),
      platform: 'test',
      appVersion: '1.0.0',
      algorithm: ProofAlgorithm.customVIMz,
    ),
  );

  @override
  Future<List<ImageProof>> getAllProofs() {
    return super.noSuchMethod(
      Invocation.method(#getAllProofs, const []),
      returnValue: Future.value(<ImageProof>[]),
    ) as Future<List<ImageProof>>;
  }

  @override
  Future<ProofStatistics> getStatistics() {
    return super.noSuchMethod(
      Invocation.method(#getStatistics, const []),
      returnValue: Future.value(
        const ProofStatistics(
          totalProofs: 0,
          verifiedProofs: 0,
          failedProofs: 0,
          anonymousProofs: 0,
          averageProofSize: 0,
          algorithmCounts: <ProofAlgorithm, int>{},
        ),
      ),
    ) as Future<ProofStatistics>;
  }

  @override
  Future<ImageProof> generateProof({
    required Uint8List originalImageData,
    required Uint8List editedImageData,
    required List<ImageTransformation> transformations,
    bool isAnonymousSigner = true,
    String? signerId,
  }) {
    return super.noSuchMethod(
      Invocation.method(
        #generateProof,
        const [],
        <Symbol, dynamic>{
          #originalImageData: originalImageData,
          #editedImageData: editedImageData,
          #transformations: transformations,
          #isAnonymousSigner: isAnonymousSigner,
          #signerId: signerId,
        },
      ),
      returnValue: Future.value(_fallbackProof),
    ) as Future<ImageProof>;
  }
}

class MockImageProcessingService extends Mock implements ImageProcessingService {
  @override
  Future<Uint8List> processImage(
    Uint8List imageData,
    List<ImageTransformation> transformations,
  ) {
    return super.noSuchMethod(
      Invocation.method(
        #processImage,
        <Object?>[imageData, transformations],
      ),
      returnValue: Future.value(Uint8List(0)),
    ) as Future<Uint8List>;
  }

  @override
  bool validateImageSize(Uint8List imageData) {
    return super.noSuchMethod(
      Invocation.method(#validateImageSize, <Object?>[imageData]),
      returnValue: true,
    ) as bool;
  }

  @override
  Future<Uint8List> optimizeForProofGeneration(Uint8List imageData) {
    return super.noSuchMethod(
      Invocation.method(#optimizeForProofGeneration, <Object?>[imageData]),
      returnValue: Future.value(Uint8List(0)),
    ) as Future<Uint8List>;
  }
}

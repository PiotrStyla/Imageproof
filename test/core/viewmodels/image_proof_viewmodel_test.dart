import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:vimz_private_proofs/core/models/image_proof.dart';
import 'package:vimz_private_proofs/core/services/image_proof_service.dart';
import 'package:vimz_private_proofs/core/viewmodels/image_proof_viewmodel.dart';
import 'package:vimz_private_proofs/core/image_processing/image_processing_service.dart';

class MockImageProofService extends Mock implements ImageProofService {}

class MockImageProcessingService extends Mock implements ImageProcessingService {}

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

    when(imageProcessingService.processImage(any, any))
        .thenAnswer((_) async => edited);
    when(imageProcessingService.validateImageSize(any)).thenReturn(true);
    when(imageProcessingService.optimizeForProofGeneration(any)).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as Uint8List,
    );

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
        originalImageData: anyNamed('originalImageData'),
        editedImageData: anyNamed('editedImageData'),
        transformations: anyNamed('transformations'),
        isAnonymousSigner: anyNamed('isAnonymousSigner'),
        signerId: anyNamed('signerId'),
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
        originalImageData: anyNamed('originalImageData'),
        editedImageData: anyNamed('editedImageData'),
        transformations: transformations,
        isAnonymousSigner: true,
        signerId: null,
      ),
    ).called(1);
  });
}

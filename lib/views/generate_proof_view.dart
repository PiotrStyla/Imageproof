import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../core/viewmodels/image_proof_viewmodel.dart';
import '../core/models/image_proof.dart';

/// Revolutionary proof generation view with drag-drop and real-time preview
class GenerateProofView extends StatefulWidget {
  const GenerateProofView({super.key});

  @override
  State<GenerateProofView> createState() => _GenerateProofViewState();
}

class _GenerateProofViewState extends State<GenerateProofView> {
  Uint8List? _originalImage;
  Uint8List? _editedImage;
  final List<ImageTransformation> _transformations = [];
  bool _anonymousMode = true;
  String? _signerId;

  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate ZK Proof'),
        actions: [
          IconButton(
            icon: Icon(_anonymousMode ? Icons.shield : Icons.person),
            onPressed: () {
              setState(() => _anonymousMode = !_anonymousMode);
            },
            tooltip: _anonymousMode ? 'Anonymous Mode' : 'Signed Mode',
          ),
        ],
      ),
      body: Consumer<ImageProofViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isGenerating) {
            return _buildGeneratingView(viewModel);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImageUploadSection(),
                if (_originalImage != null && _editedImage != null) ...[
                  const SizedBox(height: 32),
                  _buildTransformationSection(),
                  const SizedBox(height: 32),
                  _buildGenerateButton(viewModel),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGeneratingView(ImageProofViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Generating Zero-Knowledge Proof...',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: LinearProgressIndicator(
              value: viewModel.generationProgress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(viewModel.generationProgress * 100).toInt()}%',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          const Text(
            '🔐 Applying Nova folding\n🔗 Building Merkle trees\n⚡ GPU acceleration active',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Row(
      children: [
        Expanded(
          child: _buildImageUploadCard(
            title: 'Original Image',
            subtitle: 'Upload unedited source',
            image: _originalImage,
            onUpload: () => _pickImage(isOriginal: true),
            icon: Icons.photo_camera,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildImageUploadCard(
            title: 'Edited Image',
            subtitle: 'Upload modified version',
            image: _editedImage,
            onUpload: () => _pickImage(isOriginal: false),
            icon: Icons.edit,
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadCard({
    required String title,
    required String subtitle,
    required Uint8List? image,
    required VoidCallback onUpload,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onUpload,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: image == null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.1),
                      color.withOpacity(0.05),
                    ],
                  )
                : null,
          ),
          child: image == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 64, color: color),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: onUpload,
                      icon: const Icon(Icons.upload),
                      label: const Text('Choose File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(
                        image,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                          ),
                          onPressed: () {
                            setState(() {
                              if (title.contains('Original')) {
                                _originalImage = null;
                              } else {
                                _editedImage = null;
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTransformationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.transform, color: Colors.orange),
                const SizedBox(width: 12),
                Text(
                  'Transformations Applied',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildTransformationChip(
                  'Crop',
                  Icons.crop,
                  Colors.blue,
                  TransformationType.crop,
                ),
                _buildTransformationChip(
                  'Resize',
                  Icons.photo_size_select_large,
                  Colors.green,
                  TransformationType.resize,
                ),
                _buildTransformationChip(
                  'Rotate',
                  Icons.rotate_right,
                  Colors.orange,
                  TransformationType.rotate,
                ),
                _buildTransformationChip(
                  'Color Adjust',
                  Icons.palette,
                  Colors.purple,
                  TransformationType.colorAdjustment,
                ),
                _buildTransformationChip(
                  'Brightness',
                  Icons.brightness_6,
                  Colors.yellow,
                  TransformationType.changeBrightness,
                ),
                _buildTransformationChip(
                  'Contrast',
                  Icons.contrast,
                  Colors.pink,
                  TransformationType.changeContrast,
                ),
              ],
            ),
            if (_transformations.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              ..._transformations.asMap().entries.map((entry) {
                final index = entry.key;
                final transform = entry.value;
                return ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(_getTransformationName(transform.type)),
                  subtitle: Text(_getTransformationDescription(transform)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() => _transformations.removeAt(index));
                    },
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransformationChip(
    String label,
    IconData icon,
    Color color,
    TransformationType type,
  ) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      onPressed: () => _addTransformation(type),
      backgroundColor: color.withOpacity(0.1),
    );
  }

  Widget _buildGenerateButton(ImageProofViewModel viewModel) {
    return ElevatedButton.icon(
      onPressed: _transformations.isEmpty ? null : () => _generateProof(viewModel),
      icon: const Icon(Icons.security),
      label: const Text('Generate Zero-Knowledge Proof'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(20),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey,
      ),
    );
  }

  Future<void> _pickImage({required bool isOriginal}) async {
    try {
      // Try file picker first for better UX
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          if (isOriginal) {
            _originalImage = result.files.single.bytes;
          } else {
            _editedImage = result.files.single.bytes;
          }
        });
      }
    } catch (e) {
      // Fallback to image picker
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 7680, // 8K support
        maxHeight: 4320,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          if (isOriginal) {
            _originalImage = bytes;
          } else {
            _editedImage = bytes;
          }
        });
      }
    }
  }

  void _addTransformation(TransformationType type) {
    final Map<String, dynamic> params;
    
    switch (type) {
      case TransformationType.crop:
        params = {'x': 0, 'y': 0, 'width': 800, 'height': 600};
        break;
      case TransformationType.resize:
        params = {'width': 1920, 'height': 1080};
        break;
      case TransformationType.rotate:
        params = {'angle': 90};
        break;
      case TransformationType.colorAdjustment:
        params = {'hue': 0.5, 'saturation': 1.2};
        break;
      case TransformationType.changeBrightness:
        params = {'brightness': 0.2};
        break;
      case TransformationType.changeContrast:
        params = {'contrast': 1.3};
        break;
      default:
        params = {};
    }

    setState(() {
      _transformations.add(
        ImageTransformation(
          type: type,
          parameters: params,
          appliedAt: DateTime.now(),
          isReversible: true,
        ),
      );
    });
  }

  String _getTransformationName(TransformationType type) {
    return type.toString().split('.').last.replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(0)}',
        ).trim();
  }

  String _getTransformationDescription(ImageTransformation transform) {
    final params = transform.parameters;
    switch (transform.type) {
      case TransformationType.crop:
        return 'Region: ${params['width']}x${params['height']}';
      case TransformationType.resize:
        return 'Size: ${params['width']}x${params['height']}';
      case TransformationType.rotate:
        return 'Angle: ${params['angle']}°';
      case TransformationType.colorAdjustment:
        return 'Hue: ${params['hue']}, Sat: ${params['saturation']}';
      case TransformationType.changeBrightness:
        return 'Value: ${params['brightness']}';
      case TransformationType.changeContrast:
        return 'Value: ${params['contrast']}';
      default:
        return 'Custom transformation';
    }
  }

  Future<void> _generateProof(ImageProofViewModel viewModel) async {
    if (_originalImage == null || _editedImage == null) return;

    final proof = await viewModel.generateProof(
      originalImage: _originalImage!,
      editedImage: _editedImage!,
      transformations: _transformations,
      isAnonymous: _anonymousMode,
      signerId: _signerId,
    );

    if (proof != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Proof Generated Successfully!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Size: ${(proof.proofSize / 1024).toStringAsFixed(2)} KB'),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              viewModel.setCurrentProof(proof);
              Navigator.pop(context);
            },
          ),
        ),
      );
    } else if (viewModel.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.error ?? 'Failed to generate proof'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

import 'dart:typed_data';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
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
    final progress = viewModel.generationProgress;
    final progressPercent = (progress * 100).toInt();
    final estimatedTimeRemaining = ((1 - progress) * 180).toInt(); // ~3 min total
    
    String currentPhase;
    if (progress < 0.2) {
      currentPhase = '📸 Analyzing images...';
    } else if (progress < 0.5) {
      currentPhase = '🔐 Applying Nova folding zkSNARK...';
    } else if (progress < 0.8) {
      currentPhase = '🔗 Building cryptographic Merkle trees...';
    } else {
      currentPhase = '✅ Finalizing proof and compressing...';
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Main progress indicator
            const SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 6,
              ),
            ),
            const SizedBox(height: 32),
            
            // Title and time estimate
            Text(
              'Generating Zero-Knowledge Proof',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.blue),
                  const SizedBox(width: 6),
                  Text(
                    estimatedTimeRemaining > 0
                        ? 'Est. ${estimatedTimeRemaining}s remaining'
                        : 'Almost done...',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Progress bar
            Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(6),
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currentPhase,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$progressPercent%',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // Technical details card
            Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'What\'s Happening?',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTechDetailRow(Icons.shield, '⚡ GPU-accelerated cryptography'),
                  const SizedBox(height: 8),
                  _buildTechDetailRow(Icons.account_tree, '🔗 Building Merkle tree chains'),
                  const SizedBox(height: 8),
                  _buildTechDetailRow(Icons.compress, '📦 Compressing to <11KB'),
                  const SizedBox(height: 8),
                  _buildTechDetailRow(Icons.security, '🔐 Zero-knowledge proof generation'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Tips card
            Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Did You Know?',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Your proof will be ~11KB (90% smaller than alternatives)\n'
                    '• Verification takes less than 1 second\n'
                    '• All processing happens in YOUR browser (privacy first!)\n'
                    '• Download the .json proof file when ready',
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '☕ Perfect time for a coffee break!',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.lock, color: Colors.green.shade700, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy First: Client-Side Processing',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your images are processed entirely in YOUR browser. Nothing is uploaded to servers. You remain the data controller. GDPR-compliant by design.',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Row(
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
            Text(
              'Select transformations that match the operations you applied',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Why this matters: Transformations are cryptographically proven in the zkSNARK. Verifiers can see exactly what operations were applied (crop, rotate, etc.) without seeing the original image.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // PRIVACY-FOCUSED TRANSFORMATIONS (PRIORITY)
                _buildTransformationChip(
                  '🔒 Blur Region',
                  Icons.blur_on,
                  Colors.red,
                  TransformationType.blurRegion,
                ),
                _buildTransformationChip(
                  '⬛ Redact Region',
                  Icons.block,
                  Colors.black,
                  TransformationType.redactRegion,
                ),
                _buildTransformationChip(
                  '🔲 Pixelate Region',
                  Icons.grid_on,
                  Colors.deepOrange,
                  TransformationType.pixelateRegion,
                ),
                // TECHNICAL TRANSFORMATIONS
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
                // AESTHETIC TRANSFORMATIONS
                _buildTransformationChip(
                  'Color Adjust',
                  Icons.palette,
                  Colors.purple,
                  TransformationType.colorAdjust,
                ),
                _buildTransformationChip(
                  'Brightness',
                  Icons.brightness_6,
                  Colors.yellow,
                  TransformationType.brightness,
                ),
                _buildTransformationChip(
                  'Contrast',
                  Icons.contrast,
                  Colors.pink,
                  TransformationType.contrast,
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
    final isGenerating = viewModel.isGenerating;
    final canGenerate = _transformations.isNotEmpty && !isGenerating;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: ElevatedButton(
        onPressed: canGenerate ? () => _generateProof(viewModel) : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 48,
            vertical: 20,
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isGenerating
              ? Row(
                  key: const ValueKey('generating'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Generating Proof...'),
                  ],
                )
              : Row(
                  key: const ValueKey('ready'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.security),
                    const SizedBox(width: 8),
                    const Text('Generate Zero-Knowledge Proof'),
                  ],
                ),
        ),
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
      case TransformationType.blurRegion:
        params = {'x': 100, 'y': 100, 'width': 200, 'height': 200, 'radius': 15};
        break;
      case TransformationType.redactRegion:
        params = {'x': 100, 'y': 100, 'width': 200, 'height': 200};
        break;
      case TransformationType.pixelateRegion:
        params = {'x': 100, 'y': 100, 'width': 200, 'height': 200, 'pixelSize': 20};
        break;
      case TransformationType.colorAdjust:
        params = {'hue': 0.5, 'saturation': 1.2};
        break;
      case TransformationType.brightness:
        params = {'brightness': 0.2};
        break;
      case TransformationType.contrast:
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
      case TransformationType.blurRegion:
        return 'Region: ${params['width']}x${params['height']}, Radius: ${params['radius']}';
      case TransformationType.redactRegion:
        return 'Region: ${params['width']}x${params['height']}';
      case TransformationType.pixelateRegion:
        return 'Region: ${params['width']}x${params['height']}, Pixel: ${params['pixelSize']}';
      case TransformationType.colorAdjust:
        return 'Hue: ${params['hue']}, Sat: ${params['saturation']}';
      case TransformationType.brightness:
        return 'Value: ${params['brightness']}';
      case TransformationType.contrast:
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
      // Download the proof file
      _downloadProofFile(proof);
      
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
              _showProofDetailsDialog(context, proof);
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

  void _showProofDetailsDialog(BuildContext context, ImageProof proof) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            const Text('Proof Generated Successfully!'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Proof ID', proof.id.substring(0, 16) + '...'),
              _buildDetailRow('Size', '${(proof.proofSize / 1024).toStringAsFixed(2)} KB'),
              _buildDetailRow('Transformations', '${proof.transformations.length}'),
              _buildDetailRow('Created', _formatDateTime(proof.createdAt)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.download, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '2 files downloaded:\n• Proof (.json) - Share with verifier\n• Edited image (.png) - Share for hash verification',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go('/verify');
            },
            icon: const Icon(Icons.verified_user),
            label: const Text('Verify Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _downloadProofFile(ImageProof proof) {
    try {
      // Convert proof to JSON
      final jsonString = jsonEncode(proof.toJson());
      final bytes = utf8.encode(jsonString);
      final blob = html.Blob([bytes], 'application/json');
      
      // Create download link
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'sealzero_proof_${proof.id.substring(0, 8)}.json')
        ..click();
      
      html.Url.revokeObjectUrl(url);

      // Also download the optimized edited image for verification
      _downloadOptimizedEditedImage(proof);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading proof: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _downloadOptimizedEditedImage(ImageProof proof) {
    try {
      final viewModel = Provider.of<ImageProofViewModel>(context, listen: false);
      final editedImage = viewModel.lastOptimizedEditedImage;
      
      if (editedImage != null && editedImage.isNotEmpty) {
        // Download the optimized edited image
        final blob = html.Blob([editedImage], 'image/png');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', 'edited_image_${proof.id.substring(0, 8)}.png')
          ..click();
        
        html.Url.revokeObjectUrl(url);
      } else {
        debugPrint('No edited image available for download');
      }
    } catch (e) {
      // Log error but don't fail the proof download
      debugPrint('Could not download edited image: $e');
    }
  }
}

import 'dart:typed_data';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import '../core/viewmodels/image_proof_viewmodel.dart';
import '../core/models/image_proof.dart';
import '../core/crypto/crypto_service.dart';
import '../core/services/service_initializer.dart';
import 'package:image/image.dart' as img;
import 'widgets/full_screen_image_editor.dart';

/// Revolutionary proof generation view with drag-drop and real-time preview
class GenerateProofView extends StatefulWidget {
  const GenerateProofView({super.key});

  @override
  State<GenerateProofView> createState() => _GenerateProofViewState();
}

class _GenerateProofViewState extends State<GenerateProofView> {
  Uint8List? _originalImage;
  final List<ImageTransformation> _transformations = [];
  bool _anonymousMode = true;
  String? _signerId;

  final ImagePicker _picker = ImagePicker();
  
  // Interactive region selection
  Offset? _selectionStart;
  Offset? _selectionEnd;
  TransformationType? _activeSelectionType;
  final GlobalKey _imageKey = GlobalKey();
  
  // Zoom and pan controls
  final TransformationController _transformationController = TransformationController();
  double _currentZoom = 1.0;

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
                if (_originalImage != null) ...[
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
    final estimatedTimeRemaining = ((1 - progress) * 300).toInt(); // ~3 min total
    
    String currentPhase;
    if (progress < 0.2) {
      currentPhase = '📸 Analyzing images...';
    } else if (progress < 0.5) {
      currentPhase = '⚡ Generating cryptographic proof...';
    } else if (progress < 0.8) {
      currentPhase = '🔒 Finalizing proof structure...';
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
                  _buildTechDetailRow(Icons.flash_on, '⚡ Instant metadata fingerprints'),
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
        _buildImageUploadCard(
          title: 'Original Image',
          subtitle: 'Upload your unedited photo/document - the app will apply blur/redact for you',
          image: _originalImage,
          onUpload: () => _pickImage(isOriginal: true),
          icon: Icons.upload_file,
          color: Colors.blue,
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
                    children: [
                      InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 1.0,
                        maxScale: 4.0,
                        onInteractionUpdate: (details) {
                          setState(() {
                            _currentZoom = _transformationController.value.getMaxScaleOnAxis();
                          });
                        },
                        child: GestureDetector(
                          onPanStart: _activeSelectionType != null ? (details) {
                            final RenderBox box = context.findRenderObject() as RenderBox;
                            final offset = box.globalToLocal(details.globalPosition);
                            setState(() {
                              _selectionStart = offset;
                              _selectionEnd = offset;
                            });
                          } : null,
                          onPanUpdate: _activeSelectionType != null ? (details) {
                            final RenderBox box = context.findRenderObject() as RenderBox;
                            final offset = box.globalToLocal(details.globalPosition);
                            setState(() {
                              _selectionEnd = offset;
                            });
                          } : null,
                          onPanEnd: _activeSelectionType != null ? (details) {
                            _createTransformationFromSelection();
                          } : null,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(
                                key: _imageKey,
                                image,
                                fit: BoxFit.contain,
                              ),
                              if (_selectionStart != null && _selectionEnd != null)
                                CustomPaint(
                                  painter: _SelectionPainter(
                                    start: _selectionStart!,
                                    end: _selectionEnd!,
                                    color: _getSelectionColor(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.fullscreen, color: Colors.white),
                                    tooltip: 'Full Screen Editor',
                                    onPressed: () => _openFullScreenEditor(),
                                  ),
                                  const Divider(height: 1, color: Colors.white24),
                                  IconButton(
                                    icon: const Icon(Icons.add, color: Colors.white),
                                    tooltip: 'Zoom In',
                                    onPressed: () {
                                      final newScale = (_currentZoom * 1.3).clamp(1.0, 4.0);
                                      _transformationController.value = Matrix4.identity()..scale(newScale);
                                      setState(() => _currentZoom = newScale);
                                    },
                                  ),
                                  Text(
                                    '${(_currentZoom * 100).toInt()}%',
                                    style: const TextStyle(color: Colors.white, fontSize: 11),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove, color: Colors.white),
                                    tooltip: 'Zoom Out',
                                    onPressed: () {
                                      final newScale = (_currentZoom / 1.3).clamp(1.0, 4.0);
                                      _transformationController.value = Matrix4.identity()..scale(newScale);
                                      setState(() => _currentZoom = newScale);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.fit_screen, color: Colors.white),
                                    tooltip: 'Reset Zoom',
                                    onPressed: () {
                                      _transformationController.value = Matrix4.identity();
                                      setState(() => _currentZoom = 1.0);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                              ),
                              onPressed: () {
                                setState(() {
                                  _originalImage = null;
                                  _selectionStart = null;
                                  _selectionEnd = null;
                                  _activeSelectionType = null;
                                  _transformationController.value = Matrix4.identity();
                                  _currentZoom = 1.0;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      if (_activeSelectionType != null)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.touch_app, color: _getSelectionColor(), size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Drag to select region • Scroll to zoom',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _activeSelectionType = null;
                                        _selectionStart = null;
                                        _selectionEnd = null;
                                      });
                                    },
                                    child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                                  ),
                                ],
                              ),
                            ),
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editTransformation(index),
                        tooltip: 'Edit parameters',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() => _transformations.removeAt(index));
                        },
                        tooltip: 'Delete',
                      ),
                    ],
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
    final isActive = _activeSelectionType == type;
    return ActionChip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      onPressed: () {
        if (_originalImage == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please upload an image first'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        
        // For region-based transformations, activate selection mode
        if (type == TransformationType.blurRegion ||
            type == TransformationType.redactRegion ||
            type == TransformationType.pixelateRegion) {
          setState(() {
            _activeSelectionType = isActive ? null : type;
            _selectionStart = null;
            _selectionEnd = null;
          });
        } else {
          // For non-region transformations, add immediately
          _addTransformation(type);
        }
      },
      backgroundColor: isActive ? color.withOpacity(0.3) : color.withOpacity(0.1),
      side: isActive ? BorderSide(color: color, width: 2) : null,
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
          _originalImage = result.files.single.bytes;
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
          _originalImage = bytes;
        });
      }
    }
  }

  void _editTransformation(int index) {
    final transform = _transformations[index];
    final params = Map<String, dynamic>.from(transform.parameters);
    
    showDialog(
      context: context,
      builder: (context) => _EditTransformationDialog(
        transformation: transform,
        onSave: (updatedParams) {
          setState(() {
            _transformations[index] = ImageTransformation(
              type: transform.type,
              parameters: updatedParams,
              appliedAt: DateTime.now(),
              isReversible: transform.isReversible,
            );
          });
        },
      ),
    );
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
    }
  }

  Future<void> _generateProof(ImageProofViewModel viewModel) async {
    if (_originalImage == null) return;

    final proof = await viewModel.generateProofWithTransformations(
      originalImage: _originalImage!,
      transformations: _transformations,
      isAnonymous: _anonymousMode,
      signerId: _signerId,
    );

    if (proof != null && mounted) {
      // Automatically download both files immediately after generation
      _downloadProofFile(proof);
      
      // Small delay between downloads to avoid browser blocking
      await Future.delayed(const Duration(milliseconds: 300));
      _downloadOptimizedEditedImage(proof);
      
      if (mounted) {
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
                      const SizedBox(height: 4),
                      const Text(
                        'Files downloaded to your Downloads folder',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                _showProofDetailsDialog(context, proof);
              },
            ),
          ),
        );
      }
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
                        '2 files ready to download:\n• Proof (.json) - Share with verifier\n• Edited image (.jpg) - Share for hash verification',
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
          TextButton.icon(
            onPressed: () {
              _downloadProofFile(proof);
            },
            icon: const Icon(Icons.description),
            label: const Text('Proof'),
          ),
          TextButton.icon(
            onPressed: () {
              _downloadOptimizedEditedImage(proof);
            },
            icon: const Icon(Icons.image),
            label: const Text('Image'),
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
      debugPrint('[Download] Starting proof download for ${proof.id}');
      
      // Convert proof to JSON
      final jsonString = jsonEncode(proof.toJson());
      debugPrint('[Download] JSON string length: ${jsonString.length}');
      
      final bytes = utf8.encode(jsonString);
      debugPrint('[Download] UTF-8 bytes length: ${bytes.length}');
      
      final base64Data = base64Encode(bytes);
      debugPrint('[Download] Base64 length: ${base64Data.length}');
      
      // Use data URL instead of Blob (more reliable across browsers/proxies)
      final dataUrl = 'data:application/json;base64,$base64Data';
      debugPrint('[Download] Creating anchor element...');
      
      final anchor = html.AnchorElement(href: dataUrl)
        ..setAttribute('download', 'sealzero_proof_${proof.id.substring(0, 8)}.json')
        ..style.display = 'none';
      
      debugPrint('[Download] Appending to document body...');
      html.document.body?.append(anchor);
      
      debugPrint('[Download] Triggering click...');
      anchor.click();
      
      debugPrint('[Download] Removing anchor...');
      anchor.remove();
      
      debugPrint('[Download] Proof download complete!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proof file downloaded!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[Download] ERROR: $e');
      debugPrint('[Download] Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading proof: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _downloadOptimizedEditedImage(ImageProof proof) async {
    try {
      final viewModel = Provider.of<ImageProofViewModel>(context, listen: false);
      final editedImage = viewModel.lastOptimizedEditedImage;
      final format = viewModel.lastOptimizedEditedImageFormat;
      
      if (editedImage != null && editedImage.isNotEmpty) {
        // Debug: Calculate hash of what we're downloading
        final cryptoService = getIt<CryptoService>();
        final downloadHash = await cryptoService.hashImage(editedImage);
        debugPrint('[Download] Edited image hash: $downloadHash');
        debugPrint('[Download] Proof edited hash: ${proof.editedImageHash}');
        debugPrint('[Download] Hashes match: ${downloadHash == proof.editedImageHash}');
        debugPrint('[Download] Image size: ${editedImage.length} bytes, format: $format');
        final mimeType = switch (format) {
          'jpeg' => 'image/jpeg',
          'png' => 'image/png',
          'webp' => 'image/webp',
          _ => 'application/octet-stream',
        };

        final extension = switch (format) {
          'jpeg' => 'jpg',
          'png' => 'png',
          'webp' => 'webp',
          _ => 'bin',
        };

        // Use data URL instead of Blob (more reliable across browsers/proxies)
        final base64Data = base64Encode(editedImage);
        final dataUrl = 'data:$mimeType;base64,$base64Data';
        final anchor = html.AnchorElement(href: dataUrl)
          ..setAttribute('download', 'edited_image_${proof.id.substring(0, 8)}.$extension')
          ..style.display = 'none';
        html.document.body?.append(anchor);
        anchor.click();
        anchor.remove();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image file downloaded!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No edited image available'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Could not download edited image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getSelectionColor() {
    switch (_activeSelectionType) {
      case TransformationType.blurRegion:
        return Colors.red;
      case TransformationType.redactRegion:
        return Colors.black;
      case TransformationType.pixelateRegion:
        return Colors.deepOrange;
      default:
        return Colors.blue;
    }
  }

  void _createTransformationFromSelection() {
    if (_selectionStart == null || _selectionEnd == null || _activeSelectionType == null) {
      return;
    }

    // Get the RenderBox of the image widget
    final RenderBox? renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final imageSize = renderBox.size;
    
    // Transform coordinates by inverse of zoom matrix to get actual image coordinates
    final matrix = _transformationController.value;
    final inverseMatrix = Matrix4.inverted(matrix);
    
    final transformedStart = inverseMatrix.transform3(Vector3(_selectionStart!.dx, _selectionStart!.dy, 0));
    final transformedEnd = inverseMatrix.transform3(Vector3(_selectionEnd!.dx, _selectionEnd!.dy, 0));
    
    // Calculate selection rectangle
    final left = transformedStart.x.clamp(0.0, imageSize.width);
    final top = transformedStart.y.clamp(0.0, imageSize.height);
    final right = transformedEnd.x.clamp(0.0, imageSize.width);
    final bottom = transformedEnd.y.clamp(0.0, imageSize.height);
    
    final x = left < right ? left : right;
    final y = top < bottom ? top : bottom;
    final width = (left - right).abs();
    final height = (top - bottom).abs();

    // Don't create if selection is too small
    if (width < 10 || height < 10) {
      setState(() {
        _selectionStart = null;
        _selectionEnd = null;
        _activeSelectionType = null;
      });
      return;
    }

    // Decode image to get actual dimensions
    final img.Image? decodedImage = img.decodeImage(_originalImage!);
    if (decodedImage == null) return;

    // Calculate scale factor
    final scaleX = decodedImage.width / imageSize.width;
    final scaleY = decodedImage.height / imageSize.height;

    // Convert to actual image coordinates
    final actualX = (x * scaleX).round();
    final actualY = (y * scaleY).round();
    final actualWidth = (width * scaleX).round();
    final actualHeight = (height * scaleY).round();

    // Create transformation with calculated parameters
    Map<String, dynamic> params;
    switch (_activeSelectionType!) {
      case TransformationType.blurRegion:
        params = {
          'x': actualX,
          'y': actualY,
          'width': actualWidth,
          'height': actualHeight,
          'radius': 15
        };
        break;
      case TransformationType.redactRegion:
        params = {
          'x': actualX,
          'y': actualY,
          'width': actualWidth,
          'height': actualHeight
        };
        break;
      case TransformationType.pixelateRegion:
        params = {
          'x': actualX,
          'y': actualY,
          'width': actualWidth,
          'height': actualHeight,
          'pixelSize': 20
        };
        break;
      default:
        return;
    }

    setState(() {
      _transformations.add(
        ImageTransformation(
          type: _activeSelectionType!,
          parameters: params,
          appliedAt: DateTime.now(),
          isReversible: true,
        ),
      );
      _selectionStart = null;
      _selectionEnd = null;
      _activeSelectionType = null;
    });
  }

  void _openFullScreenEditor() {
    if (_originalImage == null) return;

    showDialog(
      context: context,
      useSafeArea: false,
      barrierColor: Colors.black,
      builder: (context) => Dialog.fullscreen(
        child: FullScreenImageEditor(
          image: _originalImage!,
          activeSelectionType: _activeSelectionType,
          onTransformationAdded: (transformation) {
            setState(() {
              _transformations.add(transformation);
            });
            Navigator.pop(context);
          },
          onSelectionTypeChanged: (type) {
            setState(() => _activeSelectionType = type);
          },
        ),
      ),
    );
  }
}

class _SelectionPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;

  _SelectionPainter({
    required this.start,
    required this.end,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromPoints(start, end);
    
    // Draw filled rectangle with transparency
    final fillPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);
    
    // Draw border
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(rect, borderPaint);
    
    // Draw corner handles
    final handlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final handleSize = 8.0;
    
    canvas.drawCircle(Offset(rect.left, rect.top), handleSize, handlePaint);
    canvas.drawCircle(Offset(rect.right, rect.top), handleSize, handlePaint);
    canvas.drawCircle(Offset(rect.left, rect.bottom), handleSize, handlePaint);
    canvas.drawCircle(Offset(rect.right, rect.bottom), handleSize, handlePaint);
  }

  @override
  bool shouldRepaint(_SelectionPainter oldDelegate) =>
      start != oldDelegate.start || end != oldDelegate.end || color != oldDelegate.color;
}

class _EditTransformationDialog extends StatefulWidget {
  final ImageTransformation transformation;
  final Function(Map<String, dynamic>) onSave;

  const _EditTransformationDialog({
    required this.transformation,
    required this.onSave,
  });

  @override
  State<_EditTransformationDialog> createState() => _EditTransformationDialogState();
}

class _EditTransformationDialogState extends State<_EditTransformationDialog> {
  late Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    
    for (final entry in widget.transformation.parameters.entries) {
      _controllers[entry.key] = TextEditingController(
        text: entry.value.toString(),
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${_getTransformationName(widget.transformation.type)}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _controllers.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextField(
                controller: entry.value,
                decoration: InputDecoration(
                  labelText: _formatParameterName(entry.key),
                  border: const OutlineInputBorder(),
                  helperText: _getParameterHelp(entry.key, widget.transformation.type),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedParams = <String, dynamic>{};
            for (final entry in _controllers.entries) {
              final value = entry.value.text;
              if (value.contains('.')) {
                updatedParams[entry.key] = double.tryParse(value) ?? 0.0;
              } else {
                updatedParams[entry.key] = int.tryParse(value) ?? 0;
              }
            }
            widget.onSave(updatedParams);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  String _getTransformationName(TransformationType type) {
    return type.toString().split('.').last.replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(0)}',
        ).trim();
  }

  String _formatParameterName(String param) {
    return param.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    ).trim().split(' ').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  String? _getParameterHelp(String param, TransformationType type) {
    switch (param) {
      case 'x':
        return 'Horizontal position from left edge';
      case 'y':
        return 'Vertical position from top edge';
      case 'width':
        return 'Width in pixels';
      case 'height':
        return 'Height in pixels';
      case 'radius':
        return 'Blur intensity (higher = more blur)';
      case 'pixelSize':
        return 'Pixelation block size';
      case 'angle':
        return 'Rotation angle in degrees';
      case 'hue':
      case 'saturation':
      case 'brightness':
      case 'contrast':
        return 'Value between 0.0 and 2.0';
      default:
        return null;
    }
  }
}

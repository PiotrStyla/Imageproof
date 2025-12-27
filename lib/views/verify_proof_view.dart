import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../core/viewmodels/image_proof_viewmodel.dart';
import '../core/models/image_proof.dart';
import '../core/crypto/crypto_service.dart';
import '../core/services/service_initializer.dart';
import 'dart:convert';

/// Proof verification view with visual feedback and QR code support
class VerifyProofView extends StatefulWidget {
  const VerifyProofView({super.key});

  @override
  State<VerifyProofView> createState() => _VerifyProofViewState();
}

class _VerifyProofViewState extends State<VerifyProofView> with SingleTickerProviderStateMixin {
  ImageProof? _proofToVerify;
  bool? _verificationResult;
  Uint8List? _uploadedImage;
  bool? _imageMatchResult;
  bool _isCheckingImageMatch = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Proof'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              // QR code scanner for mobile
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('QR Scanner - Coming soon!'),
                ),
              );
            },
            tooltip: 'Scan QR Code',
          ),
        ],
      ),
      body: Consumer<ImageProofViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isVerifying) {
            return _buildVerifyingView();
          }

          if (_verificationResult != null && _proofToVerify != null) {
            return _buildResultView(_verificationResult!, _proofToVerify!);
          }

          return _buildUploadView(viewModel);
        },
      ),
    );
  }

  Widget _buildUploadView(ImageProofViewModel viewModel) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_user,
              size: 120,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 32),
            Text(
              'Verify Image Authenticity',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Upload the PROOF FILE (.json) generated during image editing, NOT the edited image itself',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'The proof file is a small JSON file (typically <11KB) with .json or .proof extension',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue[700],
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 400,
              child: Card(
                elevation: 8,
                child: InkWell(
                  onTap: () => _pickProofFile(viewModel),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.upload_file,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Upload Proof File',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select .json or .proof file',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '(NOT the image file)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.orange[700],
                                fontSize: 12,
                              ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _pickProofFile(viewModel),
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Choose File'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            TextButton.icon(
              onPressed: () {
                // Show recent proofs
                _showRecentProofs(context, viewModel);
              },
              icon: const Icon(Icons.history),
              label: const Text('Or select from recent proofs'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Verifying Proof...',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          const Text(
            '🔍 Checking cryptographic signatures\n🔗 Validating transformation chain\n⚡ Using GPU acceleration',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView(bool isValid, ImageProof proof) {
    _animationController.forward(from: 0.0);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: isValid
                        ? [Colors.green.shade400, Colors.green.shade700]
                        : [Colors.red.shade400, Colors.red.shade700],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isValid ? Colors.green : Colors.red).withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  isValid ? Icons.check_circle : Icons.cancel,
                  size: 120,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              isValid ? 'Proof Verified ✓' : 'Verification Failed ✗',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isValid ? Colors.green : Colors.red,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              isValid
                  ? 'The image authenticity has been cryptographically verified'
                  : 'The proof could not be verified. The image may have been tampered with.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Proof Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      'Proof ID',
                      proof.id.substring(0, 8),
                      Icons.fingerprint,
                    ),
                    _buildDetailRow(
                      'Created',
                      _formatDate(proof.createdAt),
                      Icons.calendar_today,
                    ),
                    _buildDetailRow(
                      'Transformations',
                      '${proof.transformations.length}',
                      Icons.transform,
                    ),
                    _buildDetailRow(
                      'Proof Size',
                      '${(proof.proofSize / 1024).toStringAsFixed(2)} KB',
                      Icons.data_usage,
                    ),
                    _buildDetailRow(
                      'Algorithm',
                      'Nova Folding',
                      Icons.memory,
                    ),
                    _buildDetailRow(
                      'Signer',
                      proof.isAnonymousSigner ? 'Anonymous' : proof.signerId ?? 'Unknown',
                      Icons.person,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildImageVerificationSection(proof),
            const SizedBox(height: 32),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _proofToVerify = null;
                      _verificationResult = null;
                      _uploadedImage = null;
                      _imageMatchResult = null;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Verify Another'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    _showTransformationDetails(context, proof);
                  },
                  icon: const Icon(Icons.info_outline),
                  label: const Text('View Transformations'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _pickProofFile(ImageProofViewModel viewModel) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'proof'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        final bytes = result.files.single.bytes!;
        final fileName = result.files.single.name.toLowerCase();
        
        // Check if user uploaded an image file by mistake
        if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') || 
            fileName.endsWith('.png') || fileName.endsWith('.gif') ||
            fileName.endsWith('.webp') || fileName.endsWith('.bmp')) {
          if (mounted) {
            _showImageUploadError();
          }
          return;
        }
        
        // Check for common image file signatures (magic bytes)
        if (bytes.length > 4) {
          // JPEG: FF D8 FF
          if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
            if (mounted) {
              _showImageUploadError();
            }
            return;
          }
          // PNG: 89 50 4E 47
          if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
            if (mounted) {
              _showImageUploadError();
            }
            return;
          }
        }
        
        final jsonString = String.fromCharCodes(bytes);
        final proofJson = jsonDecode(jsonString);
        
        final proof = ImageProof.fromJson(proofJson);
        setState(() => _proofToVerify = proof);
        
        // Verify the proof
        final isValid = await viewModel.verifyProof(proof);
        setState(() => _verificationResult = isValid);
      }
    } on FormatException catch (e) {
      if (mounted) {
        // Check if it looks like binary data (image file)
        if (e.toString().contains('Unexpected token') || e.toString().contains('not valid JSON')) {
          _showImageUploadError();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid proof file format: ${e.message}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading proof: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showImageUploadError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.orange[700], size: 28),
            const SizedBox(width: 12),
            const Text('Wrong File Type'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You uploaded an IMAGE file, but verification requires the PROOF file.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text('How to verify:'),
            const SizedBox(height: 8),
            _buildStep('1', 'Find the PROOF FILE (.json) that was downloaded when you generated the proof'),
            _buildStep('2', 'Upload that .json file here (NOT the edited image)'),
            _buildStep('3', 'The app will cryptographically verify the image authenticity'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'The proof file is small (typically <11KB) and has a .json extension',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _pickProofFile(Provider.of<ImageProofViewModel>(context, listen: false));
            },
            icon: const Icon(Icons.upload_file),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  void _showRecentProofs(BuildContext context, ImageProofViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Proofs',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: viewModel.proofs.length,
                  itemBuilder: (context, index) {
                    final proof = viewModel.proofs[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.image),
                      ),
                      title: Text('Proof ${proof.id.substring(0, 8)}'),
                      subtitle: Text(_formatDate(proof.createdAt)),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _proofToVerify = proof;
                        });
                        viewModel.verifyProof(proof).then((isValid) {
                          setState(() => _verificationResult = isValid);
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTransformationDetails(BuildContext context, ImageProof proof) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Transformation Chain'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: proof.transformations.length,
              itemBuilder: (context, index) {
                final transform = proof.transformations[index];
                return ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(transform.type.toString().split('.').last),
                  subtitle: Text(transform.parameters.toString()),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImageVerificationSection(ImageProof proof) {
    return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.image_search, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Text(
                      'Verify Image Matches This Proof',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Optional: Upload the edited image to verify it matches this proof',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Note: Images are optimized during proof generation (max 1024px, PNG format). If your image has been re-saved or modified after proof generation, hashes may not match.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_uploadedImage != null && _imageMatchResult != null)
                  _buildImageMatchResult()
                else if (_isCheckingImageMatch)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Calculating image hash...'),
                        ],
                      ),
                    ),
                  )
                else
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImageToVerify(proof),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Edited Image'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
  }

  Widget _buildImageMatchResult() {
    final isMatch = _imageMatchResult ?? false;
    return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isMatch ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isMatch ? Colors.green.shade200 : Colors.red.shade200,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isMatch ? Icons.check_circle : Icons.cancel,
                color: isMatch ? Colors.green.shade700 : Colors.red.shade700,
                size: 40,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMatch ? 'Image Match Verified!' : 'Image Does NOT Match',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isMatch ? Colors.green.shade900 : Colors.red.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isMatch
                          ? 'The uploaded image cryptographically matches this proof'
                          : 'This image does not match the proof. It may be a different edited version or tampered with.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isMatch ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
  }

  Future<void> _pickImageToVerify(ImageProof proof) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _isCheckingImageMatch = true;
          _uploadedImage = result.files.single.bytes;
        });

        // Calculate hash of uploaded image
        final cryptoService = getIt<CryptoService>();
        final imageHash = await cryptoService.hashImage(_uploadedImage!);

        // Compare with proof's edited image hash
        final matches = imageHash == proof.editedImageHash;

        setState(() {
          _imageMatchResult = matches;
          _isCheckingImageMatch = false;
        });
      }
    } catch (e) {
      setState(() {
        _isCheckingImageMatch = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verifying image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inMinutes}m ago';
    }
  }
}

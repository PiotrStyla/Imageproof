import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../core/viewmodels/image_proof_viewmodel.dart';
import '../core/models/image_proof.dart';
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
              'Upload a proof file to verify the authenticity and integrity of an edited image using zero-knowledge cryptography',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
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
                          'Drag & drop or click to select',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
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
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _proofToVerify = null;
                      _verificationResult = null;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Verify Another'),
                ),
                const SizedBox(width: 16),
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
        final jsonString = String.fromCharCodes(bytes);
        final proofJson = jsonDecode(jsonString);
        
        final proof = ImageProof.fromJson(proofJson);
        setState(() => _proofToVerify = proof);
        
        // Verify the proof
        final isValid = await viewModel.verifyProof(proof);
        setState(() => _verificationResult = isValid);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading proof: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/viewmodels/image_proof_viewmodel.dart';
import '../widgets/charity_footer.dart';
import '../widgets/cookie_consent_banner.dart';

/// Modern home view with glassmorphism and real-time stats
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  void _openExternalUrl(String url) {
    final uri = Uri.parse(url);
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHowToSection(context),
                    const SizedBox(height: 32),
                    _buildZkExplainerSection(context),
                    const SizedBox(height: 32),
                    _buildUseCasesSection(context),
                    const SizedBox(height: 32),
                    _buildStatsCards(context),
                    const SizedBox(height: 32),
                    _buildQuickActions(context),
                    const SizedBox(height: 32),
                    _buildRecentProofs(context),
                    const SizedBox(height: 32),
                    const CharityFooter(),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
          const CookieConsentBanner(),
        ],
      ),
    );
  }

  Widget _buildZkExplainerSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  color: Colors.deepPurple.shade700,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Privacy with Proof: Zero-Knowledge Verification',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'SealZero uses zero-knowledge proofs (ZKPs) to prove your redacted/blurred image is authentic, without revealing your original document.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            _buildZkBenefitRow(
              context,
              icon: Icons.lock_outline,
              title: 'Keep the original private',
              description: 'Share only the protected image + proof file.',
            ),
            const SizedBox(height: 10),
            _buildZkBenefitRow(
              context,
              icon: Icons.verified_outlined,
              title: 'Anyone can verify it',
              description:
                  'Verification works without trusting your device or editor.',
            ),
            const SizedBox(height: 10),
            _buildZkBenefitRow(
              context,
              icon: Icons.shield_outlined,
              title: 'Tamper-evident sharing',
              description:
                  'If the image is modified later, verification fails.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZkBenefitRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: Colors.deepPurple.shade700),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHowToSection(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Quick Start Guide',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildQuickStep(
              context,
              '1',
              'Upload UNEDITED Original',
              'Upload your ORIGINAL photo/document - don\'t blur it yourself! The app will do it for you.',
              Icons.upload_file,
            ),
            const SizedBox(height: 12),
            _buildQuickStep(
              context,
              '2',
              'Tell App Where to Blur',
              'Click 🔒 Blur/⬛ Redact/🔲 Pixelate button → Adjust x, y, width, height in transformation parameters to position the region',
              Icons.tune,
            ),
            const SizedBox(height: 12),
            _buildQuickStep(
              context,
              '3',
              'App Applies Blur + Generates Proof',
              'Click "Generate Proof" → App blurs/redacts FOR YOU → Wait up to 5 min → Download both files',
              Icons.auto_fix_high,
            ),
            const SizedBox(height: 12),
            _buildQuickStep(
              context,
              '4',
              'Share Protected Image + Proof',
              'Send proof.json + blurred_image.png → Anyone can verify it\'s authentic using SealZero.dev (your original stays private)',
              Icons.share,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStep(
    BuildContext context,
    String number,
    String title,
    String description,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
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
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(icon, color: Colors.blue.shade700, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar.large(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'SealZero',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
            ),
          ),
          child: Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context) {
    return Consumer<ImageProofViewModel>(
      builder: (context, viewModel, child) {
        final stats = viewModel.statistics;

        return Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.verified_user,
                title: 'Total Proofs',
                value: '${stats?.totalProofs ?? 0}',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle,
                title: 'Verified',
                value: '${stats?.verifiedProofs ?? 0}',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                icon: Icons.shield,
                title: 'Anonymous',
                value: '${stats?.anonymousProofs ?? 0}',
                color: Colors.purple,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.add_photo_alternate,
                title: 'Generate Proof',
                subtitle:
                    'Upload an original document to modify it - blur, redact, pixelate some parts of it and generate proof',
                color: Colors.indigo,
                onTap: () {
                  context.go('/generate');
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ActionCard(
                icon: Icons.verified,
                title: 'Verify Proof',
                subtitle: 'Validate image authenticity',
                color: Colors.teal,
                onTap: () {
                  context.go('/verify');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentProofs(BuildContext context) {
    return Consumer<ImageProofViewModel>(
      builder: (context, viewModel, child) {
        final proofs = viewModel.proofs.take(5).toList();

        if (proofs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: Column(
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No proofs yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Proofs',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...proofs.map((proof) => _ProofListItem(proof: proof)),
          ],
        );
      },
    );
  }

  Widget _buildUseCasesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy-Preserving Use Cases',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _UseCaseCard(
                icon: Icons.article,
                title: 'Journalism',
                description: 'Prove authenticity while protecting sources',
                example: 'Redacted memo with protected names',
                color: Colors.orange,
                onTap: () {
                  _openExternalUrl('https://youtube.com/shorts/WOWN9DGS9PM');
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _UseCaseCard(
                icon: Icons.warning_amber_rounded,
                title: 'Whistleblowing',
                description: 'Share evidence without revealing identity',
                example: 'Documents with sensitive details removed',
                color: Colors.red,
                onTap: () {
                  _openExternalUrl('https://youtu.be/rXXHFO7HnI8');
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _UseCaseCard(
                icon: Icons.gavel,
                title: 'GDPR Compliance',
                description: 'Publish and collaborate safely',
                example: 'Personal data blurred/redacted',
                color: Colors.blue,
                onTap: () {
                  _openExternalUrl(
                    'https://youtube.com/shorts/EsyXVCHSogw?feature=share',
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _UseCaseCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String example;
  final Color color;
  final VoidCallback? onTap;

  const _UseCaseCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.example,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(description, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Ex: $example',
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withAlpha(26),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProofListItem extends StatelessWidget {
  final dynamic proof;

  const _ProofListItem({required this.proof});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.image)),
        title: Text('Proof ${proof.id.substring(0, 8)}'),
        subtitle: Text('Created ${_formatDate(proof.createdAt)}'),
        trailing: _getStatusIcon(proof.verificationStatus),
        onTap: () {
          // Show proof details
        },
      ),
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

  Widget _getStatusIcon(dynamic status) {
    return Icon(Icons.check_circle, color: Colors.green);
  }
}

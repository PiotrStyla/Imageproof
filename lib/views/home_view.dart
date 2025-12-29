import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../core/viewmodels/image_proof_viewmodel.dart';
import '../widgets/charity_footer.dart';
import '../widgets/cookie_consent_banner.dart';

/// Modern home view with glassmorphism and real-time stats
class HomeView extends StatelessWidget {
  const HomeView({super.key});

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
              'Generate Proof',
              'Upload original + edited images, select transformations applied → Wait ~3 minutes → Download 2 files: proof.json + edited image',
              Icons.add_photo_alternate,
            ),
            const SizedBox(height: 12),
            _buildQuickStep(
              context,
              '2',
              'Share Both Files',
              'Send proof.json + edited_image.png to verifier (keep original private)',
              Icons.share,
            ),
            const SizedBox(height: 12),
            _buildQuickStep(
              context,
              '3',
              'Verify Authenticity',
              'Upload proof.json → Verify transformations → Upload edited_image.png → Confirm hash match',
              Icons.verified_user,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Transformations prove the exact operations applied (crop, rotate, etc.), not just that the image was edited',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
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
              colors: [
                Color(0xFF4F46E5),
                Color(0xFF7C3AED),
              ],
            ),
          ),
          child: Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
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
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.add_photo_alternate,
                title: 'Generate Proof',
                subtitle: 'Create ZK proof for edited image',
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _UseCaseCard(
                icon: Icons.article,
                title: 'Journalism',
                description: 'Prove document authenticity while protecting sources',
                example: 'Leaked memo with redacted names',
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _UseCaseCard(
                icon: Icons.warning_amber_rounded,
                title: 'Whistleblowing',
                description: 'Share evidence without revealing identity',
                example: 'Internal emails with masked metadata',
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _UseCaseCard(
                icon: Icons.gavel,
                title: 'GDPR Compliance',
                description: 'Publish research with privacy protection',
                example: 'Study photos with blurred faces',
                color: Colors.blue,
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

  const _UseCaseCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.example,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Ex: $example',
                style: TextStyle(
                  fontSize: 12,
                  color: color.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
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
      color: color.withOpacity(0.1),
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
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
        leading: const CircleAvatar(
          child: Icon(Icons.image),
        ),
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
    return Icon(
      Icons.check_circle,
      color: Colors.green,
    );
  }
}

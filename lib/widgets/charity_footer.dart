import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

/// Charity support banner displayed at the bottom of pages
class CharityFooter extends StatelessWidget {
  const CharityFooter({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1E293B),
                  const Color(0xFF0F172A),
                ]
              : [
                  const Color(0xFF6366F1),
                  const Color(0xFF4F46E5),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Charity Section
          Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '💝',
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Support a Good Cause',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'If you like or use this app, please consider supporting the Hospice Foundation in Cracow, Poland. They provide compassionate end-of-life care and support for patients and their families.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.95),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _launchUrl('https://fundacja-hospicjum.org/'),
                  icon: const Icon(Icons.favorite),
                  label: const Text('Donate Here'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your contribution makes a real difference in people\'s lives. Thank you for your generosity! 🙏',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Footer Links
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            runSpacing: 12,
            children: [
              _FooterLink(
                text: 'Privacy Policy',
                onTap: () => context.go('/privacy'),
              ),
              _FooterLink(
                text: 'Cookie Policy',
                onTap: () => context.go('/cookies'),
              ),
              _FooterLink(
                text: 'Terms of Service',
                onTap: () => context.go('/terms'),
              ),
              _FooterLink(
                text: 'GitHub',
                onTap: () => _launchUrl(
                  'https://github.com/PiotrStyla/Imageproof',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Copyright
          Text(
            '© ${DateTime.now().year} VIMz Private Proofs. Built with ❤️ using Flutter',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Powered by Zero-Knowledge Cryptography | Making the Internet More Trustworthy',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _FooterLink({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            decoration: TextDecoration.underline,
            decorationColor: Colors.white.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}

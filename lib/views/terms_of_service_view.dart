import 'package:flutter/material.dart';

class TermsOfServiceView extends StatelessWidget {
  const TermsOfServiceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terms of Service',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Last Updated: December 27, 2025',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 32),
              _buildSection(
                context,
                'Acceptance of Terms',
                'By accessing and using SealZero ("the Service"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the Service.',
              ),
              _buildSection(
                context,
                'Description of Service',
                'VIMz Private Proofs is a free, open-source web application that generates zero-knowledge cryptographic proofs for image authenticity. The Service:\n\n'
                    '• Runs entirely client-side in your browser\n'
                    '• Does not require user accounts or authentication\n'
                    '• Processes images locally without server uploads\n'
                    '• Is provided "as-is" for educational and research purposes',
              ),
              _buildSection(
                context,
                'Use License',
                'This project is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License (CC BY-NC-SA 4.0).\n\n'
                    'You are FREE to:\n'
                    '• Use for personal, academic, and research purposes\n'
                    '• Modify and adapt the source code\n'
                    '• Share and redistribute\n\n'
                    'Under these conditions:\n'
                    '• Attribution: Give appropriate credit\n'
                    '• NonCommercial: NO commercial use without permission\n'
                    '• ShareAlike: Distribute modifications under same license\n\n'
                    'See the LICENSE file in our GitHub repository for full details.',
              ),
              _buildSection(
                context,
                'Commercial Use Restrictions',
                'Commercial use is PROHIBITED without explicit written permission.\n\n'
                    'Commercial use includes:\n'
                    '• Using in commercial products or services\n'
                    '• Offering as a paid service\n'
                    '• Using to generate revenue directly or indirectly\n'
                    '• Integrating into commercial applications\n\n'
                    'For commercial licensing inquiries:\n'
                    'Email: p.styla@gmail.com\n'
                    'X (Twitter): @PiotrSty',
              ),
              _buildSection(
                context,
                'Acceptable Use',
                'You agree to use the Service only for lawful purposes and in accordance with these Terms. You agree NOT to:\n\n'
                    '• Use the Service for any illegal activities\n'
                    '• Attempt to reverse engineer or compromise security\n'
                    '• Use automated systems to access the Service excessively\n'
                    '• Interfere with or disrupt the Service\n'
                    '• Violate any applicable laws or regulations',
              ),
              _buildSection(
                context,
                'Disclaimer of Warranties',
                'THE SERVICE IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO:\n\n'
                    '• Warranties of merchantability\n'
                    '• Fitness for a particular purpose\n'
                    '• Non-infringement\n'
                    '• Accuracy, reliability, or completeness\n\n'
                    'We do not warrant that:\n'
                    '• The Service will be uninterrupted or error-free\n'
                    '• Defects will be corrected\n'
                    '• The Service is free of viruses or harmful components',
              ),
              _buildSection(
                context,
                'Limitation of Liability',
                'TO THE MAXIMUM EXTENT PERMITTED BY LAW, IN NO EVENT SHALL VIMZ PRIVATE PROOFS, ITS DEVELOPERS, OR CONTRIBUTORS BE LIABLE FOR:\n\n'
                    '• Any indirect, incidental, special, or consequential damages\n'
                    '• Loss of profits, data, or goodwill\n'
                    '• Service interruption\n'
                    '• Any damages arising from your use or inability to use the Service\n\n'
                    'This limitation applies even if we have been advised of the possibility of such damages.',
              ),
              _buildSection(
                context,
                'Cryptographic Security Disclaimer',
                'While we implement industry-standard cryptographic protocols:\n\n'
                    '• No cryptographic system is 100% secure\n'
                    '• Proofs depend on proper implementation and key management\n'
                    '• Users are responsible for validating proofs for their use case\n'
                    '• We make no guarantees about proof integrity in all scenarios\n\n'
                    'This is an academic/research implementation. For critical applications, conduct your own security audit.',
              ),
              _buildSection(
                context,
                'Research and Academic Use',
                'This Service implements concepts from the PETS 2025 research paper:\n'
                    '"VIMz: Private Proofs of Image Manipulation using Folding-based zkSNARKs"\n\n'
                    'If you use this Service in academic work, please cite the original paper.',
              ),
              _buildSection(
                context,
                'Third-Party Services',
                'The Service is hosted on GitHub Pages, which has its own Terms of Service. By using VIMz Private Proofs, you also agree to GitHub\'s terms:\n'
                    'https://docs.github.com/en/site-policy/github-terms/github-terms-of-service',
              ),
              _buildSection(
                context,
                'Privacy & GDPR Compliance',
                'Your use of the Service is also governed by our Privacy Policy. The Service processes all data locally in your browser and does not transmit personal information to our servers.\n\n'
                    'For EU Residents:\n'
                    '• We comply with GDPR (General Data Protection Regulation)\n'
                    '• All image processing is client-side (you are the data controller)\n'
                    '• No server-side storage of personal data\n'
                    '• Full details in our Privacy Policy\n\n'
                    'By using this Service, you acknowledge understanding that YOU are responsible for ensuring compliance with applicable data protection laws for any personal/sensitive data you process.',
              ),
              _buildSection(
                context,
                'Open Source',
                'This is an open-source project. You can:\n\n'
                    '• View the source code on GitHub\n'
                    '• Report issues and bugs\n'
                    '• Contribute improvements\n'
                    '• Fork and modify for your own use\n\n'
                    'GitHub Repository: https://github.com/PiotrStyla/Imageproof',
              ),
              _buildSection(
                context,
                'Modifications to Service',
                'We reserve the right to:\n\n'
                    '• Modify or discontinue the Service at any time\n'
                    '• Change features or functionality\n'
                    '• Update these Terms of Service\n\n'
                    'Continued use after changes constitutes acceptance of modified terms.',
              ),
              _buildSection(
                context,
                'Governing Law',
                'These Terms shall be governed by and construed in accordance with the laws of Poland, without regard to conflict of law provisions.',
              ),
              _buildSection(
                context,
                'Contact Information',
                'For questions about these Terms of Service:\n\n'
                    'Email: p.styla@gmail.com\n'
                    'X (Twitter): @PiotrSty\n'
                    'GitHub: https://github.com/PiotrStyla',
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}

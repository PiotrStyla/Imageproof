import 'package:flutter/material.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Privacy Policy',
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Last Updated: December 27, 2025',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
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
                  children: [
                    Icon(Icons.shield, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'GDPR Compliant: This application is designed with EU data protection regulations in mind.',
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
              const SizedBox(height: 32),
              _buildSection(
                context,
                'Introduction',
                'VIMz Private Proofs ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we handle your information when you use our web application.',
              ),
              _buildSection(
                context,
                'Data We Collect',
                'SealZero is a client-side application that runs entirely in your browser. We do NOT collect, store, or transmit any personal data to our servers.\n\n'
                    '• Images you upload are processed locally in your browser\n'
                    '• Generated proofs are stored locally using browser storage (IndexedDB via Hive)\n'
                    '• No user accounts or authentication required\n'
                    '• No tracking cookies or analytics',
              ),
              _buildSection(
                context,
                'Local Storage',
                'The application uses browser local storage (IndexedDB) to:\n\n'
                    '• Cache generated proofs for your convenience\n'
                    '• Store application preferences\n'
                    '• Improve performance through local caching\n\n'
                    'All data remains on your device and is never transmitted to external servers. You can clear this data at any time through your browser settings.',
              ),
              _buildSection(
                context,
                'Third-Party Services',
                'Our application is hosted on GitHub Pages. GitHub may collect technical information such as:\n\n'
                    '• IP addresses\n'
                    '• Browser type and version\n'
                    '• Referring pages\n\n'
                    'Please refer to GitHub\'s Privacy Policy for more information: https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement',
              ),
              _buildSection(
                context,
                'Image Processing',
                'All image processing and cryptographic operations occur entirely within your browser:\n\n'
                    '• Images are never uploaded to our servers\n'
                    '• Proofs are generated client-side using WebAssembly\n'
                    '• Original images remain private and under your control',
              ),
              _buildSection(
                context,
                'Cookies',
                'We use minimal essential cookies for application functionality. See our Cookie Policy for details.',
              ),
              _buildSection(
                context,
                'Legal Basis for Processing (GDPR Article 6)',
                'We process data based on:\n\n'
                    '• Consent (Article 6(1)(a)): By using the Service, you consent to local storage of proofs\n'
                    '• Legitimate Interests (Article 6(1)(f)): Client-side processing for application functionality\n\n'
                    'You can withdraw consent at any time by clearing browser data.',
              ),
              _buildSection(
                context,
                'Your GDPR Rights (EU Residents)',
                'Under the General Data Protection Regulation (GDPR), you have the following rights:\n\n'
                    '• Right of Access: View locally stored data via browser DevTools\n'
                    '• Right to Erasure ("Right to be Forgotten"): Clear browser storage anytime\n'
                    '• Right to Data Portability: Export proofs as JSON files\n'
                    '• Right to Object: Stop using the Service at any time\n'
                    '• Right to Restriction: Control what data you process locally\n\n'
                    'Since all processing is client-side, you have direct control over your data.',
              ),
              _buildSection(
                context,
                'Data Retention',
                'Locally Stored Data:\n'
                    '• Proofs are stored indefinitely in your browser until you delete them\n'
                    '• No server-side data retention (nothing to delete on our end)\n'
                    '• You control retention via browser settings\n\n'
                    'To delete all data: Clear browser storage (IndexedDB) for this website.',
              ),
              _buildSection(
                context,
                'International Data Transfers',
                'The application is hosted on GitHub Pages (US-based service). However:\n\n'
                    '• No personal data is transmitted to servers\n'
                    '• All image processing happens in your browser\n'
                    '• GitHub may log technical data (IP, browser) - see their privacy policy\n'
                    '• Standard Contractual Clauses (SCCs) apply via GitHub\'s terms',
              ),
              _buildSection(
                context,
                'Special Categories of Personal Data (GDPR Article 9)',
                'Images you process may contain special category data (faces, biometrics, health data, etc.). Important:\n\n'
                    '• We do NOT process this data on servers\n'
                    '• YOU are the data controller for images you process\n'
                    '• All processing is client-side under YOUR control\n'
                    '• Ensure you have legal basis to process sensitive data\n'
                    '• We do NOT access, store, or transmit your images',
              ),
              _buildSection(
                context,
                'Data Protection Officer',
                'For a service of this nature (no server-side data processing), a formal Data Protection Officer is not required. For privacy inquiries:\n\n'
                    'Email: p.styla@gmail.com\n'
                    'Subject: Privacy/GDPR Inquiry',
              ),
              _buildSection(
                context,
                'Your Rights',
                'Since we do not collect or store personal data on servers, traditional data rights (access, deletion, portability) are not applicable. However:\n\n'
                    '• You have full control over locally stored data\n'
                    '• You can clear browser storage at any time\n'
                    '• You can use the application anonymously',
              ),
              _buildSection(
                context,
                'Children\'s Privacy',
                'Our service is not directed to individuals under 13. We do not knowingly collect information from children.',
              ),
              _buildSection(
                context,
                'Changes to This Policy',
                'We may update this Privacy Policy occasionally. Changes will be posted on this page with an updated "Last Updated" date.',
              ),
              _buildSection(
                context,
                'Supervisory Authority (EU)',
                'If you are an EU resident and believe your data protection rights have been violated, you have the right to lodge a complaint with your local supervisory authority:\n\n'
                    'Find your authority: https://edpb.europa.eu/about-edpb/board/members_en',
              ),
              _buildSection(
                context,
                'Contact Us',
                'For privacy questions or to exercise your GDPR rights:\n\n'
                    'Email: p.styla@gmail.com\n'
                    'X (Twitter): @PiotrSty\n\n'
                    'We will respond to requests within 30 days as required by GDPR.',
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
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}

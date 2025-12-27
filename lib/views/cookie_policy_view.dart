import 'package:flutter/material.dart';

class CookiePolicyView extends StatelessWidget {
  const CookiePolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cookie Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cookie Policy',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Last Updated: December 26, 2025',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 32),
              _buildSection(
                context,
                'What Are Cookies',
                'Cookies are small text files stored on your device by your web browser. They help websites remember information about your visit.',
              ),
              _buildSection(
                context,
                'How We Use Cookies',
                'SealZero uses minimal cookies and browser storage technologies for essential functionality only. We do NOT use cookies for tracking or advertising.',
              ),
              _buildSection(
                context,
                'Types of Storage We Use',
                '**Essential Functional Storage:**\n\n'
                    '• **IndexedDB (via Hive)**: Stores generated proofs and application state locally in your browser\n'
                    '• **LocalStorage**: Stores user preferences and settings\n'
                    '• **SessionStorage**: Temporary data during your session\n\n'
                    'These are necessary for the application to function and cannot be disabled without breaking core features.',
              ),
              _buildSection(
                context,
                'Third-Party Cookies',
                'Since our application is hosted on GitHub Pages, GitHub may set its own cookies for:\n\n'
                    '• Performance monitoring\n'
                    '• Security\n'
                    '• Service optimization\n\n'
                    'We do not control these cookies. Please refer to GitHub\'s Cookie Policy for details.',
              ),
              _buildSection(
                context,
                'No Tracking or Analytics',
                'We explicitly do NOT use:\n\n'
                    '• Analytics cookies (e.g., Google Analytics)\n'
                    '• Advertising cookies\n'
                    '• Social media tracking pixels\n'
                    '• Cross-site tracking\n\n'
                    'Your privacy is paramount to us.',
              ),
              _buildSection(
                context,
                'Managing Browser Storage',
                'You can control and delete browser storage through your browser settings:\n\n'
                    '**Chrome/Edge:**\n'
                    'Settings → Privacy and Security → Clear browsing data → Cookies and site data\n\n'
                    '**Firefox:**\n'
                    'Settings → Privacy & Security → Cookies and Site Data → Clear Data\n\n'
                    '**Safari:**\n'
                    'Preferences → Privacy → Manage Website Data → Remove All\n\n'
                    'Note: Clearing storage will delete locally saved proofs and preferences.',
              ),
              _buildSection(
                context,
                'Data Retention',
                'Browser storage data persists until you:\n\n'
                    '• Manually clear browser storage\n'
                    '• Clear browser cache\n'
                    '• Uninstall your browser\n\n'
                    'We do not have access to or control over this data as it resides entirely on your device.',
              ),
              _buildSection(
                context,
                'Updates to This Policy',
                'We may update this Cookie Policy to reflect changes in technology or legal requirements. Check this page periodically for updates.',
              ),
              _buildSection(
                context,
                'Contact Us',
                'If you have questions about our use of cookies or browser storage:\n\n'
                    'Email: p.styla@gmail.com\n'
                    'X (Twitter): @PiotrSty',
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

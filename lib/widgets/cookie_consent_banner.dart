import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

/// Cookie consent banner displayed on first visit
class CookieConsentBanner extends StatefulWidget {
  const CookieConsentBanner({super.key});

  @override
  State<CookieConsentBanner> createState() => _CookieConsentBannerState();
}

class _CookieConsentBannerState extends State<CookieConsentBanner> {
  bool _showBanner = false;
  static const String _consentKey = 'cookie_consent_given';

  @override
  void initState() {
    super.initState();
    _checkConsent();
  }

  Future<void> _checkConsent() async {
    final prefs = await SharedPreferences.getInstance();
    final hasConsent = prefs.getBool(_consentKey) ?? false;
    if (!hasConsent) {
      setState(() {
        _showBanner = true;
      });
    }
  }

  Future<void> _acceptConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, true);
    setState(() {
      _showBanner = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showBanner) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Material(
        elevation: 8,
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: theme.primaryColor.withOpacity(0.3),
                width: 2,
              ),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                const Icon(
                  Icons.cookie,
                  size: 32,
                  color: Color(0xFF6366F1),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Privacy & Local Storage Notice',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This app stores generated proofs locally in your browser (IndexedDB). All image processing is client-side. No data sent to servers. No tracking. By continuing, you consent to local storage. See Privacy Policy for GDPR rights.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => context.go('/privacy'),
                      child: const Text('Privacy Policy'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        setState(() => _showBanner = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Essential storage is required for basic functionality. Some features may not work.'),
                            duration: Duration(seconds: 4),
                          ),
                        );
                      },
                      child: const Text('Reject (Limited Functionality)'),
                    ),
                    ElevatedButton(
                      onPressed: _acceptConsent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Accept & Continue'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

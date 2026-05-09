import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.surfaceDark,
              child: Icon(Icons.code_rounded, color: AppTheme.primaryAccent, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Mohd Sarfraz Saifi', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text(
                'B.Tech CSE (AI & ML)\nLovely Professional University',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16, height: 1.5)
            ),
            const SizedBox(height: 32),

            _buildListTile(Icons.email_outlined, 'Email', 'mohdsarfrazsaifi205@gmail.com', () => _launchURL('mailto:mohdsarfrazsaifi205@gmail.com')),
            _buildListTile(Icons.link_rounded, 'LinkedIn', 'Connect with me', () => _launchURL('https://www.linkedin.com/in/sarfrazcodes/')), // Update with your actual LinkedIn handle
            _buildListTile(Icons.privacy_tip_outlined, 'Privacy Policy', 'Data strictly stored securely', () {
              showAboutDialog(
                context: context,
                applicationName: 'Career Tracker',
                applicationVersion: '1.0.0',
                applicationLegalese: 'All tracking data is stored securely. AI processing is done via secure Google Gemini API calls without saving personal metrics on external third-party servers.',
              );
            }),

            const SizedBox(height: 40),
            const Text('© 2026 Personal Career Tracking App', style: TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, String sub, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryAccent.withAlpha(20)),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.secondaryAccent),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(sub, style: const TextStyle(color: AppTheme.textSecondary)),
        onTap: onTap,
      ),
    );
  }
}
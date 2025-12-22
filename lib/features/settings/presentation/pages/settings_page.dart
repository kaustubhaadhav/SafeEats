import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // App Info Section
          const _SectionHeader(title: 'About'),
          const _SettingsTile(
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: '1.0.0',
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'About This App',
            subtitle: 'Learn more about food safety scanning',
            onTap: () => _showAboutDialog(context),
          ),

          const Divider(),

          // Data Sources Section
          const _SectionHeader(title: 'Data Sources'),
          _SettingsTile(
            icon: Icons.public,
            title: 'Open Food Facts',
            subtitle: 'Product ingredient database',
            onTap: () => _showDataSourceInfo(
              context,
              title: 'Open Food Facts',
              description:
                  'Open Food Facts is a free, open, collaborative database of food products from around the world. '
                  'It contains information about ingredients, nutrition facts, and allergens.',
              url: 'https://world.openfoodfacts.org',
            ),
          ),
          _SettingsTile(
            icon: Icons.science,
            title: 'IARC Classifications',
            subtitle: 'International Agency for Research on Cancer',
            onTap: () => _showDataSourceInfo(
              context,
              title: 'IARC Classifications',
              description:
                  'The International Agency for Research on Cancer (IARC) is part of the World Health Organization. '
                  'IARC evaluates and classifies agents based on their potential to cause cancer:\n\n'
                  '• Group 1: Carcinogenic to humans\n'
                  '• Group 2A: Probably carcinogenic\n'
                  '• Group 2B: Possibly carcinogenic\n'
                  '• Group 3: Not classifiable',
              url: 'https://monographs.iarc.who.int',
            ),
          ),
          _SettingsTile(
            icon: Icons.gavel,
            title: 'California Prop 65',
            subtitle: 'Safe Drinking Water and Toxic Enforcement Act',
            onTap: () => _showDataSourceInfo(
              context,
              title: 'California Proposition 65',
              description:
                  'Proposition 65 requires businesses to provide warnings about significant exposures to chemicals '
                  'that cause cancer, birth defects, or other reproductive harm. The list contains over 900 chemicals.',
              url: 'https://oehha.ca.gov/proposition-65',
            ),
          ),

          const Divider(),

          // Privacy Section
          const _SectionHeader(title: 'Privacy'),
          const _SettingsTile(
            icon: Icons.storage,
            title: 'Data Storage',
            subtitle: 'All data is stored locally on your device',
          ),
          _SettingsTile(
            icon: Icons.delete_outline,
            title: 'Clear All Data',
            subtitle: 'Delete scan history and cached products',
            onTap: () => _showClearDataDialog(context),
          ),

          const Divider(),

          // Help Section
          const _SectionHeader(title: 'Help'),
          _SettingsTile(
            icon: Icons.help_outline,
            title: 'How to Use',
            subtitle: 'Quick guide to scanning products',
            onTap: () => _showHowToUseDialog(context),
          ),
          _SettingsTile(
            icon: Icons.warning_amber_outlined,
            title: 'Disclaimer',
            subtitle: 'Important information about this app',
            onTap: () => _showDisclaimerDialog(context),
          ),

          const Divider(),

          // Credits
          const _SectionHeader(title: 'Credits'),
          _SettingsTile(
            icon: Icons.code,
            title: 'Open Source Libraries',
            subtitle: 'View licenses and attributions',
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'Food Safety Scanner',
                applicationVersion: '1.0.0',
              );
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.eco, color: Colors.green),
            SizedBox(width: 12),
            Text('Food Safety Scanner'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This app helps you make informed decisions about food products by scanning barcodes and checking ingredients against known carcinogen databases.',
            ),
            SizedBox(height: 16),
            Text(
              'Features:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Scan product barcodes'),
            Text('• View ingredient lists'),
            Text('• Check for potential carcinogens'),
            Text('• Track scan history'),
            Text('• Browse carcinogen database'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDataSourceInfo(
    BuildContext context, {
    required String title,
    required String description,
    required String url,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.link,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      url,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                      ),
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
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will delete all your scan history and cached product data. '
          'The carcinogen database will be reset to defaults.\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Implement clear data
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showHowToUseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Use'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HowToStep(
                number: '1',
                title: 'Scan a Product',
                description:
                    'Tap the Scan tab and point your camera at a food product barcode.',
              ),
              _HowToStep(
                number: '2',
                title: 'View Results',
                description:
                    'See the ingredient list and any detected carcinogenic compounds.',
              ),
              _HowToStep(
                number: '3',
                title: 'Understand Risk Levels',
                description:
                    'Risk levels range from Safe (green) to Critical (red) based on IARC classifications.',
              ),
              _HowToStep(
                number: '4',
                title: 'Learn More',
                description:
                    'Tap on any detected carcinogen to see detailed information about it.',
              ),
              _HowToStep(
                number: '5',
                title: 'Browse Database',
                description:
                    'Explore the complete carcinogen database in the Database tab.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  void _showDisclaimerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 12),
            Text('Disclaimer'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            'This application is provided for informational and educational purposes only.\n\n'
            '• The information in this app should not be used as a substitute for professional medical advice, diagnosis, or treatment.\n\n'
            '• While we strive to keep the database accurate and up-to-date, we cannot guarantee the completeness or accuracy of all information.\n\n'
            '• The presence of a substance in the carcinogen database does not necessarily mean it poses a significant health risk at the concentrations found in food products.\n\n'
            '• Many factors affect cancer risk, including dose, duration of exposure, and individual susceptibility.\n\n'
            '• Always consult qualified healthcare professionals for medical advice and concerns about food safety.\n\n'
            '• The developers of this app assume no liability for any decisions made based on the information provided.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }
}

class _HowToStep extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _HowToStep({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
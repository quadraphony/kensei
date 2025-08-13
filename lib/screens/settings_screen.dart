import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../services/security_service.dart';
import '../models/vpn_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ProfileService _profileService = ProfileService();
  final SecurityService _securityService = SecurityService();
  final _subscriptionUrlController = TextEditingController();
  final _subscriptionNameController = TextEditingController();
  final _dnsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _securityService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSubscriptionSection(),
          const SizedBox(height: 24),
          _buildNetworkSection(),
          const SizedBox(height: 24),
          _buildSecuritySection(),
          const SizedBox(height: 24),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildSubscriptionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.subscriptions,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Subscriptions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Subscription>>(
              stream: _profileService.subscriptionsStream,
              builder: (context, snapshot) {
                final subscriptions = snapshot.data ?? [];
                
                return Column(
                  children: [
                    for (final subscription in subscriptions)
                      _buildSubscriptionTile(subscription),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _showAddSubscriptionDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Subscription'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionTile(Subscription subscription) {
    return ListTile(
      leading: const Icon(Icons.rss_feed),
      title: Text(subscription.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subscription.url),
          const SizedBox(height: 4),
          Text(
            'Last updated: ${_formatDate(subscription.lastUpdated)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            '${subscription.configs.length} configs',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) => _handleSubscriptionAction(value, subscription),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'update',
            child: Row(
              children: [
                Icon(Icons.refresh),
                SizedBox(width: 8),
                Text('Update'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.red),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.network_check,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Network',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<Map<String, dynamic>>(
              stream: _securityService.settingsStream,
              builder: (context, snapshot) {
                final settings = snapshot.data ?? {};
                
                return Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Auto Reconnect'),
                      subtitle: const Text('Automatically reconnect when connection is lost'),
                      value: settings['autoReconnect'] ?? true,
                      onChanged: (value) {
                        _securityService.setAutoReconnect(value);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('IPv6 Support'),
                      subtitle: const Text('Enable IPv6 traffic routing'),
                      value: settings['ipv6Support'] ?? false,
                      onChanged: (value) {
                        _securityService.setIpv6Support(value);
                      },
                    ),
                    ListTile(
                      title: const Text('DNS Servers'),
                      subtitle: Text((settings['dnsServers'] as List<String>?)?.join(', ') ?? '1.1.1.1, 8.8.8.8'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _showDnsSettingsDialog(settings['dnsServers'] as List<String>? ?? ['1.1.1.1', '8.8.8.8']);
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Security',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<Map<String, dynamic>>(
              stream: _securityService.settingsStream,
              builder: (context, snapshot) {
                final settings = snapshot.data ?? {};
                
                return Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Kill Switch'),
                      subtitle: const Text('Block internet when VPN disconnects'),
                      value: settings['killSwitch'] ?? true,
                      onChanged: (value) {
                        _securityService.setKillSwitch(value);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('DNS Leak Protection'),
                      subtitle: const Text('Prevent DNS queries from bypassing VPN'),
                      value: settings['dnsLeakProtection'] ?? true,
                      onChanged: (value) {
                        _securityService.setDnsLeakProtection(value);
                      },
                    ),
                    ListTile(
                      title: const Text('Encryption'),
                      subtitle: Text(settings['encryptionMethod'] ?? 'AES-256-GCM'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _showEncryptionSettingsDialog(settings['encryptionMethod'] ?? 'AES-256-GCM');
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'About',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Version'),
              subtitle: const Text('1.0.0'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showAboutDialog();
              },
            ),
            ListTile(
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showPrivacyPolicy();
              },
            ),
            ListTile(
              title: const Text('Terms of Service'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showTermsOfService();
              },
            ),
            ListTile(
              title: const Text('Open Source Licenses'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                showLicensePage(context: context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSubscriptionDialog() {
    _subscriptionNameController.clear();
    _subscriptionUrlController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _subscriptionNameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _subscriptionUrlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _subscriptionNameController.text.trim();
              final url = _subscriptionUrlController.text.trim();
              
              if (name.isNotEmpty && url.isNotEmpty) {
                Navigator.of(context).pop();
                await _profileService.addSubscription(name: name, url: url);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Subscription added')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDnsSettingsDialog(List<String> currentServers) {
    _dnsController.text = currentServers.join(', ');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('DNS Servers'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _dnsController,
              decoration: const InputDecoration(
                labelText: 'DNS Servers (comma separated)',
                border: OutlineInputBorder(),
                hintText: '1.1.1.1, 8.8.8.8, 9.9.9.9',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            const Text(
              'Popular DNS Servers:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildDnsChip('Cloudflare', '1.1.1.1, 1.0.0.1'),
                _buildDnsChip('Google', '8.8.8.8, 8.8.4.4'),
                _buildDnsChip('Quad9', '9.9.9.9, 149.112.112.112'),
                _buildDnsChip('OpenDNS', '208.67.222.222, 208.67.220.220'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final servers = _dnsController.text
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              
              if (servers.isNotEmpty) {
                Navigator.of(context).pop();
                await _securityService.setDnsServers(servers);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('DNS servers updated')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildDnsChip(String name, String servers) {
    return ActionChip(
      label: Text(name),
      onPressed: () {
        _dnsController.text = servers;
      },
    );
  }

  void _showEncryptionSettingsDialog(String currentMethod) {
    final methods = [
      'AES-256-GCM',
      'AES-256-CBC',
      'ChaCha20-Poly1305',
      'AES-128-GCM',
      'AES-128-CBC',
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Encryption Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: methods.map((method) {
            return RadioListTile<String>(
              title: Text(method),
              value: method,
              groupValue: currentMethod,
              onChanged: (value) async {
                if (value != null) {
                  Navigator.of(context).pop();
                  await _securityService.setEncryptionMethod(value);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Encryption method set to $value')),
                    );
                  }
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Kensei Tunnel Privacy Policy\n\n'
            '1. Data Collection\n'
            'We do not collect, store, or transmit any personal data or browsing activity. All VPN configurations and logs are stored locally on your device.\n\n'
            '2. No Logging Policy\n'
            'We maintain a strict no-logging policy. No connection logs, traffic data, or user activities are recorded or monitored.\n\n'
            '3. Local Storage\n'
            'All application data, including VPN profiles and settings, are stored locally on your device using encrypted storage.\n\n'
            '4. Third-Party Services\n'
            'The application may connect to subscription URLs provided by users. We are not responsible for the privacy practices of these third-party services.\n\n'
            '5. Security\n'
            'All sensitive data is encrypted using AES-256-GCM encryption before storage. Network traffic is protected according to the selected VPN protocol.\n\n'
            '6. Updates\n'
            'This privacy policy may be updated from time to time. Users will be notified of any significant changes.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'Kensei Tunnel Terms of Service\n\n'
            '1. Acceptance of Terms\n'
            'By using Kensei Tunnel, you agree to these terms of service and our privacy policy.\n\n'
            '2. Permitted Use\n'
            'This software is provided for legitimate privacy and security purposes. Users must comply with all applicable laws and regulations.\n\n'
            '3. Prohibited Activities\n'
            'Users may not use this software for illegal activities, including but not limited to:\n'
            '- Accessing copyrighted content without permission\n'
            '- Circumventing network security measures\n'
            '- Engaging in malicious activities\n\n'
            '4. Disclaimer\n'
            'This software is provided "as is" without warranties of any kind. We are not liable for any damages arising from its use.\n\n'
            '5. User Responsibility\n'
            'Users are responsible for:\n'
            '- Configuring the software properly\n'
            '- Ensuring compliance with local laws\n'
            '- Protecting their device and credentials\n\n'
            '6. Limitation of Liability\n'
            'In no event shall the developers be liable for any indirect, incidental, or consequential damages.\n\n'
            '7. Termination\n'
            'These terms remain in effect until terminated by either party.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleSubscriptionAction(String action, Subscription subscription) {
    switch (action) {
      case 'update':
        _updateSubscription(subscription);
        break;
      case 'delete':
        _deleteSubscription(subscription);
        break;
    }
  }

  void _updateSubscription(Subscription subscription) async {
    await _profileService.updateSubscription(subscription.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription updated')),
      );
    }
  }

  void _deleteSubscription(Subscription subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subscription'),
        content: Text('Are you sure you want to delete "${subscription.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _profileService.deleteSubscription(subscription.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Subscription deleted')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Kensei Tunnel',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.shield,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: [
        const Text(
          'A fully functional cross-platform VPN client powered by the Sing-box library, '
          'supporting all major VPN protocols with robust security and real-time monitoring.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Features:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const Text('• Multi-Protocol Support'),
        const Text('• Cross-Platform Compatibility'),
        const Text('• Real-time Monitoring'),
        const Text('• Automatic Reconnection'),
        const Text('• Profile Management'),
        const Text('• End-to-End Encryption'),
        const Text('• Smart Routing'),
        const Text('• DNS Configuration'),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _subscriptionUrlController.dispose();
    _subscriptionNameController.dispose();
    _dnsController.dispose();
    super.dispose();
  }
}


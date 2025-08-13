import 'package:flutter/material.dart';
import '../models/vpn_config.dart';
import '../services/profile_service.dart';
import 'add_profile_screen.dart';

class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  final ProfileService _profileService = ProfileService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshSubscriptions,
            tooltip: 'Refresh Subscriptions',
          ),
        ],
      ),
      body: StreamBuilder<List<VPNConfig>>(
        stream: _profileService.profilesStream,
        builder: (context, snapshot) {
          final profiles = snapshot.data ?? [];
          
          if (profiles.isEmpty) {
            return _buildEmptyState();
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              return _buildProfileCard(profile);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddProfileScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dns_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Profiles Available',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add a profile or refresh subscriptions to get started',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddProfileScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Profile'),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _refreshSubscriptions,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(VPNConfig profile) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getProtocolColor(profile.protocol).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getProtocolColor(profile.protocol).withOpacity(0.3),
            ),
          ),
          child: Icon(
            _getProtocolIcon(profile.protocol),
            color: _getProtocolColor(profile.protocol),
          ),
        ),
        title: Text(
          profile.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${profile.protocolDisplayName} • ${profile.displayAddress}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(profile.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, profile),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: Row(
                children: [
                  Icon(Icons.copy),
                  SizedBox(width: 8),
                  Text('Duplicate'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 8),
                  Text('Share'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'test_latency',
              child: Row(
                children: [
                  Icon(Icons.network_check),
                  SizedBox(width: 8),
                  Text('Test Latency'),
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
        onTap: () => _showProfileDetails(profile),
      ),
    );
  }

  Color _getProtocolColor(VPNProtocol protocol) {
    switch (protocol) {
      case VPNProtocol.vmess:
        return Colors.blue;
      case VPNProtocol.trojan:
        return Colors.red;
      case VPNProtocol.vless:
        return Colors.green;
      case VPNProtocol.shadowsocks:
        return Colors.purple;
      case VPNProtocol.wireguard:
        return Colors.orange;
      case VPNProtocol.tuic:
        return Colors.teal;
      case VPNProtocol.hysteria:
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  IconData _getProtocolIcon(VPNProtocol protocol) {
    switch (protocol) {
      case VPNProtocol.vmess:
        return Icons.cloud;
      case VPNProtocol.trojan:
        return Icons.security;
      case VPNProtocol.vless:
        return Icons.flash_on;
      case VPNProtocol.shadowsocks:
        return Icons.visibility_off;
      case VPNProtocol.wireguard:
        return Icons.vpn_key;
      case VPNProtocol.tuic:
        return Icons.speed;
      case VPNProtocol.hysteria:
        return Icons.rocket_launch;
      default:
        return Icons.dns;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleMenuAction(String action, VPNConfig profile) {
    switch (action) {
      case 'edit':
        _editProfile(profile);
        break;
      case 'duplicate':
        _duplicateProfile(profile);
        break;
      case 'share':
        _shareProfile(profile);
        break;
      case 'test_latency':
        _testLatency(profile);
        break;
      case 'delete':
        _deleteProfile(profile);
        break;
    }
  }

  void _editProfile(VPNConfig profile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddProfileScreen(editingProfile: profile),
      ),
    );
  }

  void _duplicateProfile(VPNConfig profile) async {
    await _profileService.addProfile(
      name: '${profile.name} (Copy)',
      protocol: profile.protocol,
      server: profile.server,
      port: profile.port,
      config: Map<String, dynamic>.from(profile.config),
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile duplicated')),
      );
    }
  }

  void _deleteProfile(VPNConfig profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text('Are you sure you want to delete "${profile.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _profileService.deleteProfile(profile.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile deleted')),
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

  void _showProfileDetails(VPNConfig profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getProtocolColor(profile.protocol).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getProtocolColor(profile.protocol).withOpacity(0.3),
                      ),
                    ),
                    child: Icon(
                      _getProtocolIcon(profile.protocol),
                      color: _getProtocolColor(profile.protocol),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${profile.protocolDisplayName} • ${profile.displayAddress}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection('Basic Information', [
                        _buildDetailRow('Name', profile.name),
                        _buildDetailRow('Protocol', profile.protocolDisplayName),
                        _buildDetailRow('Server', profile.server),
                        _buildDetailRow('Port', profile.port.toString()),
                        _buildDetailRow('Created', _formatDate(profile.createdAt)),
                        if (profile.lastConnected != null)
                          _buildDetailRow('Last Connected', _formatDate(profile.lastConnected!)),
                      ]),
                      const SizedBox(height: 16),
                      _buildDetailSection('Configuration', [
                        for (final entry in profile.config.entries)
                          _buildDetailRow(entry.key, entry.value.toString()),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshSubscriptions() async {
    for (final subscription in _profileService.subscriptions) {
      await _profileService.updateSubscription(subscription.id);
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscriptions refreshed')),
      );
    }
  }
}



  void _shareProfile(VPNConfig profile) {
    // For now, we'll just show a snackbar with the profile's JSON string.
    // In a real app, you'd generate a shareable link or QR code.
    final profileJson = profile.toJson();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share this profile: ${profileJson.toString()}')),
    );
  }




  void _testLatency(VPNConfig profile) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Testing latency for ${profile.name}...")),
    );
    final latency = await _profileService.testProfileLatency(profile);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Latency for ${profile.name}: ${latency}ms")),
      );
    }
  }



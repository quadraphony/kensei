import 'package:flutter/material.dart';
import '../models/vpn_config.dart' as models;
import '../services/vpn_service.dart';
import '../services/profile_service.dart';
import '../widgets/connection_button.dart';
import '../widgets/connection_stats.dart';
import '../widgets/server_info_card.dart';
import 'profiles_screen.dart';
import 'logs_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VPNService _vpnService = VPNService();
  final ProfileService _profileService = ProfileService();
  
  VPNConnectionState _connectionState = VPNConnectionState.disconnected;
  models.VPNConfig? _selectedProfile;
  models.ConnectionStats? _currentStats;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    // Listen to VPN state changes
    _vpnService.connectionStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _connectionState = state;
        });
      }
    });

    // Listen to stats updates
    _vpnService.statsStream.listen((stats) {
      if (mounted) {
        setState(() {
          _currentStats = stats;
        });
      }
    });

    // Set default profile if available
    _profileService.profilesStream.listen((profiles) {
      if (mounted && _selectedProfile == null && profiles.isNotEmpty) {
        setState(() {
          _selectedProfile = profiles.first;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(),
          const ProfilesScreen(),
          const LogsScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.dns_outlined),
            selectedIcon: Icon(Icons.dns),
            label: 'Profiles',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'Logs',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text('Kensei Tunnel'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshProfiles,
              tooltip: 'Refresh Profiles',
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Connection Button
              ConnectionButton(
                connectionState: _connectionState,
                onPressed: _toggleConnection,
              ),
              
              const SizedBox(height: 24),
              
              // Server Selection
              _buildServerSelection(),
              
              const SizedBox(height: 24),
              
              // Connection Stats
              if (_connectionState == VPNConnectionState.connected && _currentStats != null)
                ConnectionStats(stats: _currentStats!),
              
              const SizedBox(height: 24),
              
              // Server Info
              if (_selectedProfile != null)
                ServerInfoCard(profile: _selectedProfile!),
              
              const SizedBox(height: 24),
              
              // Quick Actions
              _buildQuickActions(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildServerSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.dns,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Server Selection',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<models.VPNConfig>>(
              stream: _profileService.profilesStream,
              builder: (context, snapshot) {
                final profiles = snapshot.data ?? [];
                
                if (profiles.isEmpty) {
                  return Column(
                    children: [
                      const Text('No profiles available'),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedIndex = 1; // Switch to profiles tab
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Profile'),
                      ),
                    ],
                  );
                }
                
                return DropdownButtonFormField<models.VPNConfig>(
                  value: _selectedProfile,
                  decoration: const InputDecoration(
                    labelText: 'Select Server',
                    border: OutlineInputBorder(),
                  ),
                  items: profiles.map((profile) {
                    return DropdownMenuItem<models.VPNConfig>(
                      value: profile,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getProtocolColor(profile.protocol),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  profile.name,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '${profile.protocolDisplayName} • ${profile.displayAddress}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (profile) {
                    setState(() {
                      _selectedProfile = profile;
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flash_on,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _refreshProfiles,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Profile'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 2;
                      });
                    },
                    icon: const Icon(Icons.article),
                    label: const Text('View Logs'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 3;
                      });
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Settings'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getProtocolColor(models.VPNProtocol protocol) {
    switch (protocol) {
      case models.VPNProtocol.vmess:
        return Colors.blue;
      case models.VPNProtocol.trojan:
        return Colors.red;
      case models.VPNProtocol.vless:
        return Colors.green;
      case models.VPNProtocol.shadowsocks:
        return Colors.purple;
      case models.VPNProtocol.wireguard:
        return Colors.orange;
      case models.VPNProtocol.tuic:
        return Colors.teal;
      case models.VPNProtocol.hysteria:
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  Future<void> _toggleConnection() async {
    if (_selectedProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a profile first')),
      );
      return;
    }

    if (_connectionState == VPNConnectionState.connected ||
        _connectionState == VPNConnectionState.connecting) {
      await _vpnService.disconnect();
    } else {
      await _vpnService.connect(_selectedProfile!);
    }
  }

  Future<void> _refreshProfiles() async {
    // Refresh all subscriptions
    for (final subscription in _profileService.subscriptions) {
      await _profileService.updateSubscription(subscription.id);
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profiles refreshed')),
      );
    }
  }

  @override
  void dispose() {
    _vpnService.dispose();
    super.dispose();
  }
}


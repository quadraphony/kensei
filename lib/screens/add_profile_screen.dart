import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vpn_config.dart';
import '../services/profile_service.dart';

class AddProfileScreen extends StatefulWidget {
  final VPNConfig? editingProfile;

  const AddProfileScreen({super.key, this.editingProfile});

  @override
  State<AddProfileScreen> createState() => _AddProfileScreenState();
}

class _AddProfileScreenState extends State<AddProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final _formKey = GlobalKey<FormState>();
  
  VPNProtocol _selectedProtocol = VPNProtocol.vmess;
  final _nameController = TextEditingController();
  final _serverController = TextEditingController();
  final _portController = TextEditingController();
  
  // VMess fields
  final _vmessUuidController = TextEditingController();
  final _vmessSecurityController = TextEditingController(text: 'auto');
  final _vmessAlterIdController = TextEditingController(text: '0');
  final _vmessNetworkController = TextEditingController(text: 'tcp');
  final _vmessPathController = TextEditingController();
  final _vmessHostController = TextEditingController();
  final _vmessSniController = TextEditingController();
  bool _vmessTls = false;
  
  // Trojan fields
  final _trojanPasswordController = TextEditingController();
  final _trojanSniController = TextEditingController();
  final _trojanNetworkController = TextEditingController(text: 'tcp');
  final _trojanPathController = TextEditingController();
  final _trojanHostController = TextEditingController();
  
  // VLESS fields
  final _vlessUuidController = TextEditingController();
  final _vlessFlowController = TextEditingController();
  final _vlessSecurityController = TextEditingController(text: 'none');
  final _vlessSniController = TextEditingController();
  final _vlessNetworkController = TextEditingController(text: 'tcp');
  final _vlessPathController = TextEditingController();
  final _vlessHostController = TextEditingController();
  
  // Shadowsocks fields
  final _ssMethodController = TextEditingController(text: 'aes-256-gcm');
  final _ssPasswordController = TextEditingController();
  final _ssPluginController = TextEditingController();
  final _ssPluginOptsController = TextEditingController();
  
  // WireGuard fields
  final _wgPrivateKeyController = TextEditingController();
  final _wgPeerPublicKeyController = TextEditingController();
  final _wgLocalAddressController = TextEditingController(text: '10.0.0.2/32');
  final _wgMtuController = TextEditingController(text: '1420');
  
  // TUIC fields
  final _tuicUuidController = TextEditingController();
  final _tuicPasswordController = TextEditingController();
  final _tuicAlpnController = TextEditingController(text: 'h3');
  final _tuicSniController = TextEditingController();
  
  // Hysteria fields
  final _hysteriaAuthController = TextEditingController();
  final _hysteriaAlpnController = TextEditingController(text: 'h3');
  final _hysteriaSniController = TextEditingController();
  final _hysteriaObfsController = TextEditingController();

  bool _killSwitchEnabled = false;
  bool _alwaysOnEnabled = false;
  bool _splitTunnelingEnabled = false;
  List<String> _splitTunnelingApps = [];

  @override
  void initState() {
    super.initState();
    if (widget.editingProfile != null) {
      _loadProfileData(widget.editingProfile!);
    }
  }

  void _loadProfileData(VPNConfig profile) {
    _selectedProtocol = profile.protocol;
    _nameController.text = profile.name;
    _serverController.text = profile.server;
    _portController.text = profile.port.toString();
    
    switch (profile.protocol) {
      case VPNProtocol.vmess:
        final config = VMessConfig.fromJson(profile.config);
        _vmessUuidController.text = config.uuid;
        _vmessSecurityController.text = config.security;
        _vmessAlterIdController.text = config.alterId.toString();
        _vmessNetworkController.text = config.network;
        _vmessPathController.text = config.path;
        _vmessHostController.text = config.host;
        _vmessSniController.text = config.sni;
        _vmessTls = config.tls;
        break;
      case VPNProtocol.trojan:
        final config = TrojanConfig.fromJson(profile.config);
        _trojanPasswordController.text = config.password;
        _trojanSniController.text = config.sni;
        _trojanNetworkController.text = config.network;
        _trojanPathController.text = config.path;
        _trojanHostController.text = config.host;
        break;
      case VPNProtocol.vless:
        final config = VLESSConfig.fromJson(profile.config);
        _vlessUuidController.text = config.uuid;
        _vlessFlowController.text = config.flow;
        _vlessSecurityController.text = config.security;
        _vlessSniController.text = config.sni;
        _vlessNetworkController.text = config.network;
        _vlessPathController.text = config.path;
        _vlessHostController.text = config.host;
        break;
      case VPNProtocol.shadowsocks:
        final config = ShadowsocksConfig.fromJson(profile.config);
        _ssMethodController.text = config.method;
        _ssPasswordController.text = config.password;
        _ssPluginController.text = config.plugin;
        _ssPluginOptsController.text = config.pluginOpts;
        break;
      case VPNProtocol.wireguard:
        final config = WireGuardConfig.fromJson(profile.config);
        _wgPrivateKeyController.text = config.privateKey;
        _wgPeerPublicKeyController.text = config.peerPublicKey;
        _wgLocalAddressController.text = config.localAddress.join(', ');
        _wgMtuController.text = config.mtu.toString();
        break;
      case VPNProtocol.tuic:
        final config = TUICConfig.fromJson(profile.config);
        _tuicUuidController.text = config.uuid;
        _tuicPasswordController.text = config.password;
        _tuicAlpnController.text = config.alpn;
        _tuicSniController.text = config.sni;
        break;
      case VPNProtocol.hysteria:
        final config = HysteriaConfig.fromJson(profile.config);
        _hysteriaAuthController.text = config.auth;
        _hysteriaAlpnController.text = config.alpn;
        _hysteriaSniController.text = config.sni;
        _hysteriaObfsController.text = config.obfs;
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editingProfile != null ? 'Edit Profile' : 'Add Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.content_paste),
            onPressed: _pasteFromClipboard,
            tooltip: 'Paste from Clipboard',
          ),
          TextButton(
            onPressed: _saveProfile,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Profile Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a profile name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<VPNProtocol>(
                      value: _selectedProtocol,
                      decoration: const InputDecoration(
                        labelText: 'Protocol',
                        border: OutlineInputBorder(),
                      ),
                      items: VPNProtocol.values.map((protocol) {
                        return DropdownMenuItem(
                          value: protocol,
                          child: Text(_getProtocolDisplayName(protocol)),
                        );
                      }).toList(),
                      onChanged: (protocol) {
                        setState(() {
                          _selectedProtocol = protocol!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _serverController,
                            decoration: const InputDecoration(
                              labelText: 'Server Address',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter server address';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _portController,
                            decoration: const InputDecoration(
                              labelText: 'Port',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter port';
                              }
                              final port = int.tryParse(value);
                              if (port == null || port < 1 || port > 65535) {
                                return 'Invalid port';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Protocol-specific configuration
            _buildProtocolConfiguration(),

            const SizedBox(height: 16),

            // Advanced Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Advanced Settings',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SwitchListTile(
                      title: const Text('Kill Switch'),
                      subtitle: const Text('Block all internet traffic if VPN connection drops.'),
                      value: _killSwitchEnabled,
                      onChanged: (value) {
                        setState(() {
                          _killSwitchEnabled = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text("Always-on VPN"),
                      subtitle: const Text("Automatically reconnect VPN if disconnected."),
                      value: _alwaysOnEnabled,
                      onChanged: (value) {
                        setState(() {
                          _alwaysOnEnabled = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text("Split Tunneling"),
                      subtitle: const Text("Select which apps use the VPN."),
                      value: _splitTunnelingEnabled,
                      onChanged: (value) {
                        setState(() {
                          _splitTunnelingEnabled = value;
                        });
                      },
                    ),
                    if (_splitTunnelingEnabled)
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                        child: TextFormField(
                          controller: TextEditingController(text: _splitTunnelingApps.join(", ")),
                          decoration: const InputDecoration(
                            labelText: "Apps to bypass VPN (comma-separated)",
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _splitTunnelingApps = value.split(", ").map((e) => e.trim()).toList();
                            });
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocolConfiguration() {
    switch (_selectedProtocol) {
      case VPNProtocol.vmess:
        return _buildVMessConfiguration();
      case VPNProtocol.trojan:
        return _buildTrojanConfiguration();
      case VPNProtocol.vless:
        return _buildVLESSConfiguration();
      case VPNProtocol.shadowsocks:
        return _buildShadowsocksConfiguration();
      case VPNProtocol.wireguard:
        return _buildWireGuardConfiguration();
      case VPNProtocol.tuic:
        return _buildTUICConfiguration();
      case VPNProtocol.hysteria:
        return _buildHysteriaConfiguration();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildVMessConfiguration() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VMess Configuration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vmessUuidController,
              decoration: const InputDecoration(
                labelText: 'UUID',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter UUID';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _vmessSecurityController,
                    decoration: const InputDecoration(
                      labelText: 'Security',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _vmessAlterIdController,
                    decoration: const InputDecoration(
                      labelText: 'Alter ID',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vmessNetworkController,
              decoration: const InputDecoration(
                labelText: 'Network (tcp/ws/grpc)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vmessPathController,
              decoration: const InputDecoration(
                labelText: 'Path (for WebSocket)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vmessHostController,
              decoration: const InputDecoration(
                labelText: 'Host',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _vmessSniController,
                    decoration: const InputDecoration(
                      labelText: 'SNI',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _vmessTls,
                      onChanged: (value) {
                        setState(() {
                          _vmessTls = value ?? false;
                        });
                      },
                    ),
                    const Text('Enable TLS'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrojanConfiguration() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trojan Configuration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _trojanPasswordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter password';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _trojanSniController,
              decoration: const InputDecoration(
                labelText: 'SNI',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _trojanNetworkController,
              decoration: const InputDecoration(
                labelText: 'Network (tcp/ws)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _trojanPathController,
              decoration: const InputDecoration(
                labelText: 'Path (for WebSocket)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _trojanHostController,
              decoration: const InputDecoration(
                labelText: 'Host',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVLESSConfiguration() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VLESS Configuration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vlessUuidController,
              decoration: const InputDecoration(
                labelText: 'UUID',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter UUID';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _vlessFlowController,
                    decoration: const InputDecoration(
                      labelText: 'Flow',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _vlessSecurityController,
                    decoration: const InputDecoration(
                      labelText: 'Security',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vlessSniController,
              decoration: const InputDecoration(
                labelText: 'SNI',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vlessNetworkController,
              decoration: const InputDecoration(
                labelText: 'Network (tcp/ws/grpc)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vlessPathController,
              decoration: const InputDecoration(
                labelText: 'Path (for WebSocket)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vlessHostController,
              decoration: const InputDecoration(
                labelText: 'Host',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShadowsocksConfiguration() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shadowsocks Configuration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ssMethodController,
                    decoration: const InputDecoration(
                      labelText: 'Method',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _ssPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter password';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ssPluginController,
              decoration: const InputDecoration(
                labelText: 'Plugin (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ssPluginOptsController,
              decoration: const InputDecoration(
                labelText: 'Plugin Options (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWireGuardConfiguration() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WireGuard Configuration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _wgPrivateKeyController,
              decoration: const InputDecoration(
                labelText: 'Private Key',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter private key';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _wgPeerPublicKeyController,
              decoration: const InputDecoration(
                labelText: 'Peer Public Key',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter peer public key';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _wgLocalAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Local Address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _wgMtuController,
                    decoration: const InputDecoration(
                      labelText: 'MTU',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTUICConfiguration() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TUIC Configuration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tuicUuidController,
              decoration: const InputDecoration(
                labelText: 'UUID',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter UUID';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tuicPasswordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter password';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tuicAlpnController,
                    decoration: const InputDecoration(
                      labelText: 'ALPN',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _tuicSniController,
                    decoration: const InputDecoration(
                      labelText: 'SNI',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHysteriaConfiguration() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hysteria Configuration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hysteriaAuthController,
              decoration: const InputDecoration(
                labelText: 'Auth String',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter auth string';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _hysteriaAlpnController,
                    decoration: const InputDecoration(
                      labelText: 'ALPN',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _hysteriaSniController,
                    decoration: const InputDecoration(
                      labelText: 'SNI',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _hysteriaObfsController,
              decoration: const InputDecoration(
                labelText: 'Obfuscation (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getProtocolDisplayName(VPNProtocol protocol) {
    switch (protocol) {
      case VPNProtocol.vmess:
        return 'VMess';
      case VPNProtocol.trojan:
        return 'Trojan';
      case VPNProtocol.vless:
        return 'VLESS';
      case VPNProtocol.shadowsocks:
        return 'Shadowsocks';
      case VPNProtocol.wireguard:
        return 'WireGuard';
      case VPNProtocol.tuic:
        return 'TUIC';
      case VPNProtocol.hysteria:
        return 'Hysteria';
      case VPNProtocol.socks:
        return 'SOCKS';
      case VPNProtocol.http:
        return 'HTTP';
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text;
    final server = _serverController.text;
    final port = int.parse(_portController.text);

    try {
      String profileId;
      
      switch (_selectedProtocol) {
        case VPNProtocol.vmess:
          profileId = await _profileService.createVMessProfile(
            name: name,
            server: server,
            port: port,
            uuid: _vmessUuidController.text,
            security: _vmessSecurityController.text,
            alterId: int.parse(_vmessAlterIdController.text),
            network: _vmessNetworkController.text,
            path: _vmessPathController.text,
            host: _vmessHostController.text,
            tls: _vmessTls,
            sni: _vmessSniController.text,
            killSwitchEnabled: _killSwitchEnabled,
            alwaysOnEnabled: _alwaysOnEnabled,
            splitTunnelingEnabled: _splitTunnelingEnabled,
            splitTunnelingApps: _splitTunnelingApps,
          );
          break;
        case VPNProtocol.trojan:
          profileId = await _profileService.createTrojanProfile(
            name: name,
            server: server,
            port: port,
            password: _trojanPasswordController.text,
            sni: _trojanSniController.text,
            network: _trojanNetworkController.text,
            path: _trojanPathController.text,
            host: _trojanHostController.text,
            killSwitchEnabled: _killSwitchEnabled,
            alwaysOnEnabled: _alwaysOnEnabled,
            splitTunnelingEnabled: _splitTunnelingEnabled,
            splitTunnelingApps: _splitTunnelingApps,
          );
          break;
        case VPNProtocol.vless:
          profileId = await _profileService.createVLESSProfile(
            name: name,
            server: server,
            port: port,
            uuid: _vlessUuidController.text,
            flow: _vlessFlowController.text,
            security: _vlessSecurityController.text,
            sni: _vlessSniController.text,
            network: _vlessNetworkController.text,
            path: _vlessPathController.text,
            host: _vlessHostController.text,
            killSwitchEnabled: _killSwitchEnabled,
            alwaysOnEnabled: _alwaysOnEnabled,
            splitTunnelingEnabled: _splitTunnelingEnabled,
            splitTunnelingApps: _splitTunnelingApps,
          );
          break;
        case VPNProtocol.shadowsocks:
          profileId = await _profileService.createShadowsocksProfile(
            name: name,
            server: server,
            port: port,
            method: _ssMethodController.text,
            password: _ssPasswordController.text,
            plugin: _ssPluginController.text,
            pluginOpts: _ssPluginOptsController.text,
            killSwitchEnabled: _killSwitchEnabled,
            alwaysOnEnabled: _alwaysOnEnabled,
            splitTunnelingEnabled: _splitTunnelingEnabled,
            splitTunnelingApps: _splitTunnelingApps,
          );
          break;
        case VPNProtocol.wireguard:
          profileId = await _profileService.createWireGuardProfile(
            name: name,
            server: server,
            port: port,
            privateKey: _wgPrivateKeyController.text,
            peerPublicKey: _wgPeerPublicKeyController.text,
            localAddress: _wgLocalAddressController.text.split(',').map((e) => e.trim()).toList(),
            mtu: int.parse(_wgMtuController.text),
            killSwitchEnabled: _killSwitchEnabled,
            alwaysOnEnabled: _alwaysOnEnabled,
            splitTunnelingEnabled: _splitTunnelingEnabled,
            splitTunnelingApps: _splitTunnelingApps,
          );
          break;
        case VPNProtocol.tuic:
          profileId = await _profileService.createTUICProfile(
            name: name,
            server: server,
            port: port,
            uuid: _tuicUuidController.text,
            password: _tuicPasswordController.text,
            alpn: _tuicAlpnController.text,
            sni: _tuicSniController.text,
            killSwitchEnabled: _killSwitchEnabled,
            alwaysOnEnabled: _alwaysOnEnabled,
            splitTunnelingEnabled: _splitTunnelingEnabled,
            splitTunnelingApps: _splitTunnelingApps,
          );
          break;
        case VPNProtocol.hysteria:
          profileId = await _profileService.createHysteriaProfile(
            name: name,
            server: server,
            port: port,
            auth: _hysteriaAuthController.text,
            alpn: _hysteriaAlpnController.text,
            sni: _hysteriaSniController.text,
            obfs: _hysteriaObfsController.text,
            killSwitchEnabled: _killSwitchEnabled,
            alwaysOnEnabled: _alwaysOnEnabled,
            splitTunnelingEnabled: _splitTunnelingEnabled,
            splitTunnelingApps: _splitTunnelingApps,
          );
          break;
        default:
          throw UnsupportedError('Protocol not supported');
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.editingProfile != null 
                ? 'Profile updated successfully' 
                : 'Profile created successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serverController.dispose();
    _portController.dispose();
    _vmessUuidController.dispose();
    _vmessSecurityController.dispose();
    _vmessAlterIdController.dispose();
    _vmessNetworkController.dispose();
    _vmessPathController.dispose();
    _vmessHostController.dispose();
    _vmessSniController.dispose();
    _trojanPasswordController.dispose();
    _trojanSniController.dispose();
    _trojanNetworkController.dispose();
    _trojanPathController.dispose();
    _trojanHostController.dispose();
    _vlessUuidController.dispose();
    _vlessFlowController.dispose();
    _vlessSecurityController.dispose();
    _vlessSniController.dispose();
    _vlessNetworkController.dispose();
    _vlessPathController.dispose();
    _vlessHostController.dispose();
    _ssMethodController.dispose();
    _ssPasswordController.dispose();
    _ssPluginController.dispose();
    _ssPluginOptsController.dispose();
    _wgPrivateKeyController.dispose();
    _wgPeerPublicKeyController.dispose();
    _wgLocalAddressController.dispose();
    _wgMtuController.dispose();
    _tuicUuidController.dispose();
    _tuicPasswordController.dispose();
    _tuicAlpnController.dispose();
    _tuicSniController.dispose();
    _hysteriaAuthController.dispose();
    _hysteriaAlpnController.dispose();
    _hysteriaSniController.dispose();
    _hysteriaObfsController.dispose();
    super.dispose();
  }
}



  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      final pastedText = clipboardData.text!;
      final parsedConfig = _profileService.parseConfigString(pastedText);
      if (parsedConfig != null) {
        setState(() {
          _selectedProtocol = parsedConfig.protocol;
          _nameController.text = parsedConfig.name;
          _serverController.text = parsedConfig.server;
          _portController.text = parsedConfig.port.toString();
          // Populate other fields based on protocol
          switch (parsedConfig.protocol) {
            case VPNProtocol.vmess:
              final config = VMessConfig.fromJson(parsedConfig.config);
              _vmessUuidController.text = config.uuid;
              _vmessSecurityController.text = config.security;
              _vmessAlterIdController.text = config.alterId.toString();
              _vmessNetworkController.text = config.network;
              _vmessPathController.text = config.path;
              _vmessHostController.text = config.host;
              _vmessSniController.text = config.sni;
              _vmessTls = config.tls;
              break;
            case VPNProtocol.trojan:
              final config = TrojanConfig.fromJson(parsedConfig.config);
              _trojanPasswordController.text = config.password;
              _trojanSniController.text = config.sni;
              _trojanNetworkController.text = config.network;
              _trojanPathController.text = config.path;
              _trojanHostController.text = config.host;
              break;
            case VPNProtocol.vless:
              final config = VLESSConfig.fromJson(parsedConfig.config);
              _vlessUuidController.text = config.uuid;
              _vlessFlowController.text = config.flow;
              _vlessSecurityController.text = config.security;
              _vlessSniController.text = config.sni;
              _vlessNetworkController.text = config.network;
              _vlessPathController.text = config.path;
              _vlessHostController.text = config.host;
              break;
            case VPNProtocol.shadowsocks:
              final config = ShadowsocksConfig.fromJson(parsedConfig.config);
              _ssMethodController.text = config.method;
              _ssPasswordController.text = config.password;
              _ssPluginController.text = config.plugin;
              _ssPluginOptsController.text = config.pluginOpts;
              break;
            case VPNProtocol.wireguard:
              final config = WireGuardConfig.fromJson(parsedConfig.config);
              _wgPrivateKeyController.text = config.privateKey;
              _wgPeerPublicKeyController.text = config.peerPublicKey;
              _wgLocalAddressController.text = config.localAddress.join(", ");
              _wgMtuController.text = config.mtu.toString();
              break;
            case VPNProtocol.tuic:
              final config = TUICConfig.fromJson(parsedConfig.config);
              _tuicUuidController.text = config.uuid;
              _tuicPasswordController.text = config.password;
              _tuicAlpnController.text = config.alpn;
              _tuicSniController.text = config.sni;
              break;
            case VPNProtocol.hysteria:
              final config = HysteriaConfig.fromJson(parsedConfig.config);
              _hysteriaAuthController.text = config.auth;
              _hysteriaAlpnController.text = config.alpn;
              _hysteriaSniController.text = config.sni;
              _hysteriaObfsController.text = config.obfs;
              break;
            default:
              break;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile parsed and loaded!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not parse clipboard content as a VPN profile.")),
        );
      }
    }
  }

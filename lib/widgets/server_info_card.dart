import 'package:flutter/material.dart';
import '../models/vpn_config.dart';

class ServerInfoCard extends StatelessWidget {
  final VPNConfig profile;

  const ServerInfoCard({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                Text(
                  'Server Information',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              'Name',
              profile.name,
              Icons.label,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              'Protocol',
              profile.protocolDisplayName,
              Icons.security,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              'Server',
              profile.server,
              Icons.dns,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              'Port',
              profile.port.toString(),
              Icons.router,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              'Created',
              _formatDate(profile.createdAt),
              Icons.calendar_today,
            ),
            if (profile.lastConnected != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                context,
                'Last Connected',
                _formatDate(profile.lastConnected!),
                Icons.history,
              ),
            ],
            const SizedBox(height: 16),
            _buildProtocolSpecificInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildProtocolSpecificInfo(BuildContext context) {
    switch (profile.protocol) {
      case VPNProtocol.vmess:
        return _buildVMessInfo(context);
      case VPNProtocol.trojan:
        return _buildTrojanInfo(context);
      case VPNProtocol.vless:
        return _buildVLESSInfo(context);
      case VPNProtocol.shadowsocks:
        return _buildShadowsocksInfo(context);
      case VPNProtocol.wireguard:
        return _buildWireGuardInfo(context);
      case VPNProtocol.tuic:
        return _buildTUICInfo(context);
      case VPNProtocol.hysteria:
        return _buildHysteriaInfo(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildVMessInfo(BuildContext context) {
    final config = VMessConfig.fromJson(profile.config);
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'VMess Configuration',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(context, 'Security', config.security, Icons.lock),
        const SizedBox(height: 4),
        _buildInfoRow(context, 'Network', config.network, Icons.network_check),
        if (config.tls) ...[
          const SizedBox(height: 4),
          _buildInfoRow(context, 'TLS', 'Enabled', Icons.verified_user),
        ],
      ],
    );
  }

  Widget _buildTrojanInfo(BuildContext context) {
    final config = TrojanConfig.fromJson(profile.config);
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'Trojan Configuration',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(context, 'Network', config.network, Icons.network_check),
        if (config.sni.isNotEmpty) ...[
          const SizedBox(height: 4),
          _buildInfoRow(context, 'SNI', config.sni, Icons.dns),
        ],
      ],
    );
  }

  Widget _buildVLESSInfo(BuildContext context) {
    final config = VLESSConfig.fromJson(profile.config);
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'VLESS Configuration',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(context, 'Security', config.security, Icons.lock),
        const SizedBox(height: 4),
        _buildInfoRow(context, 'Network', config.network, Icons.network_check),
        if (config.flow.isNotEmpty) ...[
          const SizedBox(height: 4),
          _buildInfoRow(context, 'Flow', config.flow, Icons.stream),
        ],
      ],
    );
  }

  Widget _buildShadowsocksInfo(BuildContext context) {
    final config = ShadowsocksConfig.fromJson(profile.config);
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'Shadowsocks Configuration',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(context, 'Method', config.method, Icons.lock),
        if (config.plugin.isNotEmpty) ...[
          const SizedBox(height: 4),
          _buildInfoRow(context, 'Plugin', config.plugin, Icons.extension),
        ],
      ],
    );
  }

  Widget _buildWireGuardInfo(BuildContext context) {
    final config = WireGuardConfig.fromJson(profile.config);
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'WireGuard Configuration',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(context, 'MTU', config.mtu.toString(), Icons.settings_ethernet),
        const SizedBox(height: 4),
        _buildInfoRow(context, 'Local Address', config.localAddress.join(', '), Icons.location_on),
      ],
    );
  }

  Widget _buildTUICInfo(BuildContext context) {
    final config = TUICConfig.fromJson(profile.config);
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'TUIC Configuration',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(context, 'ALPN', config.alpn, Icons.http),
        if (config.sni.isNotEmpty) ...[
          const SizedBox(height: 4),
          _buildInfoRow(context, 'SNI', config.sni, Icons.dns),
        ],
      ],
    );
  }

  Widget _buildHysteriaInfo(BuildContext context) {
    final config = HysteriaConfig.fromJson(profile.config);
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'Hysteria Configuration',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(context, 'ALPN', config.alpn, Icons.http),
        if (config.obfs.isNotEmpty) ...[
          const SizedBox(height: 4),
          _buildInfoRow(context, 'Obfuscation', config.obfs, Icons.shuffle),
        ],
      ],
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}


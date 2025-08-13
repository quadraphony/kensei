import 'dart:convert';

enum VPNProtocol {
  vmess,
  trojan,
  vless,
  shadowsocks,
  wireguard,
  tuic,
  hysteria,
  socks,
  http,
}

class VPNConfig {
  final String id;
  final String name;
  final VPNProtocol protocol;
  final String server;
  final int port;
  final Map<String, dynamic> config;
  final DateTime createdAt;
  final DateTime? lastConnected;

  VPNConfig({
    required this.id,
    required this.name,
    required this.protocol,
    required this.server,
    required this.port,
    required this.config,
    required this.createdAt,
    this.lastConnected,
    this.isActive = false,
    this.killSwitchEnabled = false,
    this.alwaysOnEnabled = false,
    this.splitTunnelingEnabled = false,
    this.splitTunnelingApps = const [],
  });

  factory VPNConfig.fromJson(Map<String, dynamic> json) {
    return VPNConfig(
      id: json['id'],
      name: json['name'],
      protocol: VPNProtocol.values.firstWhere(
        (e) => e.toString().split('.').last == json['protocol'],
      ),
      server: json['server'],
      port: json['port'],
      config: json['config'],
      createdAt: DateTime.parse(json['createdAt']),
      lastConnected: json['lastConnected'] != null
          ? DateTime.parse(json['lastConnected'])
          : null,
      isActive: json["isActive"] ?? false,
      killSwitchEnabled: json["killSwitchEnabled"] ?? false,
      alwaysOnEnabled: json["alwaysOnEnabled"] ?? false,
      splitTunnelingEnabled: json["splitTunnelingEnabled"] ?? false,
      splitTunnelingApps: List<String>.from(json["splitTunnelingApps"] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'protocol': protocol.toString().split('.').last,
      'server': server,
      'port': port,
      'config': config,
      'createdAt': createdAt.toIso8601String(),
      'lastConnected': lastConnected?.toIso8601String(),
      'isActive': isActive,
      'killSwitchEnabled': killSwitchEnabled,
      'alwaysOnEnabled': alwaysOnEnabled,
      'splitTunnelingEnabled': splitTunnelingEnabled,
      'splitTunnelingApps': splitTunnelingApps,
    };
  }

  VPNConfig copyWith({
    String? id,
    String? name,
    VPNProtocol? protocol,
    String? server,
    int? port,
    Map<String, dynamic>? config,
    DateTime? createdAt,
    DateTime? lastConnected,
    bool? isActive,
    bool? killSwitchEnabled,
    bool? alwaysOnEnabled,
    bool? splitTunnelingEnabled,
    List<String>? splitTunnelingApps,
    int? latencyMs,
    double? uploadSpeedKbps,
    double? downloadSpeedKbps,
  }) {
    return VPNConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      protocol: protocol ?? this.protocol,
      server: server ?? this.server,
      port: port ?? this.port,
      config: config ?? this.config,
      createdAt: createdAt ?? this.createdAt,
      lastConnected: lastConnected ?? this.lastConnected,
      isActive: isActive ?? this.isActive,
      killSwitchEnabled: killSwitchEnabled ?? this.killSwitchEnabled,
      alwaysOnEnabled: alwaysOnEnabled ?? this.alwaysOnEnabled,
      splitTunnelingEnabled: splitTunnelingEnabled ?? this.splitTunnelingEnabled,
      splitTunnelingApps: splitTunnelingApps ?? this.splitTunnelingApps,
      latencyMs: latencyMs ?? this.latencyMs,
      uploadSpeedKbps: uploadSpeedKbps ?? this.uploadSpeedKbps,
      downloadSpeedKbps: downloadSpeedKbps ?? this.downloadSpeedKbps,
    );
  }

  String get protocolDisplayName {
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

  String get displayAddress => '$server:$port';
}

class VMessConfig {
  final String uuid;
  final String security;
  final int alterId;
  final String network;
  final String path;
  final String host;
  final bool tls;
  final String sni;

  VMessConfig({
    required this.uuid,
    required this.security,
    required this.alterId,
    required this.network,
    required this.path,
    required this.host,
    required this.tls,
    required this.sni,
  });

  factory VMessConfig.fromJson(Map<String, dynamic> json) {
    return VMessConfig(
      uuid: json['uuid'] ?? '',
      security: json['security'] ?? 'auto',
      alterId: json['alter_id'] ?? 0,
      network: json['network'] ?? 'tcp',
      path: json['path'] ?? '',
      host: json['host'] ?? '',
      tls: json['tls'] ?? false,
      sni: json['sni'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'security': security,
      'alter_id': alterId,
      'network': network,
      'path': path,
      'host': host,
      'tls': tls,
      'sni': sni,
    };
  }
}

class TrojanConfig {
  final String password;
  final String sni;
  final String network;
  final String path;
  final String host;

  TrojanConfig({
    required this.password,
    required this.sni,
    required this.network,
    required this.path,
    required this.host,
  });

  factory TrojanConfig.fromJson(Map<String, dynamic> json) {
    return TrojanConfig(
      password: json['password'] ?? '',
      sni: json['sni'] ?? '',
      network: json['network'] ?? 'tcp',
      path: json['path'] ?? '',
      host: json['host'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'password': password,
      'sni': sni,
      'network': network,
      'path': path,
      'host': host,
    };
  }
}

class VLESSConfig {
  final String uuid;
  final String flow;
  final String security;
  final String sni;
  final String network;
  final String path;
  final String host;

  VLESSConfig({
    required this.uuid,
    required this.flow,
    required this.security,
    required this.sni,
    required this.network,
    required this.path,
    required this.host,
  });

  factory VLESSConfig.fromJson(Map<String, dynamic> json) {
    return VLESSConfig(
      uuid: json['uuid'] ?? '',
      flow: json['flow'] ?? '',
      security: json['security'] ?? 'none',
      sni: json['sni'] ?? '',
      network: json['network'] ?? 'tcp',
      path: json['path'] ?? '',
      host: json['host'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'flow': flow,
      'security': security,
      'sni': sni,
      'network': network,
      'path': path,
      'host': host,
    };
  }
}

class ShadowsocksConfig {
  final String method;
  final String password;
  final String plugin;
  final String pluginOpts;

  ShadowsocksConfig({
    required this.method,
    required this.password,
    required this.plugin,
    required this.pluginOpts,
  });

  factory ShadowsocksConfig.fromJson(Map<String, dynamic> json) {
    return ShadowsocksConfig(
      method: json['method'] ?? 'aes-256-gcm',
      password: json['password'] ?? '',
      plugin: json['plugin'] ?? '',
      pluginOpts: json['plugin_opts'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'password': password,
      'plugin': plugin,
      'plugin_opts': pluginOpts,
    };
  }
}

class WireGuardConfig {
  final String privateKey;
  final String peerPublicKey;
  final List<String> localAddress;
  final int mtu;

  WireGuardConfig({
    required this.privateKey,
    required this.peerPublicKey,
    required this.localAddress,
    required this.mtu,
  });

  factory WireGuardConfig.fromJson(Map<String, dynamic> json) {
    return WireGuardConfig(
      privateKey: json['private_key'] ?? '',
      peerPublicKey: json['peer_public_key'] ?? '',
      localAddress: List<String>.from(json['local_address'] ?? []),
      mtu: json['mtu'] ?? 1420,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'private_key': privateKey,
      'peer_public_key': peerPublicKey,
      'local_address': localAddress,
      'mtu': mtu,
    };
  }
}

class TUICConfig {
  final String uuid;
  final String password;
  final String alpn;
  final String sni;

  TUICConfig({
    required this.uuid,
    required this.password,
    required this.alpn,
    required this.sni,
  });

  factory TUICConfig.fromJson(Map<String, dynamic> json) {
    return TUICConfig(
      uuid: json['uuid'] ?? '',
      password: json['password'] ?? '',
      alpn: json['alpn'] ?? 'h3',
      sni: json['sni'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'password': password,
      'alpn': alpn,
      'sni': sni,
    };
  }
}

class HysteriaConfig {
  final String auth;
  final String alpn;
  final String sni;
  final String obfs;

  HysteriaConfig({
    required this.auth,
    required this.alpn,
    required this.sni,
    required this.obfs,
  });

  factory HysteriaConfig.fromJson(Map<String, dynamic> json) {
    return HysteriaConfig(
      auth: json['auth'] ?? '',
      alpn: json['alpn'] ?? 'h3',
      sni: json['sni'] ?? '',
      obfs: json['obfs'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'auth': auth,
      'alpn': alpn,
      'sni': sni,
      'obfs': obfs,
    };
  }
}

class ConnectionStats {
  final int uploadBytes;
  final int downloadBytes;
  final Duration connectionTime;
  final String status;
  final int latencyMs; // New field for latency in milliseconds
  final double uploadSpeedKbps; // New field for upload speed in KBps
  final double downloadSpeedKbps; // New field for download speed in KBps

  ConnectionStats({
    required this.uploadBytes,
    required this.downloadBytes,
    required this.connectionTime,
    required this.status,
    this.latencyMs = 0,
    this.uploadSpeedKbps = 0.0,
    this.downloadSpeedKbps = 0.0,
  });

  String get uploadFormatted => _formatBytes(uploadBytes);
  String get downloadFormatted => _formatBytes(downloadBytes);
  String get totalFormatted => _formatBytes(uploadBytes + downloadBytes);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class Subscription {
  final String id;
  final String name;
  final String url;
  final DateTime lastUpdated;
  final List<VPNConfig> configs;
  final bool autoUpdate;
  final int updateInterval; // in hours

  Subscription({
    required this.id,
    required this.name,
    required this.url,
    required this.lastUpdated,
    required this.configs,
    this.autoUpdate = true,
    this.updateInterval = 24,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      name: json['name'],
      url: json['url'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
      configs: (json['configs'] as List)
          .map((config) => VPNConfig.fromJson(config))
          .toList(),
      autoUpdate: json['autoUpdate'] ?? true,
      updateInterval: json['updateInterval'] ?? 24,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'lastUpdated': lastUpdated.toIso8601String(),
      'configs': configs.map((config) => config.toJson()).toList(),
      'autoUpdate': autoUpdate,
      'updateInterval': updateInterval,
    };
  }
}


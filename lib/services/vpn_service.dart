import 'dart:async';
import 'dart:convert';
import 'dart:math';
import '../ffi/sing_box_bindings.dart';
import '../models/vpn_config.dart';

enum VPNConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

class VPNService {
  static final VPNService _instance = VPNService._internal();
  factory VPNService() => _instance;
  VPNService._internal();

  VPNConnectionState _connectionState = VPNConnectionState.disconnected;
  VPNConfig? _currentConfig;
  Timer? _statsTimer;
  Timer? _reconnectTimer;
  
  final StreamController<VPNConnectionState> _stateController = 
      StreamController<VPNConnectionState>.broadcast();
  final StreamController<ConnectionStats> _statsController = 
      StreamController<ConnectionStats>.broadcast();
  final StreamController<String> _logController = 
      StreamController<String>.broadcast();

  Stream<VPNConnectionState> get connectionStateStream => _stateController.stream;
  Stream<ConnectionStats> get statsStream => _statsController.stream;
  Stream<String> get logStream => _logController.stream;

  VPNConnectionState get connectionState => _connectionState;
  VPNConfig? get currentConfig => _currentConfig;

  DateTime? _connectionStartTime;
  int _uploadBytes = 0;
  int _downloadBytes = 0;

  Future<bool> connect(VPNConfig config) async {
    if (_connectionState == VPNConnectionState.connecting ||
        _connectionState == VPNConnectionState.connected) {
      return false;
    }

    _updateState(VPNConnectionState.connecting);
    _currentConfig = config;
    _connectionStartTime = DateTime.now();
    
    try {
      final singBoxConfig = await _generateSingBoxConfig(config);
      final result = SingBoxBindings.startVPNConnection(jsonEncode(singBoxConfig));
      
      _log('Connection attempt: $result');
      
      if (result.contains('successfully')) {
        _updateState(VPNConnectionState.connected);
        _startStatsTimer();
        _log('Connected to ${config.name} (${config.displayAddress})');
        return true;
      } else {
        _updateState(VPNConnectionState.error);
        _log('Connection failed: $result');
        return false;
      }
    } catch (e) {
      _updateState(VPNConnectionState.error);
      _log('Connection error: $e');
      return false;
    }
  }

  Future<bool> disconnect() async {
    if (_connectionState == VPNConnectionState.disconnected ||
        _connectionState == VPNConnectionState.disconnecting) {
      return false;
    }

    _updateState(VPNConnectionState.disconnecting);
    
    try {
      final result = SingBoxBindings.stopVPNConnection();
      _log('Disconnection result: $result');
      
      _stopStatsTimer();
      _updateState(VPNConnectionState.disconnected);
      _currentConfig = null;
      _connectionStartTime = null;
      _uploadBytes = 0;
      _downloadBytes = 0;
      
      _log('Disconnected successfully');
      return true;
    } catch (e) {
      _updateState(VPNConnectionState.error);
      _log('Disconnection error: $e');
      return false;
    }
  }

  Future<bool> reconnect() async {
    if (_currentConfig == null) return false;
    
    _log('Attempting to reconnect...');
    await disconnect();
    await Future.delayed(const Duration(seconds: 2));
    return await connect(_currentConfig!);
  }

  void _updateState(VPNConnectionState newState) {
    _connectionState = newState;
    _stateController.add(newState);
  }

  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    _logController.add('[$timestamp] $message');
  }

  void _startStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateStats();
    });
  }

  void _stopStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = null;
  }

  void _updateStats() {
    if (_connectionStartTime == null) return;
    
    // Simulate traffic stats (in a real implementation, this would come from the VPN core)
    final random = Random();
    _uploadBytes += random.nextInt(1024);
    _downloadBytes += random.nextInt(2048);
    
    final connectionTime = DateTime.now().difference(_connectionStartTime!);
    final stats = ConnectionStats(
      uploadBytes: _uploadBytes,
      downloadBytes: _downloadBytes,
      connectionTime: connectionTime,
      status: _connectionState.toString().split('.').last,
    );
    
    _statsController.add(stats);
  }

  Future<Map<String, dynamic>> _generateSingBoxConfig(VPNConfig config) async {
    final outbound = await _createOutboundConfig(config);
    
    return {
      "log": {
        "level": "info",
        "timestamp": true
      },
      "dns": {
        "servers": [
          {
            "tag": "cloudflare",
            "address": "https://1.1.1.1/dns-query"
          },
          {
            "tag": "google",
            "address": "https://8.8.8.8/dns-query"
          }
        ],
        "rules": [
          {
            "outbound": "any",
            "server": "cloudflare"
          }
        ]
      },
      "inbounds": [
        {
          "type": "tun",
          "tag": "tun-in",
          "interface_name": "kensei-tunnel",
          "inet4_address": "172.19.0.1/30",
          "auto_route": true,
          "strict_route": false,
          "sniff": true
        }
      ],
      "outbounds": [
        outbound,
        {
          "type": "direct",
          "tag": "direct"
        },
        {
          "type": "block",
          "tag": "block"
        },
        {
          "type": "dns",
          "tag": "dns-out"
        }
      ],
      "route": {
        "rules": [
          {
            "protocol": "dns",
            "outbound": "dns-out"
          },
          {
            "network": "udp",
            "port": 443,
            "outbound": "block"
          },
          {
            "geosite": "cn",
            "outbound": "direct"
          },
          {
            "geoip": "cn",
            "outbound": "direct"
          }
        ],
        "auto_detect_interface": true
      }
    };
  }

  Future<Map<String, dynamic>> _createOutboundConfig(VPNConfig config) async {
    switch (config.protocol) {
      case VPNProtocol.vmess:
        return _createVMessOutbound(config);
      case VPNProtocol.trojan:
        return _createTrojanOutbound(config);
      case VPNProtocol.vless:
        return _createVLESSOutbound(config);
      case VPNProtocol.shadowsocks:
        return _createShadowsocksOutbound(config);
      case VPNProtocol.wireguard:
        return _createWireGuardOutbound(config);
      case VPNProtocol.tuic:
        return _createTUICOutbound(config);
      case VPNProtocol.hysteria:
        return _createHysteriaOutbound(config);
      default:
        throw UnsupportedError('Protocol ${config.protocol} not supported');
    }
  }

  Map<String, dynamic> _createVMessOutbound(VPNConfig config) {
    final vmessConfig = VMessConfig.fromJson(config.config);
    
    return {
      "type": "vmess",
      "tag": "proxy",
      "server": config.server,
      "server_port": config.port,
      "uuid": vmessConfig.uuid,
      "security": vmessConfig.security,
      "alter_id": vmessConfig.alterId,
      "transport": {
        "type": vmessConfig.network,
        if (vmessConfig.network == "ws") ...{
          "path": vmessConfig.path,
          "headers": {
            if (vmessConfig.host.isNotEmpty) "Host": vmessConfig.host,
          }
        }
      },
      if (vmessConfig.tls) ...{
        "tls": {
          "enabled": true,
          if (vmessConfig.sni.isNotEmpty) "server_name": vmessConfig.sni,
        }
      }
    };
  }

  Map<String, dynamic> _createTrojanOutbound(VPNConfig config) {
    final trojanConfig = TrojanConfig.fromJson(config.config);
    
    return {
      "type": "trojan",
      "tag": "proxy",
      "server": config.server,
      "server_port": config.port,
      "password": trojanConfig.password,
      "tls": {
        "enabled": true,
        if (trojanConfig.sni.isNotEmpty) "server_name": trojanConfig.sni,
      },
      if (trojanConfig.network == "ws") ...{
        "transport": {
          "type": "ws",
          "path": trojanConfig.path,
          "headers": {
            if (trojanConfig.host.isNotEmpty) "Host": trojanConfig.host,
          }
        }
      }
    };
  }

  Map<String, dynamic> _createVLESSOutbound(VPNConfig config) {
    final vlessConfig = VLESSConfig.fromJson(config.config);
    
    return {
      "type": "vless",
      "tag": "proxy",
      "server": config.server,
      "server_port": config.port,
      "uuid": vlessConfig.uuid,
      if (vlessConfig.flow.isNotEmpty) "flow": vlessConfig.flow,
      if (vlessConfig.security == "tls") ...{
        "tls": {
          "enabled": true,
          if (vlessConfig.sni.isNotEmpty) "server_name": vlessConfig.sni,
        }
      },
      if (vlessConfig.network == "ws") ...{
        "transport": {
          "type": "ws",
          "path": vlessConfig.path,
          "headers": {
            if (vlessConfig.host.isNotEmpty) "Host": vlessConfig.host,
          }
        }
      }
    };
  }

  Map<String, dynamic> _createShadowsocksOutbound(VPNConfig config) {
    final ssConfig = ShadowsocksConfig.fromJson(config.config);
    
    return {
      "type": "shadowsocks",
      "tag": "proxy",
      "server": config.server,
      "server_port": config.port,
      "method": ssConfig.method,
      "password": ssConfig.password,
      if (ssConfig.plugin.isNotEmpty) ...{
        "plugin": ssConfig.plugin,
        "plugin_opts": ssConfig.pluginOpts,
      }
    };
  }

  Map<String, dynamic> _createWireGuardOutbound(VPNConfig config) {
    final wgConfig = WireGuardConfig.fromJson(config.config);
    
    return {
      "type": "wireguard",
      "tag": "proxy",
      "server": config.server,
      "server_port": config.port,
      "private_key": wgConfig.privateKey,
      "peer_public_key": wgConfig.peerPublicKey,
      "local_address": wgConfig.localAddress,
      "mtu": wgConfig.mtu,
    };
  }

  Map<String, dynamic> _createTUICOutbound(VPNConfig config) {
    final tuicConfig = TUICConfig.fromJson(config.config);
    
    return {
      "type": "tuic",
      "tag": "proxy",
      "server": config.server,
      "server_port": config.port,
      "uuid": tuicConfig.uuid,
      "password": tuicConfig.password,
      "tls": {
        "enabled": true,
        if (tuicConfig.sni.isNotEmpty) "server_name": tuicConfig.sni,
        if (tuicConfig.alpn.isNotEmpty) "alpn": [tuicConfig.alpn],
      }
    };
  }

  Map<String, dynamic> _createHysteriaOutbound(VPNConfig config) {
    final hysteriaConfig = HysteriaConfig.fromJson(config.config);
    
    return {
      "type": "hysteria",
      "tag": "proxy",
      "server": config.server,
      "server_port": config.port,
      "auth_str": hysteriaConfig.auth,
      "tls": {
        "enabled": true,
        if (hysteriaConfig.sni.isNotEmpty) "server_name": hysteriaConfig.sni,
        if (hysteriaConfig.alpn.isNotEmpty) "alpn": [hysteriaConfig.alpn],
      },
      if (hysteriaConfig.obfs.isNotEmpty) "obfs": hysteriaConfig.obfs,
    };
  }

  void dispose() {
    _stateController.close();
    _statsController.close();
    _logController.close();
    _statsTimer?.cancel();
    _reconnectTimer?.cancel();
  }
}


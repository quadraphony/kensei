import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  bool _killSwitchEnabled = true;
  bool _dnsLeakProtectionEnabled = true;
  bool _autoReconnectEnabled = true;
  bool _ipv6SupportEnabled = false;
  List<String> _dnsServers = ['1.1.1.1', '8.8.8.8', '9.9.9.9'];
  String _encryptionMethod = 'AES-256-GCM';

  final StreamController<Map<String, dynamic>> _settingsController = 
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get settingsStream => _settingsController.stream;

  // Getters
  bool get killSwitchEnabled => _killSwitchEnabled;
  bool get dnsLeakProtectionEnabled => _dnsLeakProtectionEnabled;
  bool get autoReconnectEnabled => _autoReconnectEnabled;
  bool get ipv6SupportEnabled => _ipv6SupportEnabled;
  List<String> get dnsServers => List.unmodifiable(_dnsServers);
  String get encryptionMethod => _encryptionMethod;

  Future<void> initialize() async {
    await _loadSettings();
    _notifySettingsChanged();
  }

  Future<void> setKillSwitch(bool enabled) async {
    _killSwitchEnabled = enabled;
    await _saveSettings();
    _notifySettingsChanged();
    
    if (enabled) {
      await _enableKillSwitch();
    } else {
      await _disableKillSwitch();
    }
  }

  Future<void> setDnsLeakProtection(bool enabled) async {
    _dnsLeakProtectionEnabled = enabled;
    await _saveSettings();
    _notifySettingsChanged();
    
    if (enabled) {
      await _enableDnsLeakProtection();
    } else {
      await _disableLeakProtection();
    }
  }

  Future<void> setAutoReconnect(bool enabled) async {
    _autoReconnectEnabled = enabled;
    await _saveSettings();
    _notifySettingsChanged();
  }

  Future<void> setIpv6Support(bool enabled) async {
    _ipv6SupportEnabled = enabled;
    await _saveSettings();
    _notifySettingsChanged();
    
    if (enabled) {
      await _enableIpv6Support();
    } else {
      await _disableIpv6Support();
    }
  }

  Future<void> setDnsServers(List<String> servers) async {
    _dnsServers = List.from(servers);
    await _saveSettings();
    _notifySettingsChanged();
    await _updateDnsConfiguration();
  }

  Future<void> setEncryptionMethod(String method) async {
    _encryptionMethod = method;
    await _saveSettings();
    _notifySettingsChanged();
  }

  Future<void> _enableKillSwitch() async {
    try {
      if (Platform.isLinux || Platform.isMacOS) {
        // Block all traffic except VPN interface
        await Process.run('sudo', [
          'iptables', '-I', 'OUTPUT', '!', '-o', 'kensei-tunnel', '-j', 'DROP'
        ]);
        await Process.run('sudo', [
          'iptables', '-I', 'INPUT', '!', '-i', 'kensei-tunnel', '-j', 'DROP'
        ]);
      } else if (Platform.isWindows) {
        // Windows firewall rules
        await Process.run('netsh', [
          'advfirewall', 'firewall', 'add', 'rule',
          'name=KenseiTunnel_KillSwitch',
          'dir=out', 'action=block', 'enable=yes'
        ]);
      }
    } catch (e) {
      print('Error enabling kill switch: $e');
    }
  }

  Future<void> _disableKillSwitch() async {
    try {
      if (Platform.isLinux || Platform.isMacOS) {
        // Remove blocking rules
        await Process.run('sudo', [
          'iptables', '-D', 'OUTPUT', '!', '-o', 'kensei-tunnel', '-j', 'DROP'
        ]);
        await Process.run('sudo', [
          'iptables', '-D', 'INPUT', '!', '-i', 'kensei-tunnel', '-j', 'DROP'
        ]);
      } else if (Platform.isWindows) {
        await Process.run('netsh', [
          'advfirewall', 'firewall', 'delete', 'rule',
          'name=KenseiTunnel_KillSwitch'
        ]);
      }
    } catch (e) {
      print('Error disabling kill switch: $e');
    }
  }

  Future<void> _enableDnsLeakProtection() async {
    try {
      if (Platform.isLinux || Platform.isMacOS) {
        // Redirect DNS queries to VPN interface
        for (final dns in _dnsServers) {
          await Process.run('sudo', [
            'iptables', '-t', 'nat', '-I', 'OUTPUT',
            '-p', 'udp', '--dport', '53',
            '-j', 'DNAT', '--to-destination', '$dns:53'
          ]);
        }
      } else if (Platform.isWindows) {
        // Set DNS servers via netsh
        for (int i = 0; i < _dnsServers.length; i++) {
          final dns = _dnsServers[i];
          if (i == 0) {
            await Process.run('netsh', [
              'interface', 'ip', 'set', 'dns',
              'name="Kensei Tunnel"', 'static', dns
            ]);
          } else {
            await Process.run('netsh', [
              'interface', 'ip', 'add', 'dns',
              'name="Kensei Tunnel"', dns, 'index=${i + 1}'
            ]);
          }
        }
      }
    } catch (e) {
      print('Error enabling DNS leak protection: $e');
    }
  }

  Future<void> _disableLeakProtection() async {
    try {
      if (Platform.isLinux || Platform.isMacOS) {
        // Remove DNS redirection rules
        await Process.run('sudo', [
          'iptables', '-t', 'nat', '-F', 'OUTPUT'
        ]);
      } else if (Platform.isWindows) {
        await Process.run('netsh', [
          'interface', 'ip', 'set', 'dns',
          'name="Kensei Tunnel"', 'dhcp'
        ]);
      }
    } catch (e) {
      print('Error disabling DNS leak protection: $e');
    }
  }

  Future<void> _enableIpv6Support() async {
    try {
      if (Platform.isLinux || Platform.isMacOS) {
        await Process.run('sudo', [
          'sysctl', '-w', 'net.ipv6.conf.all.disable_ipv6=0'
        ]);
        await Process.run('sudo', [
          'ip6tables', '-I', 'OUTPUT', '-o', 'kensei-tunnel', '-j', 'ACCEPT'
        ]);
      } else if (Platform.isWindows) {
        await Process.run('netsh', [
          'interface', 'ipv6', 'set', 'global', 'randomizeidentifiers=enabled'
        ]);
      }
    } catch (e) {
      print('Error enabling IPv6 support: $e');
    }
  }

  Future<void> _disableIpv6Support() async {
    try {
      if (Platform.isLinux || Platform.isMacOS) {
        await Process.run('sudo', [
          'sysctl', '-w', 'net.ipv6.conf.all.disable_ipv6=1'
        ]);
        await Process.run('sudo', [
          'ip6tables', '-F'
        ]);
      } else if (Platform.isWindows) {
        await Process.run('netsh', [
          'interface', 'ipv6', 'set', 'global', 'randomizeidentifiers=disabled'
        ]);
      }
    } catch (e) {
      print('Error disabling IPv6 support: $e');
    }
  }

  Future<void> _updateDnsConfiguration() async {
    if (_dnsLeakProtectionEnabled) {
      await _disableLeakProtection();
      await _enableDnsLeakProtection();
    }
  }

  String encryptData(String data, String key) {
    final keyBytes = utf8.encode(key);
    final dataBytes = utf8.encode(data);
    final hmacSha256 = Hmac(sha256, keyBytes);
    final digest = hmacSha256.convert(dataBytes);
    
    // Simple XOR encryption for demonstration
    final random = Random();
    final iv = List.generate(16, (i) => random.nextInt(256));
    final encrypted = <int>[];
    
    for (int i = 0; i < dataBytes.length; i++) {
      encrypted.add(dataBytes[i] ^ keyBytes[i % keyBytes.length] ^ iv[i % iv.length]);
    }
    
    final result = [...iv, ...encrypted, ...digest.bytes];
    return base64.encode(result);
  }

  String decryptData(String encryptedData, String key) {
    try {
      final data = base64.decode(encryptedData);
      final keyBytes = utf8.encode(key);
      
      final iv = data.sublist(0, 16);
      final encrypted = data.sublist(16, data.length - 32);
      final storedDigest = data.sublist(data.length - 32);
      
      final decrypted = <int>[];
      for (int i = 0; i < encrypted.length; i++) {
        decrypted.add(encrypted[i] ^ keyBytes[i % keyBytes.length] ^ iv[i % iv.length]);
      }
      
      // Verify integrity
      final hmacSha256 = Hmac(sha256, keyBytes);
      final computedDigest = hmacSha256.convert(decrypted);
      
      if (computedDigest.bytes.toString() != storedDigest.toString()) {
        throw Exception('Data integrity check failed');
      }
      
      return utf8.decode(decrypted);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  Future<bool> validateConfiguration(Map<String, dynamic> config) async {
    try {
      // Check required fields
      if (!config.containsKey('type') || !config.containsKey('server')) {
        return false;
      }

      final type = config['type'] as String;
      final server = config['server'] as String;
      
      // Validate server address
      if (!_isValidAddress(server)) {
        return false;
      }

      // Protocol-specific validation
      switch (type.toLowerCase()) {
        case 'vmess':
          return _validateVMessConfig(config);
        case 'trojan':
          return _validateTrojanConfig(config);
        case 'vless':
          return _validateVLESSConfig(config);
        case 'shadowsocks':
          return _validateShadowsocksConfig(config);
        case 'wireguard':
          return _validateWireGuardConfig(config);
        case 'tuic':
          return _validateTUICConfig(config);
        case 'hysteria':
          return _validateHysteriaConfig(config);
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  bool _isValidAddress(String address) {
    // Check if it's a valid IP address or domain name
    final ipv4Regex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    final ipv6Regex = RegExp(r'^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$');
    final domainRegex = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$');
    
    return ipv4Regex.hasMatch(address) || 
           ipv6Regex.hasMatch(address) || 
           domainRegex.hasMatch(address);
  }

  bool _validateVMessConfig(Map<String, dynamic> config) {
    return config.containsKey('uuid') && 
           config.containsKey('server_port') &&
           config['uuid'].toString().isNotEmpty;
  }

  bool _validateTrojanConfig(Map<String, dynamic> config) {
    return config.containsKey('password') && 
           config.containsKey('server_port') &&
           config['password'].toString().isNotEmpty;
  }

  bool _validateVLESSConfig(Map<String, dynamic> config) {
    return config.containsKey('uuid') && 
           config.containsKey('server_port') &&
           config['uuid'].toString().isNotEmpty;
  }

  bool _validateShadowsocksConfig(Map<String, dynamic> config) {
    return config.containsKey('method') && 
           config.containsKey('password') &&
           config.containsKey('server_port') &&
           config['method'].toString().isNotEmpty &&
           config['password'].toString().isNotEmpty;
  }

  bool _validateWireGuardConfig(Map<String, dynamic> config) {
    return config.containsKey('private_key') && 
           config.containsKey('peer_public_key') &&
           config.containsKey('server_port') &&
           config['private_key'].toString().isNotEmpty &&
           config['peer_public_key'].toString().isNotEmpty;
  }

  bool _validateTUICConfig(Map<String, dynamic> config) {
    return config.containsKey('uuid') && 
           config.containsKey('password') &&
           config.containsKey('server_port') &&
           config['uuid'].toString().isNotEmpty &&
           config['password'].toString().isNotEmpty;
  }

  bool _validateHysteriaConfig(Map<String, dynamic> config) {
    return config.containsKey('auth_str') && 
           config.containsKey('server_port') &&
           config['auth_str'].toString().isNotEmpty;
  }

  Future<List<String>> scanForVulnerabilities(Map<String, dynamic> config) async {
    final vulnerabilities = <String>[];

    // Check for weak encryption
    if (config.containsKey('security') && 
        ['none', 'auto'].contains(config['security'])) {
      vulnerabilities.add('Weak or no encryption detected');
    }

    // Check for insecure methods
    if (config.containsKey('method')) {
      final method = config['method'].toString().toLowerCase();
      if (['rc4', 'des', 'md5'].any((weak) => method.contains(weak))) {
        vulnerabilities.add('Insecure encryption method: $method');
      }
    }

    // Check for default passwords
    if (config.containsKey('password')) {
      final password = config['password'].toString();
      final commonPasswords = ['password', '123456', 'admin', 'root', 'default'];
      if (commonPasswords.contains(password.toLowerCase())) {
        vulnerabilities.add('Weak default password detected');
      }
    }

    // Check for unencrypted connections
    if (config.containsKey('tls') && config['tls'] == false) {
      vulnerabilities.add('Unencrypted connection (TLS disabled)');
    }

    // Check for missing SNI
    if (config.containsKey('tls') && config['tls'] == true &&
        (!config.containsKey('sni') || config['sni'].toString().isEmpty)) {
      vulnerabilities.add('Missing SNI for TLS connection');
    }

    return vulnerabilities;
  }

  void _notifySettingsChanged() {
    _settingsController.add({
      'killSwitch': _killSwitchEnabled,
      'dnsLeakProtection': _dnsLeakProtectionEnabled,
      'autoReconnect': _autoReconnectEnabled,
      'ipv6Support': _ipv6SupportEnabled,
      'dnsServers': _dnsServers,
      'encryptionMethod': _encryptionMethod,
    });
  }

  Future<void> _loadSettings() async {
    try {
      final file = await _getSettingsFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final settings = jsonDecode(content) as Map<String, dynamic>;
        
        _killSwitchEnabled = settings['killSwitch'] ?? true;
        _dnsLeakProtectionEnabled = settings['dnsLeakProtection'] ?? true;
        _autoReconnectEnabled = settings['autoReconnect'] ?? true;
        _ipv6SupportEnabled = settings['ipv6Support'] ?? false;
        _dnsServers = List<String>.from(settings['dnsServers'] ?? ['1.1.1.1', '8.8.8.8']);
        _encryptionMethod = settings['encryptionMethod'] ?? 'AES-256-GCM';
      }
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final file = await _getSettingsFile();
      final settings = {
        'killSwitch': _killSwitchEnabled,
        'dnsLeakProtection': _dnsLeakProtectionEnabled,
        'autoReconnect': _autoReconnectEnabled,
        'ipv6Support': _ipv6SupportEnabled,
        'dnsServers': _dnsServers,
        'encryptionMethod': _encryptionMethod,
      };
      await file.writeAsString(jsonEncode(settings));
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  Future<File> _getSettingsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/kensei_tunnel_security_settings.json');
  }

  void dispose() {
    _settingsController.close();
  }
}


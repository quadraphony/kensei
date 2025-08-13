import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import '../models/vpn_config.dart';
import '../ffi/sing_box_bindings.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final List<VPNConfig> _profiles = [];
  final List<Subscription> _subscriptions = [];
  
  final StreamController<List<VPNConfig>> _profilesController = 
      StreamController<List<VPNConfig>>.broadcast();
  final StreamController<List<Subscription>> _subscriptionsController = 
      StreamController<List<Subscription>>.broadcast();

  Stream<List<VPNConfig>> get profilesStream => _profilesController.stream;
  Stream<List<Subscription>> get subscriptionsStream => _subscriptionsController.stream;

  List<VPNConfig> get profiles => List.unmodifiable(_profiles);
  List<Subscription> get subscriptions => List.unmodifiable(_subscriptions);

  // Default subscription URL
  static const String defaultSubscriptionUrl = 'https://raw.githubusercontent.com/barry-far/V2ray-config/main/Sub1.txt';

  Future<void> initialize() async {
    await _loadProfiles();
    await _loadSubscriptions();
    
    // Add default subscription if no subscriptions exist
    if (_subscriptions.isEmpty) {
      await addSubscription(
        name: 'Default V2Ray Configs',
        url: defaultSubscriptionUrl,
      );
    }
  }

  String _generateId() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(Iterable.generate(
        16, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  Future<String> addProfile({
    required String name,
    required VPNProtocol protocol,
    required String server,
    required int port,
    required Map<String, dynamic> config,
    bool killSwitchEnabled = false,
    bool alwaysOnEnabled = false,
    bool splitTunnelingEnabled = false,
    List<String> splitTunnelingApps = const [],
  }) async {
    final id = _generateId();
    final profile = VPNConfig(
      id: id,
      name: name,
      protocol: protocol,
      server: server,
      port: port,
      config: config,
      createdAt: DateTime.now(),
      isActive: false,
      killSwitchEnabled: killSwitchEnabled,
      alwaysOnEnabled: alwaysOnEnabled,
      splitTunnelingEnabled: splitTunnelingEnabled,
      splitTunnelingApps: splitTunnelingApps,
    );

    _profiles.add(profile);
    await _saveProfiles();
    _profilesController.add(_profiles);
    
    return id;
  }

  Future<void> updateProfile(String id, VPNConfig updatedProfile) async {
    final index = _profiles.indexWhere((p) => p.id == id);
    if (index != -1) {
      _profiles[index] = updatedProfile;
      await _saveProfiles();
      _profilesController.add(_profiles);
    }
  }

  Future<void> deleteProfile(String id) async {
    _profiles.removeWhere((p) => p.id == id);
    await _saveProfiles();
    _profilesController.add(_profiles);
  }

  Future<VPNConfig?> getProfile(String id) async {
    return _profiles.firstWhere((p) => p.id == id, orElse: () => throw StateError('Profile not found'));
  }

  Future<String> addSubscription({
    required String name,
    required String url,
    bool autoUpdate = true,
    int updateInterval = 24,
  }) async {
    final id = _generateId();
    final subscription = Subscription(
      id: id,
      name: name,
      url: url,
      lastUpdated: DateTime.now(),
      configs: [],
      autoUpdate: autoUpdate,
      updateInterval: updateInterval,
    );

    _subscriptions.add(subscription);
    await _saveSubscriptions();
    _subscriptionsController.add(_subscriptions);
    
    // Fetch configs immediately
    await updateSubscription(id);
    
    return id;
  }

  Future<void> updateSubscription(String id) async {
    final index = _subscriptions.indexWhere((s) => s.id == id);
    if (index == -1) return;

    final subscription = _subscriptions[index];
    
    try {
      final configsJson = SingBoxBindings.fetchSubscriptionConfigs(subscription.url);
      final configsList = jsonDecode(configsJson) as List;
      
      final configs = <VPNConfig>[];
      for (final configData in configsList) {
        final config = _parseSubscriptionConfig(configData);
        if (config != null) {
          configs.add(config);
        }
      }
      
      final updatedSubscription = Subscription(
        id: subscription.id,
        name: subscription.name,
        url: subscription.url,
        lastUpdated: DateTime.now(),
        configs: configs,
        autoUpdate: subscription.autoUpdate,
        updateInterval: subscription.updateInterval,
      );
      
      _subscriptions[index] = updatedSubscription;
      
      // Add configs to profiles if they don't exist
      for (final config in configs) {
        if (!_profiles.any((p) => p.server == config.server && p.port == config.port)) {
          _profiles.add(config);
        }
      }
      
      await _saveSubscriptions();
      await _saveProfiles();
      _subscriptionsController.add(_subscriptions);
      _profilesController.add(_profiles);
      
    } catch (e) {
      print('Error updating subscription: $e');
    }
  }

  Future<void> deleteSubscription(String id) async {
    _subscriptions.removeWhere((s) => s.id == id);
    await _saveSubscriptions();
    _subscriptionsController.add(_subscriptions);
  }

  VPNConfig? _parseSubscriptionConfig(Map<String, dynamic> configData) {
    try {
      final type = configData['type'] as String?;
      if (type == null) return null;

      VPNProtocol? protocol;
      switch (type.toLowerCase()) {
        case 'vmess':
          protocol = VPNProtocol.vmess;
          break;
        case 'trojan':
          protocol = VPNProtocol.trojan;
          break;
        case 'vless':
          protocol = VPNProtocol.vless;
          break;
        case 'shadowsocks':
          protocol = VPNProtocol.shadowsocks;
          break;
        case 'wireguard':
          protocol = VPNProtocol.wireguard;
          break;
        case 'tuic':
          protocol = VPNProtocol.tuic;
          break;
        case 'hysteria':
          protocol = VPNProtocol.hysteria;
          break;
        default:
          return null;
      }

      final server = configData['server'] as String?;
      final port = configData['server_port'];
      final tag = configData['tag'] as String? ?? 'Unknown';

      if (server == null || port == null) return null;

      final portInt = port is String ? int.tryParse(port) : port as int?;
      if (portInt == null) return null;

      return VPNConfig(
        id: _generateId(),
        name: tag,
        protocol: protocol,
        server: server,
        port: portInt,
        config: configData,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      print('Error parsing config: $e');
      return null;
    }
  }

  Future<String> createVMessProfile({
    required String name,
    required String server,
    required int port,
    required String uuid,
    required String security,
    required int alterId,
    required String network,
    required String path,
    required String host,
    required bool tls,
    required String sni,
    bool killSwitchEnabled = false,
    bool alwaysOnEnabled = false,
    bool splitTunnelingEnabled = false,
    List<String> splitTunnelingApps = const [],
  }) async {
    final config = VMessConfig(
      uuid: uuid,
      security: security,
      alterId: alterId,
      network: network,
      path: path,
      host: host,
      tls: tls,
      sni: sni,
    );

    return await addProfile(
      name: name,
      protocol: VPNProtocol.vmess,
      server: server,
      port: port,
      config: config.toJson(),
      killSwitchEnabled: killSwitchEnabled,
      alwaysOnEnabled: alwaysOnEnabled,
      splitTunnelingEnabled: splitTunnelingEnabled,
      splitTunnelingApps: splitTunnelingApps,
    );
  }

  Future<String> createTrojanProfile({
    required String name,
    required String server,
    required int port,
    required String password,
    required String sni,
    required String network,
    required String path,
    required String host,
    bool killSwitchEnabled = false,
    bool alwaysOnEnabled = false,
    bool splitTunnelingEnabled = false,
    List<String> splitTunnelingApps = const [],
  }) async {
    final config = TrojanConfig(
      password: password,
      sni: sni,
      network: network,
      path: path,
      host: host,
    );

    return await addProfile(
      name: name,
      protocol: VPNProtocol.trojan,
      server: server,
      port: port,
      config: config.toJson(),
      killSwitchEnabled: killSwitchEnabled,
      alwaysOnEnabled: alwaysOnEnabled,
      splitTunnelingEnabled: splitTunnelingEnabled,
      splitTunnelingApps: splitTunnelingApps,
    );
  }

  Future<String> createVLESSProfile({
    required String name,
    required String server,
    required int port,
    required String uuid,
    required String flow,
    required String security,
    required String sni,
    required String network,
    required String path,
    required String host,
    bool killSwitchEnabled = false,
    bool alwaysOnEnabled = false,
    bool splitTunnelingEnabled = false,
    List<String> splitTunnelingApps = const [],
  }) async {
    final config = VLESSConfig(
      uuid: uuid,
      flow: flow,
      security: security,
      sni: sni,
      network: network,
      path: path,
      host: host,
    );

    return await addProfile(
      name: name,
      protocol: VPNProtocol.vless,
      server: server,
      port: port,
      config: config.toJson(),
      killSwitchEnabled: killSwitchEnabled,
      alwaysOnEnabled: alwaysOnEnabled,
      splitTunnelingEnabled: splitTunnelingEnabled,
      splitTunnelingApps: splitTunnelingApps,
    );
  }

  Future<String> createShadowsocksProfile({
    required String name,
    required String server,
    required int port,
    required String method,
    required String password,
    String plugin = "",
    String pluginOpts = "",
    bool killSwitchEnabled = false,
    bool alwaysOnEnabled = false,
    bool splitTunnelingEnabled = false,
    List<String> splitTunnelingApps = const [],
  }) async {
    final config = ShadowsocksConfig(
      method: method,
      password: password,
      plugin: plugin,
      pluginOpts: pluginOpts,
    );
    return await addProfile(
      name: name,
      protocol: VPNProtocol.shadowsocks,
      server: server,
      port: port,
      config: config.toJson(),
      killSwitchEnabled: killSwitchEnabled,
      alwaysOnEnabled: alwaysOnEnabled,
      splitTunnelingEnabled: splitTunnelingEnabled,
      splitTunnelingApps: splitTunnelingApps,
    );
  }

  Future<String> createTUICProfile({
    required String name,
    required String server,
    required int port,
    required String uuid,
    required String password,
    required String alpn,
    required String sni,
    bool killSwitchEnabled = false,
    bool alwaysOnEnabled = false,
    bool splitTunnelingEnabled = false,
    List<String> splitTunnelingApps = const [],
  }) async {
    final config = TUICConfig(
      uuid: uuid,
      password: password,
      alpn: alpn,
      sni: sni,
    );

    return await addProfile(
      name: name,
      protocol: VPNProtocol.tuic,
      server: server,
      port: port,
      config: config.toJson(),
      killSwitchEnabled: killSwitchEnabled,
      alwaysOnEnabled: alwaysOnEnabled,
      splitTunnelingEnabled: splitTunnelingEnabled,
      splitTunnelingApps: splitTunnelingApps,
    );
  }

  Future<String> createHysteriaProfile({
    required String name,
    required String server,
    required int port,
    required String auth,
    required String alpn,
    required String sni,
    String obfs = "",
    bool killSwitchEnabled = false,
    bool alwaysOnEnabled = false,
    bool splitTunnelingEnabled = false,
    List<String> splitTunnelingApps = const [],
  }) async {
    final config = HysteriaConfig(
      auth: auth,
      alpn: alpn,
      sni: sni,
      obfs: obfs,
    );

    return await addProfile(
      name: name,
      protocol: VPNProtocol.hysteria,
      server: server,
      port: port,
      config: config.toJson(),
      killSwitchEnabled: killSwitchEnabled,
      alwaysOnEnabled: alwaysOnEnabled,
      splitTunnelingEnabled: splitTunnelingEnabled,
      splitTunnelingApps: splitTunnelingApps,
    );
  }

  Future<void> _loadProfiles() async {
    try {
      final file = await _getProfilesFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        _profiles.clear();
        _profiles.addAll(jsonList.map((json) => VPNConfig.fromJson(json)));
      }
    } catch (e) {
      print('Error loading profiles: $e');
    }
  }

  Future<void> _saveProfiles() async {
    try {
      final file = await _getProfilesFile();
      final jsonList = _profiles.map((profile) => profile.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      print('Error saving profiles: $e');
    }
  }

  Future<void> _loadSubscriptions() async {
    try {
      final file = await _getSubscriptionsFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        _subscriptions.clear();
        _subscriptions.addAll(jsonList.map((json) => Subscription.fromJson(json)));
      }
    } catch (e) {
      print('Error loading subscriptions: $e');
    }
  }

  Future<void> _saveSubscriptions() async {
    try {
      final file = await _getSubscriptionsFile();
      final jsonList = _subscriptions.map((sub) => sub.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      print('Error saving subscriptions: $e');
    }
  }

  Future<File> _getProfilesFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/kensei_tunnel_profiles.json');
  }

  Future<File> _getSubscriptionsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/kensei_tunnel_subscriptions.json');
  }
}


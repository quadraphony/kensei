import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// Define the native library
final DynamicLibrary _lib = Platform.isAndroid
    ? DynamicLibrary.open('libsing_box.so')
    : Platform.isIOS
        ? DynamicLibrary.process()
        : Platform.isWindows
            ? DynamicLibrary.open('libsing_box.dll')
            : DynamicLibrary.open('./native/libsing_box.so');

// Define function signatures
typedef StartVPNNative = Pointer<Utf8> Function(Pointer<Utf8> configJSON);
typedef StartVPNDart = Pointer<Utf8> Function(Pointer<Utf8> configJSON);

typedef StopVPNNative = Pointer<Utf8> Function();
typedef StopVPNDart = Pointer<Utf8> Function();

typedef GetVPNStatusNative = Pointer<Utf8> Function();
typedef GetVPNStatusDart = Pointer<Utf8> Function();

typedef FetchSubscriptionNative = Pointer<Utf8> Function(Pointer<Utf8> subscriptionURL);
typedef FetchSubscriptionDart = Pointer<Utf8> Function(Pointer<Utf8> subscriptionURL);

typedef CreateVMessConfigNative = Pointer<Utf8> Function(
  Pointer<Utf8> server,
  Pointer<Utf8> port,
  Pointer<Utf8> uuid,
  Pointer<Utf8> security,
  Pointer<Utf8> alterID,
  Pointer<Utf8> network,
  Pointer<Utf8> path,
  Pointer<Utf8> host,
  Pointer<Utf8> tls,
  Pointer<Utf8> sni,
  Pointer<Utf8> tag,
);
typedef CreateVMessConfigDart = Pointer<Utf8> Function(
  Pointer<Utf8> server,
  Pointer<Utf8> port,
  Pointer<Utf8> uuid,
  Pointer<Utf8> security,
  Pointer<Utf8> alterID,
  Pointer<Utf8> network,
  Pointer<Utf8> path,
  Pointer<Utf8> host,
  Pointer<Utf8> tls,
  Pointer<Utf8> sni,
  Pointer<Utf8> tag,
);

typedef CreateTrojanConfigNative = Pointer<Utf8> Function(
  Pointer<Utf8> server,
  Pointer<Utf8> port,
  Pointer<Utf8> password,
  Pointer<Utf8> sni,
  Pointer<Utf8> network,
  Pointer<Utf8> path,
  Pointer<Utf8> host,
  Pointer<Utf8> tag,
);
typedef CreateTrojanConfigDart = Pointer<Utf8> Function(
  Pointer<Utf8> server,
  Pointer<Utf8> port,
  Pointer<Utf8> password,
  Pointer<Utf8> sni,
  Pointer<Utf8> network,
  Pointer<Utf8> path,
  Pointer<Utf8> host,
  Pointer<Utf8> tag,
);

typedef CreateVLESSConfigNative = Pointer<Utf8> Function(
  Pointer<Utf8> server,
  Pointer<Utf8> port,
  Pointer<Utf8> uuid,
  Pointer<Utf8> flow,
  Pointer<Utf8> security,
  Pointer<Utf8> sni,
  Pointer<Utf8> network,
  Pointer<Utf8> path,
  Pointer<Utf8> host,
  Pointer<Utf8> tag,
);
typedef CreateVLESSConfigDart = Pointer<Utf8> Function(
  Pointer<Utf8> server,
  Pointer<Utf8> port,
  Pointer<Utf8> uuid,
  Pointer<Utf8> flow,
  Pointer<Utf8> security,
  Pointer<Utf8> sni,
  Pointer<Utf8> network,
  Pointer<Utf8> path,
  Pointer<Utf8> host,
  Pointer<Utf8> tag,
);

typedef CreateShadowsocksConfigNative = Pointer<Utf8> Function(
  Pointer<Utf8> server,
  Pointer<Utf8> port,
  Pointer<Utf8> method,
  Pointer<Utf8> password,
  Pointer<Utf8> tag,
);
typedef CreateShadowsocksConfigDart = Pointer<Utf8> Function(
  Pointer<Utf8> server,
  Pointer<Utf8> port,
  Pointer<Utf8> method,
  Pointer<Utf8> password,
  Pointer<Utf8> tag,
);

typedef CreateWireGuardConfigNative = Pointer<Utf8> Function(
  Pointer<Utf8> server,
  Pointer<Utf8> port,
  Pointer<Utf8> privateKey,
  Pointer<Utf8> peerPublicKey,
  Pointer<Utf8> localAddress,
  Pointer<Utf8> tag,
);
typedef CreateWireGuardConfigDart = Pointer<Utf8> Function(
  Pointer<Utf8> server,
  Pointer<Utf8> port,
  Pointer<Utf8> privateKey,
  Pointer<Utf8> peerPublicKey,
  Pointer<Utf8> localAddress,
  Pointer<Utf8> tag,
);

typedef CreateTUICConfigNative = Pointer<Utf8> Function(
  Pointer<Utf8> server,
  Pointer<Utf8> port,
  Pointer<Utf8> uuid,
  Pointer<Utf8> password,
  Pointer<Utf8> alpn,
  Pointer<Utf8> sni,
  Pointer<Utf8> tag,
);
typedef CreateTUICConfigDart = Pointer<Utf8> Function(
  Pointer<Utf8> server,
  Pointer<Utf8> port,
  Pointer<Utf8> uuid,
  Pointer<Utf8> password,
  Pointer<Utf8> alpn,
  Pointer<Utf8> sni,
  Pointer<Utf8> tag,
);

typedef CreateHysteriaConfigNative = Pointer<Utf8> Function(
  Pointer<Utf8> server,
  Pointer<Utf8> port,
  Pointer<Utf8> auth,
  Pointer<Utf8> alpn,
  Pointer<Utf8> sni,
  Pointer<Utf8> obfs,
  Pointer<Utf8> tag,
);
typedef CreateHysteriaConfigDart = Pointer<Utf8> Function(
  Pointer<Utf8> server,
  Pointer<Utf8> port,
  Pointer<Utf8> auth,
  Pointer<Utf8> alpn,
  Pointer<Utf8> sni,
  Pointer<Utf8> obfs,
  Pointer<Utf8> tag,
);

typedef FreeStringNative = Void Function(Pointer<Utf8> str);
typedef FreeStringDart = void Function(Pointer<Utf8> str);

// Bind functions
final StartVPNDart startVPN = _lib.lookupFunction<StartVPNNative, StartVPNDart>('StartVPN');
final StopVPNDart stopVPN = _lib.lookupFunction<StopVPNNative, StopVPNDart>('StopVPN');
final GetVPNStatusDart getVPNStatus = _lib.lookupFunction<GetVPNStatusNative, GetVPNStatusDart>('GetVPNStatus');
final FetchSubscriptionDart fetchSubscription = _lib.lookupFunction<FetchSubscriptionNative, FetchSubscriptionDart>('FetchSubscription');

final CreateVMessConfigDart createVMessConfig = _lib.lookupFunction<CreateVMessConfigNative, CreateVMessConfigDart>('CreateVMessConfig');
final CreateTrojanConfigDart createTrojanConfig = _lib.lookupFunction<CreateTrojanConfigNative, CreateTrojanConfigDart>('CreateTrojanConfig');
final CreateVLESSConfigDart createVLESSConfig = _lib.lookupFunction<CreateVLESSConfigNative, CreateVLESSConfigDart>('CreateVLESSConfig');
final CreateShadowsocksConfigDart createShadowsocksConfig = _lib.lookupFunction<CreateShadowsocksConfigNative, CreateShadowsocksConfigDart>('CreateShadowsocksConfig');
final CreateWireGuardConfigDart createWireGuardConfig = _lib.lookupFunction<CreateWireGuardConfigNative, CreateWireGuardConfigDart>('CreateWireGuardConfig');
final CreateTUICConfigDart createTUICConfig = _lib.lookupFunction<CreateTUICConfigNative, CreateTUICConfigDart>('CreateTUICConfig');
final CreateHysteriaConfigDart createHysteriaConfig = _lib.lookupFunction<CreateHysteriaConfigNative, CreateHysteriaConfigDart>('CreateHysteriaConfig');

final FreeStringDart freeString = _lib.lookupFunction<FreeStringNative, FreeStringDart>('FreeString');

// Helper functions
String pointerToString(Pointer<Utf8> ptr) {
  final result = ptr.toDartString();
  freeString(ptr);
  return result;
}

class SingBoxBindings {
  static String startVPNConnection(String configJSON) {
    final configPtr = configJSON.toNativeUtf8();
    final resultPtr = startVPN(configPtr);
    final result = pointerToString(resultPtr);
    malloc.free(configPtr);
    return result;
  }

  static String stopVPNConnection() {
    final resultPtr = stopVPN();
    return pointerToString(resultPtr);
  }

  static String getConnectionStatus() {
    final resultPtr = getVPNStatus();
    return pointerToString(resultPtr);
  }

  static String fetchSubscriptionConfigs(String subscriptionURL) {
    final urlPtr = subscriptionURL.toNativeUtf8();
    final resultPtr = fetchSubscription(urlPtr);
    final result = pointerToString(resultPtr);
    malloc.free(urlPtr);
    return result;
  }

  static String createVMessConfiguration({
    required String server,
    required String port,
    required String uuid,
    required String security,
    required String alterID,
    required String network,
    required String path,
    required String host,
    required String tls,
    required String sni,
    required String tag,
  }) {
    final serverPtr = server.toNativeUtf8();
    final portPtr = port.toNativeUtf8();
    final uuidPtr = uuid.toNativeUtf8();
    final securityPtr = security.toNativeUtf8();
    final alterIDPtr = alterID.toNativeUtf8();
    final networkPtr = network.toNativeUtf8();
    final pathPtr = path.toNativeUtf8();
    final hostPtr = host.toNativeUtf8();
    final tlsPtr = tls.toNativeUtf8();
    final sniPtr = sni.toNativeUtf8();
    final tagPtr = tag.toNativeUtf8();

    final resultPtr = createVMessConfig(
      serverPtr, portPtr, uuidPtr, securityPtr, alterIDPtr,
      networkPtr, pathPtr, hostPtr, tlsPtr, sniPtr, tagPtr,
    );

    final result = pointerToString(resultPtr);

    malloc.free(serverPtr);
    malloc.free(portPtr);
    malloc.free(uuidPtr);
    malloc.free(securityPtr);
    malloc.free(alterIDPtr);
    malloc.free(networkPtr);
    malloc.free(pathPtr);
    malloc.free(hostPtr);
    malloc.free(tlsPtr);
    malloc.free(sniPtr);
    malloc.free(tagPtr);

    return result;
  }

  static String createTrojanConfiguration({
    required String server,
    required String port,
    required String password,
    required String sni,
    required String network,
    required String path,
    required String host,
    required String tag,
  }) {
    final serverPtr = server.toNativeUtf8();
    final portPtr = port.toNativeUtf8();
    final passwordPtr = password.toNativeUtf8();
    final sniPtr = sni.toNativeUtf8();
    final networkPtr = network.toNativeUtf8();
    final pathPtr = path.toNativeUtf8();
    final hostPtr = host.toNativeUtf8();
    final tagPtr = tag.toNativeUtf8();

    final resultPtr = createTrojanConfig(
      serverPtr, portPtr, passwordPtr, sniPtr,
      networkPtr, pathPtr, hostPtr, tagPtr,
    );

    final result = pointerToString(resultPtr);

    malloc.free(serverPtr);
    malloc.free(portPtr);
    malloc.free(passwordPtr);
    malloc.free(sniPtr);
    malloc.free(networkPtr);
    malloc.free(pathPtr);
    malloc.free(hostPtr);
    malloc.free(tagPtr);

    return result;
  }

  static String createVLESSConfiguration({
    required String server,
    required String port,
    required String uuid,
    required String flow,
    required String security,
    required String sni,
    required String network,
    required String path,
    required String host,
    required String tag,
  }) {
    final serverPtr = server.toNativeUtf8();
    final portPtr = port.toNativeUtf8();
    final uuidPtr = uuid.toNativeUtf8();
    final flowPtr = flow.toNativeUtf8();
    final securityPtr = security.toNativeUtf8();
    final sniPtr = sni.toNativeUtf8();
    final networkPtr = network.toNativeUtf8();
    final pathPtr = path.toNativeUtf8();
    final hostPtr = host.toNativeUtf8();
    final tagPtr = tag.toNativeUtf8();

    final resultPtr = createVLESSConfig(
      serverPtr, portPtr, uuidPtr, flowPtr, securityPtr,
      sniPtr, networkPtr, pathPtr, hostPtr, tagPtr,
    );

    final result = pointerToString(resultPtr);

    malloc.free(serverPtr);
    malloc.free(portPtr);
    malloc.free(uuidPtr);
    malloc.free(flowPtr);
    malloc.free(securityPtr);
    malloc.free(sniPtr);
    malloc.free(networkPtr);
    malloc.free(pathPtr);
    malloc.free(hostPtr);
    malloc.free(tagPtr);

    return result;
  }

  static String createShadowsocksConfiguration({
    required String server,
    required String port,
    required String method,
    required String password,
    required String tag,
  }) {
    final serverPtr = server.toNativeUtf8();
    final portPtr = port.toNativeUtf8();
    final methodPtr = method.toNativeUtf8();
    final passwordPtr = password.toNativeUtf8();
    final tagPtr = tag.toNativeUtf8();

    final resultPtr = createShadowsocksConfig(
      serverPtr, portPtr, methodPtr, passwordPtr, tagPtr,
    );

    final result = pointerToString(resultPtr);

    malloc.free(serverPtr);
    malloc.free(portPtr);
    malloc.free(methodPtr);
    malloc.free(passwordPtr);
    malloc.free(tagPtr);

    return result;
  }

  static String createWireGuardConfiguration({
    required String server,
    required String port,
    required String privateKey,
    required String peerPublicKey,
    required String localAddress,
    required String tag,
  }) {
    final serverPtr = server.toNativeUtf8();
    final portPtr = port.toNativeUtf8();
    final privateKeyPtr = privateKey.toNativeUtf8();
    final peerPublicKeyPtr = peerPublicKey.toNativeUtf8();
    final localAddressPtr = localAddress.toNativeUtf8();
    final tagPtr = tag.toNativeUtf8();

    final resultPtr = createWireGuardConfig(
      serverPtr, portPtr, privateKeyPtr, peerPublicKeyPtr,
      localAddressPtr, tagPtr,
    );

    final result = pointerToString(resultPtr);

    malloc.free(serverPtr);
    malloc.free(portPtr);
    malloc.free(privateKeyPtr);
    malloc.free(peerPublicKeyPtr);
    malloc.free(localAddressPtr);
    malloc.free(tagPtr);

    return result;
  }

  static String createTUICConfiguration({
    required String server,
    required String port,
    required String uuid,
    required String password,
    required String alpn,
    required String sni,
    required String tag,
  }) {
    final serverPtr = server.toNativeUtf8();
    final portPtr = port.toNativeUtf8();
    final uuidPtr = uuid.toNativeUtf8();
    final passwordPtr = password.toNativeUtf8();
    final alpnPtr = alpn.toNativeUtf8();
    final sniPtr = sni.toNativeUtf8();
    final tagPtr = tag.toNativeUtf8();

    final resultPtr = createTUICConfig(
      serverPtr, portPtr, uuidPtr, passwordPtr,
      alpnPtr, sniPtr, tagPtr,
    );

    final result = pointerToString(resultPtr);

    malloc.free(serverPtr);
    malloc.free(portPtr);
    malloc.free(uuidPtr);
    malloc.free(passwordPtr);
    malloc.free(alpnPtr);
    malloc.free(sniPtr);
    malloc.free(tagPtr);

    return result;
  }

  static String createHysteriaConfiguration({
    required String server,
    required String port,
    required String auth,
    required String alpn,
    required String sni,
    required String obfs,
    required String tag,
  }) {
    final serverPtr = server.toNativeUtf8();
    final portPtr = port.toNativeUtf8();
    final authPtr = auth.toNativeUtf8();
    final alpnPtr = alpn.toNativeUtf8();
    final sniPtr = sni.toNativeUtf8();
    final obfsPtr = obfs.toNativeUtf8();
    final tagPtr = tag.toNativeUtf8();

    final resultPtr = createHysteriaConfig(
      serverPtr, portPtr, authPtr, alpnPtr,
      sniPtr, obfsPtr, tagPtr,
    );

    final result = pointerToString(resultPtr);

    malloc.free(serverPtr);
    malloc.free(portPtr);
    malloc.free(authPtr);
    malloc.free(alpnPtr);
    malloc.free(sniPtr);
    malloc.free(obfsPtr);
    malloc.free(tagPtr);

    return result;
  }
}


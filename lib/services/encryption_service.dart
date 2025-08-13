import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final Random _random = Random.secure();

  // AES-256-GCM Encryption
  Map<String, dynamic> encryptAES256GCM(String plaintext, String password) {
    final key = _deriveKey(password, 32);
    final iv = _generateRandomBytes(12); // 96-bit IV for GCM
    final aad = utf8.encode('kensei-tunnel-aad');

    final cipher = GCMBlockCipher(AESEngine());
    final params = AEADParameters(
      KeyParameter(key),
      128, // 128-bit tag
      iv,
      aad,
    );

    cipher.init(true, params);

    final plaintextBytes = utf8.encode(plaintext);
    final ciphertext = cipher.process(plaintextBytes);

    return {
      'ciphertext': base64.encode(ciphertext),
      'iv': base64.encode(iv),
      'tag': base64.encode(cipher.mac ?? Uint8List(0)), // Handle potential null mac
      'algorithm': 'AES-256-GCM',
    };
  }

  String decryptAES256GCM(Map<String, dynamic> encryptedData, String password) {
    final key = _deriveKey(password, 32);
    final iv = base64.decode(encryptedData['iv']);
    final ciphertext = base64.decode(encryptedData['ciphertext']);
    final tag = base64.decode(encryptedData['tag']);
    final aad = utf8.encode('kensei-tunnel-aad');

    final cipher = GCMBlockCipher(AESEngine());
    final params = AEADParameters(
      KeyParameter(key),
      128,
      iv,
      aad,
    );

    cipher.init(false, params);

    // Combine ciphertext and tag for decryption
    final combined = Uint8List.fromList([...ciphertext, ...tag]);
    final decrypted = cipher.process(combined);

    return utf8.decode(decrypted);
  }

  // ChaCha20-Poly1305 Encryption
  Map<String, dynamic> encryptChaCha20Poly1305(String plaintext, String password) {
    final key = _deriveKey(password, 32);
    final nonce = _generateRandomBytes(12);
    final aad = utf8.encode('kensei-tunnel-aad');

    final cipher = ChaCha20Poly1305(key);
    final plaintextBytes = utf8.encode(plaintext);
    final result = cipher.encrypt(nonce, plaintextBytes, aad);

    return {
      'ciphertext': base64.encode(result.sublist(0, result.length - 16)),
      'nonce': base64.encode(nonce),
      'tag': base64.encode(result.sublist(result.length - 16)),
      'algorithm': 'ChaCha20-Poly1305',
    };
  }

  String decryptChaCha20Poly1305(Map<String, dynamic> encryptedData, String password) {
    final key = _deriveKey(password, 32);
    final nonce = base64.decode(encryptedData['nonce']);
    final ciphertext = base64.decode(encryptedData['ciphertext']);
    final tag = base64.decode(encryptedData['tag']);
    final aad = utf8.encode('kensei-tunnel-aad');

    final cipher = ChaCha20Poly1305(key);
    final combined = Uint8List.fromList([...ciphertext, ...tag]);
    final decrypted = cipher.decrypt(nonce, combined, aad);

    return utf8.decode(decrypted);
  }

  // RSA Key Generation and Encryption
  Map<String, String> generateRSAKeyPair({int keySize = 2048}) {
    final keyGen = RSAKeyGenerator();
    final secureRandom = FortunaRandom();
    
    // Seed the random number generator
    final seedSource = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      seedSource[i] = _random.nextInt(256);
    }
    secureRandom.seed(KeyParameter(seedSource));

    final params = RSAKeyGeneratorParameters(
      BigInt.parse('65537'), // Standard public exponent
      keySize,
      64, // Certainty for prime generation
    );

    keyGen.init(ParametersWithRandom(params, secureRandom));
    final keyPair = keyGen.generateKeyPair();

    final publicKey = keyPair.publicKey as RSAPublicKey;
    final privateKey = keyPair.privateKey as RSAPrivateKey;

    return {
      'publicKey': _encodeRSAPublicKey(publicKey),
      'privateKey': _encodeRSAPrivateKey(privateKey),
    };
  }

  String encryptRSA(String plaintext, String publicKeyPem) {
    final publicKey = _decodeRSAPublicKey(publicKeyPem);
    final cipher = OAEPEncoding(RSAEngine());
    cipher.init(true, PublicKeyParameter<RSAPublicKey>(publicKey));

    final plaintextBytes = utf8.encode(plaintext);
    final encrypted = cipher.process(plaintextBytes);

    return base64.encode(encrypted);
  }

  String decryptRSA(String ciphertext, String privateKeyPem) {
    final privateKey = _decodeRSAPrivateKey(privateKeyPem);
    final cipher = OAEPEncoding(RSAEngine());
    cipher.init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));

    final ciphertextBytes = base64.decode(ciphertext);
    final decrypted = cipher.process(ciphertextBytes);

    return utf8.decode(decrypted);
  }

  // Digital Signatures
  String signData(String data, String privateKeyPem) {
    final privateKey = _decodeRSAPrivateKey(privateKeyPem);
    final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));

    final dataBytes = utf8.encode(data);
    final signature = signer.generateSignature(dataBytes);

    return base64.encode(signature.bytes);
  }

  bool verifySignature(String data, String signature, String publicKeyPem) {
    try {
      final publicKey = _decodeRSAPublicKey(publicKeyPem);
      final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
      signer.init(false, PublicKeyParameter<RSAPublicKey>(publicKey));

      final dataBytes = utf8.encode(data);
      final signatureBytes = base64.decode(signature);
      final rsaSignature = RSASignature(signatureBytes);

      return signer.verifySignature(dataBytes, rsaSignature);
    } catch (e) {
      return false;
    }
  }

  // Key Derivation
  Uint8List _deriveKey(String password, int keyLength) {
    final salt = utf8.encode('kensei-tunnel-salt-2024');
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    pbkdf2.init(Pbkdf2Parameters(salt, 100000, keyLength));

    return pbkdf2.process(utf8.encode(password));
  }

  // Random Bytes Generation
  Uint8List _generateRandomBytes(int length) {
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return bytes;
  }

  // Hash Functions
  String sha256Hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String sha512Hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha512.convert(bytes);
    return digest.toString();
  }

  String hmacSha256(String message, String key) {
    final keyBytes = utf8.encode(key);
    final messageBytes = utf8.encode(message);
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(messageBytes);
    return digest.toString();
  }

  // WireGuard Key Generation
  Map<String, String> generateWireGuardKeys() {
    final privateKey = _generateRandomBytes(32);
    final publicKey = _curve25519ScalarMult(privateKey, _curve25519BasePoint());

    return {
      'privateKey': base64.encode(privateKey),
      'publicKey': base64.encode(publicKey),
    };
  }

  // Curve25519 operations for WireGuard
  Uint8List _curve25519BasePoint() {
    final basePoint = Uint8List(32);
    basePoint[0] = 9;
    return basePoint;
  }

  Uint8List _curve25519ScalarMult(Uint8List scalar, Uint8List point) {
    // Simplified implementation - in production, use a proper Curve25519 library
    final result = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      result[i] = (scalar[i] ^ point[i % point.length]) & 0xFF;
    }
    return result;
  }

  // RSA Key Encoding/Decoding
  String _encodeRSAPublicKey(RSAPublicKey publicKey) {
    final modulus = publicKey.modulus!;
    final exponent = publicKey.exponent!;
    
    // Simple PEM-like encoding
    final keyData = {
      'modulus': modulus.toString(),
      'exponent': exponent.toString(),
    };
    
    final encoded = base64.encode(utf8.encode(jsonEncode(keyData)));
    return '-----BEGIN PUBLIC KEY-----\n$encoded\n-----END PUBLIC KEY-----\n';
  }

  String _encodeRSAPrivateKey(RSAPrivateKey privateKey) {
    final modulus = privateKey.modulus!;
    final exponent = privateKey.exponent!;
    final p = privateKey.p!;
    final q = privateKey.q!;
    
    final keyData = {
      'modulus': modulus.toString(),
      'exponent': exponent.toString(),
      'p': p.toString(),
      'q': q.toString(),
    };
    
    final encoded = base64.encode(utf8.encode(jsonEncode(keyData)));
    return '-----BEGIN PRIVATE KEY-----\n$encoded\n-----END PRIVATE KEY-----\n';
  }

  RSAPublicKey _decodeRSAPublicKey(String pem) {
    final cleaned = pem
        .replaceAll('-----BEGIN PUBLIC KEY-----', '')
        .replaceAll('-----END PUBLIC KEY-----', '')
        .replaceAll('\n', '');
    
    final decoded = utf8.decode(base64.decode(cleaned));
    final keyData = jsonDecode(decoded) as Map<String, dynamic>;
    
    final modulus = BigInt.parse(keyData['modulus']);
    final exponent = BigInt.parse(keyData['exponent']);
    
    return RSAPublicKey(modulus, exponent);
  }

  RSAPrivateKey _decodeRSAPrivateKey(String pem) {
    final cleaned = pem
        .replaceAll('-----BEGIN PRIVATE KEY-----', '')
        .replaceAll('-----END PRIVATE KEY-----', '')
        .replaceAll('\n', '');
    
    final decoded = utf8.decode(base64.decode(cleaned));
    final keyData = jsonDecode(decoded) as Map<String, dynamic>;
    
    final modulus = BigInt.parse(keyData['modulus']);
    final exponent = BigInt.parse(keyData['exponent']);
    final p = BigInt.parse(keyData['p']);
    final q = BigInt.parse(keyData['q']);
    
    return RSAPrivateKey(modulus, exponent, p, q);
  }

  // Secure Random String Generation
  String generateSecureRandomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(_random.nextInt(chars.length)),
      ),
    );
  }

  // UUID Generation
  String generateUUID() {
    final bytes = _generateRandomBytes(16);
    
    // Set version (4) and variant bits
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
    
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  // Password Strength Validation
  Map<String, dynamic> validatePasswordStrength(String password) {
    final result = {
      'score': 0,
      'strength': 'Very Weak',
      'suggestions': <String>[],
    };

    if (password.length < 8) {
      result['suggestions'].add('Use at least 8 characters');
    } else {
      result['score'] = (result['score'] as int) + 1;
    }

    if (password.contains(RegExp(r'[a-z]'))) {
      result['score'] = (result['score'] as int) + 1;
    } else {
      result['suggestions'].add('Include lowercase letters');
    }

    if (password.contains(RegExp(r'[A-Z]'))) {
      result['score'] = (result['score'] as int) + 1;
    } else {
      result['suggestions'].add('Include uppercase letters');
    }

    if (password.contains(RegExp(r'[0-9]'))) {
      result['score'] = (result['score'] as int) + 1;
    } else {
      result['suggestions'].add('Include numbers');
    }

    if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_]'))) {
      result['score'] = (result['score'] as int) + 1;
    } else {
      result['suggestions'].add('Include special characters');
    }

    if (password.length >= 12) {
      result['score'] = (result['score'] as int) + 1;
    }

    final score = result['score'] as int;
    if (score >= 5) {
      result['strength'] = 'Very Strong';
    } else if (score >= 4) {
      result['strength'] = 'Strong';
    } else if (score >= 3) {
      result['strength'] = 'Medium';
    } else if (score >= 2) {
      result['strength'] = 'Weak';
    }

    return result;
  }

  // Secure Configuration Validation
  List<String> validateSecurityConfiguration(Map<String, dynamic> config) {
    final issues = <String>[];

    // Check encryption method
    final method = config['method']?.toString().toLowerCase();
    if (method != null) {
      final weakMethods = ['rc4', 'des', 'md5', 'none'];
      if (weakMethods.any((weak) => method.contains(weak))) {
        issues.add('Weak encryption method detected: $method');
      }
    }

    // Check password strength
    final password = config['password']?.toString();
    if (password != null) {
      final strength = validatePasswordStrength(password);
      if ((strength['score'] as int) < 3) {
        issues.add('Weak password detected');
      }
    }

    // Check TLS configuration
    if (config['tls'] == false) {
      issues.add('TLS encryption is disabled');
    }

    // Check for default credentials
    final commonPasswords = ['password', '123456', 'admin', 'root'];
    if (password != null && commonPasswords.contains(password.toLowerCase())) {
      issues.add('Default or common password detected');
    }

    // Check key lengths
    final keyLength = config['key_length'] as int?;
    if (keyLength != null && keyLength < 256) {
      issues.add('Key length too short: $keyLength bits');
    }

    return issues;
  }
}

// ChaCha20-Poly1305 Implementation
class ChaCha20Poly1305 {
  final Uint8List _key;

  ChaCha20Poly1305(this._key);

  Uint8List encrypt(Uint8List nonce, Uint8List plaintext, Uint8List aad) {
    // Simplified implementation - in production, use a proper ChaCha20-Poly1305 library
    final encrypted = Uint8List(plaintext.length);
    for (int i = 0; i < plaintext.length; i++) {
      encrypted[i] = plaintext[i] ^ _key[i % _key.length] ^ nonce[i % nonce.length];
    }
    
    // Generate authentication tag
    final tag = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      tag[i] = (encrypted.fold(0, (a, b) => a ^ b) ^ aad.fold(0, (a, b) => a ^ b)) & 0xFF;
    }
    
    return Uint8List.fromList([...encrypted, ...tag]);
  }

  Uint8List decrypt(Uint8List nonce, Uint8List ciphertext, Uint8List aad) {
    final encrypted = ciphertext.sublist(0, ciphertext.length - 16);
    final tag = ciphertext.sublist(ciphertext.length - 16);
    
    // Verify authentication tag
    final expectedTag = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      expectedTag[i] = (encrypted.fold(0, (a, b) => a ^ b) ^ aad.fold(0, (a, b) => a ^ b)) & 0xFF;
    }
    
    bool tagValid = true;
    for (int i = 0; i < 16; i++) {
      if (tag[i] != expectedTag[i]) {
        tagValid = false;
        break;
      }
    }
    
    if (!tagValid) {
      throw Exception('Authentication tag verification failed');
    }
    
    final decrypted = Uint8List(encrypted.length);
    for (int i = 0; i < encrypted.length; i++) {
      decrypted[i] = encrypted[i] ^ _key[i % _key.length] ^ nonce[i % nonce.length];
    }
    
    return decrypted;
  }
}



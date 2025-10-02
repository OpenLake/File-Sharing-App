import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/export.dart';
import 'package:crypto/crypto.dart';

/// Service for handling end-to-end encryption of files
/// Uses AES-256-GCM for symmetric encryption with ECDH for key exchange
class EncryptionService {
  static const int keySize = 32; // 256 bits for AES-256
  static const int ivSize = 16; // 128 bits for GCM mode

  /// Generates a secure random AES key
  static Key generateKey() {
    final secureRandom = FortunaRandom();
    final seedSource = SecureRandom();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(256));
    }
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    final keyBytes = secureRandom.nextBytes(keySize);
    return Key(keyBytes);
  }

  /// Generates a secure random IV (Initialization Vector)
  static IV generateIV() {
    final secureRandom = FortunaRandom();
    final seedSource = SecureRandom();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(256));
    }
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    final ivBytes = secureRandom.nextBytes(ivSize);
    return IV(ivBytes);
  }

  /// Encrypts file data using AES-256-GCM
  /// Returns a map containing encrypted bytes, IV, and key for decryption
  static Map<String, dynamic> encryptFile(Uint8List fileBytes) {
    final key = generateKey();
    final iv = generateIV();

    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);

    return {
      'encryptedBytes': encrypted.bytes,
      'iv': iv.base64,
      'key': key.base64,
      'algorithm': 'AES-256-GCM',
    };
  }

  /// Decrypts file data using AES-256-GCM
  /// Requires the encrypted bytes, IV, and key
  static Uint8List decryptFile(
    Uint8List encryptedBytes,
    String ivBase64,
    String keyBase64,
  ) {
    final key = Key.fromBase64(keyBase64);
    final iv = IV.fromBase64(ivBase64);

    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    final encrypted = Encrypted(encryptedBytes);
    
    final decryptedBytes = encrypter.decryptBytes(encrypted, iv: iv);
    return Uint8List.fromList(decryptedBytes);
  }

  /// Generates ECDH key pair for secure key exchange
  /// Uses P-256 (secp256r1) curve
  static AsymmetricKeyPair<PublicKey, PrivateKey> generateECDHKeyPair() {
    final keyParams = ECKeyGeneratorParameters(ECCurve_secp256r1());
    
    final secureRandom = FortunaRandom();
    final seedSource = SecureRandom();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(256));
    }
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    final keyGenerator = KeyGenerator('EC')
      ..init(ParametersWithRandom(keyParams, secureRandom));

    final keyPair = keyGenerator.generateKeyPair();
    return keyPair;
  }

  /// Derives a shared secret from ECDH key exchange
  /// This can be used to encrypt the AES key for transmission
  static Uint8List deriveSharedSecret(
    ECPrivateKey privateKey,
    ECPublicKey publicKey,
  ) {
    final agreement = ECDHBasicAgreement();
    agreement.init(privateKey);
    final sharedSecret = agreement.calculateAgreement(publicKey);
    
    // Convert BigInt to bytes
    final bytes = _encodeBigInt(sharedSecret);
    
    // Use SHA-256 to derive a consistent-length key
    final digest = sha256.convert(bytes);
    return Uint8List.fromList(digest.bytes);
  }

  /// Helper method to encode BigInt to bytes
  static Uint8List _encodeBigInt(BigInt number) {
    final size = (number.bitLength + 7) >> 3;
    final result = Uint8List(size);
    for (int i = 0; i < size; i++) {
      result[size - i - 1] = (number & BigInt.from(0xff)).toInt();
      number = number >> 8;
    }
    return result;
  }

  /// Generates a hash of the file for integrity verification
  static String generateFileHash(Uint8List fileBytes) {
    final digest = sha256.convert(fileBytes);
    return digest.toString();
  }

  /// Creates encryption metadata to be stored alongside the encrypted file
  static Map<String, dynamic> createMetadata({
    required String iv,
    required String key,
    required String originalFilename,
    required String fileHash,
    required int originalSize,
  }) {
    return {
      'version': '1.0',
      'algorithm': 'AES-256-GCM',
      'iv': iv,
      'key': key,
      'originalFilename': originalFilename,
      'fileHash': fileHash,
      'originalSize': originalSize,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Parses encryption metadata
  static Map<String, dynamic> parseMetadata(String jsonString) {
    return json.decode(jsonString) as Map<String, dynamic>;
  }

  /// Serializes encryption metadata to JSON
  static String serializeMetadata(Map<String, dynamic> metadata) {
    return json.encode(metadata);
  }
}

/// Secure random number generator implementation
class SecureRandom {
  final _generator = FortunaRandom();
  bool _initialized = false;

  int nextInt(int max) {
    if (!_initialized) {
      _initializeGenerator();
    }
    // Generate random bytes and convert to int
    final bytes = _generator.nextBytes(4);
    final value = (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
    return value.abs() % max;
  }

  void _initializeGenerator() {
    final seeds = <int>[];
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Use timestamp as part of seed
    for (int i = 0; i < 8; i++) {
      seeds.add((timestamp >> (i * 8)) & 0xff);
    }
    
    // Add more entropy from current time with different scales
    for (int i = 0; i < 24; i++) {
      seeds.add((DateTime.now().microsecondsSinceEpoch * (i + 1)) & 0xff);
    }

    _generator.seed(KeyParameter(Uint8List.fromList(seeds)));
    _initialized = true;
  }
}

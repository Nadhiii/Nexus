import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for securely storing sensitive card data locally.
/// CVV and other sensitive card details should NEVER be stored in cloud databases.
/// This service uses flutter_secure_storage which uses:
/// - iOS: Keychain
/// - Android: EncryptedSharedPreferences / Keystore
class SecureCardService {
  static final SecureCardService _instance = SecureCardService._internal();
  factory SecureCardService() => _instance;
  SecureCardService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Key format: cvv_{accountId}
  String _cvvKey(String accountId) => 'cvv_$accountId';

  // Key format: card_pin_{accountId}
  String _pinKey(String accountId) => 'card_pin_$accountId';

  /// Store CVV securely for an account
  Future<void> storeCvv(String accountId, String cvv) async {
    if (cvv.isEmpty) return;
    await _storage.write(key: _cvvKey(accountId), value: cvv);
  }

  /// Retrieve CVV for an account
  Future<String?> getCvv(String accountId) async {
    return await _storage.read(key: _cvvKey(accountId));
  }

  /// Delete CVV for an account (when account is deleted)
  Future<void> deleteCvv(String accountId) async {
    await _storage.delete(key: _cvvKey(accountId));
  }

  /// Store PIN securely for an account
  Future<void> storePin(String accountId, String pin) async {
    if (pin.isEmpty) return;
    await _storage.write(key: _pinKey(accountId), value: pin);
  }

  /// Retrieve PIN for an account
  Future<String?> getPin(String accountId) async {
    return await _storage.read(key: _pinKey(accountId));
  }

  /// Delete PIN for an account
  Future<void> deletePin(String accountId) async {
    await _storage.delete(key: _pinKey(accountId));
  }

  /// Delete all secure data for an account
  Future<void> deleteAllForAccount(String accountId) async {
    await Future.wait([deleteCvv(accountId), deletePin(accountId)]);
  }

  /// Check if CVV exists for an account
  Future<bool> hasCvv(String accountId) async {
    final cvv = await getCvv(accountId);
    return cvv != null && cvv.isNotEmpty;
  }

  /// Migrate existing CVV from Firestore to secure storage
  /// Call this once during app upgrade
  Future<void> migrateCvvFromFirestore(String accountId, String? cvv) async {
    if (cvv != null && cvv.isNotEmpty) {
      await storeCvv(accountId, cvv);
    }
  }
}

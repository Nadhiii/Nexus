import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages secure storage and retrieval of PDF passwords
class PDFPasswordManager {
  static const String _storageKey = 'pdf_passwords';
  static const _secureStorage = FlutterSecureStorage();

  /// Adds a password to saved passwords
  static Future<void> savePassword(String password) async {
    try {
      final passwords = await getSavedPasswords();

      // Avoid duplicates
      if (passwords.contains(password)) {
        return;
      }

      passwords.add(password);
      await _secureStorage.write(
        key: _storageKey,
        value: passwords.join('|||'), // Use delimiter to join passwords
      );
    } catch (e) {
      print('Error saving PDF password: $e');
    }
  }

  /// Retrieves all saved passwords
  static Future<List<String>> getSavedPasswords() async {
    try {
      final stored = await _secureStorage.read(key: _storageKey);
      if (stored == null || stored.isEmpty) {
        return [];
      }
      return stored.split('|||').where((p) => p.isNotEmpty).toList();
    } catch (e) {
      print('Error retrieving PDF passwords: $e');
      return [];
    }
  }

  /// Removes a specific password
  static Future<void> removePassword(String password) async {
    try {
      final passwords = await getSavedPasswords();
      passwords.removeWhere((p) => p == password);

      if (passwords.isEmpty) {
        await _secureStorage.delete(key: _storageKey);
      } else {
        await _secureStorage.write(
          key: _storageKey,
          value: passwords.join('|||'),
        );
      }
    } catch (e) {
      print('Error removing PDF password: $e');
    }
  }

  /// Clears all saved passwords
  static Future<void> clearAllPasswords() async {
    try {
      await _secureStorage.delete(key: _storageKey);
    } catch (e) {
      print('Error clearing PDF passwords: $e');
    }
  }

  /// Gets password count
  static Future<int> getPasswordCount() async {
    try {
      final passwords = await getSavedPasswords();
      return passwords.length;
    } catch (e) {
      print('Error getting password count: $e');
      return 0;
    }
  }

  /// Checks if any passwords are saved
  static Future<bool> hasPasswords() async {
    try {
      final count = await getPasswordCount();
      return count > 0;
    } catch (e) {
      print('Error checking if passwords exist: $e');
      return false;
    }
  }
}

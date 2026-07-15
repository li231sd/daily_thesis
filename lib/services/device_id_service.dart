import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// Generates and persists a random, anonymous identifier for this
/// install. Used as the `userId` key for push notification registration
/// until real account-based (Google Sign-In) sync is added — at that
/// point this ID can simply be swapped for the authenticated account ID
/// without changing the Worker's storage shape (`token:${userId}`).
class DeviceIdService {
  DeviceIdService._();

  static const _key = 'device_id_v1';

  /// Returns the existing device ID if one was already generated for
  /// this install, otherwise creates and persists a new one.
  static Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null && existing.isNotEmpty) return existing;

    final newId = _generate();
    await prefs.setString(_key, newId);
    return newId;
  }

  static String _generate() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));

    // Set version (4) and variant bits so it reads as a standard UUIDv4.
    // It isn't cryptographically tied to anything — it's just a stable
    // random label for this install.
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}

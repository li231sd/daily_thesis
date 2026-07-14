import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Must be a top-level function (not a class method) — FCM calls this
/// in a separate isolate when a push arrives while the app is fully
/// terminated (not just backgrounded).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background push received: ${message.messageId}');
}

/// Centralizes push notification setup: permission request, FCM token
/// retrieval, and displaying a banner when a push arrives while the
/// app is open (FCM doesn't do this automatically on Android).
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  static const _channel = AndroidNotificationChannel(
    'daily_thesis_default',
    'Daily Thesis Notifications',
    description: 'New paper recommendations and app updates',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    try {
      // iOS/Android 13+ requires explicit permission.
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('Notification permission: ${settings.authorizationStatus}');

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      await _localNotifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );

      _fcmToken = await _messaging.getToken();
      debugPrint('FCM token: $_fcmToken');

      // Token can rotate (e.g. app reinstall, token expiry) — re-sync
      // to your backend whenever that happens.
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('FCM token refreshed: $newToken');
        // TODO once cross-device sync (MongoDB) is in: send newToken
        // to the Worker so pushes keep reaching this device.
      });

      // Foreground messages don't show a system banner on Android by
      // default — display one manually via flutter_local_notifications.
      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}

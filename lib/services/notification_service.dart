import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

/// Handles Firebase Cloud Messaging (FCM) push notifications.
/// Must be initialised once at app startup after Firebase.initializeApp().
class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId = 'mottainai_channel';
  static const _channelName = 'Mottainai Notifications';

  /// Call once in main.dart after Firebase.initializeApp()
  static Future<void> initialize() async {
    // Request permission (iOS + Android 13+)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Local notifications setup
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );

    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Register FCM token with backend
    final token = await _messaging.getToken();
    if (token != null) {
      await ApiService.registerFcmToken(token);
    }

    // Refresh token when it changes
    _messaging.onTokenRefresh.listen((newToken) {
      ApiService.registerFcmToken(newToken);
    });

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }
}

/// Background message handler — must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are handled by the OS notification tray automatically.
  // Add any background processing logic here if needed.
}

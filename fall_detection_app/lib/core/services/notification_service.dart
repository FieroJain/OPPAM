import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.init();
  await NotificationService.showFallAlert(
    severity: message.data['severity'] ?? 'High',
    confidence: double.tryParse(message.data['confidence'] ?? '0') ?? 0.0,
  );
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
    await FirebaseMessaging.instance.subscribeToTopic('fall_alerts');
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showFallAlert(
        severity: message.data['severity'] ?? 'High',
        confidence: double.tryParse(message.data['confidence'] ?? '0') ?? 0.0,
      );
    });
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> showFallAlert({
    String severity = 'High',
    double confidence = 0.0,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'fall_alerts',
        'Fall Alerts',
        channelDescription: 'Alerts when a fall is detected',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
      ),
    );
    await _plugin.show(
      0,
      'Fall Detected!',
      'Severity: $severity | Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
      details,
    );
  }

  static Future<void> showSOSAlert() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'sos_alerts',
        'SOS Alerts',
        channelDescription: 'SOS emergency alerts',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
      ),
    );
    await _plugin.show(
      1,
      'SOS Alert!',
      'Patient pressed SOS - immediate assistance needed!',
      details,
    );
  }
}

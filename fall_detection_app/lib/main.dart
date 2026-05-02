import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'app.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDrEo1mUWDlaxYWvriNd7Ts6KQmEcrKfH0",
      appId: "1:796237246852:android:320d52cc6a09c53535add1",
      messagingSenderId: "796237246852",
      projectId: "fallproject01",
      databaseURL: "https://fallproject01-default-rtdb.asia-southeast1.firebasedatabase.app",
      storageBucket: "fallproject01.firebasestorage.app",
    ),
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.init();
  runApp(const FallDetectionApp());
}
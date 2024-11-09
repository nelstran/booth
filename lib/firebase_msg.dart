import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class FirebaseMsg {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // Request permission from users
    await _firebaseMessaging.requestPermission();
    
    // Fetch token from each user
    final fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $fcmToken');
  }

  void handleMessage(BuildContext context) {
    Navigator.pushNamed(context, '/main_ui_page');
  }

  Future<void> initPushNotifications(BuildContext context) async {
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) handleMessage(context);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handleMessage(context);
    });
  }
}

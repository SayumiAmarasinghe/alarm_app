import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';

// Import your screens
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/alarm_config_screen.dart';
import 'screens/challenge_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/ringing_screen.dart';

// Import the alarm service
import 'services/alarm_service.dart';

// 1. Create a global navigator key so the background service can force the app to navigate
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Ask for Android permissions
  if (Platform.isAndroid) {
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestExactAlarmsPermission();
  }

  // 1. Set up the tap listener (for when the phone is awake and you click the banner)
  final alarmService = AlarmService();
  await alarmService.init((String? payload) async {
    if (payload != null) {
      // Unpack the bundled payload
      List<String> data = payload.split('|');
      String alarmId = data[0];
      String mediaType = data.length > 1 ? data[1] : 'local';
      String mediaUri = data.length > 2 ? data[2] : '';

      // 🚨 FIX: Extract the boolean! (Defaults to true if something breaks)
      bool requiresMath = data.length > 3 ? data[3] == 'true' : true;

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => AlarmRingingScreen(
            alarmId: alarmId,
            requiresMathChallenge: requiresMath, // 🚨 FIX: Pass the dynamic boolean!
            mediaType: mediaType,
            mediaUri: mediaUri,
          ),
        ),
      );
    }
  });

  // 2. THE AUTO-WAKE FIX
  // Check if Android natively forced the app to boot up via the Full-Screen Intent
  final NotificationAppLaunchDetails? launchDetails = await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  if (launchDetails?.didNotificationLaunchApp ?? false) {
    final String? payload = launchDetails!.notificationResponse?.payload;
    if (payload != null) {
      // Unpack the bundled payload here too!
      List<String> data = payload.split('|');
      String alarmId = data[0];
      String mediaType = data.length > 1 ? data[1] : 'local';
      String mediaUri = data.length > 2 ? data[2] : '';

      // 🚨 FIX: Extract the boolean here too!
      bool requiresMath = data.length > 3 ? data[3] == 'true' : true;

      // Force the screen to route immediately without waiting for a click!
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => AlarmRingingScreen(
              alarmId: alarmId,
              requiresMathChallenge: requiresMath, // 🚨 FIX: Pass the dynamic boolean!
              mediaType: mediaType,
              mediaUri: mediaUri,
            ),
          ),
        );
      });
    }
  }

  runApp(const RiseRitualApp());
}

class RiseRitualApp extends StatelessWidget {
  const RiseRitualApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Attach the navigator key to your app
      title: 'SyncRise',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        primaryColor: const Color(0xFF7B52FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7B52FF),
          surface: Color(0xFF16161E),
        ),
        fontFamily: 'Inter',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/config': (context) => const AlarmConfigScreen(),
        '/challenge': (context) => const ChallengeScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
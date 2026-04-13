import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:typed_data';

class AlarmService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init(Function(String?) onAlarmFired) async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidInitSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const InitializationSettings initSettings = InitializationSettings(android: androidInitSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        onAlarmFired(response.payload);
      },
    );
  }

  Future<void> scheduleAlarm({
    required int id,
    required DateTime scheduledTime,
    required String payload,
    required bool isSpotify,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    // 🚨 BUMPED TO v4: Forces Android to create a fresh channel with the default system sound
    final String channelId = isSpotify
        ? 'rise_ritual_spotify_v1'
        : 'rise_ritual_alarms_v4';
    final bool shouldPlaySound = !isSpotify;

    await _notificationsPlugin.zonedSchedule(
      id,
      'SyncRise',
      'Wake up!',
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Alarms',
          channelDescription: 'High priority channel for wake-up alarms',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          playSound: shouldPlaySound,

          // We completely removed the custom "sound:" property here!
          // By leaving it blank, Android automatically defaults to the system ringtone.

          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          additionalFlags: shouldPlaySound ? Int32List.fromList(<int>[4]) : null,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }
}
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
    String repeatOption = 'Never', // 🚨 NEW PARAMETER
  }) async {
    final String channelId = isSpotify ? 'rise_ritual_spotify_v1' : 'rise_ritual_alarms_v4';
    final bool shouldPlaySound = !isSpotify;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        'Alarms',
        channelDescription: 'High priority channel for wake-up alarms',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
        playSound: shouldPlaySound,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        additionalFlags: shouldPlaySound ? Int32List.fromList(<int>[4]) : null,
      ),
    );

    // 1. Wipe the slate clean! Cancel any existing alarms tied to this Firebase ID
    // to prevent ghost alarms from ringing if the user changed the days.
    await _notificationsPlugin.cancel(id);
    for (int i = 1; i <= 7; i++) {
      await _notificationsPlugin.cancel(id + i);
    }

    // 2. Map the repeat options to Android's scheduling system
    List<int> targetDays = [];
    DateTimeComponents? matchComponents;

    if (repeatOption == 'Never') {
      targetDays = [scheduledTime.weekday]; // Rings once
      matchComponents = null;
    } else if (repeatOption == 'Everyday') {
      targetDays = [scheduledTime.weekday]; // Schedule once, OS repeats daily
      matchComponents = DateTimeComponents.time;
    } else if (repeatOption == 'Weekdays') {
      targetDays = [1, 2, 3, 4, 5]; // Mon - Fri
      matchComponents = DateTimeComponents.dayOfWeekAndTime;
    } else if (repeatOption == 'Weekends') {
      targetDays = [6, 7]; // Sat - Sun
      matchComponents = DateTimeComponents.dayOfWeekAndTime;
    } else {
      // Specific day like "Every Monday"
      matchComponents = DateTimeComponents.dayOfWeekAndTime;
      if (repeatOption == 'Every Monday') targetDays = [1];
      else if (repeatOption == 'Every Tuesday') targetDays = [2];
      else if (repeatOption == 'Every Wednesday') targetDays = [3];
      else if (repeatOption == 'Every Thursday') targetDays = [4];
      else if (repeatOption == 'Every Friday') targetDays = [5];
      else if (repeatOption == 'Every Saturday') targetDays = [6];
      else if (repeatOption == 'Every Sunday') targetDays = [7];
    }

    final now = DateTime.now();

    // 3. Loop through and schedule the exact required days
    for (int dayOfWeek in targetDays) {
      DateTime nextDate = DateTime(now.year, now.month, now.day, scheduledTime.hour, scheduledTime.minute);

      // Fast-forward to the correct day of the week
      while (nextDate.weekday != dayOfWeek || nextDate.isBefore(now)) {
        nextDate = nextDate.add(const Duration(days: 1));
      }

      // Generate a unique sub-ID so "Weekdays" can hold 5 separate alarms at once
      int notificationId = (targetDays.length == 1) ? id : id + dayOfWeek;

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        'SyncRise',
        'Wake up!',
        tz.TZDateTime.from(nextDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
        matchDateTimeComponents: matchComponents,
      );
    }
  }

  // 🚨 NEW HELPER: Call this from your main screen when a user deletes a toggle!
  Future<void> cancelAlarm(int baseId) async {
    await _notificationsPlugin.cancel(baseId);
    for (int i = 1; i <= 7; i++) {
      await _notificationsPlugin.cancel(baseId + i);
    }
  }
}
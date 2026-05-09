import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final StreamController<ReceivedAction> actionStream =
  StreamController<ReceivedAction>.broadcast();

  static Future<void> initializeNotification() async {
    await AwesomeNotifications().initialize(
      // 1. Ensure this exists in android/app/src/main/res/drawable
      // If it fails, try setting this to null temporarily to test
      'resource://drawable/launcher_icon',
      [
        NotificationChannel(
          channelKey: 'timer_channel',
          channelName: 'Study Timer',
          channelDescription: 'Ongoing study session notifications',
          defaultColor: const Color(0xFF6366F1),
          importance: NotificationImportance.Max,
          locked: true,
          // Added these to ensure visibility
          criticalAlerts: true,
          onlyAlertOnce: true,
        ),
        NotificationChannel(
          channelKey: 'reminders_channel',
          channelName: 'Task Reminders',
          channelDescription: 'Scheduled alerts for your goals',
          defaultColor: const Color(0xFF6366F1),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          criticalAlerts: true,
        ),
      ],
      debug: true, // ✅ Set this to true to see errors in your terminal!
    );

    // ✅ Listeners should be set after initialization is called
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
      onNotificationDisplayedMethod: onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: onDismissActionReceivedMethod,
    );
  }

  static Future<bool> requestPermission() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      // This will trigger the system dialog you are seeing
      isAllowed = await AwesomeNotifications().requestPermissionToSendNotifications();
    }
    return isAllowed;
  }

  // --- TIMER NOTIFICATIONS ---

  static Future<void> showIdleNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'timer_channel',
        title: 'Ready to Focus?',
        body: 'Select a category to start tracking.',
        category: NotificationCategory.Service,
        notificationLayout: NotificationLayout.Default,
        locked: true,
      ),
      actionButtons: [
        NotificationActionButton(key: 'START_Deep Work', label: '▶ Deep Work', color: Colors.green),
        NotificationActionButton(key: 'START_Coding', label: '▶ Coding', color: Colors.blue),
        NotificationActionButton(key: 'START_Reading', label: '▶ Reading', color: Colors.purple),
      ],
    );
  }

  static Future<void> showActiveNotification(String category, String time) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'timer_channel',
        title: '🔴 Tracking: $category',
        body: 'Time Elapsed: $time',
        category: NotificationCategory.Progress,
        notificationLayout: NotificationLayout.Default,
        locked: true,
        // Added this to prevent a "chirp" every second the timer updates
        payload: {'type': 'timer'},
      ),
      actionButtons: [
        NotificationActionButton(key: 'STOP_TIMER', label: 'Stop & Save', color: Colors.red),
      ],
    );
  }

  // --- REMINDER NOTIFICATIONS ---

  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required DateTime scheduledTime,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'reminders_channel',
        title: title,
        body: 'Time to crush your goals! 💪',
        category: NotificationCategory.Reminder,
        wakeUpScreen: true,
      ),
      schedule: NotificationCalendar.fromDate(
        date: scheduledTime,
        preciseAlarm: true,
        allowWhileIdle: true,
      ),
    );
  }

  // --- MANDATORY LISTENER METHODS ---

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    actionStream.add(receivedAction);
  }

  @pragma('vm:entry-point')
  static Future<void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {}

  @pragma('vm:entry-point')
  static Future<void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {}

  @pragma('vm:entry-point')
  static Future<void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {}
}
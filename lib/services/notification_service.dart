import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final StreamController<ReceivedAction> actionStream =
  StreamController<ReceivedAction>.broadcast();

  static Future<void> initializeNotification() async {
    try {
      await AwesomeNotifications().initialize(
        // 1. Ensure this exists in android/app/src/main/res/drawable
        // If it fails, try setting this to null temporarily to test
        null, // Changed to null to avoid resource not found errors in release mode
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
        debug: kDebugMode, // Only enable verbose notifications logging in debug builds.
      );

      // ✅ Listeners should be set after initialization is called
      AwesomeNotifications().setListeners(
        onActionReceivedMethod: onActionReceivedMethod,
        onNotificationCreatedMethod: onNotificationCreatedMethod,
        onNotificationDisplayedMethod: onNotificationDisplayedMethod,
        onDismissActionReceivedMethod: onDismissActionReceivedMethod,
      );
    } catch (e) {
      debugPrint("Notification Init Error: $e");
    }
  }

  static Future<bool> requestPermission() async {
    try {
      bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        // This will trigger the system dialog you are seeing
        isAllowed = await AwesomeNotifications().requestPermissionToSendNotifications();
      }
      return isAllowed;
    } catch (e) {
      debugPrint("Notification Permission Error: $e");
      return false;
    }
  }

  // --- TIMER NOTIFICATIONS ---

  static Future<void> showIdleNotification() async {
    try {
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
    } catch (e) {
      debugPrint("Show Idle Error: $e");
    }
  }

  static Future<void> showActiveNotification(String category, String time) async {
    try {
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
    } catch (e) {
      debugPrint("Show Active Error: $e");
    }
  }

  // --- REMINDER NOTIFICATIONS ---

  static Future<void> scheduleReminder({
    required int id,
    required String title,
    required DateTime scheduledTime,
  }) async {
    try {
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
          preciseAlarm: false,
          allowWhileIdle: true,
        ),
      );
    } catch (e) {
      debugPrint("Schedule Reminder Error: $e");
    }
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
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln; // Import với prefix
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../routes.dart';

class NotificationService {
  static final fln.FlutterLocalNotificationsPlugin _notifications =
  fln.FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState>? navigatorKey;

  // --- Kênh Thông báo cho Android ---
  static const String _dailyReminderChannelId = 'daily_reminder_channel';
  static const String _dailyReminderChannelName = 'Nhắc nhở Hàng ngày';
  static const String _dailyReminderChannelDescription = 'Thông báo nhắc nhở chi tiêu và tổng kết hàng ngày.';

  static const String _budgetAlertChannelId = 'budget_alert_channel';
  static const String _budgetAlertChannelName = 'Cảnh báo Ngân sách';
  static const String _budgetAlertChannelDescription = 'Thông báo khi chi tiêu gần hoặc vượt quá ngân sách.';

  static const String _periodicReminderChannelId = 'periodic_reminder_channel';
  static const String _periodicReminderChannelName = 'Nhắc nhở Định kỳ';
  static const String _periodicReminderChannelDescription = 'Thông báo nhắc nhở theo tuần hoặc tháng.';


  static Future<void> init(GlobalKey<NavigatorState> navKey) async {
    navigatorKey = navKey;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.local);

    const fln.AndroidInitializationSettings androidSettings =
    fln.AndroidInitializationSettings('@mipmap/ic_launcher'); // Đảm bảo icon này tồn tại

    const fln.DarwinInitializationSettings darwinSettings = fln.DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      // onDidReceiveLocalNotification đã được loại bỏ vì onDidReceiveNotificationResponse thường xử lý được
    );

    const fln.InitializationSettings initSettings = fln.InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: onDidReceiveBackgroundNotificationResponse,
    );

    final fln.AndroidFlutterLocalNotificationsPlugin? androidImplementation =
    _notifications.resolvePlatformSpecificImplementation<
        fln.AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await _createNotificationChannels(androidImplementation);
      await androidImplementation.requestNotificationsPermission(); // Cho Android 13+
    }

    await _notifications
        .resolvePlatformSpecificImplementation<
        fln.IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _createNotificationChannels(fln.AndroidFlutterLocalNotificationsPlugin androidPlugin) async {
    final dailyChannel = fln.AndroidNotificationChannel(
      _dailyReminderChannelId,
      _dailyReminderChannelName,
      description: _dailyReminderChannelDescription,
      importance: fln.Importance.defaultImportance,
    );
    final budgetChannel = fln.AndroidNotificationChannel(
      _budgetAlertChannelId,
      _budgetAlertChannelName,
      description: _budgetAlertChannelDescription,
      importance: fln.Importance.max, // Cảnh báo nên có độ ưu tiên cao
      // sound: const fln.RawResourceAndroidNotificationSound('custom_alert_sound'), // Nếu có file âm thanh
    );
    final periodicChannel = fln.AndroidNotificationChannel(
      _periodicReminderChannelId,
      _periodicReminderChannelName,
      description: _periodicReminderChannelDescription,
      importance: fln.Importance.defaultImportance,
    );

    await androidPlugin.createNotificationChannel(dailyChannel);
    await androidPlugin.createNotificationChannel(budgetChannel);
    await androidPlugin.createNotificationChannel(periodicChannel);
  }

  static void onDidReceiveNotificationResponse(fln.NotificationResponse response) {
    final String? payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      debugPrint('Notification tapped (foreground/background): $payload');
      _handlePayloadNavigation(payload);
    }
  }

  @pragma('vm:entry-point')
  static void onDidReceiveBackgroundNotificationResponse(fln.NotificationResponse response) {
    final String? payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      debugPrint('Notification tapped (terminated): $payload');
      // Xử lý payload khi app được mở từ thông báo lúc bị tắt.
    }
  }

  static void _handlePayloadNavigation(String payload) {
    if (navigatorKey?.currentState != null) {
      navigatorKey!.currentState!.pushNamed(Routes.notifications, arguments: payload);
    } else {
      debugPrint("NavigatorKey is null, cannot navigate from notification.");
    }
  }

  /// Thông báo tức thì (ví dụ: cảnh báo ngân sách)
  static Future<void> showBudgetAlert({
    required int id,
    required String title,
    required String body,
    String payload = 'budget_alert_payload',
  }) async {
    const fln.AndroidNotificationDetails androidDetails = fln.AndroidNotificationDetails(
      _budgetAlertChannelId,
      _budgetAlertChannelName,
      channelDescription: _budgetAlertChannelDescription,
      importance: fln.Importance.max,
      priority: fln.Priority.high,
      icon: '@mipmap/ic_launcher',
      ticker: 'Cảnh báo ngân sách!',
    );
    const fln.DarwinNotificationDetails darwinDetails = fln.DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const fln.NotificationDetails notificationDetails = fln.NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    try {
      await _notifications.show(id, title, body, notificationDetails, payload: payload);
      debugPrint('Showed Budget Alert id $id with payload: $payload');
    } catch (e) {
      debugPrint('Error showing budget alert: $e');
    }
  }

  /// Thông báo định kỳ hàng ngày
  static Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    int second = 0,
    String payload = 'daily_reminder_payload',
  }) async {
    final tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute, second);

    const fln.AndroidNotificationDetails androidDetails = fln.AndroidNotificationDetails(
      _dailyReminderChannelId,
      _dailyReminderChannelName,
      channelDescription: _dailyReminderChannelDescription,
      importance: fln.Importance.defaultImportance,
      priority: fln.Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );
    const fln.DarwinNotificationDetails darwinDetails = fln.DarwinNotificationDetails(
        presentAlert: true, presentBadge: true, presentSound: true);
    const fln.NotificationDetails notificationDetails = fln.NotificationDetails(
        android: androidDetails, iOS: darwinDetails, macOS: darwinDetails);

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: fln.DateTimeComponents.time,
        payload: payload,
      );
      debugPrint('Scheduled Daily Reminder id $id at $scheduledDate with payload: $payload');
    } catch (e) {
      debugPrint('Error scheduling daily reminder: $e');
    }
  }

  /// Thông báo định kỳ hàng tuần
  static Future<void> scheduleWeeklyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    int second = 0,
    required List<int> daysOfWeek, // Nhận List<int> (1=Monday ... 7=Sunday)
    String payload = 'weekly_reminder_payload',
  }) async {
    if (daysOfWeek.isEmpty) {
      debugPrint("Cannot schedule weekly reminder without specified days.");
      return;
    }
    for (var dayValue in daysOfWeek) {
      if (dayValue < 1 || dayValue > 7) {
        debugPrint("Invalid day value for weekly reminder: $dayValue. Must be 1-7.");
        continue;
      }
      final tz.TZDateTime scheduledDate = _nextInstanceOfDayAndTime(dayValue, hour, minute, second);
      final int uniqueId = id + dayValue;

      const fln.AndroidNotificationDetails androidDetails = fln.AndroidNotificationDetails(
          _periodicReminderChannelId, _periodicReminderChannelName, channelDescription: _periodicReminderChannelDescription);
      const fln.DarwinNotificationDetails darwinDetails = fln.DarwinNotificationDetails(presentSound: true, presentAlert: true, presentBadge: true);
      const fln.NotificationDetails notificationDetails = fln.NotificationDetails(android: androidDetails, iOS: darwinDetails, macOS: darwinDetails);

      try {
        await _notifications.zonedSchedule(
          uniqueId,
          title,
          body,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: fln.DateTimeComponents.dayOfWeekAndTime,
          payload: payload,
        );
        debugPrint('Scheduled Weekly Reminder id $uniqueId for day $dayValue at $scheduledDate with payload: $payload');
      } catch (e) {
        debugPrint('Error scheduling weekly reminder for day $dayValue: $e');
      }
    }
  }

  /// Thông báo định kỳ hàng tháng
  static Future<void> scheduleMonthlyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    int second = 0,
    required int dayOfMonth,
    String payload = 'monthly_reminder_payload',
  }) async {
    if (dayOfMonth < 1 || dayOfMonth > 31) {
      debugPrint("Invalid day of month for monthly reminder.");
      return;
    }
    final tz.TZDateTime scheduledDate = _nextInstanceOfDayOfMonthAndTime(dayOfMonth, hour, minute, second);

    const fln.AndroidNotificationDetails androidDetails = fln.AndroidNotificationDetails(
        _periodicReminderChannelId, _periodicReminderChannelName, channelDescription: _periodicReminderChannelDescription);
    const fln.DarwinNotificationDetails darwinDetails = fln.DarwinNotificationDetails(presentSound: true, presentAlert: true, presentBadge: true);
    const fln.NotificationDetails notificationDetails = fln.NotificationDetails(android: androidDetails, iOS: darwinDetails, macOS: darwinDetails);

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: fln.DateTimeComponents.dayOfMonthAndTime,
        payload: payload,
      );
      debugPrint('Scheduled Monthly Reminder id $id for day $dayOfMonth at $scheduledDate with payload: $payload');
    } catch (e) {
      debugPrint('Error scheduling monthly reminder: $e');
    }
  }

  // --- Helper methods for scheduling ---
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute, int second) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute, second);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static tz.TZDateTime _nextInstanceOfDayAndTime(int dayValue, int hour, int minute, int second) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute, second);
    while (scheduledDate.weekday != dayValue) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static tz.TZDateTime _nextInstanceOfDayOfMonthAndTime(int dayOfMonth, int hour, int minute, int second) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate;

    try {
      scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, dayOfMonth, hour, minute, second);
    } catch (e) {
      final lastDayOfMonth = tz.TZDateTime(tz.local, now.year, now.month + 1, 0);
      scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, lastDayOfMonth.day, hour, minute, second);
    }

    if (scheduledDate.isBefore(now) || scheduledDate.day != dayOfMonth) {
      int year = now.year;
      int month = now.month + 1;
      while (true) {
        if (month > 12) {
          month = 1;
          year++;
        }
        try {
          scheduledDate = tz.TZDateTime(tz.local, year, month, dayOfMonth, hour, minute, second);
          if (scheduledDate.day == dayOfMonth && !scheduledDate.isBefore(now)) {
            break;
          }
          if (scheduledDate.day == dayOfMonth && scheduledDate.isBefore(now)){
            month++;
            continue;
          }
        } catch (e) {
          // Ngày không hợp lệ, thử tháng tiếp theo
        }
        month++;
        if (year > now.year + 2) { // Giới hạn để tránh vòng lặp vô hạn
          // Nếu không tìm thấy ngày hợp lệ trong 2 năm tới, có thể đặt vào ngày cuối của tháng gần nhất
          final lastDayOfSafeMonth = tz.TZDateTime(tz.local, year, month, 0);
          scheduledDate = tz.TZDateTime(tz.local, year, month-1, lastDayOfSafeMonth.day, hour, minute, second);
          break;
        }
      }
    }
    return scheduledDate;
  }

  // --- Utility methods ---
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    debugPrint('Canceled notification id $id');
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('Canceled all notifications');
  }
}

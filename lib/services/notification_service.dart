import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../routes.dart';

class NotificationService {
  static final fln.FlutterLocalNotificationsPlugin _notifications =
  fln.FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState>? navigatorKey;

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
    fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    const fln.DarwinInitializationSettings darwinSettings = fln.DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
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
      await androidImplementation.requestNotificationsPermission();
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
      importance: fln.Importance.max,
      // sound: const fln.RawResourceAndroidNotificationSound('custom_alert_sound'),
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
    }
  }

  static void _handlePayloadNavigation(String payload) {
    if (navigatorKey?.currentState != null) {
      navigatorKey!.currentState!.pushNamed(Routes.notifications, arguments: payload);
    } else {
      debugPrint("NavigatorKey is null, cannot navigate from notification.");
    }
  }

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

  static Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour, // ***** THAY THÀNH INT *****
    required int minute, // ***** THAY THÀNH INT *****
    int second = 0,    // ***** THAY THÀNH INT (OPTIONAL) *****
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

  static Future<void> scheduleWeeklyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,    // ***** THAY THÀNH INT *****
    required int minute,  // ***** THAY THÀNH INT *****
    int second = 0,     // ***** THAY THÀNH INT (OPTIONAL) *****
    required List<int> daysOfWeek, // ***** THAY THÀNH List<int> (1=Monday ... 7=Sunday) *****
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
      // Chuyển đổi int (1-7) thành fln.Day nếu cần thiết bên trong _nextInstanceOfDayAndTime
      // Hoặc _nextInstanceOfDayAndTime sẽ xử lý trực tiếp int
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

  static Future<void> scheduleMonthlyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,     // ***** THAY THÀNH INT *****
    required int minute,   // ***** THAY THÀNH INT *****
    int second = 0,      // ***** THAY THÀNH INT (OPTIONAL) *****
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
    while (scheduledDate.weekday != dayValue) { // DateTime.weekday (1=Monday, 7=Sunday)
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
      // Nếu ngày không hợp lệ cho tháng hiện tại (ví dụ ngày 31 tháng 2),
      // đặt lịch vào ngày cuối cùng của tháng đó.
      final lastDayOfMonth = tz.TZDateTime(tz.local, now.year, now.month + 1, 0);
      scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, lastDayOfMonth.day, hour, minute, second);
    }

    // Nếu ngày đã qua trong tháng này, hoặc ngày không hợp lệ, lên lịch cho tháng tiếp theo
    if (scheduledDate.isBefore(now) || scheduledDate.day != dayOfMonth) {
      int year = now.year;
      int month = now.month + 1;
      // Lặp để tìm tháng hợp lệ có ngày dayOfMonth
      while (true) {
        if (month > 12) {
          month = 1;
          year++;
        }
        try {
          scheduledDate = tz.TZDateTime(tz.local, year, month, dayOfMonth, hour, minute, second);
          // Nếu tạo được ngày hợp lệ và nó sau thời điểm hiện tại, thì dùng ngày này
          if (scheduledDate.day == dayOfMonth && !scheduledDate.isBefore(now)) {
            break;
          }
          // Nếu tạo được ngày hợp lệ nhưng nó trước now (nghĩa là ngày đó của tháng sau vẫn trước now)
          // thì cần nhảy tiếp sang tháng sau nữa
          if (scheduledDate.day == dayOfMonth && scheduledDate.isBefore(now)){
            month++;
            continue;
          }
          // Nếu ngày không hợp lệ (ví dụ 31/2) thì nó sẽ throw exception và đi vào catch
        } catch (e) {
          // Ngày không hợp lệ cho tháng này, thử tháng tiếp theo
        }
        month++;
        if (year > now.year + 2) break; // Giới hạn tìm kiếm để tránh vòng lặp vô hạn
      }
    }
    return scheduledDate;
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    debugPrint('Canceled notification id $id');
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    debugPrint('Canceled all notifications');
  }
}

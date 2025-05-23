import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln; // Import với prefix
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../routes.dart';

class NotificationPayloadType {
  static const String budgetAlert = 'budget_alert';
  static const String dailyReminder = 'daily_reminder';
  static const String weeklyReminder = 'weekly_reminder';
  static const String monthlyReminder = 'monthly_reminder';
  static const String generalInfo = 'general_info';
}


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

  static const String _generalInfoChannelId = 'general_info_channel';
  static const String _generalInfoChannelName = 'Thông tin Chung';
  static const String _generalInfoChannelDescription = 'Các thông báo thông tin chung từ ứng dụng.';


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
      importance: fln.Importance.max,
      // sound: const fln.RawResourceAndroidNotificationSound('custom_alert_sound'), // Nếu có file âm thanh
    );
    final periodicChannel = fln.AndroidNotificationChannel(
      _periodicReminderChannelId,
      _periodicReminderChannelName,
      description: _periodicReminderChannelDescription,
      importance: fln.Importance.defaultImportance,
    );
    final generalChannel = fln.AndroidNotificationChannel(
      _generalInfoChannelId,
      _generalInfoChannelName,
      description: _generalInfoChannelDescription,
      importance: fln.Importance.high,
    );

    await androidPlugin.createNotificationChannel(dailyChannel);
    await androidPlugin.createNotificationChannel(budgetChannel);
    await androidPlugin.createNotificationChannel(periodicChannel);
    await androidPlugin.createNotificationChannel(generalChannel);
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
      // Ví dụ: lưu payload vào SharedPreferences để màn hình đầu tiên của app đọc và xử lý.
    }
  }

  static void _handlePayloadNavigation(String jsonPayload) {
    if (navigatorKey?.currentState != null) {
      dynamic argumentsToPass = jsonPayload;
      try {
        final Map<String, dynamic> payloadMap = jsonDecode(jsonPayload);
        argumentsToPass = payloadMap;

        // Ví dụ về cách điều hướng dựa trên type:
        // final String? type = payloadMap['type'] as String?;
        // if (type == NotificationPayloadType.budgetAlert) {
        //   final budgetId = payloadMap['budgetId'] as String?;
        //   if (budgetId != null) {
        //     navigatorKey!.currentState!.pushNamed(Routes.budgetDetailScreen, arguments: budgetId);
        //     return;
        //   }
        // }

        navigatorKey!.currentState!.pushNamed(Routes.notifications, arguments: argumentsToPass);

      } catch (e) {
        debugPrint('Error decoding JSON payload: $e. Passing raw payload string.');
        navigatorKey!.currentState!.pushNamed(Routes.notifications, arguments: jsonPayload);
      }
    } else {
      debugPrint("NavigatorKey is null, cannot navigate from notification.");
    }
  }

  /// Thông báo tức thì chung
  static Future<void> showGeneralNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final Map<String, dynamic> payloadMap = {
      'type': NotificationPayloadType.generalInfo,
      'title': title,
      'body': body,
      'data': data ?? {},
      'timestamp': DateTime.now().toIso8601String(),
    };
    const fln.AndroidNotificationDetails androidDetails = fln.AndroidNotificationDetails(
      _generalInfoChannelId,
      _generalInfoChannelName,
      channelDescription: _generalInfoChannelDescription,
      importance: fln.Importance.high,
      priority: fln.Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const fln.DarwinNotificationDetails darwinDetails = fln.DarwinNotificationDetails(
        presentAlert: true, presentBadge: true, presentSound: true);
    const fln.NotificationDetails notificationDetails = fln.NotificationDetails(
        android: androidDetails, iOS: darwinDetails, macOS: darwinDetails);

    try {
      await _notifications.show(id, title, body, notificationDetails, payload: jsonEncode(payloadMap));
      debugPrint('Showed General Notification id $id with payload: ${jsonEncode(payloadMap)}');
    } catch (e) {
      debugPrint('Error showing general notification: $e');
    }
  }


  static Future<void> showBudgetAlert({
    required int id,
    required String title,
    required String body,
    String? budgetId,
    String? alertType,
  }) async {
    final Map<String, dynamic> payloadMap = {
      'type': NotificationPayloadType.budgetAlert,
      'title': title,
      'body': body,
      'budgetId': budgetId,
      'alertType': alertType,
      'timestamp': DateTime.now().toIso8601String(),
    };
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
        presentAlert: true, presentBadge: true, presentSound: true);
    const fln.NotificationDetails notificationDetails = fln.NotificationDetails(
        android: androidDetails, iOS: darwinDetails, macOS: darwinDetails);

    try {
      await _notifications.show(id, title, body, notificationDetails, payload: jsonEncode(payloadMap));
      debugPrint('Showed Budget Alert id $id with payload: ${jsonEncode(payloadMap)}');
    } catch (e) {
      debugPrint('Error showing budget alert: $e');
    }
  }

  static Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    int second = 0,
    // String payload = 'daily_reminder_payload', // Payload sẽ được tạo bên trong
  }) async {
    final tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute, second);
    final Map<String, dynamic> payloadMap = {
      'type': NotificationPayloadType.dailyReminder,
      'title': title,
      'body': body,
      'scheduledTime': scheduledDate.toIso8601String(),
      'timestamp': DateTime.now().toIso8601String(),
    };

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
        payload: jsonEncode(payloadMap),
      );
      debugPrint('Scheduled Daily Reminder id $id at $scheduledDate with payload: ${jsonEncode(payloadMap)}');
    } catch (e) {
      debugPrint('Error scheduling daily reminder: $e');
    }
  }

  static Future<void> scheduleWeeklyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    int second = 0,
    required List<int> daysOfWeek,
    String? customData,
  }) async {
    if (daysOfWeek.isEmpty) {
      debugPrint("Cannot schedule weekly reminder without specified days.");
      return;
    }
    final Map<String, dynamic> payloadMapBase = {
      'type': NotificationPayloadType.weeklyReminder,
      'title': title,
      'body': body,
      'days': daysOfWeek.join(','),
      'time': '$hour:$minute:$second',
      'customData': customData,
      'timestamp': DateTime.now().toIso8601String(),
    };

    for (var dayValue in daysOfWeek) {
      if (dayValue < 1 || dayValue > 7) {
        debugPrint("Invalid day value for weekly reminder: $dayValue. Must be 1-7.");
        continue;
      }
      final tz.TZDateTime scheduledDate = _nextInstanceOfDayAndTime(dayValue, hour, minute, second);
      final int uniqueId = id + dayValue;

      final Map<String, dynamic> finalPayloadMap = Map<String, dynamic>.from(payloadMapBase);
      finalPayloadMap['scheduledDay'] = dayValue;

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
          payload: jsonEncode(finalPayloadMap),
        );
        debugPrint('Scheduled Weekly Reminder id $uniqueId for day $dayValue at $scheduledDate');
      } catch (e) {
        debugPrint('Error scheduling weekly reminder for day $dayValue: $e');
      }
    }
  }

  static Future<void> scheduleMonthlyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    int second = 0,
    required int dayOfMonth,
    String? customData,
  }) async {
    if (dayOfMonth < 1 || dayOfMonth > 31) {
      debugPrint("Invalid day of month for monthly reminder.");
      return;
    }
    final tz.TZDateTime scheduledDate = _nextInstanceOfDayOfMonthAndTime(dayOfMonth, hour, minute, second);
    final Map<String, dynamic> payloadMap = {
      'type': NotificationPayloadType.monthlyReminder,
      'title': title,
      'body': body,
      'dayOfMonth': dayOfMonth,
      'time': '$hour:$minute:$second',
      'customData': customData,
      'timestamp': DateTime.now().toIso8601String(),
    };

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
        payload: jsonEncode(payloadMap),
      );
      debugPrint('Scheduled Monthly Reminder id $id for day $dayOfMonth at $scheduledDate');
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

    int currentYear = now.year;
    int currentMonth = now.month;

    while (true) {
      try {
        // Cố gắng tạo ngày với dayOfMonth của tháng hiện tại (currentMonth)
        scheduledDate = tz.TZDateTime(tz.local, currentYear, currentMonth, dayOfMonth, hour, minute, second);
        // Nếu ngày tạo được là ngày mong muốn và không nằm trong quá khứ (hoặc là đúng hôm nay nhưng giờ đã qua)
        if (scheduledDate.day == dayOfMonth && !scheduledDate.isBefore(now)) {
          return scheduledDate; // Tìm thấy ngày hợp lệ
        }
      } catch (e) {
        // Ngày không hợp lệ cho tháng/năm hiện tại (ví dụ: 31 tháng 2)
        // Bỏ qua lỗi và thử tháng tiếp theo
      }

      // Chuyển sang tháng tiếp theo
      currentMonth++;
      if (currentMonth > 12) {
        currentMonth = 1;
        currentYear++;
      }

      // Giới hạn vòng lặp để tránh trường hợp không tìm thấy ngày hợp lệ (ví dụ: dayOfMonth = 32)
      // Hoặc nếu đã tìm quá xa trong tương lai
      if (currentYear > now.year + 5) { // Giới hạn tìm kiếm trong 5 năm
        debugPrint("Could not find a valid date for day $dayOfMonth within 5 years. Defaulting to a future date.");
        // Fallback: trả về một ngày trong tương lai gần, ví dụ ngày 1 của tháng tới
        return tz.TZDateTime(tz.local, now.year, now.month + 1, 1, hour, minute, second);
      }
    }
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

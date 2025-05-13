import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  /// Gọi cái này trong `main()` trước khi runApp()
  static Future<void> init() async {
    // Khởi tạo cơ sở dữ liệu timezone
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
  }

  /// Lên lịch thông báo hàng ngày vào giờ/phút chỉ định
  static Future<void> showDailySummary({
    required int id,
    required String title,
    required String body,
    int hour = 20,
    int minute = 0,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_summary',
          'Daily Summary',
          channelDescription: 'Nhắc tóm tắt chi tiêu hàng ngày',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      // Bắt buộc phải chỉ định AndroidScheduleMode
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // Lặp lại mỗi ngày cùng giờ
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}

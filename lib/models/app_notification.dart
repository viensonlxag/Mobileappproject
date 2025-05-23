import 'package:flutter/material.dart'; // ***** THÊM IMPORT NÀY *****
import 'package:cloud_firestore/cloud_firestore.dart';

enum AppNotificationType {
  budgetAlert, // Cảnh báo ngân sách
  dailyReminder, // Nhắc nhở hàng ngày
  weeklyReminder, // Nhắc nhở hàng tuần
  monthlyReminder, // Nhắc nhở hàng tháng
  general // Thông báo chung
}

extension AppNotificationTypeExtension on AppNotificationType {
  // ***** SỬA TÊN GETTER *****
  String get displayName {
    switch (this) {
      case AppNotificationType.budgetAlert:
        return 'Cảnh báo Ngân sách';
      case AppNotificationType.dailyReminder:
        return 'Nhắc nhở Hàng ngày';
      case AppNotificationType.weeklyReminder:
        return 'Nhắc nhở Hàng tuần';
      case AppNotificationType.monthlyReminder:
        return 'Nhắc nhở Hàng tháng';
      case AppNotificationType.general:
      default:
        return 'Thông báo';
    }
  }

  IconData get icon {
    switch (this) {
      case AppNotificationType.budgetAlert:
        return Icons.warning_amber_rounded;
      case AppNotificationType.dailyReminder:
        return Icons.today_rounded;
      case AppNotificationType.weeklyReminder:
        return Icons.calendar_view_week_rounded;
      case AppNotificationType.monthlyReminder:
        return Icons.calendar_month_rounded;
      case AppNotificationType.general:
      default:
        return Icons.notifications_rounded;
    }
  }
}


class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final AppNotificationType type;
  final String? originalPayload; // Payload gốc từ local notification
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.originalPayload,
    this.isRead = false,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      title: data['title'] ?? 'Không có tiêu đề',
      body: data['body'] ?? 'Không có nội dung',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: AppNotificationType.values.firstWhere(
              (e) => e.toString() == data['type'],
          orElse: () => AppNotificationType.general
      ),
      originalPayload: data['originalPayload'] as String?, // Đảm bảo ép kiểu đúng
      isRead: data['isRead'] as bool? ?? false, // Đảm bảo ép kiểu đúng
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.toString(), // Lưu trữ enum dưới dạng string
      'originalPayload': originalPayload,
      'isRead': isRead,
    };
  }
}

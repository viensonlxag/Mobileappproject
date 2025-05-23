import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/app_notification.dart'; // Import model AppNotification

class NotificationsScreen extends StatelessWidget {
  // payload không còn cần thiết ở đây nữa vì chúng ta sẽ hiển thị danh sách
  // final String? payload;

  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final notifications = appProvider.appNotifications; // Lấy danh sách thông báo từ AppProvider
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trung tâm Thông báo'),
        actions: [
          if (notifications.any((n) => n.isRead)) // Chỉ hiển thị nút nếu có thông báo đã đọc
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Xóa tất cả đã đọc',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Xóa thông báo đã đọc?'),
                    content: const Text('Bạn có chắc chắn muốn xóa tất cả các thông báo đã đọc không?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Xóa'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await appProvider.deleteAllReadAppNotifications();
                }
              },
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'Không có thông báo nào',
              style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Các thông báo quan trọng sẽ xuất hiện ở đây.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(8.0),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationItem(context, notification, appProvider, theme);
        },
        separatorBuilder: (context, index) => const Divider(height: 1),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, AppNotification notification, AppProvider appProvider, ThemeData theme) {
    final timeFormatter = DateFormat('HH:mm dd/MM/yyyy', 'vi_VN');
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) async {
        await appProvider.deleteAppNotification(notification.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã xóa thông báo: "${notification.title}"')),
          );
        }
      },
      background: Container(
        color: Colors.red.shade600,
        padding: const EdgeInsets.only(right: 20.0),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Xóa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: notification.isRead
              ? Colors.grey.shade300
              : theme.colorScheme.primary.withOpacity(0.15),
          child: Icon(
            notification.type.icon,
            color: notification.isRead ? Colors.grey.shade600 : theme.colorScheme.primary,
            size: 24,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            color: notification.isRead ? Colors.grey[700] : theme.textTheme.bodyLarge?.color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.body,
              style: TextStyle(
                color: notification.isRead ? Colors.grey[600] : theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              timeFormatter.format(notification.timestamp),
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Icon(Icons.circle, color: theme.colorScheme.primary, size: 10),
        onTap: () async {
          if (!notification.isRead) {
            await appProvider.markAppNotificationAsRead(notification.id);
          }
          // TODO: Xử lý điều hướng dựa trên notification.originalPayload nếu cần
          // Ví dụ: nếu payload là 'budget_alert:over:budget123', có thể điều hướng đến màn hình chi tiết ngân sách budget123
          debugPrint("Notification tapped: ${notification.title}, Payload: ${notification.originalPayload}");
        },
        contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      ),
    );
  }
}

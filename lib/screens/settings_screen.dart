import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Để định dạng thời gian
import '../providers/app_provider.dart';
import '../routes.dart';
// import '../services/notification_service.dart'; // Không cần trực tiếp ở đây nữa

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận Đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Đăng xuất'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await Provider.of<AppProvider>(context, listen: false).appSignOut(context);
              },
            ),
          ],
        );
      },
    );
  }

  // ***** THÊM HÀM CHỌN GIỜ CHO NHẮC NHỞ HÀNG NGÀY *****
  Future<void> _selectDailyReminderTime(BuildContext context, AppProvider appProvider) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: appProvider.dailyReminderTime,
      helpText: 'CHỌN GIỜ NHẮC NHỞ',
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              // Tùy chỉnh theme của TimePicker nếu muốn
              backgroundColor: Colors.white,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
              ),
              // ... các thuộc tính khác
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedTime != null && (pickedTime.hour != appProvider.dailyReminderHour || pickedTime.minute != appProvider.dailyReminderMinute)) {
      await appProvider.updateDailyReminderSetting(
        enabled: appProvider.dailyReminderEnabled, // Giữ nguyên trạng thái bật/tắt
        hour: pickedTime.hour,
        minute: pickedTime.minute,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final userName = appProvider.userName;
    final userEmail = appProvider.currentUser?.email ?? 'Không có email';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài Đặt'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    userName.isNotEmpty && userName != "Bạn" ? userName[0].toUpperCase() : "?",
                    style: TextStyle(fontSize: 28, color: theme.colorScheme.onPrimaryContainer),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        userEmail,
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          _buildSettingsItem(
            context,
            icon: Icons.account_circle_outlined,
            title: 'Thông tin cá nhân',
            subtitle: 'Chỉnh sửa tên, ngày sinh,...',
            onTap: () {
              Navigator.pushNamed(context, Routes.userProfile);
            },
          ),

          // ***** THÊM MỤC CÀI ĐẶT THÔNG BÁO *****
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Text(
              'Thông báo & Nhắc nhở',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Nhắc nhở hàng ngày'),
            subtitle: Text(appProvider.dailyReminderEnabled
                ? 'Bật lúc ${appProvider.dailyReminderTime.format(context)}'
                : 'Tắt'),
            value: appProvider.dailyReminderEnabled,
            onChanged: (bool value) {
              appProvider.updateDailyReminderSetting(
                enabled: value,
                hour: appProvider.dailyReminderHour, // Giữ nguyên giờ phút hiện tại khi chỉ bật/tắt
                minute: appProvider.dailyReminderMinute,
              );
            },
            secondary: Icon(appProvider.dailyReminderEnabled ? Icons.notifications_active_outlined : Icons.notifications_off_outlined),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          ),
          if (appProvider.dailyReminderEnabled)
            ListTile(
              title: const Text('  Thời gian nhắc nhở'), // Thụt vào một chút
              trailing: Text(appProvider.dailyReminderTime.format(context), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              onTap: () => _selectDailyReminderTime(context, appProvider),
              contentPadding: const EdgeInsets.only(left: 72.0, right: 16.0), // Căn chỉnh với SwitchListTile
            ),
          // TODO: Thêm cài đặt cho nhắc nhở hàng tuần, hàng tháng tương tự

          const Divider(),
          _buildSettingsItem(
            context,
            icon: Icons.logout_rounded,
            title: 'Đăng xuất',
            onTap: () {
              _confirmLogout(context);
            },
            color: Colors.red.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        String? subtitle,
        required VoidCallback onTap,
        Color? color,
      }) {
    final itemColor = color ?? Theme.of(context).textTheme.bodyLarge?.color;
    return ListTile(
      leading: Icon(icon, color: itemColor, size: 26),
      title: Text(title, style: TextStyle(fontSize: 16, color: itemColor, fontWeight: color != null ? FontWeight.w500 : FontWeight.normal)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])) : null,
      trailing: (color == null) ? Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]) : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    );
  }
}

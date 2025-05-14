import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../routes.dart';

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
                Navigator.of(dialogContext).pop(); // Đóng dialog trước
                // Gọi hàm signOut từ AppProvider (đã đổi tên thành appSignOut)
                await Provider.of<AppProvider>(context, listen: false).appSignOut(context);
                // Việc điều hướng đã được xử lý trong appSignOut
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lấy tên người dùng hiện tại để hiển thị (tùy chọn)
    final userName = Provider.of<AppProvider>(context).userName;
    final userEmail = Provider.of<AppProvider>(context).currentUser?.email ?? 'Không có email';


    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài Đặt'),
        // backgroundColor và foregroundColor sẽ lấy từ theme trong main.dart
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: <Widget>[
          // Thông tin người dùng cơ bản
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.pinkAccent.withOpacity(0.2),
                  child: Text(
                    userName.isNotEmpty && userName != "Bạn" ? userName[0].toUpperCase() : "?",
                    style: const TextStyle(fontSize: 28, color: Colors.pinkAccent),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        userEmail,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
          // Thêm các mục cài đặt khác nếu cần
          // _buildSettingsItem(
          //   context,
          //   icon: Icons.notifications_outlined,
          //   title: 'Thông báo',
          //   onTap: () { /* Xử lý */ },
          // ),
          // _buildSettingsItem(
          //   context,
          //   icon: Icons.color_lens_outlined,
          //   title: 'Giao diện',
          //   onTap: () { /* Xử lý */ },
          // ),
          const Divider(),
          _buildSettingsItem(
            context,
            icon: Icons.logout_rounded,
            title: 'Đăng xuất',
            onTap: () {
              _confirmLogout(context);
            },
            color: Colors.red.shade700, // Màu đỏ cho mục đăng xuất
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
        Color? color, // Cho phép tùy chỉnh màu của icon và text
      }) {
    final itemColor = color ?? Theme.of(context).textTheme.bodyLarge?.color;
    return ListTile(
      leading: Icon(icon, color: itemColor, size: 26),
      title: Text(title, style: TextStyle(fontSize: 16, color: itemColor)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])) : null,
      trailing: (color == null) ? Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]) : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    );
  }
}

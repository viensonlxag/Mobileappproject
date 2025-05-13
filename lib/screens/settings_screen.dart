import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final prov = context.read<AppProvider>();
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Đăng xuất'),
          onTap: () => prov.signOut(),
        ),
        // Add toggles for Dark Mode, Notifications, etc.
      ],
    );
  }
}
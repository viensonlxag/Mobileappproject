import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  final String? payload; // Payload nhận được từ thông báo

  const NotificationsScreen({super.key, this.payload});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.notifications_active_rounded, size: 80, color: Colors.amber),
              const SizedBox(height: 20),
              Text(
                'Chi tiết Thông báo',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                payload ?? 'Không có dữ liệu payload.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Quay lại'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

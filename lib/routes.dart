import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';

class Routes {
  static const String login = '/login';
  static const String home = '/home';
  static const String addTransaction = '/add-transaction';
  static const String history = '/history';
  static const String settings = '/settings';

  /// Route generator chuẩn hóa (dùng const String cho case match)
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.login: // ✅ Sửa đây
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case Routes.home: // ✅ Sửa đây
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case Routes.addTransaction: // ✅ Sửa đây
        return MaterialPageRoute(builder: (_) => const AddTransactionScreen());
      case Routes.history: // ✅ Sửa đây
        return MaterialPageRoute(builder: (_) => const HistoryScreen());
      case Routes.settings: // ✅ Sửa đây
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}

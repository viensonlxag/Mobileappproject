import 'package:flutter/material.dart';
import '../screens/login_screen.dart'; // Đảm bảo đường dẫn đúng
import '../screens/home_screen.dart';   // Đảm bảo đường dẫn đúng
import '../screens/add_transaction_screen.dart'; // Đảm bảo đường dẫn đúng
import '../screens/history_screen.dart'; // Đảm bảo đường dẫn đúng
import '../screens/settings_screen.dart'; // Đảm bảo đường dẫn đúng
import '../screens/user_profile_screen.dart'; // <-- THÊM IMPORT NÀY (tạo file này ở bước sau)

class Routes {
  static const String login = '/login';
  static const String home = '/home';
  static const String addTransaction = '/add-transaction';
  static const String history = '/history';
  static const String settings = '/settings';
  static const String userProfile = '/user-profile'; // <-- THÊM ROUTE MỚI

  static Route<dynamic> generateRoute(RouteSettings routeSettings) { // Đổi tên settings thành routeSettings
    switch (routeSettings.name) {
      case Routes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case Routes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case Routes.addTransaction:
        return MaterialPageRoute(builder: (_) => const AddTransactionScreen());
      case Routes.history:
        return MaterialPageRoute(builder: (_) => const HistoryScreen());
      case Routes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case Routes.userProfile: // <-- THÊM CASE CHO USER PROFILE
        return MaterialPageRoute(builder: (_) => const UserProfileScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Không tìm thấy đường dẫn: ${routeSettings.name}')),
          ),
        );
    }
  }
}

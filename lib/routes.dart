import 'package:flutter/material.dart';
import '../screens/login_screen.dart'; // Đảm bảo đường dẫn đúng
import '../screens/home_screen.dart';   // Đảm bảo đường dẫn đúng, chứa enum CategoryDetailType
import '../screens/add_transaction_screen.dart'; // Đảm bảo đường dẫn đúng
import '../screens/history_screen.dart'; // Đảm bảo đường dẫn đúng
import '../screens/settings_screen.dart'; // Đảm bảo đường dẫn đúng
import '../screens/user_profile_screen.dart'; // Đảm bảo đường dẫn đúng
import '../screens/category_transactions_screen.dart'; // THÊM IMPORT NÀY
import '../models/expense_transaction.dart'; // THÊM IMPORT NÀY

class Routes {
  static const String login = '/login';
  static const String home = '/home';
  static const String addTransaction = '/add-transaction'; // Dùng cho cả Thêm và Sửa
  static const String history = '/history';
  static const String settings = '/settings';
  static const String userProfile = '/user-profile';
  static const String categoryTransactions = '/category-transactions'; // THÊM ROUTE NÀY

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case Routes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case Routes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case Routes.addTransaction:
        final ExpenseTransaction? transactionToEdit;
        // Kiểm tra xem arguments có được truyền và có đúng kiểu ExpenseTransaction không
        if (routeSettings.arguments != null && routeSettings.arguments is ExpenseTransaction) {
          transactionToEdit = routeSettings.arguments as ExpenseTransaction?;
        } else {
          transactionToEdit = null; // Nếu không có argument hoặc sai kiểu, coi như thêm mới
        }
        return MaterialPageRoute(
          builder: (_) => AddTransactionScreen(existingTransaction: transactionToEdit),
        );
      case Routes.history:
        return MaterialPageRoute(builder: (_) => const HistoryScreen());
      case Routes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case Routes.userProfile:
        return MaterialPageRoute(builder: (_) => const UserProfileScreen());
      case Routes.categoryTransactions:
        final args = routeSettings.arguments as Map<String, dynamic>?;
        if (args != null && args.containsKey('categoryName') && args.containsKey('categoryType')) {
          return MaterialPageRoute(
            builder: (_) => CategoryTransactionsScreen(
              categoryName: args['categoryName'] as String,
              categoryType: args['categoryType'] as CategoryDetailType, // Lấy enum từ home_screen.dart
            ),
          );
        }
        // Trả về trang lỗi nếu không có arguments hợp lệ
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text("Lỗi")),
            body: const Center(child: Text('Thiếu thông tin danh mục để hiển thị chi tiết.')),
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text("Lỗi Điều Hướng")),
            body: Center(child: Text('Không tìm thấy đường dẫn: ${routeSettings.name}')),
          ),
        );
    }
  }
}

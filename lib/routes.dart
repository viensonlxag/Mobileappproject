import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/add_transaction_screen.dart';
import '../screens/history_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/user_profile_screen.dart';
import '../screens/category_transactions_screen.dart';
import '../models/expense_transaction.dart';
import '../screens/category_analysis_screen.dart';
import '../screens/notifications_screen.dart';

class Routes {
  static const String login = '/login';
  static const String home = '/home';
  static const String addTransaction = '/add-transaction';
  static const String history = '/history';
  static const String settings = '/settings';
  static const String userProfile = '/user-profile';
  static const String categoryTransactions = '/category-transactions';
  static const String categoryAnalysis = '/category-analysis';
  static const String notifications = '/notifications';


  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case Routes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case Routes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case Routes.addTransaction:
        final ExpenseTransaction? transactionToEdit;
        if (routeSettings.arguments != null && routeSettings.arguments is ExpenseTransaction) {
          transactionToEdit = routeSettings.arguments as ExpenseTransaction?;
        } else {
          transactionToEdit = null;
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
              categoryType: args['categoryType'] as CategoryDetailType,
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text("Lỗi")),
            body: const Center(child: Text('Thiếu thông tin danh mục để hiển thị chi tiết.')),
          ),
        );
      case Routes.categoryAnalysis:
        return MaterialPageRoute(builder: (_) => const CategoryAnalysisScreen());

      case Routes.notifications:
      // final String? payload = routeSettings.arguments as String?; // Không cần truyền payload nữa
        return MaterialPageRoute(builder: (_) => const NotificationsScreen()); // ***** BỎ TRUYỀN PAYLOAD *****

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

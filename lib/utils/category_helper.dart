import 'package:flutter/material.dart';

// LƯU Ý: Danh sách danh mục này NÊN được đồng bộ hóa với danh sách bạn
// đã định nghĩa trong AddTransactionScreen.dart.
// Lý tưởng nhất là bạn nên có một nguồn duy nhất cho các danh mục này,
// ví dụ như định nghĩa chúng trong AppProvider hoặc một service riêng.
// Hiện tại, tôi sẽ sao chép chúng từ AddTransactionScreen bạn đã cung cấp.

class CategoryHelper {
  static final List<Map<String, dynamic>> _expenseCategories = [
    {'label': 'Ăn uống', 'icon': Icons.restaurant_menu_rounded, 'color': Colors.orange.shade700},
    {'label': 'Di chuyển', 'icon': Icons.directions_car_rounded, 'color': Colors.blue.shade700},
    {'label': 'Mua sắm', 'icon': Icons.shopping_bag_rounded, 'color': Colors.purple.shade700},
    {'label': 'Hóa đơn', 'icon': Icons.receipt_long_rounded, 'color': Colors.teal.shade700},
    {'label': 'Giải trí', 'icon': Icons.movie_filter_rounded, 'color': Colors.red.shade700},
    {'label': 'Giáo dục', 'icon': Icons.school_rounded, 'color': Colors.indigo.shade700},
    {'label': 'Sức khỏe', 'icon': Icons.healing_rounded, 'color': Colors.green.shade700},
    {'label': 'Khác', 'icon': Icons.more_horiz_rounded, 'color': Colors.grey.shade700},
    // Thêm các danh mục chi tiêu khác nếu bạn có
  ];

  static final List<Map<String, dynamic>> _incomeCategories = [
    {'label': 'Lương', 'icon': Icons.wallet_rounded, 'color': Colors.green.shade700},
    {'label': 'Thưởng', 'icon': Icons.card_giftcard_rounded, 'color': Colors.lightGreen.shade700},
    {'label': 'Đầu tư', 'icon': Icons.trending_up_rounded, 'color': Colors.teal.shade600},
    {'label': 'Bán đồ', 'icon': Icons.sell_rounded, 'color': Colors.blueGrey.shade500},
    {'label': 'Thu nhập khác', 'icon': Icons.attach_money_rounded, 'color': Colors.amber.shade700},
    // Thêm các danh mục thu nhập khác nếu bạn có
  ];

  static Map<String, dynamic> getCategoryDetails(String categoryLabel, String transactionType) {
    final List<Map<String, dynamic>> categoriesToSearch =
    transactionType == 'Chi tiêu' ? _expenseCategories : _incomeCategories;

    try {
      final category = categoriesToSearch.firstWhere(
            (cat) => cat['label'] == categoryLabel,
      );
      return category;
    } catch (e) {
      // Nếu không tìm thấy, trả về một mục mặc định
      return {
        'label': categoryLabel,
        'icon': transactionType == 'Chi tiêu' ? Icons.label_important_outline_rounded : Icons.attach_money_rounded,
        'color': Colors.grey.shade600, // Màu mặc định
      };
    }
  }

  static IconData getCategoryIcon(String categoryLabel, String transactionType) {
    return getCategoryDetails(categoryLabel, transactionType)['icon'] as IconData;
  }

  static Color getCategoryColor(String categoryLabel, String transactionType) {
    return getCategoryDetails(categoryLabel, transactionType)['color'] as Color;
  }
}

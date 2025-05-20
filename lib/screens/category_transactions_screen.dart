import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/expense_transaction.dart';
import '../utils/category_helper.dart'; // Để lấy icon và màu
import '../routes.dart'; // Để điều hướng sửa giao dịch
import 'home_screen.dart' show CategoryDetailType; // <--- THÊM IMPORT NÀY

class CategoryTransactionsScreen extends StatelessWidget {
  final String categoryName;
  final CategoryDetailType categoryType; // Sử dụng enum từ home_screen

  const CategoryTransactionsScreen({
    super.key,
    required this.categoryName,
    required this.categoryType,
  });

  // Hàm hiển thị dialog xác nhận xóa (tương tự HistoryScreen)
  Future<void> _confirmDelete(BuildContext context, ExpenseTransaction transaction, AppProvider appProvider) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận Xóa'),
          content: Text('Bạn có chắc chắn muốn xóa giao dịch "${transaction.title}"?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
              child: const Text('Xóa'),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Đóng dialog trước
                try {
                  await appProvider.deleteTransaction(transaction.id);
                  // SnackBar thông báo thành công có thể không cần thiết nếu danh sách tự cập nhật
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi khi xóa: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToEditScreen(BuildContext context, ExpenseTransaction transaction) {
    Navigator.pushNamed(context, Routes.addTransaction, arguments: transaction);
  }


  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final textTheme = Theme.of(context).textTheme;
    final currencyFormatter = NumberFormat("#,##0đ", "vi_VN");

    List<ExpenseTransaction> filteredTransactions = [];

    if (categoryType == CategoryDetailType.subCategory) {
      filteredTransactions = appProvider.currentMonthTransactions
          .where((tx) => tx.category == categoryName && (tx.amount ?? 0) < 0) // Chỉ lấy chi tiêu
          .toList();
    } else { // parentCategory
      // Sửa tên phương thức cho đúng với AppProvider
      Map<String, dynamic> parentDef = AppProvider.getParentCategoryDefinitionMap()[categoryName] ?? {};
      List<String> subCategories = List<String>.from(parentDef['subCategories'] ?? []);

      // Sửa tên phương thức cho đúng với AppProvider
      if (categoryName == AppProvider.getDefaultParentCategoryName()) {
        // Nếu là "Chi tiêu khác (Cha)", lấy tất cả các danh mục con không thuộc bất kỳ danh mục cha nào đã định nghĩa
        // Sửa tên phương thức cho đúng với AppProvider
        final allDefinedSubCategories = AppProvider.getParentCategoryDefinitionMap().values.expand((def) => List<String>.from(def['subCategories'] ?? [])).toSet();
        filteredTransactions = appProvider.currentMonthTransactions
            .where((tx) => (tx.amount ?? 0) < 0 && !allDefinedSubCategories.contains(tx.category) )
            .toList();
      } else {
        filteredTransactions = appProvider.currentMonthTransactions
            .where((tx) => subCategories.contains(tx.category) && (tx.amount ?? 0) < 0)
            .toList();
      }
    }

    // Sắp xếp theo ngày giảm dần
    filteredTransactions.sort((a, b) => b.date.compareTo(a.date));

    // Tính tổng số tiền cho danh mục này
    double totalAmountForCategory = filteredTransactions.fold(0.0, (sum, tx) => sum + (tx.amount?.abs() ?? 0.0));

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        // Các style khác của AppBar sẽ lấy từ theme
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tổng chi tiêu cho mục này:', style: textTheme.titleMedium),
                Text(
                  currencyFormatter.format(totalAmountForCategory),
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: filteredTransactions.isEmpty
                ? Center(
              child: Padding( // Thêm Padding để nội dung không quá sát viền
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Không có giao dịch nào cho danh mục này trong tháng.',
                  style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            )
                : ListView.separated(
              itemCount: filteredTransactions.length,
              itemBuilder: (context, index) {
                final transaction = filteredTransactions[index];
                final categoryDetails = CategoryHelper.getCategoryDetails(transaction.category, transaction.type);
                final IconData itemIcon = categoryDetails['icon'] as IconData;
                final Color itemColor = categoryDetails['color'] as Color;

                return Dismissible(
                  key: ValueKey(transaction.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    _confirmDelete(context, transaction, appProvider);
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
                      backgroundColor: itemColor.withOpacity(0.15),
                      foregroundColor: itemColor,
                      child: Icon(itemIcon, size: 20),
                    ),
                    title: Text(
                      transaction.title,
                      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(transaction.date)),
                    trailing: Text(
                      currencyFormatter.format(transaction.amount),
                      style: textTheme.titleSmall?.copyWith(
                        color: (transaction.amount ?? 0) < 0 ? Colors.red.shade700 : Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => _navigateToEditScreen(context, transaction),
                  ),
                );
              },
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
            ),
          ),
        ],
      ),
    );
  }
}
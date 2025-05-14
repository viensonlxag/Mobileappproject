import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart'; // Import để sử dụng groupBy

import '../providers/app_provider.dart';
import '../models/expense_transaction.dart';
import '../utils/category_helper.dart'; // Import tiện ích danh mục
import '../routes.dart'; // Import Routes để điều hướng khi sửa

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  // Hàm hiển thị dialog xác nhận xóa
  Future<void> _confirmDelete(BuildContext context, ExpenseTransaction transaction) async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Người dùng phải chọn một hành động
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận Xóa Giao Dịch'),
          content: Text('Bạn có chắc chắn muốn xóa giao dịch "${transaction.title}" vào ngày ${DateFormat('dd/MM/yyyy').format(transaction.date)}?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
              child: const Text('Xóa'),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Đóng dialog trước
                try {
                  await appProvider.deleteTransaction(transaction.id);
                  // Không cần ScaffoldMessenger ở đây nếu AppProvider tự notifyListeners và UI tự cập nhật
                } catch (e) {
                  if (context.mounted) { // Kiểm tra context còn mounted không
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi khi xóa giao dịch: $e'),
                        backgroundColor: Colors.red,
                      ),
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

  // Hàm điều hướng đến màn hình sửa (sẽ được hoàn thiện sau)
  void _navigateToEditScreen(BuildContext context, ExpenseTransaction transaction) {
    // Khi màn hình AddTransactionScreen đã sẵn sàng nhận transaction để sửa:
    Navigator.pushNamed(context, Routes.addTransaction, arguments: transaction);
    // Hiện tại, AddTransactionScreen chưa xử lý argument này,
    // nên nó sẽ hoạt động như thêm mới.
    // Bạn cần cập nhật AddTransactionScreen để điền dữ liệu khi argument được truyền vào.
    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(content: Text('Chức năng sửa đang được phát triển!')),
    // );
  }


  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    // Lấy tất cả giao dịch và sắp xếp theo ngày giảm dần
    final List<ExpenseTransaction> sortedTransactions = List.from(appProvider.transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Nhóm giao dịch theo ngày
    final groupedTransactions = groupBy<ExpenseTransaction, DateTime>(
      sortedTransactions,
          (transaction) => DateTime(transaction.date.year, transaction.date.month, transaction.date.day),
    );

    final List<MapEntry<DateTime, List<ExpenseTransaction>>> groupedEntries = groupedTransactions.entries.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sổ Giao Dịch'),
        // Các thuộc tính AppBar khác sẽ lấy từ Theme
      ),
      body: sortedTransactions.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có giao dịch nào.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy nhấn nút "+" để thêm giao dịch mới!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.only(bottom: 80.0, top: 8.0), // Padding cho toàn bộ list
        itemCount: groupedEntries.length,
        itemBuilder: (ctx, groupIndex) {
          final dateGroup = groupedEntries[groupIndex];
          final date = dateGroup.key;
          final dailyTransactions = dateGroup.value;
          double dailyTotal = dailyTransactions.fold(0.0, (sum, tx) => sum + tx.amount);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('EEEE, dd MMMM, yyyy', 'vi_VN').format(date),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(dailyTotal),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: dailyTotal == 0 ? Colors.grey[700] : (dailyTotal > 0 ? Colors.green.shade700 : Colors.red.shade700),
                      ),
                    )
                  ],
                ),
              ),
              Card( // Bọc các giao dịch trong ngày bằng Card để đẹp hơn
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                elevation: 1, // Giảm elevation
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: dailyTransactions.length,
                  itemBuilder: (ctxItem, itemIndex) {
                    final transaction = dailyTransactions[itemIndex];
                    return _TransactionListItem(
                      transaction: transaction,
                      onDelete: () => _confirmDelete(context, transaction),
                      onEdit: () => _navigateToEditScreen(context, transaction),
                    );
                  },
                  separatorBuilder: (ctx, idx) => const Divider(height: 0.5, indent: 72, endIndent: 16),
                ),
              ),
            ],
          );
        },
      ),
      // FloatingActionButton để thêm giao dịch mới (tùy chọn)
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     Navigator.pushNamed(context, Routes.addTransaction);
      //   },
      //   backgroundColor: Colors.pinkAccent,
      //   child: const Icon(Icons.add, color: Colors.white),
      // ),
    );
  }
}

class _TransactionListItem extends StatelessWidget {
  final ExpenseTransaction transaction;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _TransactionListItem({
    required this.transaction,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final categoryDetails = CategoryHelper.getCategoryDetails(transaction.category, transaction.type);
    final IconData categoryIcon = categoryDetails['icon'] as IconData;
    final Color categoryColor = categoryDetails['color'] as Color;
    final bool isExpense = transaction.amount < 0;
    final NumberFormat currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        onDelete();
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
      child: Material(
        color: Colors.transparent, // Để InkWell của ListTile có hiệu ứng
        child: ListTile(
          onTap: onEdit, // Nhấn vào để sửa
          leading: CircleAvatar(
            backgroundColor: categoryColor.withOpacity(0.15),
            foregroundColor: categoryColor,
            radius: 22,
            child: Icon(categoryIcon, size: 20),
          ),
          title: Text(
            transaction.title, // Thường là tên danh mục
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (transaction.note != null && transaction.note!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    transaction.note!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (transaction.sources.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    transaction.sources.join(', '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.blueGrey.shade400, fontStyle: FontStyle.italic, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          trailing: Text(
            currencyFormatter.format(transaction.amount),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isExpense ? Colors.red.shade700 : Colors.green.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        ),
      ),
    );
  }
}

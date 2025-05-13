import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseTransaction {
  final String id;
  final String title; // Thường là tên category hoặc mô tả ngắn
  final double amount;
  final DateTime date;
  final String type; // 'Chi tiêu' hoặc 'Thu nhập'
  final String category;
  final String? note; // Ghi chú, có thể null
  final List<String> sources; // Nguồn tiền, ví dụ: ['Tiền mặt', 'Ngân hàng']

  ExpenseTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
    this.note, // Thêm note làm tham số tùy chọn
    this.sources = const [], // Thêm sources với giá trị mặc định là danh sách rỗng
  });

  // Factory constructor để tạo đối tượng từ Firestore document
  factory ExpenseTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExpenseTransaction(
      id: doc.id,
      title: data['title'] as String,
      amount: (data['amount'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      type: data['type'] as String,
      category: data['category'] as String,
      note: data['note'] as String?, // Lấy note, có thể null
      sources: List<String>.from(data['sources'] ?? []), // Lấy sources, nếu null thì dùng list rỗng
    );
  }

  // Phương thức để chuyển đổi đối tượng thành Map để lưu vào Firestore
  Map<String, dynamic> toMap() => {
    'title': title,
    'amount': amount,
    'date': Timestamp.fromDate(date),
    'type': type,
    'category': category,
    'note': note, // Thêm note vào map
    'sources': sources, // Thêm sources vào map
  };
}

// models/budget.dart

class Budget {
  final String id;
  final String name;
  final String categoryName; // Sẽ dùng để liên kết với CategoryHelper cho icon/màu sắc
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final bool isRecurring;

  Budget({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.amount,
    required this.startDate,
    required this.endDate,
    this.isRecurring = false,
  });

  // Factory constructor để tạo đối tượng Budget từ Map (dữ liệu Firestore)
  factory Budget.fromMap(Map<String, dynamic> map, String documentId) {
    return Budget(
      id: documentId,
      name: map['name'] as String? ?? '',
      categoryName: map['categoryName'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      startDate: map['startDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['startDate'] as int)
          : DateTime.now(), // Cung cấp giá trị mặc định nếu null
      endDate: map['endDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endDate'] as int)
          : DateTime.now().add(const Duration(days: 30)), // Cung cấp giá trị mặc định
      isRecurring: map['isRecurring'] as bool? ?? false,
    );
  }

  // Phương thức để chuyển đổi đối tượng Budget thành Map (để lưu vào Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'categoryName': categoryName,
      'amount': amount,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'isRecurring': isRecurring,
    };
  }
}

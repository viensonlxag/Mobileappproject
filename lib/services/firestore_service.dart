import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_transaction.dart'; // Đảm bảo đường dẫn này đúng
import '../models/budget.dart'; // ***** THÊM IMPORT CHO BUDGET MODEL *****

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid; // User ID của người dùng hiện tại

  FirestoreService(this.uid);

  // --- Transaction Methods ---

  /// Lắng nghe stream các giao dịch của người dùng.
  /// Sắp xếp theo ngày giảm dần.
  Stream<List<ExpenseTransaction>> streamTransactions() {
    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .orderBy('date', descending: true) // Sắp xếp mới nhất lên đầu
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ExpenseTransaction.fromFirestore(doc))
        .toList());
  }

  /// Thêm một giao dịch mới vào Firestore.
  Future<void> addTransaction(ExpenseTransaction tx) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .add(tx.toMap());
  }

  /// Cập nhật một giao dịch đã có trong Firestore.
  Future<void> updateTransaction(ExpenseTransaction updatedTx) {
    if (updatedTx.id.isEmpty) {
      return Future.error("Transaction ID không được rỗng khi cập nhật.");
    }
    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .doc(updatedTx.id)
        .update(updatedTx.toMap());
  }

  /// Xóa một giao dịch khỏi Firestore dựa trên ID của nó.
  Future<void> deleteTransaction(String transactionId) {
    if (transactionId.isEmpty) {
      return Future.error("Transaction ID không được rỗng khi xóa.");
    }
    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .doc(transactionId)
        .delete();
  }

  // --- Budget Methods ---

  /// Lắng nghe stream các ngân sách của người dùng.
  /// Có thể sắp xếp theo tên hoặc ngày tạo nếu muốn.
  Stream<List<Budget>> streamBudgets() {
    return _db
        .collection('users')
        .doc(uid)
        .collection('budgets') // ***** COLLECTION MỚI CHO NGÂN SÁCH *****
        .orderBy('startDate', descending: false) // Ví dụ: sắp xếp theo ngày bắt đầu
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data(); // Lấy dữ liệu một lần
        // Kiểm tra nếu data không null trước khi sử dụng
        return data != null ? Budget.fromMap(data, doc.id) : null;
      }).whereType<Budget>().toList(); // Lọc bỏ các giá trị null và chuyển thành List<Budget>
    });
  }

  /// Thêm một ngân sách mới vào Firestore.
  Future<void> addBudget(Budget budget) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .add(budget.toMap()); // Firestore sẽ tự tạo ID
  }

  /// Cập nhật một ngân sách đã có trong Firestore.
  Future<void> updateBudget(Budget updatedBudget) {
    if (updatedBudget.id.isEmpty) {
      return Future.error("Budget ID không được rỗng khi cập nhật.");
    }
    return _db
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .doc(updatedBudget.id)
        .update(updatedBudget.toMap());
  }

  /// Xóa một ngân sách khỏi Firestore dựa trên ID của nó.
  Future<void> deleteBudget(String budgetId) {
    if (budgetId.isEmpty) {
      return Future.error("Budget ID không được rỗng khi xóa.");
    }
    return _db
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .doc(budgetId)
        .delete();
  }
}

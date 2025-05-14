import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_transaction.dart'; // Đảm bảo đường dẫn này đúng

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid; // User ID của người dùng hiện tại

  FirestoreService(this.uid);

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
    // Firestore sẽ tự động tạo ID cho document mới
    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .add(tx.toMap()); // Sử dụng add() để Firestore tự tạo ID
  }

  /// Cập nhật một giao dịch đã có trong Firestore.
  /// [updatedTx] là đối tượng ExpenseTransaction đã được cập nhật thông tin.
  /// Quan trọng: updatedTx.id phải là ID của document cần cập nhật.
  Future<void> updateTransaction(ExpenseTransaction updatedTx) {
    if (updatedTx.id.isEmpty) {
      // Hoặc bạn có thể ném một lỗi cụ thể hơn
      return Future.error("Transaction ID không được rỗng khi cập nhật.");
    }
    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .doc(updatedTx.id) // Sử dụng ID của giao dịch để xác định document cần cập nhật
        .update(updatedTx.toMap()); // Sử dụng update() để cập nhật các trường
    // Hoặc .set(updatedTx.toMap(), SetOptions(merge: true)) nếu bạn muốn merge
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
        .doc(transactionId) // Sử dụng ID để xác định document cần xóa
        .delete();
  }
}

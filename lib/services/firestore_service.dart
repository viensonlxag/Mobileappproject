import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_transaction.dart'; // Đảm bảo đường dẫn này đúng
import '../models/budget.dart'; // ***** THÊM IMPORT CHO BUDGET MODEL *****
import '../models/app_notification.dart'; // ***** THÊM IMPORT CHO APP NOTIFICATION MODEL *****

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid; // User ID của người dùng hiện tại

  FirestoreService(this.uid);

  // --- Transaction Methods ---

  Stream<List<ExpenseTransaction>> streamTransactions() {
    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ExpenseTransaction.fromFirestore(doc))
        .toList());
  }

  Future<void> addTransaction(ExpenseTransaction tx) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .add(tx.toMap());
  }

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

  Stream<List<Budget>> streamBudgets() {
    return _db
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .orderBy('startDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return data != null ? Budget.fromMap(data, doc.id) : null;
      }).whereType<Budget>().toList();
    });
  }

  Future<void> addBudget(Budget budget) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .add(budget.toMap());
  }

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

  // --- AppNotification Methods ---

  /// Thêm một thông báo ứng dụng mới vào Firestore.
  Future<void> addAppNotification(AppNotification notification) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('app_notifications')
        .add(notification.toFirestore());
  }

  /// Lắng nghe stream các thông báo ứng dụng của người dùng.
  /// Sắp xếp theo thời gian giảm dần.
  Stream<List<AppNotification>> streamAppNotifications() {
    return _db
        .collection('users')
        .doc(uid)
        .collection('app_notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => AppNotification.fromFirestore(doc))
        .toList());
  }

  /// Đánh dấu một thông báo là đã đọc.
  Future<void> markNotificationAsRead(String notificationId) {
    if (notificationId.isEmpty) {
      return Future.error("Notification ID không được rỗng.");
    }
    return _db
        .collection('users')
        .doc(uid)
        .collection('app_notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Xóa một thông báo.
  Future<void> deleteAppNotification(String notificationId) {
    if (notificationId.isEmpty) {
      return Future.error("Notification ID không được rỗng.");
    }
    return _db
        .collection('users')
        .doc(uid)
        .collection('app_notifications')
        .doc(notificationId)
        .delete();
  }

  /// Xóa tất cả thông báo đã đọc.
  Future<void> deleteAllReadAppNotifications() async {
    final batch = _db.batch();
    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('app_notifications')
        .where('isRead', isEqualTo: true)
        .get();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    return batch.commit();
  }
}

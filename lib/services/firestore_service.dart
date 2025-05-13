import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_transaction.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid;

  FirestoreService(this.uid);

  Stream<List<ExpenseTransaction>> streamTransactions() {
    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
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

  Future<void> deleteTransaction(String id) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .doc(id)
        .delete();
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/expense_transaction.dart';

class AppProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  FirestoreService? _firestoreService;
  User? user;
  List<ExpenseTransaction> transactions = [];

  AppProvider() {
    _authService.userChanges.listen((firebaseUser) {
      user = firebaseUser;
      if (user != null) {
        _firestoreService = FirestoreService(user!.uid);
        _listenTransactions();
      } else {
        _firestoreService = null;
        transactions = [];
      }
      notifyListeners();
    });
  }

  void _listenTransactions() {
    _firestoreService!
        .streamTransactions()
        .listen((txList) {
      transactions = txList;
      notifyListeners();
    });
  }

  // ----------------------
  // ✅ Logic cho HomeScreen
  // ----------------------

  List<ExpenseTransaction> get currentMonthTransactions {
    final now = DateTime.now();
    return transactions.where((tx) =>
    tx.date.month == now.month && tx.date.year == now.year).toList();
  }

  List<ExpenseTransaction> get previousMonthTransactions {
    final now = DateTime.now();
    final prevMonth = DateTime(now.year, now.month - 1, 1);
    return transactions.where((tx) =>
    tx.date.month == prevMonth.month && tx.date.year == prevMonth.year).toList();
  }

  double get totalExpense {
    return currentMonthTransactions
        .where((tx) => tx.amount < 0)
        .fold(0.0, (sum, tx) => sum + tx.amount.abs());
  }

  double get totalIncome {
    return currentMonthTransactions
        .where((tx) => tx.amount > 0)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get previousMonthExpense {
    return previousMonthTransactions
        .where((tx) => tx.amount < 0)
        .fold(0.0, (sum, tx) => sum + tx.amount.abs());
  }

  String get expenseCompareText {
    final diff = totalExpense - previousMonthExpense;
    if (diff == 0) return 'Không thay đổi so với tháng trước';
    return diff > 0
        ? 'Tăng ${diff.toStringAsFixed(0)}đ so với tháng trước'
        : 'Giảm ${diff.abs().toStringAsFixed(0)}đ so với tháng trước';
  }

  /// ✅ Dữ liệu cho Pie Chart (theo category %)
  Map<String, double> get categoryBreakdown {
    final Map<String, double> data = {};

    for (var tx in currentMonthTransactions) {
      if (tx.amount < 0) {
        data[tx.category] = (data[tx.category] ?? 0) + tx.amount.abs();
      }
    }

    return data;
  }

  /// ✅ 5 giao dịch gần đây
  List<ExpenseTransaction> get recentTransactions {
    final sortedTx = List<ExpenseTransaction>.from(currentMonthTransactions);
    sortedTx.sort((a, b) => b.date.compareTo(a.date));
    return sortedTx.take(5).toList();
  }

  // ----------------------
  // ✅ Auth & Firestore
  // ----------------------

  Future<void> signIn(String email, String pass) async {
    try {
      await _authService.signIn(email, pass);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> register(String email, String pass) async {
    try {
      await _authService.register(email, pass);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addTransaction(ExpenseTransaction tx) async {
    if (_firestoreService != null) {
      await _firestoreService!.addTransaction(tx);
    } else {
      throw Exception('User chưa đăng nhập');
    }
  }

  Future<void> deleteTransaction(String id) async {
    if (_firestoreService != null) {
      await _firestoreService!.deleteTransaction(id);
    } else {
      throw Exception('User chưa đăng nhập');
    }
  }
}

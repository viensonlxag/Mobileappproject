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

  /// Đăng nhập user
  Future<void> signIn(String email, String pass) async {
    try {
      await _authService.signIn(email, pass);
    } catch (e) {
      rethrow;
    }
  }

  /// Đăng ký tài khoản
  Future<void> register(String email, String pass) async {
    try {
      await _authService.register(email, pass);
    } catch (e) {
      rethrow;
    }
  }

  /// Đăng xuất user
  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// Thêm giao dịch mới
  Future<void> addTransaction(ExpenseTransaction tx) async {
    if (_firestoreService != null) {
      await _firestoreService!.addTransaction(tx);
    } else {
      throw Exception('User chưa đăng nhập');
    }
  }

  /// Xoá giao dịch theo ID
  Future<void> deleteTransaction(String id) async {
    if (_firestoreService != null) {
      await _firestoreService!.deleteTransaction(id);
    } else {
      throw Exception('User chưa đăng nhập');
    }
  }
}

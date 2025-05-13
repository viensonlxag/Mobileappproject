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

  Future<void> signIn(String email, String pass) => _authService.signIn(email, pass);
  Future<void> register(String email, String pass) => _authService.register(email, pass);
  Future<void> signOut() => _authService.signOut();
  Future<void> addTransaction(ExpenseTransaction tx) => _firestoreService!.addTransaction(tx);
  Future<void> deleteTransaction(String id) => _firestoreService!.deleteTransaction(id);
}
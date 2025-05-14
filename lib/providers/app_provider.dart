import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Import intl cho NumberFormat
import '../services/auth_service.dart'; // Đảm bảo đường dẫn này đúng
import '../services/firestore_service.dart'; // Đảm bảo đường dẫn này đúng
import '../models/expense_transaction.dart'; // Đảm bảo đường dẫn này đúng
import '../routes.dart'; // Đảm bảo đường dẫn này đúng

class AppProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  FirestoreService? _firestoreService;
  User? _currentUser;
  List<ExpenseTransaction> _transactions = [];

  // --- TRẠNG THÁI TẢI VÀ LỖI ---
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
  // --- KẾT THÚC TRẠNG THÁI TẢI VÀ LỖI ---


  String _userName = "Bạn";
  DateTime? _userDateOfBirth;

  static const String _userNameKey = 'app_user_name_v2_3_1';
  static const String _userDateOfBirthKey = 'app_user_dob_v2_3_1';

  User? get currentUser => _currentUser;
  String get userName => _userName;
  DateTime? get userDateOfBirth => _userDateOfBirth;
  List<ExpenseTransaction> get transactions => List.unmodifiable(_transactions);

  AppProvider() {
    _authService.userChanges.listen((firebaseUser) async {
      _setLoading(true);
      _clearError();
      _currentUser = firebaseUser;
      if (_currentUser != null) {
        _firestoreService = FirestoreService(_currentUser!.uid);
        await _loadUserProfile();
        _listenTransactions();
      } else {
        _firestoreService = null;
        _transactions = [];
        _resetUserProfile();
        _calculateTotals();
      }
      _setLoading(false);
    });
  }

  void _listenTransactions() {
    if (_firestoreService == null) {
      print("AppProvider: FirestoreService is null, cannot listen to transactions.");
      _transactions = [];
      _calculateTotals();
      notifyListeners();
      return;
    }
    _firestoreService!.streamTransactions().listen((txList) {
      _transactions = txList;
      _calculateTotals();
      notifyListeners();
    }, onError: (error) {
      print("AppProvider: Lỗi lắng nghe transactions: $error");
      _setError("Không thể tải danh sách giao dịch: ${error.toString()}");
      _transactions = [];
      _calculateTotals();
      notifyListeners();
    });
  }

  Future<void> _loadUserProfile() async {
    if (_currentUser == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _userName = prefs.getString(_userNameKey) ?? _currentUser?.displayName ?? "Bạn";

      final dobMillis = prefs.getInt(_userDateOfBirthKey);
      if (dobMillis != null) {
        _userDateOfBirth = DateTime.fromMillisecondsSinceEpoch(dobMillis);
      } else {
        _userDateOfBirth = null;
      }
      if (_userName == "Bạn" && _currentUser?.displayName != null && _currentUser!.displayName!.isNotEmpty) {
        _userName = _currentUser!.displayName!;
      }
    } catch (e) {
      print("AppProvider: Lỗi tải user profile: $e");
    }
  }

  void _resetUserProfile() {
    _userName = "Bạn";
    _userDateOfBirth = null;
  }

  Future<void> updateUserName(String newName) async {
    if (_currentUser == null) {
      _setError("Vui lòng đăng nhập để cập nhật tên.");
      return;
    }
    _setLoading(true);
    _clearError();
    final oldName = _userName;
    try {
      _userName = newName.trim().isEmpty ? (_currentUser?.displayName ?? "Bạn") : newName.trim();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userNameKey, _userName);
      if (_currentUser?.displayName != _userName && _userName != "Bạn") {
        await _currentUser?.updateDisplayName(_userName);
      }
    } catch (e) {
      print("AppProvider: Lỗi cập nhật displayName trên Firebase: $e");
      _userName = oldName;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userNameKey, _userName);
      _setError("Lỗi cập nhật tên: ${e.toString()}");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUserDateOfBirth(DateTime newDateOfBirth) async {
    _setLoading(true);
    _clearError();
    try {
      _userDateOfBirth = newDateOfBirth;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_userDateOfBirthKey, _userDateOfBirth!.millisecondsSinceEpoch);
    } catch (e) {
      print("AppProvider: Lỗi cập nhật ngày sinh: $e");
      _setError("Lỗi cập nhật ngày sinh: ${e.toString()}");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  List<ExpenseTransaction> get currentMonthTransactions {
    final now = DateTime.now();
    return _transactions
        .where((tx) => tx.date.month == now.month && tx.date.year == now.year)
        .toList();
  }

  List<ExpenseTransaction> get previousMonthTransactions {
    final now = DateTime.now();
    final prevMonth = DateTime(now.year, now.month - 1, 1);
    return _transactions
        .where((tx) => tx.date.month == prevMonth.month && tx.date.year == prevMonth.year)
        .toList();
  }

  double get totalExpense {
    return currentMonthTransactions
        .where((tx) => (tx.amount ?? 0.0) < 0)
        .fold<double>(0.0, (double sum, ExpenseTransaction tx) { // Thêm kiểu rõ ràng cho sum
      final double currentAmount = tx.amount?.abs() ?? 0.0;
      return sum + currentAmount;
    });
  }

  double get totalIncome {
    return currentMonthTransactions
        .where((tx) => (tx.amount ?? 0.0) > 0)
        .fold<double>(0.0, (double sum, ExpenseTransaction tx) { // Thêm kiểu rõ ràng cho sum
      final double currentAmount = tx.amount ?? 0.0;
      return sum + currentAmount;
    });
  }

  Map<String, double> get categoryBreakdown {
    final Map<String, double> data = {};
    for (var tx in currentMonthTransactions) {
      if ((tx.amount ?? 0.0) < 0) {
        final double currentCategoryAmount = data[tx.category] ?? 0.0; // Đảm bảo không null
        final double transactionAmount = tx.amount?.abs() ?? 0.0; // Đảm bảo không null
        data[tx.category] = currentCategoryAmount + transactionAmount;
      }
    }
    return data;
  }

  String get expenseCompareText {
    final currentMonthExp = totalExpense;
    final prevMonthExp = previousMonthTransactions
        .where((tx) => (tx.amount ?? 0.0) < 0)
        .fold<double>(0.0, (double sum, ExpenseTransaction tx) { // Thêm kiểu rõ ràng cho sum
      final double currentAmount = tx.amount?.abs() ?? 0.0;
      return sum + currentAmount;
    });

    if (previousMonthTransactions.isEmpty && currentMonthExp == 0) {
      return 'Chưa có dữ liệu chi tiêu để so sánh.';
    }
    if (previousMonthTransactions.isEmpty && currentMonthExp > 0) {
      return 'Tháng trước không có chi tiêu.';
    }
    if (currentMonthExp == 0 && prevMonthExp > 0) {
      return 'Tháng này chưa có chi tiêu.';
    }
    final diff = currentMonthExp - prevMonthExp;
    if (diff == 0) return 'Không thay đổi so với tháng trước';

    final formattedDiff = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(diff.abs());
    return diff > 0
        ? 'Tăng $formattedDiff so với tháng trước'
        : 'Giảm $formattedDiff so với tháng trước';
  }

  List<ExpenseTransaction> get recentTransactions {
    final sortedTx = List<ExpenseTransaction>.from(_transactions);
    sortedTx.sort((a, b) => b.date.compareTo(a.date));
    return sortedTx.take(5).toList();
  }

  Future<void> signIn(String email, String pass) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.signIn(email, pass);
    } catch (e) {
      _setError("Đăng nhập thất bại: ${e.toString()}");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register(String email, String pass) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.register(email, pass);
    } catch (e) {
      _setError("Đăng ký thất bại: ${e.toString()}");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> appSignOut(BuildContext context) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.signOut();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(Routes.login, (Route<dynamic> route) => false);
        }
      });
    } catch (e) {
      print("AppProvider: Lỗi khi đăng xuất: $e");
      _setError("Đăng xuất thất bại: ${e.toString()}");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addTransaction(ExpenseTransaction tx) async {
    if (_firestoreService == null) {
      _setError('User chưa đăng nhập để thêm giao dịch');
      throw Exception('User chưa đăng nhập để thêm giao dịch');
    }
    _setLoading(true);
    _clearError();
    try {
      await _firestoreService!.addTransaction(tx);
    } catch (e) {
      _setError("Lỗi thêm giao dịch: ${e.toString()}");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTransaction(ExpenseTransaction updatedTx) async {
    if (_firestoreService == null) {
      _setError('User chưa đăng nhập để cập nhật giao dịch');
      throw Exception('User chưa đăng nhập để cập nhật giao dịch');
    }
    _setLoading(true);
    _clearError();
    try {
      await _firestoreService!.updateTransaction(updatedTx);
    } catch (e) {
      _setError("Lỗi cập nhật giao dịch: ${e.toString()}");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteTransaction(String id) async {
    if (_firestoreService == null) {
      _setError('User chưa đăng nhập để xóa giao dịch');
      throw Exception('User chưa đăng nhập để xóa giao dịch');
    }
    _setLoading(true);
    _clearError();
    try {
      await _firestoreService!.deleteTransaction(id);
    } catch (e) {
      _setError("Lỗi xóa giao dịch: ${e.toString()}");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _calculateTotals() {
    // Các getters sẽ tự tính toán.
  }
}

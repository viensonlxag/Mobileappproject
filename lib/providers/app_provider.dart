import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart'; // THÊM IMPORT NÀY
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/expense_transaction.dart';
import '../routes.dart'; // THÊM IMPORT NÀY

class AppProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  FirestoreService? _firestoreService;
  User? _currentUser; // Đổi tên user thành _currentUser để rõ ràng hơn
  List<ExpenseTransaction> transactions = [];

  // --- THÔNG TIN NGƯỜI DÙNG MỚI ---
  String _userName = "Bạn"; // Tên mặc định
  DateTime? _userDateOfBirth;

  static const String _userNameKey = 'app_user_name'; // Key cho SharedPreferences
  static const String _userDateOfBirthKey = 'app_user_dob';

  // Getters cho thông tin người dùng
  User? get currentUser => _currentUser;
  String get userName => _userName;
  DateTime? get userDateOfBirth => _userDateOfBirth;
  // --- KẾT THÚC THÔNG TIN NGƯỜI DÙNG MỚI ---

  AppProvider() {
    _authService.userChanges.listen((firebaseUser) async { // Chuyển thành async
      _currentUser = firebaseUser;
      if (_currentUser != null) {
        _firestoreService = FirestoreService(_currentUser!.uid);
        await _loadUserProfile(); // Tải thông tin user khi đăng nhập
        _listenTransactions();
      } else {
        _firestoreService = null;
        transactions = [];
        _resetUserProfile(); // Reset thông tin user khi đăng xuất
      }
      notifyListeners();
    });
  }

  void _listenTransactions() {
    if (_firestoreService == null) return;
    _firestoreService!.streamTransactions().listen((txList) {
      transactions = txList;
      notifyListeners(); // Thông báo sau khi cập nhật transactions
    }, onError: (error) {
      print("Lỗi lắng nghe transactions: $error");
      transactions = []; // Reset transactions nếu có lỗi
      notifyListeners();
    });
  }

  // --- PHƯƠNG THỨC QUẢN LÝ USER PROFILE MỚI ---
  Future<void> _loadUserProfile() async {
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString(_userNameKey) ?? _currentUser?.displayName ?? "Bạn";

    final dobMillis = prefs.getInt(_userDateOfBirthKey);
    if (dobMillis != null) {
      _userDateOfBirth = DateTime.fromMillisecondsSinceEpoch(dobMillis);
    } else {
      _userDateOfBirth = null;
    }
    // Nếu userName là "Bạn" và Firebase có displayName, cập nhật lại
    if (_userName == "Bạn" && _currentUser?.displayName != null && _currentUser!.displayName!.isNotEmpty) {
      _userName = _currentUser!.displayName!;
      // Tùy chọn: lưu lại vào SharedPreferences nếu muốn
      // await prefs.setString(_userNameKey, _userName);
    }
    notifyListeners();
  }

  void _resetUserProfile() {
    _userName = "Bạn";
    _userDateOfBirth = null;
    // Không cần notifyListeners() ở đây vì sẽ được gọi trong userChanges listener
  }

  Future<void> updateUserName(String newName) async {
    if (_currentUser == null) return; // Chỉ cập nhật nếu đã đăng nhập

    final oldName = _userName;
    if (newName.trim().isEmpty) {
      _userName = _currentUser?.displayName ?? "Bạn"; // Nếu rỗng, thử lấy từ Firebase hoặc mặc định
    } else {
      _userName = newName.trim();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, _userName);

    // Cập nhật displayName trên Firebase Auth nếu tên thay đổi và khác với tên trên Firebase
    if (_currentUser?.displayName != _userName && _userName != "Bạn") {
      try {
        await _currentUser?.updateDisplayName(_userName);
      } catch (e) {
        print("Lỗi cập nhật displayName trên Firebase: $e");
        _userName = oldName; // Khôi phục tên cũ nếu lỗi
        await prefs.setString(_userNameKey, _userName); // Lưu lại tên cũ
        notifyListeners();
        rethrow; // Ném lỗi ra để UI có thể xử lý
      }
    }
    notifyListeners();
  }

  Future<void> updateUserDateOfBirth(DateTime newDateOfBirth) async {
    _userDateOfBirth = newDateOfBirth;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userDateOfBirthKey, _userDateOfBirth!.millisecondsSinceEpoch);
    notifyListeners();
  }
  // --- KẾT THÚC PHƯƠNG THỨC USER PROFILE ---

  // Logic cho HomeScreen (giữ nguyên và điều chỉnh nếu cần)
  List<ExpenseTransaction> get currentMonthTransactions {
    final now = DateTime.now();
    return transactions
        .where((tx) => tx.date.month == now.month && tx.date.year == now.year)
        .toList();
  }

  List<ExpenseTransaction> get previousMonthTransactions {
    final now = DateTime.now();
    final prevMonth = DateTime(now.year, now.month - 1, 1);
    return transactions
        .where((tx) => tx.date.month == prevMonth.month && tx.date.year == prevMonth.year)
        .toList();
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
    if (previousMonthTransactions.isEmpty && currentMonthTransactions.where((tx) => tx.amount < 0).isEmpty) {
      return 'Chưa có dữ liệu chi tiêu để so sánh.';
    }
    if (previousMonthTransactions.isEmpty) {
      return 'Tháng trước không có chi tiêu.';
    }
    final diff = totalExpense - previousMonthExpense;
    if (diff == 0) return 'Không thay đổi so với tháng trước';
    return diff > 0
        ? 'Tăng ${diff.toStringAsFixed(0)}đ so với tháng trước'
        : 'Giảm ${diff.abs().toStringAsFixed(0)}đ so với tháng trước';
  }

  Map<String, double> get categoryBreakdown {
    final Map<String, double> data = {};
    for (var tx in currentMonthTransactions) {
      if (tx.amount < 0) {
        data[tx.category] = (data[tx.category] ?? 0) + tx.amount.abs();
      }
    }
    return data;
  }

  List<ExpenseTransaction> get recentTransactions {
    final sortedTx = List<ExpenseTransaction>.from(transactions); // Lấy từ tất cả giao dịch
    sortedTx.sort((a, b) => b.date.compareTo(a.date));
    return sortedTx.take(5).toList();
  }

  // Auth & Firestore (điều chỉnh signOut)
  Future<void> signIn(String email, String pass) async {
    try {
      await _authService.signIn(email, pass);
      // _loadUserProfile() sẽ được gọi bởi listener userChanges
    } catch (e) {
      rethrow;
    }
  }

  Future<void> register(String email, String pass) async {
    try {
      await _authService.register(email, pass);
      // _loadUserProfile() sẽ được gọi bởi listener userChanges
    } catch (e) {
      rethrow;
    }
  }

  // Đã sửa lại hàm signOut để truyền context
  Future<void> appSignOut(BuildContext context) async { // Đổi tên để tránh trùng với _authService.signOut
    try {
      await _authService.signOut(); // Gọi hàm signOut từ AuthService
      // _resetUserProfile() và clear transactions đã được xử lý trong listener userChanges
      // Điều hướng về màn hình đăng nhập
      Navigator.of(context).pushNamedAndRemoveUntil(Routes.login, (Route<dynamic> route) => false);
    } catch (e) {
      print("Lỗi khi đăng xuất trong AppProvider: $e");
      // Hiển thị lỗi cho người dùng nếu cần thiết
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng xuất thất bại: ${e.toString()}')),
      );
      rethrow;
    }
  }

  Future<void> addTransaction(ExpenseTransaction tx) async {
    if (_firestoreService != null) {
      await _firestoreService!.addTransaction(tx);
    } else {
      throw Exception('User chưa đăng nhập để thêm giao dịch');
    }
  }

  Future<void> deleteTransaction(String id) async {
    if (_firestoreService != null) {
      await _firestoreService!.deleteTransaction(id);
    } else {
      throw Exception('User chưa đăng nhập để xóa giao dịch');
    }
  }
}

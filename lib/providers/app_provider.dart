import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Import intl cho NumberFormat và DateFormat
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
    if (_errorMessage != message) {
      _errorMessage = message;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
  // --- KẾT THÚC TRẠNG THÁI TẢI VÀ LỖI ---

  String _userName = "Bạn";
  DateTime? _userDateOfBirth;

  // Cập nhật key để tránh xung đột với dữ liệu cũ nếu cấu trúc thay đổi đáng kể
  static const String _userNameKey = 'app_user_name_v2_4';
  static const String _userDateOfBirthKey = 'app_user_dob_v2_4';

  User? get currentUser => _currentUser;
  String get userName => _userName;
  DateTime? get userDateOfBirth => _userDateOfBirth;
  List<ExpenseTransaction> get transactions => List.unmodifiable(_transactions);

  // --- ĐỊNH NGHĨA DANH MỤC CHA VÀ CÁC THUỘC TÍNH CỦA CHÚNG ---
  // Key: Tên Danh mục cha
  // Value: Map chứa 'icon', 'color', và 'subCategories' (List<String>)
  // BẠN CẦN TÙY CHỈNH MAP NÀY CHO PHÙ HỢP VỚI ỨNG DỤNG CỦA MÌNH
  // Đảm bảo các 'label' trong subCategories khớp với các 'label' bạn dùng trong AddTransactionScreen
  static final Map<String, Map<String, dynamic>> _parentCategoryDefinitions = {
    'Chi tiêu sinh hoạt': { // Ví dụ từ hình ảnh bạn gửi
      'icon': Icons.receipt_long_outlined, // Icon hóa đơn cho sinh hoạt
      'color': Colors.orange.shade700,
      'subCategories': ['Ăn uống', 'Di chuyển', 'Hóa đơn', 'Sức khỏe', 'Chợ, siêu thị'],
    },
    'Chi phí phát sinh': { // Ví dụ từ hình ảnh bạn gửi
      'icon': Icons.attach_money_rounded, // Icon tiền
      'color': Colors.green.shade600,
      'subCategories': ['Mua sắm', 'Giải trí'], // Giả sử Mua sắm, Giải trí là chi phí phát sinh
    },
    'Chi phí cố định': { // Ví dụ từ hình ảnh bạn gửi
      'icon': Icons.home_rounded, // Icon nhà cửa cho chi phí cố định
      'color': Colors.blue.shade700,
      'subCategories': ['Giáo dục'], // Giả sử Giáo dục là chi phí cố định
    },
    // Bạn có thể thêm các danh mục cha khác ở đây
  };
  // Danh mục cha mặc định cho các danh mục con không được map rõ ràng
  static const String _defaultParentCategory = 'Chưa phân loại'; // Giống hình ảnh của bạn

  // Phương thức tĩnh để lấy icon và màu cho danh mục cha
  static Map<String, dynamic> getParentCategoryVisuals(String parentCategoryName) {
    if (_parentCategoryDefinitions.containsKey(parentCategoryName)) {
      return {
        'icon': _parentCategoryDefinitions[parentCategoryName]!['icon'] ?? Icons.label_outline_rounded,
        'color': _parentCategoryDefinitions[parentCategoryName]!['color'] ?? Colors.grey.shade600,
      };
    }
    // Mặc định cho _defaultParentCategory hoặc các danh mục cha không xác định
    if (parentCategoryName == _defaultParentCategory) {
      return {
        'icon': Icons.help_outline_rounded, // Icon dấu hỏi cho "Chưa phân loại"
        'color': Colors.blueGrey.shade400,
      };
    }
    // Trường hợp không mong muốn
    return {
      'icon': Icons.apps_rounded,
      'color': Colors.grey,
    };
  }
  // Getter tĩnh để truy cập _parentCategoryDefinitions từ bên ngoài (ví dụ: từ CategoryTransactionsScreen)
  static Map<String, Map<String, dynamic>> getParentCategoryDefinitionMap() {
    return _parentCategoryDefinitions;
  }
  static String getDefaultParentCategoryName() {
    return _defaultParentCategory;
  }


  AppProvider() {
    _authService.userChanges.listen((firebaseUser) async {
      _setLoading(true);
      clearError();
      _currentUser = firebaseUser;
      if (_currentUser != null) {
        _firestoreService = FirestoreService(_currentUser!.uid);
        await _loadUserProfile();
        _listenTransactions(); // Gọi sau khi _loadUserProfile và _firestoreService được thiết lập
      } else {
        _firestoreService = null;
        _transactions = [];
        _resetUserProfile();
        // Không cần gọi _calculateTotals() ở đây vì getters sẽ tự tính khi _transactions rỗng
      }
      _setLoading(false);
    });
  }

  void _listenTransactions() {
    if (_firestoreService == null) {
      _transactions = [];
      notifyListeners();
      return;
    }
    _firestoreService!.streamTransactions().listen((txList) {
      _transactions = txList;
      notifyListeners(); // Getters sẽ tự tính toán khi UI build lại
    }, onError: (error) {
      print("AppProvider: Lỗi lắng nghe transactions: $error");
      _setError("Không thể tải danh sách giao dịch: ${error.toString()}");
      _transactions = [];
      notifyListeners();
    });
  }

  Future<void> _loadUserProfile() async {
    if (_currentUser == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _userName = prefs.getString(_userNameKey) ?? _currentUser?.displayName ?? "Bạn";
      final dobMillis = prefs.getInt(_userDateOfBirthKey);
      _userDateOfBirth = dobMillis != null ? DateTime.fromMillisecondsSinceEpoch(dobMillis) : null;
      if (_userName == "Bạn" && _currentUser?.displayName != null && _currentUser!.displayName!.isNotEmpty) {
        _userName = _currentUser!.displayName!;
      }
    } catch (e) {
      print("AppProvider: Lỗi tải user profile: $e");
      _setError("Lỗi tải thông tin người dùng.");
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
    clearError();
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
    clearError();
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
        .fold<double>(0.0, (double sum, ExpenseTransaction tx) {
      final double currentAmount = tx.amount?.abs() ?? 0.0;
      return sum + currentAmount;
    });
  }

  double get totalIncome {
    return currentMonthTransactions
        .where((tx) => (tx.amount ?? 0.0) > 0)
        .fold<double>(0.0, (double sum, ExpenseTransaction tx) {
      final double currentAmount = tx.amount ?? 0.0;
      return sum + currentAmount;
    });
  }

  Map<String, double> get categoryBreakdown {
    final Map<String, double> data = {};
    for (var tx in currentMonthTransactions) {
      if ((tx.amount ?? 0.0) < 0) {
        final double currentCategoryAmount = data[tx.category] ?? 0.0;
        final double transactionAmount = tx.amount?.abs() ?? 0.0;
        data[tx.category] = currentCategoryAmount + transactionAmount;
      }
    }
    return data;
  }

  Map<String, double> get parentCategoryBreakdown {
    final Map<String, double> parentData = {};
    // Khởi tạo tất cả các danh mục cha đã định nghĩa với giá trị 0
    for (var parentName in _parentCategoryDefinitions.keys) {
      parentData[parentName] = 0.0;
    }
    // Khởi tạo cho danh mục cha mặc định nếu nó chưa có trong definitions
    if (!parentData.containsKey(_defaultParentCategory)){
      parentData[_defaultParentCategory] = 0.0;
    }

    for (var tx in currentMonthTransactions) {
      if ((tx.amount ?? 0.0) < 0) {
        String parentCategoryName = _defaultParentCategory;
        bool foundParent = false;
        for (var parentEntry in _parentCategoryDefinitions.entries) {
          final subCategories = parentEntry.value['subCategories'];
          if (subCategories is List<String> && subCategories.contains(tx.category)) {
            parentCategoryName = parentEntry.key;
            foundParent = true;
            break;
          }
        }
        // Nếu danh mục con là "Khác" (theo định nghĩa trong AddTransactionScreen)
        // và nó không được map vào một danh mục cha cụ thể nào ở trên,
        // thì nó sẽ được gán vào _defaultParentCategory.
        if (tx.category == 'Khác' && !foundParent) {
          parentCategoryName = _defaultParentCategory;
        }

        parentData.update(
            parentCategoryName,
                (value) => value + (tx.amount?.abs() ?? 0.0),
            ifAbsent: () => (tx.amount?.abs() ?? 0.0)
        );
      }
    }
    parentData.removeWhere((key, value) => value == 0.0);
    return parentData;
  }

  String get expenseCompareText {
    final currentMonthExp = totalExpense;
    final prevMonthExp = previousMonthTransactions
        .where((tx) => (tx.amount ?? 0.0) < 0)
        .fold<double>(0.0, (double sum, ExpenseTransaction tx) {
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

  Map<int, double> get dailyExpensesCurrentMonth {
    final Map<int, double> dailyData = {};
    final now = DateTime.now();
    final currentMonthTxs = _transactions.where((tx) =>
    tx.date.year == now.year &&
        tx.date.month == now.month &&
        (tx.amount ?? 0.0) < 0);

    for (var tx in currentMonthTxs) {
      dailyData.update(
        tx.date.day,
            (value) => value + (tx.amount?.abs() ?? 0.0),
        ifAbsent: () => (tx.amount?.abs() ?? 0.0),
      );
    }
    return dailyData;
  }

  List<MapEntry<String, double>> getRecentMonthlyExpenses({int numberOfMonths = 6}) {
    final List<MapEntry<String, double>> monthlyDataList = [];
    final now = DateTime.now();
    final monthFormat = DateFormat('MMM', 'vi_VN');

    for (int i = numberOfMonths - 1; i >= 0; i--) {
      DateTime targetMonthDateTime = DateTime(now.year, now.month - i, 1);

      double totalForMonth = _transactions
          .where((tx) =>
      tx.date.year == targetMonthDateTime.year &&
          tx.date.month == targetMonthDateTime.month &&
          (tx.amount ?? 0.0) < 0)
          .fold(0.0, (sum, tx) => sum + (tx.amount?.abs() ?? 0.0));

      monthlyDataList.add(MapEntry(monthFormat.format(targetMonthDateTime), totalForMonth));
    }
    return monthlyDataList;
  }

  Map<String, double> get monthlyExpensesCurrentYear {
    final Map<String, double> monthlyData = {};
    final now = DateTime.now();
    final currentYearTxs = _transactions.where((tx) =>
    tx.date.year == now.year &&
        (tx.amount ?? 0.0) < 0);

    final monthFormat = DateFormat('MMM', 'vi_VN');

    for (int i = 1; i <= 12; i++) {
      monthlyData[monthFormat.format(DateTime(now.year, i))] = 0.0;
    }

    for (var tx in currentYearTxs) {
      String monthKey = monthFormat.format(tx.date);
      monthlyData.update(
        monthKey,
            (value) => value + (tx.amount?.abs() ?? 0.0),
        ifAbsent: () => (tx.amount?.abs() ?? 0.0),
      );
    }
    return monthlyData;
  }

  Future<void> signIn(String email, String pass) async {
    _setLoading(true);
    clearError();
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
    clearError();
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
    clearError();
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
    clearError();
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
    clearError();
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
    clearError();
    try {
      await _firestoreService!.deleteTransaction(id);
    } catch (e) {
      _setError("Lỗi xóa giao dịch: ${e.toString()}");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
}

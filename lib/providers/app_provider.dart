import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln; // Không cần import fln.Day ở đây nữa

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../models/expense_transaction.dart';
import '../models/budget.dart';
import '../routes.dart';

class AppProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  FirestoreService? _firestoreService;
  User? _currentUser;
  List<ExpenseTransaction> _transactions = [];
  List<Budget> _budgets = [];

  bool _isLoading = false;
  String? _errorMessage;

  final Map<String, DateTime> _notifiedBudgetAlerts = {};
  static const Duration _minIntervalBetweenAlerts = Duration(hours: 24);


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

  String _userName = "Bạn";
  DateTime? _userDateOfBirth;

  static const String _userNameKey = 'app_user_name_v2_4';
  static const String _userDateOfBirthKey = 'app_user_dob_v2_4';
  static const String _savedEmailKey = 'app_saved_login_email';
  static const String _savedPasswordKey = 'app_saved_login_password';

  User? get currentUser => _currentUser;
  String get userName => _userName;
  DateTime? get userDateOfBirth => _userDateOfBirth;
  List<ExpenseTransaction> get transactions => List.unmodifiable(_transactions);
  List<Budget> get budgets => List.unmodifiable(_budgets);

  static final Map<String, Map<String, dynamic>> _parentCategoryDefinitions = {
    'Chi tiêu sinh hoạt': {
      'icon': Icons.receipt_long_outlined,
      'color': Colors.orange.shade700,
      'subCategories': ['Ăn uống', 'Di chuyển', 'Hóa đơn', 'Sức khỏe', 'Chợ, siêu thị'],
    },
    'Chi phí phát sinh': {
      'icon': Icons.attach_money_rounded,
      'color': Colors.green.shade600,
      'subCategories': ['Mua sắm', 'Giải trí'],
    },
    'Chi phí cố định': {
      'icon': Icons.home_rounded,
      'color': Colors.blue.shade700,
      'subCategories': ['Giáo dục'],
    },
  };
  static const String _defaultParentCategory = 'Chưa phân loại';

  static Map<String, dynamic> getParentCategoryVisuals(String parentCategoryName) {
    if (_parentCategoryDefinitions.containsKey(parentCategoryName)) {
      return {
        'icon': _parentCategoryDefinitions[parentCategoryName]!['icon'] ?? Icons.label_outline_rounded,
        'color': _parentCategoryDefinitions[parentCategoryName]!['color'] ?? Colors.grey.shade600,
      };
    }
    if (parentCategoryName == _defaultParentCategory) {
      return {
        'icon': Icons.help_outline_rounded,
        'color': Colors.blueGrey.shade400,
      };
    }
    return {
      'icon': Icons.apps_rounded,
      'color': Colors.grey,
    };
  }
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
        _listenTransactions();
        _listenBudgets();
      } else {
        _firestoreService = null;
        _transactions = [];
        _budgets = [];
        _resetUserProfile();
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
      checkAndNotifyForBudgets();
      notifyListeners();
    }, onError: (error) {
      _setError("Không thể tải danh sách giao dịch: ${error.toString()}");
      _transactions = [];
      notifyListeners();
    });
  }

  void _listenBudgets() {
    if (_firestoreService == null) {
      _budgets = [];
      notifyListeners();
      return;
    }
    _firestoreService!.streamBudgets().listen((budgetList) {
      _budgets = budgetList;
      checkAndNotifyForBudgets();
      notifyListeners();
    }, onError: (error) {
      _setError("Không thể tải danh sách ngân sách: ${error.toString()}");
      _budgets = [];
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
        .where((tx) => (tx.amount) < 0)
        .fold<double>(0.0, (double sum, ExpenseTransaction tx) {
      final double currentAmount = tx.amount.abs();
      return sum + currentAmount;
    });
  }

  double get totalIncome {
    return currentMonthTransactions
        .where((tx) => (tx.amount) > 0)
        .fold<double>(0.0, (double sum, ExpenseTransaction tx) {
      final double currentAmount = tx.amount;
      return sum + currentAmount;
    });
  }

  Map<String, double> get categoryBreakdown {
    final Map<String, double> data = {};
    for (var tx in currentMonthTransactions) {
      if ((tx.amount) < 0) {
        final double currentCategoryAmount = data[tx.category] ?? 0.0;
        final double transactionAmount = tx.amount.abs();
        data[tx.category] = currentCategoryAmount + transactionAmount;
      }
    }
    return data;
  }

  Map<String, double> get parentCategoryBreakdown {
    final Map<String, double> parentData = {};
    for (var parentName in _parentCategoryDefinitions.keys) {
      parentData[parentName] = 0.0;
    }
    if (!parentData.containsKey(_defaultParentCategory)){
      parentData[_defaultParentCategory] = 0.0;
    }

    for (var tx in currentMonthTransactions) {
      if ((tx.amount) < 0) {
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
        if (tx.category == 'Khác' && !foundParent) {
          parentCategoryName = _defaultParentCategory;
        }

        parentData.update(
            parentCategoryName,
                (value) => value + (tx.amount.abs()),
            ifAbsent: () => (tx.amount.abs())
        );
      }
    }
    parentData.removeWhere((key, value) => value == 0.0);
    return parentData;
  }

  String get expenseCompareText {
    final currentMonthExp = totalExpense;
    final prevMonthExp = previousMonthTransactions
        .where((tx) => (tx.amount) < 0)
        .fold<double>(0.0, (double sum, ExpenseTransaction tx) {
      final double currentAmount = tx.amount.abs();
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
        (tx.amount) < 0);

    for (var tx in currentMonthTxs) {
      dailyData.update(
        tx.date.day,
            (value) => value + (tx.amount.abs()),
        ifAbsent: () => (tx.amount.abs()),
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
          (tx.amount) < 0)
          .fold(0.0, (sum, tx) => sum + (tx.amount.abs()));

      monthlyDataList.add(MapEntry(monthFormat.format(targetMonthDateTime), totalForMonth));
    }
    return monthlyDataList;
  }

  Map<String, double> get monthlyExpensesCurrentYear {
    final Map<String, double> monthlyData = {};
    final now = DateTime.now();
    final currentYearTxs = _transactions.where((tx) =>
    tx.date.year == now.year &&
        (tx.amount) < 0);

    final monthFormat = DateFormat('MMM', 'vi_VN');

    for (int i = 1; i <= 12; i++) {
      monthlyData[monthFormat.format(DateTime(now.year, i))] = 0.0;
    }

    for (var tx in currentYearTxs) {
      String monthKey = monthFormat.format(tx.date);
      monthlyData.update(
        monthKey,
            (value) => value + (tx.amount.abs()),
        ifAbsent: () => (tx.amount.abs()),
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
      _setError(e.toString());
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
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    clearError();
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    clearError();
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  Future<void> appSignOut(BuildContext context) async {
    _setLoading(true);
    clearError();
    try {
      await _authService.signOut();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(Routes.login, (Route<dynamic> route) => false);
      }
    } catch (e) {
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

  Future<void> addBudget(Budget budget) async {
    if (_firestoreService == null) {
      _setError('User chưa đăng nhập để thêm ngân sách');
      throw Exception('User chưa đăng nhập để thêm ngân sách');
    }
    _setLoading(true);
    clearError();
    try {
      await _firestoreService!.addBudget(budget);
    } catch (e) {
      _setError("Lỗi thêm ngân sách: ${e.toString()}");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateBudget(Budget updatedBudget) async {
    if (_firestoreService == null) {
      _setError('User chưa đăng nhập để cập nhật ngân sách');
      throw Exception('User chưa đăng nhập để cập nhật ngân sách');
    }
    _setLoading(true);
    clearError();
    try {
      await _firestoreService!.updateBudget(updatedBudget);
    } catch (e) {
      _setError("Lỗi cập nhật ngân sách: ${e.toString()}");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteBudget(String budgetId) async {
    if (_firestoreService == null) {
      _setError('User chưa đăng nhập để xóa ngân sách');
      throw Exception('User chưa đăng nhập để xóa ngân sách');
    }
    _setLoading(true);
    clearError();
    try {
      await _firestoreService!.deleteBudget(budgetId);
    } catch (e) {
      _setError("Lỗi xóa ngân sách: ${e.toString()}");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> checkAndNotifyForBudgets() async {
    if (_budgets.isEmpty || _transactions.isEmpty) return;
    final now = DateTime.now();

    for (var budget in _budgets) {
      if (now.isBefore(budget.startDate) || now.isAfter(budget.endDate.copyWith(hour: 23, minute: 59, second: 59))) {
        continue;
      }

      DateTime periodStartForSpent;
      DateTime periodEndForSpent;

      if (budget.isRecurring) {
        final firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);
        final lastDayOfCurrentMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);

        if (!(budget.endDate.isBefore(firstDayOfCurrentMonth) || budget.startDate.isAfter(lastDayOfCurrentMonth))) {
          try { periodStartForSpent = DateTime(now.year, now.month, budget.startDate.day); }
          catch (e) { periodStartForSpent = DateTime(now.year, now.month, DateTime(now.year, now.month + 1, 0).day); }

          if (budget.endDate.day >= budget.startDate.day || (budget.startDate.month == budget.endDate.month && budget.startDate.year == budget.endDate.year)) {
            try { periodEndForSpent = DateTime(now.year, now.month, budget.endDate.day, 23, 59, 59, 999); }
            catch (e) { periodEndForSpent = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999); }
          } else {
            if (now.day < budget.startDate.day) {
              try { periodStartForSpent = DateTime(now.year, now.month -1, budget.startDate.day); }
              catch (e) { periodStartForSpent = DateTime(now.year, now.month -1, DateTime(now.year, now.month, 0).day); }
              try { periodEndForSpent = DateTime(now.year, now.month, budget.endDate.day, 23, 59, 59, 999); }
              catch (e) { periodEndForSpent = DateTime(now.year, now.month + 1, 0,23,59,59,999); }
            } else {
              try { periodStartForSpent = DateTime(now.year, now.month, budget.startDate.day); }
              catch (e) { periodStartForSpent = DateTime(now.year, now.month, DateTime(now.year, now.month + 1, 0).day); }
              try { periodEndForSpent = DateTime(now.year, now.month + 1, budget.endDate.day, 23, 59, 59, 999); }
              catch (e) { periodEndForSpent = DateTime(now.year, now.month + 2, 0,23,59,59,999); }
            }
          }
          if(periodStartForSpent.isBefore(budget.startDate)) periodStartForSpent = budget.startDate;
          if(periodEndForSpent.isAfter(budget.endDate)) periodEndForSpent = budget.endDate.copyWith(hour:23, minute:59, second:59, millisecond: 999);
        } else {
          continue;
        }
      } else {
        periodStartForSpent = budget.startDate;
        periodEndForSpent = budget.endDate.copyWith(hour: 23, minute: 59, second: 59, millisecond: 999);
      }

      double currentSpent = 0;
      if (!periodStartForSpent.isAfter(periodEndForSpent)) {
        final relevantTransactions = _transactions.where((tx) {
          return tx.category == budget.categoryName &&
              tx.amount < 0 &&
              !tx.date.isBefore(periodStartForSpent) &&
              !tx.date.isAfter(periodEndForSpent);
        });
        currentSpent = relevantTransactions.fold(0.0, (sum, tx) => sum + tx.amount.abs());
      }

      double spendingPercentage = budget.amount > 0 ? (currentSpent / budget.amount) : 0;
      String notificationKeyNear = 'budget_near_${budget.id}_${now.year}_${now.month}';
      String notificationKeyOver = 'budget_over_${budget.id}_${now.year}_${now.month}';

      if (spendingPercentage >= 1.0) {
        if (_canNotify(notificationKeyOver)) {
          await NotificationService.showBudgetAlert(
            id: budget.id.hashCode,
            title: 'Cảnh báo: Vượt Ngân Sách!',
            body: 'Bạn đã vượt ngân sách cho "${budget.name}". Đã chi: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits:0).format(currentSpent)} / ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits:0).format(budget.amount)}',
            payload: 'budget_alert:over:${budget.id}',
          );
          _markAsNotified(notificationKeyOver);
          _markAsNotified(notificationKeyNear);
        }
      } else if (spendingPercentage >= 0.8) {
        if (_canNotify(notificationKeyNear)) {
          await NotificationService.showBudgetAlert(
            id: budget.id.hashCode + 1,
            title: 'Cảnh báo: Ngân Sách Sắp Hết!',
            body: 'Chi tiêu cho "${budget.name}" đã đạt ${(spendingPercentage * 100).toStringAsFixed(0)}% ngân sách. (${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits:0).format(currentSpent)} / ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits:0).format(budget.amount)})',
            payload: 'budget_alert:near:${budget.id}',
          );
          _markAsNotified(notificationKeyNear);
        }
      }
    }
  }

  bool _canNotify(String notificationKey) {
    final lastNotifiedTime = _notifiedBudgetAlerts[notificationKey];
    if (lastNotifiedTime == null || DateTime.now().difference(lastNotifiedTime) > _minIntervalBetweenAlerts) {
      return true;
    }
    return false;
  }

  void _markAsNotified(String notificationKey) {
    _notifiedBudgetAlerts[notificationKey] = DateTime.now();
  }

  Future<void> scheduleDailyAppReminder(int hour, int minute) async {
    await NotificationService.scheduleDailyReminder(
        id: 1,
        title: 'Nhắc nhở hàng ngày',
        body: 'Đừng quên ghi lại các chi tiêu của bạn hôm nay nhé!',
        hour: hour,
        minute: minute,
        payload: 'daily_reminder_payload'
    );
  }

  Future<void> scheduleWeeklyAppReminder(List<int> daysOfWeek, int hour, int minute) async {
    await NotificationService.scheduleWeeklyReminder(
        id: 2,
        title: 'Nhắc nhở hàng tuần',
        body: 'Xem lại tổng kết chi tiêu tuần này và lên kế hoạch cho tuần tới!',
        daysOfWeek: daysOfWeek,
        hour: hour,
        minute: minute,
        payload: 'weekly_reminder_payload'
    );
  }

  Future<void> scheduleMonthlyAppReminder(int dayOfMonth, int hour, int minute) async {
    await NotificationService.scheduleMonthlyReminder(
        id: 3,
        title: 'Nhắc nhở hàng tháng',
        body: 'Đã đến lúc xem lại ngân sách và chi tiêu tháng này rồi!',
        dayOfMonth: dayOfMonth,
        hour: hour,
        minute: minute,
        payload: 'monthly_reminder_payload'
    );
  }

  Future<void> cancelAllAppNotifications() async {
    await NotificationService.cancelAllNotifications();
  }

  Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedEmailKey);
  }

  Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedEmailKey, email);
  }

  Future<void> clearSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedEmailKey);
  }

  Future<String?> getSavedPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedPasswordKey);
  }

  Future<void> savePassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedPasswordKey, password);
  }

  Future<void> clearSavedPassword() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedPasswordKey);
  }
}

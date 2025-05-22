import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart'; // Import để sử dụng groupBy
import 'package:table_calendar/table_calendar.dart'; // Import TableCalendar

import '../providers/app_provider.dart';
import '../models/expense_transaction.dart';
import '../utils/category_helper.dart'; // Import tiện ích danh mục
import '../routes.dart'; // Import Routes để điều hướng khi sửa

// Enum for transaction type filtering
enum TransactionTypeFilter { all, income, expense }

extension TransactionTypeFilterExtension on TransactionTypeFilter {
  String get displayName {
    switch (this) {
      case TransactionTypeFilter.all:
        return 'Tất cả';
      case TransactionTypeFilter.income:
        return 'Khoản thu';
      case TransactionTypeFilter.expense:
        return 'Khoản chi';
    }
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late DateTime _firstDay;
  late DateTime _lastDay;

  Map<DateTime, _DailySummary> _dailySummaries = {};
  bool _isCalendarVisible = true;

  // State for search and filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  TransactionTypeFilter _transactionTypeFilter = TransactionTypeFilter.all;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _initializeDateRange();
    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        _updateDailySummaries(appProvider.transactions, _focusedDay);
        appProvider.addListener(_onAppProviderChange);
      }
    });
  }

  @override
  void dispose() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    try {
      appProvider.removeListener(_onAppProviderChange);
    } catch (e) {
      debugPrint("Error removing listener from AppProvider in dispose: $e");
    }

    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {
        _searchQuery = _searchController.text;
      });
    }
  }

  void _onAppProviderChange() {
    if (mounted) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      _updateDailySummaries(appProvider.transactions, _focusedDay);
      // ***** LOẠI BỎ SETSTATE Ở ĐÂY *****
      // setState(() {});
      // AppProvider.notifyListeners() sẽ trigger rebuild cho các widget đang listen (như Consumer/Selector hoặc Provider.of(context) trong build).
      // _updateDailySummaries đã có setState riêng cho phần calendar.
    }
  }

  void _initializeDateRange() {
    final now = DateTime.now();
    _firstDay = DateTime(now.year - 5, now.month, now.day);
    _lastDay = DateTime(now.year + 5, now.month, now.day);
  }

  void _updateDailySummaries(List<ExpenseTransaction> allTransactions, DateTime focusedMonthDate) {
    final newSummaries = <DateTime, _DailySummary>{};
    final transactionsInMonth = allTransactions.where((tx) =>
    tx.date.year == focusedMonthDate.year && tx.date.month == focusedMonthDate.month);

    for (var tx in transactionsInMonth) {
      final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
      final summary = newSummaries.putIfAbsent(day, () => _DailySummary());
      if (tx.amount > 0) {
        summary.income += tx.amount;
      } else {
        summary.expense += tx.amount.abs();
      }
    }
    if (mounted) {
      setState(() {
        _dailySummaries = newSummaries;
      });
    }
  }

  Future<bool?> _confirmDeleteDialog(BuildContext parentContext, ExpenseTransaction transaction) async {
    return showDialog<bool>(
      context: parentContext,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận Xóa Giao Dịch'),
          content: Text('Bạn có chắc chắn muốn xóa giao dịch "${transaction.title}" vào ngày ${DateFormat('dd/MM/yyyy').format(transaction.date)}?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
              child: const Text('Xóa'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToEditScreen(BuildContext context, ExpenseTransaction transaction) {
    Navigator.pushNamed(context, Routes.addTransaction, arguments: transaction);
  }

  List<ExpenseTransaction> _getFilteredTransactions(List<ExpenseTransaction> allTransactionsInProvider) {
    List<ExpenseTransaction> transactionsForMonth = allTransactionsInProvider.where((tx) {
      return tx.date.year == _focusedDay.year && tx.date.month == _focusedDay.month;
    }).toList();

    if (_transactionTypeFilter == TransactionTypeFilter.income) {
      transactionsForMonth = transactionsForMonth.where((tx) => tx.amount > 0).toList();
    } else if (_transactionTypeFilter == TransactionTypeFilter.expense) {
      transactionsForMonth = transactionsForMonth.where((tx) => tx.amount < 0).toList();
    }

    if (_searchQuery.isNotEmpty) {
      transactionsForMonth = transactionsForMonth.where((tx) {
        final titleMatch = tx.title.toLowerCase().contains(_searchQuery.toLowerCase());
        final noteMatch = tx.note?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
        return titleMatch || noteMatch;
      }).toList();
    }

    transactionsForMonth.sort((a, b) => b.date.compareTo(a.date));
    return transactionsForMonth;
  }


  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final allTransactionsFromProvider = appProvider.transactions;
    final scaffoldMessenger = ScaffoldMessenger.of(context);


    final transactionsForFocusedMonthUnfiltered = allTransactionsFromProvider.where((tx) {
      return tx.date.year == _focusedDay.year && tx.date.month == _focusedDay.month;
    }).toList();

    double monthlyIncome = 0;
    double monthlyExpense = 0;
    for (var tx in transactionsForFocusedMonthUnfiltered) {
      if (tx.amount > 0) {
        monthlyIncome += tx.amount;
      } else {
        monthlyExpense += tx.amount.abs();
      }
    }
    double monthlyBalance = monthlyIncome - monthlyExpense;

    final List<ExpenseTransaction> filteredTransactionsForList = _getFilteredTransactions(allTransactionsFromProvider);

    final groupedTransactionsForList = groupBy<ExpenseTransaction, DateTime>(
      filteredTransactionsForList,
          (transaction) => DateTime(transaction.date.year, transaction.date.month, transaction.date.day),
    );
    final List<MapEntry<DateTime, List<ExpenseTransaction>>> groupedEntriesForList = groupedTransactionsForList.entries.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sổ Giao Dịch'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Visibility(
              visible: _isCalendarVisible,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () {
                                setState(() {
                                  _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, _focusedDay.day);
                                  _updateDailySummaries(allTransactionsFromProvider, _focusedDay);
                                });
                              },
                            ),
                            Text(
                              DateFormat.yMMMM('vi_VN').format(_focusedDay),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () {
                                setState(() {
                                  _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, _focusedDay.day);
                                  _updateDailySummaries(allTransactionsFromProvider, _focusedDay);
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _MonthlySummaryItem(title: 'Tổng thu', amount: monthlyIncome, color: Colors.green.shade700),
                            _MonthlySummaryItem(title: 'Tổng chi', amount: monthlyExpense, color: Colors.red.shade700),
                            _MonthlySummaryItem(title: 'Chênh lệch', amount: monthlyBalance, color: monthlyBalance >= 0 ? Colors.blue.shade700 : Colors.orange.shade700),
                          ],
                        ),
                      ],
                    ),
                  ),
                  TableCalendar<ExpenseTransaction>(
                    locale: 'vi_VN',
                    firstDay: _firstDay,
                    lastDay: _lastDay,
                    focusedDay: _focusedDay,
                    calendarFormat: CalendarFormat.month,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      if (!isSameDay(_selectedDay, selectedDay)) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      }
                    },
                    onPageChanged: (newFocusedDay) {
                      if (_focusedDay.month != newFocusedDay.month || _focusedDay.year != newFocusedDay.year) {
                        setState(() {
                          _focusedDay = newFocusedDay;
                          _updateDailySummaries(allTransactionsFromProvider, _focusedDay);
                        });
                      }
                    },
                    calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) => null,
                        defaultBuilder: (context, day, focusedDay) {
                          final summary = _dailySummaries[DateTime(day.year, day.month, day.day)];
                          final income = summary?.income ?? 0;
                          final expense = summary?.expense ?? 0;
                          final dayTextStyle = Theme.of(context).textTheme.bodySmall;
                          bool isOutside = day.month != focusedDay.month;

                          return Container(
                            margin: const EdgeInsets.all(1.5),
                            padding: const EdgeInsets.all(1.5),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${day.day}',
                                  style: dayTextStyle?.copyWith(
                                    color: isOutside ? Colors.grey.shade400 : (isSameDay(day, DateTime.now()) ? Theme.of(context).primaryColor : Colors.black87),
                                    fontWeight: isSameDay(day, DateTime.now()) ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                if (!isOutside && income > 0)
                                  Text(
                                    _formatCurrencyShort(income),
                                    style: TextStyle(fontSize: 7.5, color: Colors.green.shade600, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (!isOutside && expense > 0)
                                  Text(
                                    _formatCurrencyShort(expense),
                                    style: TextStyle(fontSize: 7.5, color: Colors.red.shade600, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          );
                        },
                        selectedBuilder: (context, day, focusedDay) {
                          final summary = _dailySummaries[DateTime(day.year, day.month, day.day)];
                          final income = summary?.income ?? 0;
                          final expense = summary?.expense ?? 0;
                          return Container(
                            margin: const EdgeInsets.all(1.5),
                            padding: const EdgeInsets.all(1.5),
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4.0),
                                border: Border.all(color: Theme.of(context).primaryColor, width: 1)
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${day.day}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorDark),
                                ),
                                if (income > 0)
                                  Text(
                                    _formatCurrencyShort(income),
                                    style: TextStyle(fontSize: 7.5, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (expense > 0)
                                  Text(
                                    _formatCurrencyShort(expense),
                                    style: TextStyle(fontSize: 7.5, color: Colors.red.shade600, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          );
                        },
                        todayBuilder: (context, day, focusedDay) {
                          final summary = _dailySummaries[DateTime(day.year, day.month, day.day)];
                          final income = summary?.income ?? 0;
                          final expense = summary?.expense ?? 0;
                          return Container(
                            margin: const EdgeInsets.all(1.5),
                            padding: const EdgeInsets.all(1.5),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4.0),
                                border: Border.all(color: Colors.amber.shade600, width: 1)
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${day.day}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                                ),
                                if (income > 0)
                                  Text(
                                    _formatCurrencyShort(income),
                                    style: TextStyle(fontSize: 7.5, color: Colors.green.shade600, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (expense > 0)
                                  Text(
                                    _formatCurrencyShort(expense),
                                    style: TextStyle(fontSize: 7.5, color: Colors.red.shade600, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          );
                        }
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
                      leftChevronVisible: false,
                      rightChevronVisible: false,
                      headerPadding: EdgeInsets.symmetric(vertical: 4.0),
                    ),
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      weekendTextStyle: TextStyle(color: Colors.red.shade400),
                      cellMargin: const EdgeInsets.all(1.0),
                    ),
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Tháng',
                    },
                  ),
                ],
              ),
            ),

            InkWell(
              onTap: () {
                setState(() {
                  _isCalendarVisible = !_isCalendarVisible;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isCalendarVisible ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm theo tên, ghi chú...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    alignment: WrapAlignment.center,
                    children: TransactionTypeFilter.values.map((filter) {
                      return FilterChip(
                        label: Text(filter.displayName, style: TextStyle(color: _transactionTypeFilter == filter ? Theme.of(context).primaryColorDark : Colors.black87)),
                        selectedColor: Theme.of(context).primaryColorLight.withOpacity(0.5),
                        checkmarkColor: Theme.of(context).primaryColorDark,
                        selected: _transactionTypeFilter == filter,
                        onSelected: (selected) {
                          setState(() {
                            _transactionTypeFilter = filter;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(height: 1, thickness: 1, color: Colors.grey[300]),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 4.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _buildTransactionListTitle(filteredTransactionsForList.length),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            filteredTransactionsForList.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _buildEmptyListMessage(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 80.0, top: 0.0),
              itemCount: groupedEntriesForList.length,
              itemBuilder: (ctx, groupIndex) {
                final dateGroup = groupedEntriesForList[groupIndex];
                final date = dateGroup.key;
                final dailyTransactions = dateGroup.value;
                double dailyTotal = dailyTransactions.fold(0.0, (sum, tx) => sum + tx.amount);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('EEEE, dd MMMM, yyyy', 'vi_VN').format(date), // Hiển thị đầy đủ năm
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(dailyTotal),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: dailyTotal == 0 ? Colors.grey[700] : (dailyTotal > 0 ? Colors.green.shade700 : Colors.red.shade700),
                            ),
                          )
                        ],
                      ),
                    ),
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: dailyTransactions.length,
                        itemBuilder: (ctxItem, itemIndex) {
                          final transaction = dailyTransactions[itemIndex];
                          return _TransactionListItem(
                            transaction: transaction,
                            onEdit: () => _navigateToEditScreen(context, transaction),
                            confirmDeleteDialog: () => _confirmDeleteDialog(context, transaction),
                            scaffoldMessenger: scaffoldMessenger,
                            appProvider: appProvider,
                          );
                        },
                        separatorBuilder: (ctx, idx) => const Divider(height: 0.5, indent: 72, endIndent: 16),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _buildTransactionListTitle(int count) {
    String monthStr = DateFormat.MMMM('vi_VN').format(_focusedDay);
    if (_transactionTypeFilter != TransactionTypeFilter.all || _searchQuery.isNotEmpty) {
      return "Kết quả ($count) trong $monthStr";
    }
    return "Giao dịch ($count) trong $monthStr";
  }

  String _buildEmptyListMessage() {
    String monthStr = DateFormat.MMMM('vi_VN').format(_focusedDay);
    if (_transactionTypeFilter != TransactionTypeFilter.all || _searchQuery.isNotEmpty) {
      return 'Không tìm thấy giao dịch nào khớp với bộ lọc trong $monthStr.';
    }
    return 'Không có giao dịch nào trong $monthStr.';
  }
}

class _DailySummary {
  double income = 0;
  double expense = 0;
}

class _MonthlySummaryItem extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const _MonthlySummaryItem({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey[700])),
        const SizedBox(height: 4),
        Text(
          NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(amount),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

String _formatCurrencyShort(double amount) {
  if (amount == 0) return '';
  if (amount.abs() < 1000) return NumberFormat("#,##0", "vi_VN").format(amount);
  final formatter = NumberFormat.compact(locale: 'vi_VN');
  return formatter.format(amount);
}

class _TransactionListItem extends StatelessWidget {
  final ExpenseTransaction transaction;
  final VoidCallback onEdit;
  final Future<bool?> Function() confirmDeleteDialog;
  final ScaffoldMessengerState scaffoldMessenger;
  final AppProvider appProvider;


  const _TransactionListItem({
    required this.transaction,
    required this.onEdit,
    required this.confirmDeleteDialog,
    required this.scaffoldMessenger,
    required this.appProvider,
  });

  @override
  Widget build(BuildContext context) {
    final categoryDetails = CategoryHelper.getCategoryDetails(transaction.category, transaction.type);
    final IconData categoryIcon = categoryDetails['icon'] as IconData;
    final Color categoryColor = categoryDetails['color'] as Color;
    final bool isExpense = transaction.amount < 0;
    final NumberFormat currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (DismissDirection direction) async {
        return await confirmDeleteDialog();
      },
      onDismissed: (DismissDirection direction) async {
        try {
          await appProvider.deleteTransaction(transaction.id);
        } catch (e) {
          debugPrint('Lỗi khi xóa giao dịch trong onDismissed: $e');
          try {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Lỗi khi xóa giao dịch: $e'),
                backgroundColor: Colors.red,
              ),
            );
          } catch (snackbarError) {
            debugPrint("Lỗi khi hiển thị SnackBar sau khi xóa: $snackbarError");
          }
        }
      },
      background: Container(
        color: Colors.red.shade600,
        padding: const EdgeInsets.only(right: 20.0),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Xóa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onEdit,
          leading: CircleAvatar(
            backgroundColor: categoryColor.withOpacity(0.15),
            foregroundColor: categoryColor,
            radius: 22,
            child: Icon(categoryIcon, size: 20),
          ),
          title: Text(
            transaction.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (transaction.note != null && transaction.note!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    transaction.note!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (transaction.sources.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    transaction.sources.join(', '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.blueGrey.shade400, fontStyle: FontStyle.italic, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          trailing: Text(
            currencyFormatter.format(transaction.amount),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isExpense ? Colors.red.shade700 : Colors.green.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        ),
      ),
    );
  }
}

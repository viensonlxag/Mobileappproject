import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // For Donut Chart
import 'package:provider/provider.dart'; // ***** THÊM IMPORT PROVIDER *****
import '../providers/app_provider.dart'; // ***** THÊM IMPORT APPPROVIDER *****
import '../models/budget.dart' as budget_model; // ***** SỬ DỤNG ALIAS CHO BUDGET MODEL *****
import '../utils/category_helper.dart';
import 'add_edit_budget_screen.dart';

// Enum cho khoảng thời gian lọc ngân sách
enum BudgetPeriodFilter { thisMonth, allTime, custom }

extension BudgetPeriodFilterExtension on BudgetPeriodFilter {
  String get displayName {
    switch (this) {
      case BudgetPeriodFilter.thisMonth:
        return 'Tháng này';
      case BudgetPeriodFilter.allTime:
        return 'Tất cả';
      case BudgetPeriodFilter.custom:
        return 'Tùy chỉnh';
    }
  }
}

// Lớp đại diện cho một mục ngân sách trên UI
class BudgetDisplayItem {
  final String id;
  final String name;
  final String categoryName;
  final IconData icon;
  final Color color;
  final double amount;
  double spent; // spent có thể thay đổi dựa trên giao dịch
  final DateTime startDate;
  final DateTime endDate;
  final bool isRecurring;

  BudgetDisplayItem({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.icon,
    required this.color,
    required this.amount,
    required this.spent,
    required this.startDate,
    required this.endDate,
    this.isRecurring = false,
  });

  double get progress => amount > 0 ? (spent / amount).clamp(0.0, 1.0) : 0.0;
  bool get isOverBudget => spent > amount;
  double get remainingAmount => amount - spent;
  int get daysLeft {
    final now = DateTime.now();
    if (isRecurring) {
      // Tính toán phức tạp hơn cho ngày còn lại của ngân sách lặp lại có thể cần thiết ở đây
      // Ví dụ đơn giản: nếu endDate.day < now.day (và cùng tháng năm), thì tính cho tháng sau
      DateTime currentCycleEndDate;
      if (now.month == endDate.month && now.year == endDate.year) {
        currentCycleEndDate = endDate;
      } else {
        // Tìm ngày cuối của chu kỳ hiện tại hoặc chu kỳ tiếp theo gần nhất
        // Đây là một ví dụ đơn giản, có thể cần logic phức tạp hơn
        int monthOffset = 0;
        while (DateTime(now.year, now.month + monthOffset, endDate.day).isBefore(now) || DateTime(now.year, now.month + monthOffset, endDate.day).month < startDate.month && DateTime(now.year, now.month + monthOffset, endDate.day).year == startDate.year) {
          monthOffset++;
          // Giới hạn để tránh vòng lặp vô hạn nếu có lỗi logic
          if (monthOffset > 12) break;
        }
        // Cố gắng tạo ngày hợp lệ
        try {
          currentCycleEndDate = DateTime(now.year, now.month + monthOffset, endDate.day);
          if (currentCycleEndDate.month != (now.month + monthOffset) % 12 && (now.month + monthOffset) % 12 != 0) { // Xử lý ngày không hợp lệ (vd: 31/2)
            currentCycleEndDate = DateTime(now.year, now.month + monthOffset + 1, 0); // Lấy ngày cuối của tháng trước
          }

        } catch (e) {
          currentCycleEndDate = DateTime(now.year, now.month + monthOffset + 1, 0);
        }


      }
      if (now.isAfter(currentCycleEndDate)) return 0;
      return currentCycleEndDate.difference(now).inDays +1;
    }
    // Ngân sách không lặp lại
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays + 1;
  }

  // Factory để tạo BudgetDisplayItem từ budget_model.Budget và AppProvider
  factory BudgetDisplayItem.fromModel(budget_model.Budget model, AppProvider appProvider) {
    final categoryDetails = CategoryHelper.getCategoryDetails(model.categoryName, 'Chi tiêu');
    double currentSpent = 0;
    final now = DateTime.now();

    // Xác định khoảng thời gian tính chi tiêu cho ngân sách
    DateTime effectiveStartDate = model.startDate;
    DateTime effectiveEndDate = model.endDate;

    if (model.isRecurring) {
      // Đối với ngân sách lặp lại, chỉ tính chi tiêu trong chu kỳ hiện tại (thường là tháng hiện tại)
      // Giả sử ngân sách lặp lại hàng tháng, tính từ ngày đầu của tháng hiện tại đến ngày cuối của tháng hiện tại
      // nhưng bị giới hạn bởi startDate và endDate gốc của budget model

      int currentCycleYear = now.year;
      int currentCycleMonth = now.month;

      // Tìm ngày bắt đầu của chu kỳ hiện tại dựa trên model.startDate.day
      DateTime cycleStartDate = DateTime(currentCycleYear, currentCycleMonth, model.startDate.day);
      // Nếu ngày bắt đầu của chu kỳ hiện tại không hợp lệ (ví dụ ngày 31 tháng 2), lùi về ngày cuối tháng trước
      if (cycleStartDate.month != currentCycleMonth) {
        cycleStartDate = DateTime(currentCycleYear, currentCycleMonth, 0); // Ngày cuối của tháng trước
      }


      // Tìm ngày kết thúc của chu kỳ hiện tại dựa trên model.endDate.day
      DateTime cycleEndDate = DateTime(currentCycleYear, currentCycleMonth, model.endDate.day);
      // Nếu ngày kết thúc của chu kỳ hiện tại không hợp lệ, lùi về ngày cuối tháng
      if (cycleEndDate.month != currentCycleMonth) {
        cycleEndDate = DateTime(currentCycleYear, currentCycleMonth + 1, 0);
      }


      // Đảm bảo cycleStartDate và cycleEndDate không vượt ra ngoài startDate và endDate gốc của model
      effectiveStartDate = cycleStartDate.isAfter(model.startDate) ? cycleStartDate : model.startDate;
      effectiveEndDate = cycleEndDate.isBefore(model.endDate) ? cycleEndDate : model.endDate;

      // Nếu chu kỳ hiện tại nằm ngoài khoảng thời gian gốc của ngân sách, không tính chi tiêu
      if (effectiveStartDate.isAfter(effectiveEndDate)) {
        currentSpent = 0;
      } else {
        final relevantTransactions = appProvider.transactions.where((tx) {
          return tx.category == model.categoryName &&
              tx.amount < 0 &&
              !tx.date.isBefore(effectiveStartDate) &&
              !tx.date.isAfter(effectiveEndDate);
        });
        currentSpent = relevantTransactions.fold(0.0, (sum, tx) => sum + tx.amount.abs());
      }

    } else { // Ngân sách không lặp lại
      final relevantTransactions = appProvider.transactions.where((tx) {
        return tx.category == model.categoryName &&
            tx.amount < 0 &&
            !tx.date.isBefore(effectiveStartDate) &&
            !tx.date.isAfter(effectiveEndDate);
      });
      currentSpent = relevantTransactions.fold(0.0, (sum, tx) => sum + tx.amount.abs());
    }


    return BudgetDisplayItem(
      id: model.id,
      name: model.name,
      categoryName: model.categoryName,
      icon: categoryDetails['icon'] as IconData,
      color: categoryDetails['color'] as Color,
      amount: model.amount,
      spent: currentSpent,
      startDate: model.startDate, // Giữ lại startDate gốc để hiển thị
      endDate: model.endDate,     // Giữ lại endDate gốc để hiển thị
      isRecurring: model.isRecurring,
    );
  }
}


class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  BudgetPeriodFilter _selectedPeriod = BudgetPeriodFilter.thisMonth;
  List<BudgetDisplayItem> _filteredBudgets = [];

  double _overallBudgetedAmount = 0;
  double _overallSpentAmount = 0;
  int _touchedIndexDonut = -1;

  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '\u0111', decimalDigits: 0);
  final DateFormat _dateFormatter = DateFormat('dd/MM');


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Gọi _filterAndCalculateBudgets ở đây để nó được gọi khi AppProvider thay đổi
    // và cũng được gọi lần đầu sau initState
    final appProvider = Provider.of<AppProvider>(context);
    _filterAndCalculateBudgets(appProvider);
  }


  void _filterAndCalculateBudgets(AppProvider appProvider) {
    final now = DateTime.now();
    final firstDayCurrentMonth = DateTime(now.year, now.month, 1);
    final lastDayCurrentMonth = DateTime(now.year, now.month + 1, 0);

    List<BudgetDisplayItem> allDisplayBudgets = appProvider.budgets
        .map((modelBudget) => BudgetDisplayItem.fromModel(modelBudget, appProvider))
        .toList();

    // setState không cần thiết ở đây nếu _filterAndCalculateBudgets được gọi từ build/didChangeDependencies
    // và Consumer/Selector được sử dụng đúng cách. Tuy nhiên, để đảm bảo UI cập nhật khi filter thay đổi,
    // chúng ta vẫn có thể giữ setState, nhưng cần cẩn thận để tránh vòng lặp build vô hạn.
    // Tạm thời vẫn dùng setState để đảm bảo cập nhật UI khi _selectedPeriod thay đổi.

    List<BudgetDisplayItem> tempFilteredBudgets;

    if (_selectedPeriod == BudgetPeriodFilter.thisMonth) {
      tempFilteredBudgets = allDisplayBudgets.where((b) {
        if (b.isRecurring) {
          // Ngân sách lặp lại: kiểm tra xem chu kỳ hiện tại (tháng này) có hiệu lực không
          DateTime cycleStartDateForCurrentMonth = DateTime(now.year, now.month, b.startDate.day);
          if (cycleStartDateForCurrentMonth.month != now.month) { // Xử lý ngày không hợp lệ (vd: 31/2)
            cycleStartDateForCurrentMonth = DateTime(now.year, now.month + 1, 0); // Lấy ngày cuối của tháng hiện tại
          }

          DateTime cycleEndDateForCurrentMonth = DateTime(now.year, now.month, b.endDate.day);
          if (cycleEndDateForCurrentMonth.month != now.month) { // Xử lý ngày không hợp lệ
            cycleEndDateForCurrentMonth = DateTime(now.year, now.month + 1, 0);
          }
          // Đảm bảo chu kỳ hiện tại nằm trong khoảng startDate, endDate gốc
          return !cycleStartDateForCurrentMonth.isAfter(b.endDate) && !cycleEndDateForCurrentMonth.isBefore(b.startDate);

        } else { // Ngân sách không lặp lại
          return !(lastDayCurrentMonth.isBefore(b.startDate) || firstDayCurrentMonth.isAfter(b.endDate));
        }
      }).toList();
    } else if (_selectedPeriod == BudgetPeriodFilter.allTime) {
      tempFilteredBudgets = List.from(allDisplayBudgets);
    } else {
      tempFilteredBudgets = List.from(allDisplayBudgets);
    }

    // Cập nhật state chỉ khi có sự thay đổi thực sự để tránh vòng lặp build không cần thiết
    // So sánh _filteredBudgets hiện tại với tempFilteredBudgets
    // Đây là một cách so sánh đơn giản, có thể cần tối ưu hơn cho danh sách lớn
    bool listsAreEqual = _filteredBudgets.length == tempFilteredBudgets.length &&
        _filteredBudgets.every((item) => tempFilteredBudgets.any((other) => other.id == item.id && other.spent == item.spent));


    if (!listsAreEqual ||
        _overallBudgetedAmount != tempFilteredBudgets.fold(0.0, (sum, b) => sum + b.amount) ||
        _overallSpentAmount != tempFilteredBudgets.fold(0.0, (sum, b) => sum + b.spent)
    ) {
      if(mounted){
        setState(() {
          _filteredBudgets = tempFilteredBudgets;
          _overallBudgetedAmount = _filteredBudgets.fold(0.0, (sum, b) => sum + b.amount);
          _overallSpentAmount = _filteredBudgets.fold(0.0, (sum, b) => sum + b.spent);
        });
      }
    }
  }

  void _navigateToAddEditBudgetScreen({budget_model.Budget? budget}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditBudgetScreen(budget: budget),
      ),
    );
    if (result == true && mounted) {
      // AppProvider đã được cập nhật và sẽ trigger rebuild thông qua Consumer
      // Không cần gọi _filterAndCalculateBudgets ở đây nữa vì didChangeDependencies hoặc build của Consumer sẽ xử lý
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        // Gọi _filterAndCalculateBudgets ở đây để đảm bảo nó được cập nhật khi
        // appProvider.budgets hoặc appProvider.transactions thay đổi.
        // Sử dụng addPostFrameCallback để tránh setState trong khi build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _filterAndCalculateBudgets(appProvider);
          }
        });

        return Scaffold(
          appBar: AppBar(
            title: const Text('Quản lý Ngân sách'),
          ),
          body: Column(
            children: [
              _buildOverallSummary(theme),
              _buildPeriodFilterChips(theme, appProvider),
              const Divider(height: 1),
              Expanded(
                child: appProvider.isLoading && _filteredBudgets.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredBudgets.isEmpty
                    ? _buildEmptyState(theme)
                    : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _filteredBudgets.length,
                  itemBuilder: (context, index) {
                    final budgetItem = _filteredBudgets[index];
                    final originalBudgetModel = appProvider.budgets.firstWhere(
                            (b) => b.id == budgetItem.id,
                        orElse: () => budget_model.Budget(
                            id: budgetItem.id, // Nên có id để tránh lỗi
                            name: budgetItem.name,
                            categoryName: budgetItem.categoryName,
                            amount: budgetItem.amount,
                            startDate: budgetItem.startDate,
                            endDate: budgetItem.endDate,
                            isRecurring: budgetItem.isRecurring
                        )
                    );
                    return _buildBudgetListItem(budgetItem, originalBudgetModel, theme);
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _navigateToAddEditBudgetScreen(),
            backgroundColor: theme.colorScheme.primary,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text('Tạo Ngân Sách', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        );
      },
    );
  }

  Widget _buildOverallSummary(ThemeData theme) {
    double overallProgress = _overallBudgetedAmount > 0 ? (_overallSpentAmount / _overallBudgetedAmount).clamp(0.0, 1.0) : 0.0;
    bool isOverallOverBudget = _overallSpentAmount > _overallBudgetedAmount;
    Color overallProgressColor = isOverallOverBudget ? Colors.red.shade700 : theme.colorScheme.secondary;

    List<PieChartSectionData> sections = [];
    if (_overallBudgetedAmount > 0) {
      sections.add(PieChartSectionData(
        color: overallProgressColor,
        value: _overallSpentAmount.clamp(0, _overallBudgetedAmount),
        title: '',
        radius: _touchedIndexDonut == 0 ? 22 : 18,
      ));
      if (_overallSpentAmount < _overallBudgetedAmount) {
        sections.add(PieChartSectionData(
          color: Colors.grey.shade300,
          value: (_overallBudgetedAmount - _overallSpentAmount).abs(), // Đảm bảo giá trị dương
          title: '',
          radius: _touchedIndexDonut == 1 ? 22 : 18,
        ));
      }
    } else {
      sections.add(PieChartSectionData(
        color: Colors.grey.shade300,
        value: 1,
        title: '',
        radius: 18,
      ));
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: PieChart(
              PieChartData(
                sectionsSpace: sections.length > 1 ? 2 : 0, // Chỉ thêm space nếu có nhiều hơn 1 section
                centerSpaceRadius: 25,
                startDegreeOffset: -90,
                sections: sections,
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    // Không cần setState ở đây nếu không thay đổi _touchedIndexDonut
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng quan ngân sách',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đã chi: ${currencyFormatter.format(_overallSpentAmount)}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                ),
                Text(
                  'Tổng đặt: ${currencyFormatter.format(_overallBudgetedAmount)}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                ),
                if (_overallBudgetedAmount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      isOverallOverBudget
                          ? 'Vượt: ${currencyFormatter.format(_overallSpentAmount - _overallBudgetedAmount)} (${(overallProgress * 100).toStringAsFixed(0)}%)'
                          : 'Còn lại: ${currencyFormatter.format(_overallBudgetedAmount - _overallSpentAmount)} (${(overallProgress * 100).toStringAsFixed(0)}%)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isOverallOverBudget ? Colors.red.shade700 : Colors.green.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilterChips(ThemeData theme, AppProvider appProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: BudgetPeriodFilter.values.where((p) => p != BudgetPeriodFilter.custom).map((period) {
          bool isSelected = _selectedPeriod == period;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(period.displayName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() { // setState ở đây để cập nhật _selectedPeriod ngay lập tức
                    _selectedPeriod = period;
                  });
                  // _filterAndCalculateBudgets sẽ được gọi lại trong build của Consumer
                }
              },
              backgroundColor: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : Colors.grey[200],
              selectedColor: theme.colorScheme.primary.withOpacity(0.25),
              labelStyle: TextStyle(
                  color: isSelected ? theme.colorScheme.primary : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                      color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
                      width: 1.2
                  )
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 80, color: Colors.grey[350]),
            const SizedBox(height: 20),
            Text(
              'Không có ngân sách nào.',
              style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedPeriod == BudgetPeriodFilter.thisMonth
                  ? 'Không có ngân sách nào được đặt cho tháng này. Hãy tạo một ngân sách mới!'
                  : 'Hãy tạo ngân sách đầu tiên của bạn bằng cách nhấn nút "+" bên dưới.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetListItem(BudgetDisplayItem budgetItem, budget_model.Budget originalBudgetModel, ThemeData theme) {
    final bool isNearLimit = budgetItem.progress >= 0.8 && budgetItem.progress < 1.0 && !budgetItem.isOverBudget;
    final Color progressColor = budgetItem.isOverBudget ? Colors.red.shade600 : (isNearLimit ? Colors.orange.shade600 : theme.colorScheme.primary);
    final String periodString = budgetItem.isRecurring
        ? 'Hàng tháng (${_dateFormatter.format(budgetItem.startDate)} - ${_dateFormatter.format(budgetItem.endDate)})'
        : '${_dateFormatter.format(budgetItem.startDate)} - ${_dateFormatter.format(budgetItem.endDate)}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () => _navigateToAddEditBudgetScreen(budget: originalBudgetModel),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: budgetItem.color.withOpacity(0.15),
                    foregroundColor: budgetItem.color,
                    radius: 18,
                    child: Icon(budgetItem.icon, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budgetItem.name,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          periodString,
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600], fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (budgetItem.isOverBudget)
                    const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20)
                  else if (isNearLimit)
                    const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đã chi: ${currencyFormatter.format(budgetItem.spent)}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[800], fontSize: 13),
                  ),
                  Text(
                    'Tổng: ${currencyFormatter.format(budgetItem.amount)}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[800], fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: budgetItem.progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    budgetItem.isOverBudget
                        ? 'Vượt: ${currencyFormatter.format(budgetItem.spent - budgetItem.amount)}'
                        : 'Còn lại: ${currencyFormatter.format(budgetItem.remainingAmount)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: budgetItem.isOverBudget ? Colors.red.shade700 : Colors.green.shade700,
                    ),
                  ),
                  Text(
                    budgetItem.isRecurring ? '${budgetItem.daysLeft} ngày còn lại' : (budgetItem.daysLeft > 0 ? '${budgetItem.daysLeft} ngày còn lại' : 'Đã kết thúc'),
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // For Donut Chart
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/budget.dart' as budget_model;
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
  double spent;
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
    DateTime cycleEndDateToConsider;

    if (isRecurring) {
      int targetYear = now.year;
      int targetMonth = now.month;
      int targetEndDay = this.endDate.day;

      DateTime currentAttemptCycleEnd = DateTime(targetYear, targetMonth, targetEndDay);
      if (currentAttemptCycleEnd.month != targetMonth) {
        currentAttemptCycleEnd = DateTime(targetYear, targetMonth + 1, 0);
      }

      if (now.isAfter(currentAttemptCycleEnd)) {
        targetMonth += 1;
        if (targetMonth > 12) {
          targetMonth = 1;
          targetYear += 1;
        }
        cycleEndDateToConsider = DateTime(targetYear, targetMonth, targetEndDay);
        if (cycleEndDateToConsider.month != targetMonth) {
          cycleEndDateToConsider = DateTime(targetYear, targetMonth + 1, 0);
        }
      } else {
        cycleEndDateToConsider = currentAttemptCycleEnd;
      }
      if (cycleEndDateToConsider.isAfter(this.endDate)) {
        cycleEndDateToConsider = this.endDate;
      }

    } else {
      cycleEndDateToConsider = this.endDate;
    }

    if (now.isAfter(cycleEndDateToConsider.copyWith(hour: 23, minute: 59, second: 59, millisecond: 999, microsecond: 999))) return 0;

    final nowDateOnly = DateTime(now.year, now.month, now.day);
    final endDateOnly = DateTime(cycleEndDateToConsider.year, cycleEndDateToConsider.month, cycleEndDateToConsider.day);
    return endDateOnly.difference(nowDateOnly).inDays;
  }


  factory BudgetDisplayItem.fromModel(budget_model.Budget model, AppProvider appProvider) {
    final categoryDetails = CategoryHelper.getCategoryDetails(model.categoryName, 'Chi tiêu');
    double currentSpent = 0;
    final now = DateTime.now();

    DateTime periodStartForSpent;
    DateTime periodEndForSpent;

    if (model.isRecurring) {
      final firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);
      final lastDayOfCurrentMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);

      if (!(model.endDate.isBefore(firstDayOfCurrentMonth) || model.startDate.isAfter(lastDayOfCurrentMonth))) {
        try {
          periodStartForSpent = DateTime(now.year, now.month, model.startDate.day);
        } catch (e) {
          periodStartForSpent = DateTime(now.year, now.month, DateTime(now.year, now.month + 1, 0).day);
        }

        if (model.endDate.day >= model.startDate.day ||
            (model.startDate.month == model.endDate.month && model.startDate.year == model.endDate.year)) {
          try {
            periodEndForSpent = DateTime(now.year, now.month, model.endDate.day, 23, 59, 59, 999);
          } catch (e) {
            periodEndForSpent = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
          }
        } else {
          if (now.day < model.startDate.day) {
            try {
              periodStartForSpent = DateTime(now.year, now.month -1, model.startDate.day);
              if (periodStartForSpent.month == now.month && now.month !=1) periodStartForSpent = DateTime(now.year, now.month-1, DateTime(now.year, now.month, 0).day);
              else if (periodStartForSpent.month != 12 && now.month ==1) periodStartForSpent = DateTime(now.year-1, 12, model.startDate.day);

            } catch (e) {
              periodStartForSpent = DateTime(now.year, now.month -1, DateTime(now.year, now.month, 0).day);
            }
            try {
              periodEndForSpent = DateTime(now.year, now.month, model.endDate.day, 23, 59, 59, 999);
            } catch (e) {
              periodEndForSpent = DateTime(now.year, now.month + 1, 0,23,59,59,999);
            }

          } else {
            try {
              periodStartForSpent = DateTime(now.year, now.month, model.startDate.day);
            } catch (e) {
              periodStartForSpent = DateTime(now.year, now.month, DateTime(now.year, now.month + 1, 0).day);
            }
            try {
              periodEndForSpent = DateTime(now.year, now.month + 1, model.endDate.day, 23, 59, 59, 999);
              if (periodEndForSpent.month != (now.month + 1 > 12 ? (now.month+1)%12 == 0 ? 12 : (now.month+1)%12 : now.month+1) ) {
                periodEndForSpent = DateTime(now.year, (now.month+1 > 12 ? (now.month+2 > 12 ? (now.month+2)%12 == 0 ? 12 : (now.month+2)%12 : now.month+2) : now.month+2),0,23,59,59,999);
                if (periodEndForSpent.year > now.year +1) periodEndForSpent = DateTime(now.year+1, 1,0,23,59,59,999);
              }
            } catch (e) {
              periodEndForSpent = DateTime(now.year, now.month + 2, 0,23,59,59,999);
            }
          }
        }
        if(periodStartForSpent.isBefore(model.startDate)) periodStartForSpent = model.startDate;
        if(periodEndForSpent.isAfter(model.endDate)) periodEndForSpent = model.endDate.copyWith(hour:23, minute:59, second:59, millisecond: 999);
      } else {
        periodStartForSpent = now.add(const Duration(days:1));
        periodEndForSpent = now;
      }
    } else {
      periodStartForSpent = model.startDate;
      periodEndForSpent = model.endDate.copyWith(hour: 23, minute: 59, second: 59, millisecond: 999);
    }

    if (!periodStartForSpent.isAfter(periodEndForSpent)) {
      final relevantTransactions = appProvider.transactions.where((tx) {
        return tx.category == model.categoryName &&
            tx.amount < 0 &&
            !tx.date.isBefore(periodStartForSpent) &&
            !tx.date.isAfter(periodEndForSpent);
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
      startDate: model.startDate,
      endDate: model.endDate,
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
    final appProvider = Provider.of<AppProvider>(context);
    _filterAndCalculateBudgets(appProvider);
  }


  void _filterAndCalculateBudgets(AppProvider appProvider) {
    final now = DateTime.now();
    final firstDayCurrentMonth = DateTime(now.year, now.month, 1);
    final lastDayCurrentMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);

    List<BudgetDisplayItem> allDisplayBudgets = appProvider.budgets
        .map((modelBudget) => BudgetDisplayItem.fromModel(modelBudget, appProvider))
        .toList();

    List<BudgetDisplayItem> tempFilteredBudgets;

    if (_selectedPeriod == BudgetPeriodFilter.thisMonth) {
      tempFilteredBudgets = allDisplayBudgets.where((b) {
        if (b.isRecurring) {
          DateTime cycleStartDateForCurrentMonth;
          try {
            cycleStartDateForCurrentMonth = DateTime(now.year, now.month, b.startDate.day);
          } catch (e) {
            cycleStartDateForCurrentMonth = DateTime(now.year, now.month, DateTime(now.year, now.month + 1, 0).day);
          }

          DateTime cycleEndDateForCurrentMonth;
          try {
            cycleEndDateForCurrentMonth = DateTime(now.year, now.month, b.endDate.day);
          } catch (e) {
            cycleEndDateForCurrentMonth = DateTime(now.year, now.month + 1, 0);
          }
          return !cycleStartDateForCurrentMonth.isAfter(b.endDate) && !cycleEndDateForCurrentMonth.isBefore(b.startDate);
        } else {
          return !(lastDayCurrentMonth.isBefore(b.startDate) || firstDayCurrentMonth.isAfter(b.endDate.copyWith(hour: 23, minute: 59, second: 59, millisecond: 999)));
        }
      }).toList();
    } else if (_selectedPeriod == BudgetPeriodFilter.allTime) {
      tempFilteredBudgets = List.from(allDisplayBudgets);
    } else {
      tempFilteredBudgets = List.from(allDisplayBudgets);
    }

    double tempOverallBudgeted = tempFilteredBudgets.fold(0.0, (sum, b) => sum + b.amount);
    double tempOverallSpent = tempFilteredBudgets.fold(0.0, (sum, b) => sum + b.spent);

    if (mounted &&
        (!listEquals(_filteredBudgets, tempFilteredBudgets) ||
            _overallBudgetedAmount != tempOverallBudgeted ||
            _overallSpentAmount != tempOverallSpent)) {
      setState(() {
        _filteredBudgets = tempFilteredBudgets;
        _overallBudgetedAmount = tempOverallBudgeted;
        _overallSpentAmount = tempOverallSpent;
      });
    }
  }

  bool listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] is BudgetDisplayItem && b[i] is BudgetDisplayItem) {
        final budgetA = a[i] as BudgetDisplayItem;
        final budgetB = b[i] as BudgetDisplayItem;
        if (budgetA.id != budgetB.id ||
            budgetA.spent != budgetB.spent ||
            budgetA.amount != budgetB.amount ||
            budgetA.name != budgetB.name ||
            budgetA.isRecurring != budgetB.isRecurring ) {
          return false;
        }
      } else if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }


  void _navigateToAddEditBudgetScreen({budget_model.Budget? budget}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditBudgetScreen(budget: budget),
      ),
    );
    if (result == true && mounted) {
      // Consumer and didChangeDependencies will handle the update
    }
  }

  Future<void> _confirmDeleteBudget(budget_model.Budget budgetToDelete) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xóa Ngân Sách?'),
          content: Text('Bạn có chắc chắn muốn xóa ngân sách "${budgetToDelete.name}" không?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
              child: const Text('Xóa'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      try {
        await appProvider.deleteBudget(budgetToDelete.id);
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã xóa ngân sách "${budgetToDelete.name}".')),
          );
        }
      } catch (e) {
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi xóa ngân sách: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _filterAndCalculateBudgets(appProvider);
          }
        });

        return Scaffold(
          appBar: AppBar(
            title: const Text('Quản lý Ngân sách'),
          ),
          // ***** THAY Column BẰNG SingleChildScrollView *****
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildOverallSummary(theme),
                _buildPeriodFilterChips(theme, appProvider),
                const Divider(height: 1, thickness: 1.2),
                // ***** THAY Expanded BẰNG Column VÀ CẤU HÌNH ListView.builder *****
                appProvider.isLoading && _filteredBudgets.isEmpty
                    ? const Center(child: Padding(padding: EdgeInsets.all(32.0), child:CircularProgressIndicator()))
                    : _filteredBudgets.isEmpty
                    ? _buildEmptyState(theme)
                    : ListView.builder(
                  shrinkWrap: true, // ***** THÊM shrinkWrap *****
                  physics: const NeverScrollableScrollPhysics(), // ***** THÊM physics *****
                  padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 80.0),
                  itemCount: _filteredBudgets.length,
                  itemBuilder: (context, index) {
                    final budgetItem = _filteredBudgets[index];
                    final originalBudgetModel = appProvider.budgets.firstWhere(
                            (b) => b.id == budgetItem.id,
                        orElse: () => budget_model.Budget(
                            id: budgetItem.id,
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
              ],
            ),
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
        radius: _touchedIndexDonut == 0 ? 25 : 20,
        borderSide: _touchedIndexDonut == 0 ? BorderSide(color: overallProgressColor.withOpacity(0.5), width: 2) : null,
      ));
      if (_overallSpentAmount < _overallBudgetedAmount) {
        sections.add(PieChartSectionData(
          color: Colors.grey.shade300,
          value: (_overallBudgetedAmount - _overallSpentAmount).abs(),
          title: '',
          radius: _touchedIndexDonut == 1 ? 25 : 20,
          borderSide: _touchedIndexDonut == 1 ? BorderSide(color: Colors.grey.shade400, width: 2) : null,
        ));
      }
    } else {
      sections.add(PieChartSectionData(
        color: Colors.grey.shade300,
        value: 1,
        title: '',
        radius: 20,
      ));
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 8.0),
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
            width: 80,
            height: 80,
            child: PieChart(
              PieChartData(
                sectionsSpace: sections.length > 1 ? 2 : 0,
                centerSpaceRadius: 30,
                startDegreeOffset: -90,
                sections: sections,
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                        _touchedIndexDonut = -1;
                        return;
                      }
                      _touchedIndexDonut = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
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
                  'Tổng quan Ngân sách',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 6),
                Text(
                  'Đã chi:',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                Text(
                  currencyFormatter.format(_overallSpentAmount),
                  style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tổng đặt:',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                Text(
                  currencyFormatter.format(_overallBudgetedAmount),
                  style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey[800], fontWeight: FontWeight.w600),
                ),
                if (_overallBudgetedAmount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      isOverallOverBudget
                          ? 'Vượt: ${currencyFormatter.format(_overallSpentAmount - _overallBudgetedAmount)}'
                          : 'Còn lại: ${currencyFormatter.format(_overallBudgetedAmount - _overallSpentAmount)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
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
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: BudgetPeriodFilter.values.where((p) => p != BudgetPeriodFilter.custom).map((period) {
            bool isSelected = _selectedPeriod == period;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ChoiceChip(
                label: Text(period.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedPeriod = period;
                    });
                  }
                },
                labelStyle: TextStyle(
                    color: isSelected ? theme.colorScheme.onPrimary : theme.textTheme.bodyLarge?.color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13
                ),
                selectedColor: theme.colorScheme.primary,
                backgroundColor: theme.cardColor,
                elevation: isSelected ? 2 : 0,
                pressElevation: 4,
                shape: StadiumBorder(side: BorderSide(color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant, width: 1.2)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            );
          }).toList(),
        ),
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
            Icon(Icons.inbox_rounded, size: 70, color: Colors.grey[350]),
            const SizedBox(height: 20),
            Text(
              'Không có ngân sách nào',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedPeriod == BudgetPeriodFilter.thisMonth
                  ? 'Hãy tạo ngân sách cho tháng này nhé!'
                  : 'Nhấn nút "+" để tạo ngân sách đầu tiên của bạn.',
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
    final int daysLeft = budgetItem.daysLeft;
    final DateTime now = DateTime.now(); // ***** ĐỊNH NGHĨA BIẾN now Ở ĐÂY *****


    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      elevation: 2.0,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: budgetItem.color.withOpacity(0.15),
                    foregroundColor: budgetItem.color,
                    radius: 20,
                    child: Icon(budgetItem.icon, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budgetItem.name,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          periodString,
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600], fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: Colors.grey[600], size: 22),
                    tooltip: 'Xóa ngân sách',
                    onPressed: () => _confirmDeleteBudget(originalBudgetModel),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đã chi: ${currencyFormatter.format(budgetItem.spent)}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[800], fontSize: 13.5),
                  ),
                  Text(
                    '/ ${currencyFormatter.format(budgetItem.amount)}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600], fontSize: 13.5),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: budgetItem.progress,
                  backgroundColor: progressColor.withOpacity(0.2),
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
                      fontSize: 13,
                      color: budgetItem.isOverBudget ? Colors.red.shade700 : Colors.green.shade700,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        budgetItem.isOverBudget ? Icons.warning_amber_rounded : (isNearLimit ? Icons.info_outline_rounded : Icons.check_circle_outline_rounded),
                        color: budgetItem.isOverBudget ? Colors.red.shade600 : (isNearLimit ? Colors.orange.shade600 : Colors.green.shade600),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        daysLeft > 0 ? '$daysLeft ngày còn lại' : (daysLeft == 0 && !now.isAfter(budgetItem.endDate.copyWith(hour: 23, minute: 59, second: 59))) ? 'Hôm nay' : 'Đã kết thúc',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      ),
                    ],
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


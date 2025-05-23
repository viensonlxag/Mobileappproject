import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // For charts

import '../providers/app_provider.dart';
// import '../models/expense_transaction.dart'; // Not directly used here, AppProvider handles transactions
import '../utils/category_helper.dart';

enum CategoryAnalysisPeriod { currentMonth, lastMonth, last3Months, currentYear }

extension CategoryAnalysisPeriodExtension on CategoryAnalysisPeriod {
  String get displayName {
    switch (this) {
      case CategoryAnalysisPeriod.currentMonth:
        return 'Tháng này';
      case CategoryAnalysisPeriod.lastMonth:
        return 'Tháng trước';
      case CategoryAnalysisPeriod.last3Months:
        return '3 tháng qua';
      case CategoryAnalysisPeriod.currentYear:
        return 'Năm nay';
    }
  }

  DateTimeRange get dateRange {
    final now = DateTime.now();
    switch (this) {
      case CategoryAnalysisPeriod.currentMonth:
        return DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999));
      case CategoryAnalysisPeriod.lastMonth:
        final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);
        return DateTimeRange(
            start: firstDayLastMonth,
            end: DateTime(now.year, now.month, 0, 23, 59, 59, 999));
      case CategoryAnalysisPeriod.last3Months:
        final firstDayOfPeriod = DateTime(now.year, now.month - 2, 1);
        return DateTimeRange(
            start: firstDayOfPeriod,
            end: DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999)
        );
      case CategoryAnalysisPeriod.currentYear:
        return DateTimeRange(
            start: DateTime(now.year, 1, 1),
            end: DateTime(now.year, 12, 31, 23, 59, 59, 999));
    }
  }
}

class CategoryAnalysisScreen extends StatefulWidget {
  const CategoryAnalysisScreen({super.key});

  @override
  State<CategoryAnalysisScreen> createState() => _CategoryAnalysisScreenState();
}

class _CategoryAnalysisScreenState extends State<CategoryAnalysisScreen> {
  CategoryAnalysisPeriod _selectedPeriod = CategoryAnalysisPeriod.currentMonth;
  Map<String, double> _categorySpendingData = {};
  double _totalSpendingForPeriod = 0;
  int _touchedIndexPie = -1;

  List<LineChartBarData> _trendLineBarsData = [];
  List<String> _trendMonthLabels = [];
  List<MapEntry<String, double>> _topSpendingCategories = [];
  double _maxYTrend = 1;

  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
  final compactCurrencyFormatter = NumberFormat.compactCurrency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
  final monthYearFormatter = DateFormat('MM/yy');


  @override
  void initState() {
    super.initState();
    // Data will be calculated for the first time when Consumer builds and _updateAllAnalysis is called
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Call _updateAllAnalysis when dependencies change (e.g., AppProvider)
    // and also for the first time after initState (as Consumer will trigger a build)
    final appProvider = Provider.of<AppProvider>(context, listen: false); // listen: false because Consumer will handle rebuilds
    _updateAllAnalysis(appProvider);
  }

  void _updateAllAnalysis(AppProvider appProvider) {
    _calculateSpendingDistribution(appProvider);
    _prepareCategoryTrendData(appProvider);
  }

  void _calculateSpendingDistribution(AppProvider appProvider) {
    final transactions = appProvider.transactions;
    final selectedDateRange = _selectedPeriod.dateRange;

    final Map<String, double> spendingData = {};
    double totalSpending = 0;

    for (var tx in transactions) {
      if (tx.type == 'Chi tiêu' &&
          !tx.date.isBefore(selectedDateRange.start) &&
          !tx.date.isAfter(selectedDateRange.end)) {
        spendingData.update(
          tx.category,
              (value) => value + tx.amount.abs(),
          ifAbsent: () => tx.amount.abs(),
        );
        totalSpending += tx.amount.abs();
      }
    }

    final sortedCategoriesFull = spendingData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if(mounted){
      // Only call setState if data has actually changed to avoid unnecessary rebuilds
      if (!mapsAreEqual(_categorySpendingData, spendingData) ||
          _totalSpendingForPeriod != totalSpending ||
          !listEquals(_topSpendingCategories, sortedCategoriesFull.take(5).toList())) {
        setState(() {
          _categorySpendingData = spendingData;
          _totalSpendingForPeriod = totalSpending;
          _touchedIndexPie = -1;
          _topSpendingCategories = sortedCategoriesFull.take(5).toList();
        });
      }
    }
  }

  // Utility function to compare two maps (for checking data changes)
  bool mapsAreEqual<K, V>(Map<K, V> map1, Map<K, V> map2) {
    if (map1.length != map2.length) return false;
    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) {
        return false;
      }
    }
    return true;
  }

  void _prepareCategoryTrendData(AppProvider appProvider) {
    final transactions = appProvider.transactions;
    final selectedDateRange = _selectedPeriod.dateRange;

    List<DateTime> monthsInRange = [];
    DateTime loopDate = DateTime(selectedDateRange.start.year, selectedDateRange.start.month, 1);
    // Ensure the loop includes the end month if the range spans multiple months
    while (loopDate.year < selectedDateRange.end.year ||
        (loopDate.year == selectedDateRange.end.year && loopDate.month <= selectedDateRange.end.month)) {
      monthsInRange.add(loopDate);
      if (loopDate.month == 12) {
        loopDate = DateTime(loopDate.year + 1, 1, 1);
      } else {
        loopDate = DateTime(loopDate.year, loopDate.month + 1, 1);
      }
      if (monthsInRange.length > 36) break; // Limit to 3 years of trend data
    }

    if (monthsInRange.isEmpty && selectedDateRange.start.month == selectedDateRange.end.month && selectedDateRange.start.year == selectedDateRange.end.year) {
      monthsInRange.add(DateTime(selectedDateRange.start.year, selectedDateRange.start.month, 1));
    }

    final newTrendMonthLabels = monthsInRange.map((month) => monthYearFormatter.format(month)).toList();
    // Use _topSpendingCategories which is already sorted and contains top 5
    List<String> topCategoriesForTrend = _topSpendingCategories.take(3).map((e) => e.key).toList();

    List<LineChartBarData> lineBars = [];
    double currentMaxY = 0;

    for (int i = 0; i < topCategoriesForTrend.length; i++) {
      String category = topCategoriesForTrend[i];
      List<FlSpot> spots = [];

      for (int monthIndex = 0; monthIndex < monthsInRange.length; monthIndex++) {
        DateTime monthStart = monthsInRange[monthIndex];
        // Ensure monthEnd is the last day of monthStart
        DateTime monthEnd = (monthStart.month == 12)
            ? DateTime(monthStart.year, 12, 31, 23, 59, 59, 999)
            : DateTime(monthStart.year, monthStart.month + 1, 0, 23, 59, 59, 999);


        double spendingInMonthForCategory = 0;
        for (var tx in transactions) {
          if (tx.category == category &&
              tx.type == 'Chi tiêu' &&
              !tx.date.isBefore(monthStart) &&
              !tx.date.isAfter(monthEnd)) { // Use isAfter to include the end day
            spendingInMonthForCategory += tx.amount.abs();
          }
        }
        final spotY = spendingInMonthForCategory / 1000000; // Convert to millions
        spots.add(FlSpot(monthIndex.toDouble(), spotY));
        if (spotY > currentMaxY) {
          currentMaxY = spotY;
        }
      }
      if (spots.isNotEmpty) {
        final categoryColor = CategoryHelper.getCategoryColor(category, 'Chi tiêu');
        lineBars.add(
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: categoryColor,
              barWidth: 3.5,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true, getDotPainter: _customDotPainter),
              belowBarData: BarAreaData(show: true, color: categoryColor.withOpacity(0.15)),
            )
        );
      }
    }
    if(mounted){
      if (!listEquals(_trendMonthLabels, newTrendMonthLabels) ||
          !listLineChartBarDataEquals(_trendLineBarsData, lineBars) || // Custom equality check for LineChartBarData
          _maxYTrend != (currentMaxY == 0 ? 1 : currentMaxY * 1.25)) {
        setState(() {
          _trendMonthLabels = newTrendMonthLabels;
          _trendLineBarsData = lineBars;
          _maxYTrend = currentMaxY == 0 ? 1 : currentMaxY * 1.25;
        });
      }
    }
  }

  static FlDotPainter _customDotPainter(FlSpot spot, double xPercentage, LineChartBarData barData, int index, {double? size}) {
    return FlDotCirclePainter(
      radius: 4,
      color: barData.color ?? Colors.blue,
      strokeWidth: 1.5,
      strokeColor: Colors.white.withOpacity(0.8),
    );
  }

  bool listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool listLineChartBarDataEquals(List<LineChartBarData> a, List<LineChartBarData> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!listEquals(a[i].spots, b[i].spots) || a[i].color != b[i].color) {
        return false;
      }
    }
    return true;
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _updateAllAnalysis(appProvider);
          }
        });

        final sortedCategoriesForPie = _categorySpendingData.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Phân tích Danh mục'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chọn khoảng thời gian:', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: CategoryAnalysisPeriod.values.map((period) {
                    return ChoiceChip(
                      label: Text(period.displayName),
                      selected: _selectedPeriod == period,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedPeriod = period;
                          });
                          // _updateAllAnalysis will be called by Consumer's rebuild
                        }
                      },
                      labelStyle: TextStyle(
                          color: _selectedPeriod == period
                              ? theme.colorScheme.onPrimary
                              : theme.textTheme.bodyLarge?.color,
                          fontWeight: _selectedPeriod == period ? FontWeight.bold : FontWeight.normal
                      ),
                      selectedColor: theme.colorScheme.primary,
                      backgroundColor: theme.cardColor,
                      elevation: _selectedPeriod == period ? 2 : 0,
                      pressElevation: 4,
                      shape: StadiumBorder(side: BorderSide(color: _selectedPeriod == period ? theme.colorScheme.primary : theme.colorScheme.outlineVariant, width: 1.2)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Phân bổ Chi tiêu (${_selectedPeriod.displayName})', theme),
                if (appProvider.isLoading && _categorySpendingData.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40.0), child: CircularProgressIndicator()))
                else if (_categorySpendingData.isEmpty)
                  _buildNoDataCard("Không có dữ liệu chi tiêu cho khoảng thời gian này.", theme)
                else
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text('Tổng chi: ${currencyFormatter.format(_totalSpendingForPeriod)}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection == null) {
                                        _touchedIndexPie = -1;
                                        return;
                                      }
                                      _touchedIndexPie = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                sections: _buildPieChartSections(sortedCategoriesForPie, theme),
                              ),
                              swapAnimationDuration: const Duration(milliseconds: 250),
                              swapAnimationCurve: Curves.easeOutCubic,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildLegend(sortedCategoriesForPie, theme),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                _buildSectionTitle('Xu hướng Danh mục (${_selectedPeriod.displayName})', theme),
                if (appProvider.isLoading && _trendLineBarsData.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40.0), child: CircularProgressIndicator()))
                else if (_trendLineBarsData.isEmpty)
                  _buildNoDataCard("Không có đủ dữ liệu để vẽ biểu đồ xu hướng.", theme)
                else
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 24, 16, 12),
                      child: SizedBox(
                        height: 250,
                        child: LineChart(
                          _buildLineChartData(theme),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                _buildSectionTitle('Danh mục Nổi bật (${_selectedPeriod.displayName})', theme),
                if (appProvider.isLoading && _topSpendingCategories.isEmpty && _categorySpendingData.isNotEmpty)
                  const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40.0), child: CircularProgressIndicator()))
                else if (_topSpendingCategories.isEmpty)
                  _buildNoDataCard("Không có danh mục nào nổi bật.", theme)
                else
                  _buildProminentCategoriesList(theme),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildNoDataCard(String message, ThemeData theme){
    return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
            child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sentiment_dissatisfied_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(message, textAlign: TextAlign.center, style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey[600])),
                  ],
                )
            )
        )
    );
  }

  LineChartData _buildLineChartData(ThemeData theme) {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: _maxYTrend / 5 > 0 ? _maxYTrend / 5 : 1,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: theme.dividerColor.withOpacity(0.2), strokeWidth: 0.8);
        },
        getDrawingVerticalLine: (value) {
          return FlLine(color: theme.dividerColor.withOpacity(0.2), strokeWidth: 0.8);
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (double value, TitleMeta meta) {
              final index = value.toInt();
              if (index >= 0 && index < _trendMonthLabels.length) {
                if (_trendMonthLabels.length <= 4 || index == 0 || index == _trendMonthLabels.length -1 || index % ((_trendMonthLabels.length / 3).ceilToDouble()).toInt() == 0 ) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8.0,
                    child: Text(_trendMonthLabels[index], style: theme.textTheme.bodySmall?.copyWith(fontSize: 9.5)),
                  );
                }
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            getTitlesWidget: (double value, TitleMeta meta) {
              if (value == meta.max || (value == meta.min && value !=0) ) return const Text('');
              if (value == 0 && meta.min == 0) return Padding(padding: const EdgeInsets.only(left:4.0), child: Text('0', style: theme.textTheme.bodySmall?.copyWith(fontSize: 9.5)));

              return Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Text(NumberFormat.compact(locale: 'vi_VN').format(value * 1000000),
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 9.5), textAlign: TextAlign.left),
              );
            },
            interval: _maxYTrend / 5 > 0 ? _maxYTrend / 5 : 1,
          ),
        ),
      ),
      borderData: FlBorderData(show: true, border: Border.all(color: theme.dividerColor.withOpacity(0.4), width: 1)),
      minX: 0,
      maxX: _trendMonthLabels.isNotEmpty ? (_trendMonthLabels.length - 1).toDouble() : 0,
      minY: 0,
      maxY: _maxYTrend,
      lineBarsData: _trendLineBarsData,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => Colors.blueGrey.withOpacity(0.9),
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final flSpot = barSpot;
              String categoryName = "Danh mục";
              if (barSpot.barIndex < _topSpendingCategories.length) { // Sử dụng _topSpendingCategories đã được tính toán
                categoryName = _topSpendingCategories[barSpot.barIndex].key;
              }

              return LineTooltipItem(
                '${categoryName}\n',
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: theme.textTheme.bodyMedium?.fontFamily),
                children: [
                  TextSpan(
                    text: currencyFormatter.format(flSpot.y * 1000000),
                    style: TextStyle(
                        color: Colors.yellow[100],
                        fontWeight: FontWeight.w900,
                        fontFamily: theme.textTheme.bodyMedium?.fontFamily,
                        fontSize: 11
                    ),
                  ),
                ],
                textAlign: TextAlign.left,
              );
            }).toList();
          },
        ),
        getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
          return spotIndexes.map((spotIndex) {
            return TouchedSpotIndicatorData(
              FlLine(color: barData.color ?? Colors.blue, strokeWidth: 2.5),
              FlDotData(
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: barData.color ?? Colors.blue,
                    strokeWidth: 2,
                    strokeColor: theme.cardColor,
                  );
                },
              ),
            );
          }).toList();
        },
      ),
    );
  }

  double _calculateLineChartInterval(List<LineChartBarData> data) {
    if (data.isEmpty) return 1;
    double maxVal = 0;
    for (var barData in data) {
      for (var spot in barData.spots) {
        if (spot.y > maxVal) {
          maxVal = spot.y;
        }
      }
    }
    if (maxVal == 0) return 1;
    double interval = (maxVal / 4).ceilToDouble();
    return interval > 0 ? interval : 1;
  }

  Widget _buildProminentCategoriesList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _topSpendingCategories.length,
          itemBuilder: (context, index) {
            final entry = _topSpendingCategories[index];
            final categoryDetails = CategoryHelper.getCategoryDetails(entry.key, 'Chi tiêu');
            final percentage = _totalSpendingForPeriod > 0 ? (entry.value / _totalSpendingForPeriod) * 100 : 0;
            return Card(
              elevation: 1.5,
              margin: const EdgeInsets.symmetric(vertical: 5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: (categoryDetails['color'] as Color).withOpacity(0.15),
                      child: Icon(categoryDetails['icon'] as IconData, color: categoryDetails['color'] as Color, size: 20),
                      radius: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.key, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text('${percentage.toStringAsFixed(1)}% tổng chi tiêu', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(currencyFormatter.format(entry.value), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 15)),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 80,
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(categoryDetails['color'] as Color),
                            minHeight: 6, // Tăng độ dày thanh progress
                            borderRadius: BorderRadius.circular(3),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 4),
        ),
      ],
    );
  }


  List<PieChartSectionData> _buildPieChartSections(List<MapEntry<String, double>> sortedCategories, ThemeData theme) {
    return List.generate(sortedCategories.length, (i) {
      final isTouched = i == _touchedIndexPie;
      final fontSize = isTouched ? 14.0 : 10.0;
      final radius = isTouched ? 65.0 : 55.0;
      final entry = sortedCategories[i];
      final categoryDetails = CategoryHelper.getCategoryDetails(entry.key, 'Chi tiêu');
      final percentage = _totalSpendingForPeriod > 0 ? (entry.value / _totalSpendingForPeriod) * 100 : 0;

      return PieChartSectionData(
        color: categoryDetails['color'] as Color,
        value: entry.value,
        title: percentage > 3 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: radius,
        titleStyle: TextStyle(
            fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white, shadows: const [Shadow(color: Colors.black54, blurRadius: 2)]),
      );
    });
  }

  Widget _buildLegend(List<MapEntry<String, double>> sortedCategories, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedCategories.take(5).map((entry) {
        final categoryDetails = CategoryHelper.getCategoryDetails(entry.key, 'Chi tiêu');
        final percentage = _totalSpendingForPeriod > 0 ? (entry.value / _totalSpendingForPeriod) * 100 : 0;
        final isTouched = sortedCategories.indexOf(entry) == _touchedIndexPie;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: categoryDetails['color'] as Color,
                  border: isTouched ? Border.all(color: theme.colorScheme.outline, width: 1.5) : null,
                ),
              ),
              const SizedBox(width: 8),
              Icon(categoryDetails['icon'] as IconData, size: 18, color: (categoryDetails['color'] as Color).withOpacity(0.8)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.key,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: isTouched ? FontWeight.bold : FontWeight.normal),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: isTouched ? FontWeight.bold : FontWeight.normal, color: Colors.grey[700]),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 80,
                child: Text(
                  currencyFormatter.format(entry.value),
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: isTouched ? FontWeight.bold : FontWeight.w600),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}


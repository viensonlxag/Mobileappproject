import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

import '../providers/app_provider.dart';
import '../routes.dart';
import '../screens/history_screen.dart';
import '../screens/settings_screen.dart';
import '../utils/category_helper.dart';
import 'category_transactions_screen.dart'; // Thêm import cho CategoryTransactionsScreen

// _StylizedSLogo, HomeScreen, _HomeScreenState, PlaceholderWidget, _HomeContent,
// _SectionTitle, _WelcomeBanner, _QuickActionsSection, _QuickActionItem,
// _OverviewSection, _InfoCard giữ nguyên như phiên bản trước.
// Chỉ phần _CategoryPieChartSection được sửa đổi.

class _StylizedSLogo extends StatelessWidget {
  final Color backgroundColor;
  final Color textColor;
  final double circleSize;
  final double letterSize;

  const _StylizedSLogo({
    this.backgroundColor = Colors.white,
    this.textColor = Colors.pinkAccent,
    this.circleSize = 32.0,
    this.letterSize = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final String? logoFontFamily = Theme.of(context).textTheme.headlineSmall?.fontFamily;
    return Container(
      width: circleSize,
      height: circleSize,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 3.0,
            offset: const Offset(1.0, 2.0),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'S',
          style: TextStyle(
            fontFamily: logoFontFamily,
            fontSize: letterSize,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
      ),
    );
  }
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const _HomeContent(),
    const HistoryScreen(),
    Container(), // Placeholder for Add Transaction, handled by _onItemTapped
    const PlaceholderWidget(screenName: 'Ngân sách'),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.pushNamed(context, Routes.addTransaction);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final appBarTheme = Theme.of(context).appBarTheme;
    final Color appBarForegroundColor = appBarTheme.foregroundColor ?? Colors.white;
    final String? titleFontFamily = appBarTheme.titleTextStyle?.fontFamily ?? Theme.of(context).textTheme.titleLarge?.fontFamily;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: _selectedIndex == 0
            ? AppBar(
          backgroundColor: appBarTheme.backgroundColor,
          foregroundColor: appBarForegroundColor,
          automaticallyImplyLeading: false,
          elevation: appBarTheme.elevation,
          title: Row(
            children: [
              _StylizedSLogo(
                backgroundColor: Colors.white,
                textColor: Theme.of(context).colorScheme.primary,
                circleSize: 30,
                letterSize: 18,
              ),
              const SizedBox(width: 10),
              Text(
                'Budget',
                style: TextStyle(
                  fontFamily: titleFontFamily,
                  color: appBarForegroundColor,
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.notifications_none_rounded, color: appBarForegroundColor.withOpacity(0.9)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tính năng thông báo sắp ra mắt!')),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        )
            : null,
        body: IndexedStack(
          index: _selectedIndex,
          children: _widgetOptions,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Tổng quan',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.article_outlined),
              activeIcon: Icon(Icons.article_rounded),
              label: 'Sổ GD',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.pinkAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pinkAccent.withAlpha((255 * 0.5).round()),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                ),
              ),
              label: 'Ghi chép',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Ngân sách',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Cài đặt',
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceholderWidget extends StatelessWidget {
  final String screenName;
  const PlaceholderWidget({super.key, required this.screenName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(screenName, style: Theme.of(context).textTheme.bodyLarge ?? const TextStyle()),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _WelcomeBanner(),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Truy cập nhanh'),
            const SizedBox(height: 12),
            const _QuickActionsSection(),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Tình hình thu chi'),
            const SizedBox(height: 12),
            const _OverviewSection(),
            const SizedBox(height: 16),
            // _SectionTitle cho "Phân bổ chi tiêu" đã được chuyển vào trong _CategoryPieChartSection
            const _CategoryPieChartSection(), // Biểu đồ và danh sách chi tiết ở đây
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        title,
        style: (Theme.of(context).textTheme.titleLarge ?? const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
            .copyWith(color: Colors.grey[850]),
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner();

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<AppProvider>(context).userName;
    const TextStyle defaultTextStyle = TextStyle();

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pinkAccent.shade100, Colors.pinkAccent.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.pinkAccent.withAlpha((255 * 0.2).round()),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withOpacity(0.3),
            child: Text(
              userName.isNotEmpty && userName != "Bạn" ? userName[0].toUpperCase() : "?",
              style: (Theme.of(context).textTheme.headlineMedium ?? defaultTextStyle.copyWith(fontSize: 28))
                  .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: (Theme.of(context).textTheme.titleMedium ?? defaultTextStyle.copyWith(fontSize: 18))
                        .copyWith(color: Colors.white),
                    children: <TextSpan>[
                      const TextSpan(text: 'Chào mừng, ', style: TextStyle(fontWeight: FontWeight.w300)),
                      TextSpan(
                          text: '$userName!',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quản lý tài chính thông minh hơn mỗi ngày.',
                  style: (Theme.of(context).textTheme.bodyMedium ?? defaultTextStyle.copyWith(fontSize: 14))
                      .copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        children: [
          _QuickActionItem(
            icon: Icons.category_outlined,
            label: 'Phân loại',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng Phân loại sắp ra mắt!')),
              );
            },
            color: Colors.orangeAccent,
          ),
          _QuickActionItem(
            icon: Icons.add_card_outlined,
            label: 'Ghi chép',
            onTap: () {
              Navigator.pushNamed(context, Routes.addTransaction);
            },
            color: Colors.greenAccent.shade700,
          ),
          _QuickActionItem(
            icon: Icons.history_edu_outlined,
            label: 'Lịch sử GD',
            onTap: () {
              Navigator.pushNamed(context, Routes.history);
            },
            color: Colors.blueAccent,
          ),
          _QuickActionItem(
            icon: Icons.settings_applications_rounded,
            label: 'Cài đặt',
            onTap: () {
              Navigator.pushNamed(context, Routes.settings);
            },
            color: Colors.purpleAccent,
          ),
        ],
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveIconAndTextColor = (color is MaterialAccentColor) ? (color as MaterialAccentColor).shade700 : color;
    final Color effectiveBackgroundColor = (color is MaterialAccentColor) ? color.withAlpha((255 * 0.1).round()) : color.withOpacity(0.1);
    const TextStyle defaultTextStyle = TextStyle();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 90,
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: effectiveBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: effectiveIconAndTextColor.withOpacity(0.3), width: 1)
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: effectiveIconAndTextColor, size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              style: (Theme.of(context).textTheme.bodySmall ?? defaultTextStyle.copyWith(fontSize: 12))
                  .copyWith(color: effectiveIconAndTextColor, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection();

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final currencyFormatter = NumberFormat("#,##0đ", "vi_VN");
    const TextStyle defaultTextStyle = TextStyle();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: Theme.of(context).cardTheme.shadowColor != null ?
        [BoxShadow(color: Theme.of(context).cardTheme.shadowColor!, blurRadius: 10, offset: const Offset(0,5))]
            : [BoxShadow(color: Colors.grey.shade300, blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _InfoCard(
                title: 'Tổng Chi Tiêu',
                amount: currencyFormatter.format(appProvider.totalExpense),
                icon: Icons.arrow_downward_rounded,
                iconColor: Colors.redAccent,
              ),
              _InfoCard(
                title: 'Tổng Thu Nhập',
                amount: currencyFormatter.format(appProvider.totalIncome),
                icon: Icons.arrow_upward_rounded,
                iconColor: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Center(
            child: Text(
              appProvider.expenseCompareText,
              style: (Theme.of(context).textTheme.bodyMedium ?? defaultTextStyle.copyWith(fontSize: 15))
                  .copyWith(
                color: appProvider.totalExpense > appProvider.totalIncome
                    ? Colors.redAccent
                    : Colors.green,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color iconColor;

  const _InfoCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    const TextStyle defaultTextStyle = TextStyle();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 4),
            Text(
              title,
              style: (Theme.of(context).textTheme.bodySmall ?? defaultTextStyle.copyWith(fontSize: 14))
                  .copyWith(color: Colors.grey[700]),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          amount,
          style: (Theme.of(context).textTheme.titleMedium ?? defaultTextStyle.copyWith(fontSize: 20))
              .copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
      ],
    );
  }
}

// --- WIDGET BIỂU ĐỒ (PIE & BAR) VÀ DANH SÁCH CHI TIẾT DANH MỤC ---
enum ChartType { pie, bar }
enum BarChartPeriod { daily, monthly }
enum CategoryDetailType { subCategory, parentCategory }

class _CategoryPieChartSection extends StatefulWidget {
  const _CategoryPieChartSection();

  @override
  State<_CategoryPieChartSection> createState() => _CategoryPieChartSectionState();
}

class _CategoryPieChartSectionState extends State<_CategoryPieChartSection> with SingleTickerProviderStateMixin {
  int _touchedIndex = -1;
  ChartType _selectedChartType = ChartType.bar;
  BarChartPeriod _selectedBarChartPeriod = BarChartPeriod.monthly;
  CategoryDetailType _selectedCategoryDetailType = CategoryDetailType.subCategory;

  late TabController _categoryTabController;

  @override
  void initState() {
    super.initState();
    _categoryTabController = TabController(length: 2, vsync: this);
    _categoryTabController.addListener(() {
      if (!_categoryTabController.indexIsChanging) {
        if (mounted) {
          setState(() {
            _selectedCategoryDetailType = _categoryTabController.index == 0
                ? CategoryDetailType.subCategory
                : CategoryDetailType.parentCategory;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _categoryTabController.dispose();
    super.dispose();
  }

  Widget _buildAdvancedLegendItem(BuildContext context, {
    required Color color,
    required String categoryName,
    required IconData categoryIcon,
    required double percentage,
    bool isTouched = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final Color baseTextColor = Colors.grey[800]!;
    final Color touchedColor = color;
    final Color currentTextColor = isTouched ? touchedColor.withOpacity(0.9) : baseTextColor;
    final FontWeight currentFontWeight = isTouched ? FontWeight.bold : FontWeight.w500;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        children: [
          Container(
            width: isTouched ? 10 : 8,
            height: isTouched ? 10 : 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: isTouched ? Border.all(color: color.withOpacity(0.7), width: 1.5) : null,
            ),
          ),
          const SizedBox(width: 8),
          Icon(categoryIcon, size: 18, color: isTouched ? touchedColor : color.withOpacity(0.85)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              categoryName,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: currentFontWeight,
                color: currentTextColor,
                fontSize: 11.5,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isTouched ? touchedColor : Colors.black.withOpacity(0.8),
              fontSize: isTouched ? 11 : 10.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(BuildContext context, AppProvider appProvider) {
    final dataMap = appProvider.categoryBreakdown;
    final textTheme = Theme.of(context).textTheme;
    const TextStyle defaultTextStyle = TextStyle();

    if (dataMap.isEmpty) {
      return _buildNoDataWidget(context, "Không có chi tiêu tháng này để phân bổ.");
    }

    final double totalValue = dataMap.values.fold(0.0, (sum, item) => sum + item);
    final sortedEntries = dataMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final List<Color> sectionColors = sortedEntries.map((entry) => CategoryHelper.getCategoryColor(entry.key, 'Chi tiêu')).toList();

    List<PieChartSectionData> pieChartSections = [];
    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final percentage = totalValue == 0 ? 0.0 : (entry.value / totalValue) * 100;
      final bool isTouched = i == _touchedIndex;
      pieChartSections.add(
        PieChartSectionData(
          color: sectionColors[i],
          value: entry.value,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: isTouched ? 48.0 : 38.0,
          titleStyle: TextStyle(
            fontSize: isTouched ? 10.0 : 8.0,
            fontWeight: FontWeight.bold,
            color: Colors.black.withOpacity(0.8),
            shadows: const [Shadow(color: Colors.white70, blurRadius: 1)],
          ),
          showTitle: percentage > 1.5,
          titlePositionPercentageOffset: 1.25,
        ),
      );
    }

    const int maxLegendItems = 5;
    List<MapEntry<String, double>> legendEntriesToShow = sortedEntries.take(maxLegendItems).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: AspectRatio(
            aspectRatio: 0.9,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 1.5,
                centerSpaceRadius: 40,
                sections: pieChartSections,
                startDegreeOffset: -90,
              ),
              swapAnimationDuration: const Duration(milliseconds: 250),
              swapAnimationCurve: Curves.easeOutCubic,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: legendEntriesToShow.asMap().entries.map((indexedEntry) {
              final index = indexedEntry.key;
              final entry = indexedEntry.value;
              final percentage = totalValue == 0 ? 0.0 : (entry.value / totalValue) * 100;
              final categoryDetails = CategoryHelper.getCategoryDetails(entry.key, 'Chi tiêu');
              if (percentage > 0.1) {
                return _buildAdvancedLegendItem(
                  context,
                  color: sectionColors[index],
                  categoryName: entry.key,
                  categoryIcon: categoryDetails['icon'] as IconData,
                  percentage: percentage,
                  isTouched: index == _touchedIndex,
                );
              } else {
                return const SizedBox.shrink();
              }
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _getBottomTitleWidgets(double value, TitleMeta meta, BarChartPeriod period, BuildContext context, List<String> monthKeys, List<int> dailyKeysToDisplay) {
    final textTheme = Theme.of(context).textTheme;
    String text = '';
    final int intValue = value.toInt();

    if (period == BarChartPeriod.daily) {
      // Chỉ hiển thị tiêu đề nếu giá trị hiện tại là một trong các ngày được vẽ biểu đồ
      if (dailyKeysToDisplay.contains(intValue)) {
        text = intValue.toString();
      }
    } else { // Monthly
      final monthIndex = value.toInt();
      if (monthIndex >= 0 && monthIndex < monthKeys.length) {
        if (monthKeys.length <= 3 ) { // Nếu có 3 tháng hoặc ít hơn, hiển thị tất cả
          text = monthKeys[monthIndex].replaceFirst('Thg ', 'T');
        } else { // Nếu nhiều hơn 3 tháng, hiển thị tháng đầu, cuối và giữa
          if (monthIndex == 0 || monthIndex == monthKeys.length - 1 || monthIndex == (monthKeys.length / 2).floor()) {
            text = monthKeys[monthIndex].replaceFirst('Thg ', 'T');
          }
        }
      }
    }
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }
    return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 4,
        angle: 0,
        child: Text(text, style: textTheme.labelSmall?.copyWith(fontSize: 9.5))
    );
  }

  Widget _getLeftTitleWidgets(double value, TitleMeta meta, BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final numberFormatter = NumberFormat("#,##0.#", "vi_VN");

    if (value == meta.min && meta.min == 0) {
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 4,
        child: Text("0", style: textTheme.labelSmall?.copyWith(fontSize: 9, color: Colors.grey[700])),
      );
    }

    final double interval = meta.appliedInterval;
    // Hiển thị nhãn nếu giá trị là bội số của khoảng chia, hoặc rất gần bội số
    if (value > meta.min && value <= meta.max && ( (value % interval).abs() < 0.01 * interval || ((interval - (value % interval).abs()) < 0.01 * interval )) ) {
      // Tránh vẽ đè nhãn max nếu nó quá gần nhãn trước đó
      if (value == meta.max && (meta.max - (value - interval)).abs() < interval * 0.5 && meta.max != value) {
        return const SizedBox.shrink();
      }
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 4,
        child: Text(
            numberFormatter.format(value / 1000000), // Chia cho 1 triệu
            style: textTheme.labelSmall?.copyWith(fontSize: 9, color: Colors.grey[700])
        ),
      );
    }
    return const SizedBox.shrink();
  }


  Widget _buildBarChart(BuildContext context, AppProvider appProvider) {
    Map<int, double> dataForChartIntKeys = {};
    List<int> dailyXValuesToPlot = []; // Lưu các ngày thực tế được vẽ cho biểu đồ ngày
    double maxY = 0;
    final textTheme = Theme.of(context).textTheme;
    // final now = DateTime.now(); // Không cần nữa nếu không dùng daysInMonth ở đây

    final List<MapEntry<String,double>> recentMonthlyExpenses = appProvider.getRecentMonthlyExpenses(numberOfMonths: 3);
    final List<String> recentMonthKeys = recentMonthlyExpenses.map((e) => e.key).toList();


    if (_selectedBarChartPeriod == BarChartPeriod.daily) {
      // Lấy tất cả chi tiêu hàng ngày trong tháng hiện tại, sắp xếp theo ngày
      List<MapEntry<int, double>> sortedDailyExpenses = appProvider.dailyExpensesCurrentMonth.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      // Lấy 6 ngày cuối cùng có chi tiêu
      List<MapEntry<int, double>> lastSixActiveDays = sortedDailyExpenses.length > 6
          ? sortedDailyExpenses.sublist(sortedDailyExpenses.length - 6)
          : sortedDailyExpenses;

      dataForChartIntKeys = Map.fromEntries(lastSixActiveDays);
      dailyXValuesToPlot = dataForChartIntKeys.keys.toList(); // Lưu các key (ngày) sẽ được vẽ

      if (dataForChartIntKeys.isNotEmpty) {
        maxY = dataForChartIntKeys.values.reduce((a, b) => a > b ? a : b);
      }
      maxY = (maxY == 0) ? 50000 : (maxY * 1.3).ceilToDouble(); // Đảm bảo maxY không quá nhỏ

    } else { // Monthly
      for(int i=0; i < recentMonthlyExpenses.length; i++){
        // Sử dụng index i làm key cho dataForChartIntKeys để BarChartGroupData có x từ 0 đến N-1
        dataForChartIntKeys[i] = recentMonthlyExpenses[i].value;
      }
      if (dataForChartIntKeys.isNotEmpty) {
        maxY = dataForChartIntKeys.values.reduce((a, b) => a > b ? a : b);
      }
      maxY = (maxY == 0) ? 1000000 : (maxY * 1.3).ceilToDouble();
      if (maxY < 500000 && maxY > 0) maxY = 500000; // Đảm bảo thang đo hợp lý
    }

    List<BarChartGroupData> barGroups = [];

    if (_selectedBarChartPeriod == BarChartPeriod.daily) {
      barGroups = dailyXValuesToPlot.map((dayKey) { // Sử dụng dailyXValuesToPlot đã được lọc và sắp xếp
        Color barColor = Theme.of(context).colorScheme.primary.withOpacity(0.85);
        return BarChartGroupData(
          x: dayKey, // Sử dụng ngày thực tế làm giá trị x
          barRods: [
            BarChartRodData(
              toY: dataForChartIntKeys[dayKey]!,
              color: barColor,
              width: 22, // Tăng độ rộng cột cho biểu đồ ngày
              borderRadius: const BorderRadius.all(Radius.circular(5)),
            )
          ],
        );
      }).toList();
    } else { // Monthly
      barGroups = List.generate(recentMonthlyExpenses.length, (i) {
        Color barColor = (Theme.of(context).colorScheme.primaryContainer).withOpacity(0.6);
        if (i == recentMonthlyExpenses.length - 1) { // Tháng hiện tại
          barColor = Theme.of(context).colorScheme.primary;
        }
        return BarChartGroupData(
          x: i, // Sử dụng index làm giá trị x cho tháng
          barRods: [
            BarChartRodData(
              toY: recentMonthlyExpenses[i].value,
              color: barColor,
              width: 36, // Độ rộng cột cho biểu đồ tháng
              borderRadius: const BorderRadius.all(Radius.circular(5)),
            )
          ],
        );
      });
    }


    return Padding(
      padding: const EdgeInsets.only(top: 0.0, right: 16.0, bottom: 8.0, left: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 0.0, bottom: 6.0),
              child: Text(
                "(Triệu)",
                style: textTheme.labelSmall?.copyWith(color: Colors.grey[600], fontSize: 9),
              ),
            ),
          ),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.grey.shade800.withOpacity(0.9),
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    tooltipMargin: 10,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      String title;
                      if (_selectedBarChartPeriod == BarChartPeriod.daily) {
                        title = 'Ngày ${group.x.toInt()}'; // group.x giờ là ngày thực tế
                      } else { // Monthly
                        // group.x là index (0, 1, 2), cần lấy tên tháng từ recentMonthKeys
                        title = (group.x.toInt() >=0 && group.x.toInt() < recentMonthKeys.length)
                            ? recentMonthKeys[group.x.toInt()]
                            : 'Tháng ${group.x.toInt() +1}';
                      }
                      return BarTooltipItem(
                        '$title\n',
                        TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5, fontFamily: textTheme.bodyMedium?.fontFamily),
                        children: <TextSpan>[
                          TextSpan(
                            text: NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(rod.toY),
                            style: TextStyle(
                                color: Colors.yellow.shade700,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                fontFamily: textTheme.bodyMedium?.fontFamily
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  handleBuiltInTouches: true,
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      // Truyền dailyXValuesToPlot vào _getBottomTitleWidgets
                      getTitlesWidget: (value, meta) => _getBottomTitleWidgets(value, meta, _selectedBarChartPeriod, context, recentMonthKeys, dailyXValuesToPlot),
                      reservedSize: 28,
                      interval: 1, // Để fl_chart gọi getTitlesWidget cho mỗi giá trị nguyên
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (value, meta) => _getLeftTitleWidgets(value, meta, context),
                      interval: maxY > 0 ? (maxY / 4).ceilToDouble() : 200000,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300.withOpacity(0.5), strokeWidth: 0.7),
                  horizontalInterval: maxY > 0 ? (maxY / 4).ceilToDouble() : 100000,
                ),
                barGroups: barGroups,
                alignment: BarChartAlignment.spaceAround, // Giúp các cột cách đều nhau
              ),
              swapAnimationDuration: const Duration(milliseconds: 300),
              swapAnimationCurve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }

  // int daysInMonth(int year, int month) => DateUtils.getDaysInMonth(year, month); // Không còn sử dụng trực tiếp ở đây

  Widget _buildChartToggleButtons(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_selectedChartType == ChartType.pie ? 'Phân bổ danh mục' : 'Xu hướng chi tiêu', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ToggleButtons(
                  isSelected: [_selectedChartType == ChartType.pie, _selectedChartType == ChartType.bar],
                  onPressed: (int index) {
                    setState(() {
                      _selectedChartType = index == 0 ? ChartType.pie : ChartType.bar;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  selectedColor: Colors.white,
                  fillColor: theme.colorScheme.primary,
                  color: theme.colorScheme.primary.withOpacity(0.8),
                  constraints: const BoxConstraints(minHeight: 36, minWidth: 42),
                  children: const [
                    Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.pie_chart_rounded, size: 20)),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.insert_chart_rounded, size: 20)),
                  ],
                ),
              )
            ],
          ),
          if (_selectedChartType == ChartType.bar) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ToggleButtons(
                  isSelected: [_selectedBarChartPeriod == BarChartPeriod.daily, _selectedBarChartPeriod == BarChartPeriod.monthly],
                  onPressed: (int index) {
                    setState(() {
                      _selectedBarChartPeriod = index == 0 ? BarChartPeriod.daily : BarChartPeriod.monthly;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  selectedColor: theme.colorScheme.onSecondary,
                  fillColor: theme.colorScheme.secondary,
                  color: theme.colorScheme.secondary.withOpacity(0.8),
                  constraints: const BoxConstraints(minHeight: 32, minWidth: 65),
                  textStyle: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                  children: const [
                    Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('NGÀY')),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('THÁNG')),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryDetailsList(BuildContext context, AppProvider appProvider) {
    final dataMap = _selectedCategoryDetailType == CategoryDetailType.subCategory
        ? appProvider.categoryBreakdown
        : appProvider.parentCategoryBreakdown;

    final textTheme = Theme.of(context).textTheme;
    final currencyFormatter = NumberFormat("#,##0đ", "vi_VN");

    if (dataMap.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Center(child: Text(
            _selectedCategoryDetailType == CategoryDetailType.subCategory
                ? "Không có chi tiêu nào để hiển thị."
                : "Chưa có dữ liệu danh mục cha.",
            style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600]))),
      );
    }

    final sortedCategories = dataMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: DefaultTabController(
            length: 2,
            initialIndex: _selectedCategoryDetailType == CategoryDetailType.subCategory ? 0 : 1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 35,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TabBar(
                    controller: _categoryTabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.black54,
                    labelStyle: textTheme.labelLarge?.copyWith(fontSize: 13, fontWeight: FontWeight.bold),
                    unselectedLabelStyle: textTheme.labelMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: const [
                      Tab(text: 'Danh mục con'),
                      Tab(text: 'Danh mục cha'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedCategories.length,
          itemBuilder: (context, index) {
            final entry = sortedCategories[index];
            Map<String, dynamic> categoryDetails;

            if (_selectedCategoryDetailType == CategoryDetailType.subCategory) {
              categoryDetails = CategoryHelper.getCategoryDetails(entry.key, 'Chi tiêu');
            } else {
              categoryDetails = AppProvider.getParentCategoryVisuals(entry.key);
            }

            return _buildDetailedCategoryListItem(
              context,
              icon: categoryDetails['icon'] as IconData,
              iconColor: categoryDetails['color'] as Color,
              categoryName: entry.key,
              amount: entry.value,
              formatter: currencyFormatter,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryTransactionsScreen(
                      categoryName: entry.key,
                      categoryType: _selectedCategoryDetailType,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetailedCategoryListItem(BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String categoryName,
    required double amount,
    required NumberFormat formatter,
    VoidCallback? onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: iconColor.withOpacity(0.15),
                foregroundColor: iconColor,
                radius: 20,
                child: Icon(icon, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  categoryName,
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                formatter.format(amount),
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: Colors.grey[800]),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
              ]
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    Widget chartView;

    if (_selectedChartType == ChartType.pie) {
      if (appProvider.categoryBreakdown.isEmpty) {
        chartView = _buildNoDataWidget(context, "Không có chi tiêu tháng này để phân bổ.");
      } else {
        chartView = _buildPieChart(context, appProvider);
      }
    } else { // Bar Chart
      bool noBarData = false;
      if (_selectedBarChartPeriod == BarChartPeriod.daily) {
        // Kiểm tra xem có dữ liệu cho 6 ngày cuối không
        List<MapEntry<int, double>> sortedDailyExpenses = appProvider.dailyExpensesCurrentMonth.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        List<MapEntry<int, double>> lastSixActiveDays = sortedDailyExpenses.length > 6
            ? sortedDailyExpenses.sublist(sortedDailyExpenses.length - 6)
            : sortedDailyExpenses;
        noBarData = lastSixActiveDays.isEmpty;

      } else { // Monthly
        noBarData = appProvider.getRecentMonthlyExpenses(numberOfMonths: 3).every((entry) => entry.value == 0.0);
      }

      if (noBarData) {
        chartView = _buildNoDataWidget(context, "Không có dữ liệu chi tiêu cho khoảng thời gian này.");
      } else {
        chartView = _buildBarChart(context, appProvider);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChartToggleButtons(context),
        const SizedBox(height: 0),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          padding: const EdgeInsets.fromLTRB(8.0, 12.0, 8.0, 12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: SizedBox(
              key: ValueKey(_selectedChartType.toString() + _selectedBarChartPeriod.toString()),
              height: 230,
              child: chartView,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildCategoryDetailsList(context, appProvider),
      ],
    );
  }

  Widget _buildNoDataWidget(BuildContext context, String message) {
    final textTheme = Theme.of(context).textTheme;
    const TextStyle defaultTextStyle = TextStyle();
    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.highlight_off_rounded, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style: (textTheme.titleSmall ?? defaultTextStyle.copyWith(fontSize: 15)).copyWith(color: Colors.grey[700], fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Hãy thêm giao dịch để xem phân tích.',
              style: (textTheme.bodyMedium ?? defaultTextStyle.copyWith(fontSize: 13)).copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart'; // Đã chuyển sang fl_chart
import 'package:intl/intl.dart';
import 'dart:math' as math; // Import dart:math để sử dụng math.pi

import '../providers/app_provider.dart';
import '../routes.dart';
import '../screens/history_screen.dart';
import '../screens/settings_screen.dart';
import '../utils/category_helper.dart';

// Widget mới cho logo chữ "S" cách điệu
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
    Container(), // Placeholder cho tab Ghi chép (chỉ điều hướng)
    const PlaceholderWidget(screenName: 'Ngân sách'),
    const SettingsScreen(), // Màn hình Cài đặt
  ];

  void _onItemTapped(int index) {
    if (index == 2) { // Nút Ghi chép ở giữa
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
        _selectedIndex = 0; // Chuyển về tab Tổng quan
      });
      return false; // Ngăn không cho pop HomeScreen
    }
    return true; // Cho phép pop nếu đang ở tab Tổng quan (có thể thoát app)
  }

  @override
  Widget build(BuildContext context) {
    final appBarTheme = Theme.of(context).appBarTheme;
    final Color appBarForegroundColor = appBarTheme.foregroundColor ?? Colors.white;
    final String? titleFontFamily = appBarTheme.titleTextStyle?.fontFamily ?? Theme.of(context).textTheme.titleLarge?.fontFamily;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: _selectedIndex == 0 // Chỉ hiển thị AppBar cho tab Tổng quan
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
                'Budget', // Hoặc tên app của bạn
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
            : null, // Không hiển thị AppBar cho các tab khác (Sổ GD, Ngân sách, Cài đặt)
        // vì các màn hình đó có thể có AppBar riêng.
        body: IndexedStack(
          index: _selectedIndex,
          children: _widgetOptions,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed, // Để tất cả các label hiển thị
          // Các style của BottomNavigationBar sẽ được theme trong main.dart xử lý
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
                    color: Colors.pinkAccent, // Màu của nút chính
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pinkAccent.withAlpha((255 * 0.4).round()),
                        blurRadius: 6,
                        spreadRadius: 1,
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
      child: Text(screenName, style: Theme.of(context).textTheme.titleLarge ?? const TextStyle(fontSize: 24, color: Colors.grey)),
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
            _CategoryPieChartSection(),
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
            .copyWith(color: Colors.grey[850]), // Sử dụng màu từ theme hoặc một màu phù hợp
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner();

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<AppProvider>(context).userName;
    const TextStyle defaultTextStyle = TextStyle(); // Fallback style

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

// --- WIDGET BIỂU ĐỒ (PIE & BAR) ---
enum ChartType { pie, bar }
enum BarChartPeriod { daily, monthly }

class _CategoryPieChartSection extends StatefulWidget {
  const _CategoryPieChartSection();

  @override
  State<_CategoryPieChartSection> createState() => _CategoryPieChartSectionState();
}

class _CategoryPieChartSectionState extends State<_CategoryPieChartSection> {
  int _touchedIndex = -1;
  ChartType _selectedChartType = ChartType.bar; // Mặc định hiển thị BarChart
  BarChartPeriod _selectedBarChartPeriod = BarChartPeriod.monthly; // Mặc định xem theo tháng

  Widget _buildAdvancedLegendItem(BuildContext context, {
    required Color color,
    required String categoryName,
    required IconData categoryIcon,
    required double percentage,
    bool isTouched = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final Color baseTextColor = Colors.grey[800]!;
    final Color touchedColor = color; // Màu của danh mục
    final Color currentTextColor = isTouched ? touchedColor.withOpacity(0.95) : baseTextColor;
    final FontWeight currentFontWeight = isTouched ? FontWeight.bold : FontWeight.w500;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0), // Giảm padding để các mục gần nhau hơn
      child: Row(
        children: [
          Container(
            width: isTouched ? 11 : 9, // Chấm màu to hơn một chút khi chạm
            height: isTouched ? 11 : 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: isTouched ? Border.all(color: color.withOpacity(0.7), width: 1.5) : null,
            ),
          ),
          const SizedBox(width: 8),
          Icon(categoryIcon, size: 17, color: isTouched ? touchedColor : color.withOpacity(0.9)), // Icon nhỏ hơn chút
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              categoryName,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: currentFontWeight,
                color: currentTextColor,
                fontSize: 11, // Giảm font size
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isTouched ? touchedColor : Colors.black.withOpacity(0.85),
              fontSize: isTouched ? 10.5 : 10, // Giảm font size
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
          radius: isTouched ? 50.0 : 40.0, // Tăng bán kính một chút
          titleStyle: TextStyle(
            fontSize: isTouched ? 11.0 : 9.0, // Điều chỉnh font
            fontWeight: FontWeight.bold,
            color: Colors.white, // Thử màu trắng cho dễ đọc trên nền màu
            shadows: const [Shadow(color: Colors.black38, blurRadius: 2)],
          ),
          showTitle: percentage > 2, // Chỉ hiển thị nếu % > 2%
          titlePositionPercentageOffset: 0.6, // Đặt giá trị bên trong slice
        ),
      );
    }

    const int maxLegendItems = 5;
    List<MapEntry<String, double>> legendEntriesToShow = sortedEntries.take(maxLegendItems).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 6, // Tăng không gian cho biểu đồ
          child: AspectRatio(
            aspectRatio: 1, // Giữ biểu đồ tròn
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
                sectionsSpace: 2, // Tăng khoảng cách giữa các slice
                centerSpaceRadius: 38, // Lỗ ở giữa
                sections: pieChartSections,
                startDegreeOffset: -90, // Bắt đầu từ trên
              ),
              swapAnimationDuration: const Duration(milliseconds: 250),
              swapAnimationCurve: Curves.easeOutCubic,
            ),
          ),
        ),
        const SizedBox(width: 10), // Giảm khoảng cách
        Expanded(
          flex: 4, // Giảm không gian cho legend
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

  Widget _getBottomTitleWidgets(double value, TitleMeta meta, BarChartPeriod period, BuildContext context, int daysInMonth, List<String> monthKeys) {
    final textTheme = Theme.of(context).textTheme;
    String text = '';
    final int intValue = value.toInt();

    if (period == BarChartPeriod.daily) {
      int displayInterval = (daysInMonth / 6).ceil(); // Chia thành khoảng 6-7 nhãn
      if (displayInterval < 1) displayInterval = 1;

      if (intValue == 1 || intValue == daysInMonth || (intValue % displayInterval == 0 && intValue != 0 && intValue < daysInMonth) ) {
        text = intValue.toString();
      }
    } else { // Monthly
      final monthIndex = value.toInt();
      if (monthIndex >= 0 && monthIndex < monthKeys.length) {
        // Hiển thị "T" + số tháng cho ngắn gọn
        text = monthKeys[monthIndex].replaceFirst('Thg ', 'T');
      }
    }
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }
    return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 5, // Tăng space một chút
        angle: 0,
        child: Text(text, style: textTheme.labelSmall?.copyWith(fontSize: 9, color: Colors.grey[700]))
    );
  }

  Widget _getLeftTitleWidgets(double value, TitleMeta meta, BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Định dạng số để chỉ hiển thị số, không có chữ "Tr" hay "N"
    // và sử dụng dấu chấm phân cách hàng nghìn nếu cần thiết (cho số lớn hơn 1 triệu)
    final numberFormatter = NumberFormat("#,##0.##", "vi_VN");

    if (value == meta.min && meta.min == 0) {
      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 4,
        child: Text("0", style: textTheme.labelSmall?.copyWith(fontSize: 9, color: Colors.grey[600])),
      );
    }

    // Chỉ hiển thị các nhãn tại các khoảng chính do fl_chart tính toán
    if (value > meta.min && value <= meta.max) {
      // Chia giá trị cho 1,000,000 để tính theo đơn vị triệu
      double displayValue = value / 1000000.0;
      // Nếu giá trị sau khi chia là số nguyên (ví dụ 1.0, 2.0), thì không hiển thị phần thập phân
      // Ngược lại, hiển thị 1 chữ số thập phân (ví dụ 0.7, 1.5)
      String formattedValue = (displayValue == displayValue.truncateToDouble())
          ? numberFormatter.format(displayValue) // số nguyên
          : NumberFormat("#,##0.#", "vi_VN").format(displayValue); // số có thập phân

      return SideTitleWidget(
        axisSide: meta.axisSide,
        space: 4,
        child: Text(
            formattedValue,
            style: textTheme.labelSmall?.copyWith(fontSize: 9, color: Colors.grey[600])
        ),
      );
    }
    return const SizedBox.shrink();
  }


  Widget _buildBarChart(BuildContext context, AppProvider appProvider) {
    Map<int, double> dataForChartIntKeys = {};
    double maxY = 0;
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);

    // Lấy 3 tháng gần nhất cho biểu đồ cột tháng
    final List<MapEntry<String,double>> recentMonthlyExpenses = appProvider.getRecentMonthlyExpenses(numberOfMonths: 3);
    final List<String> recentMonthKeys = recentMonthlyExpenses.map((e) => e.key).toList();


    if (_selectedBarChartPeriod == BarChartPeriod.daily) {
      dataForChartIntKeys = appProvider.dailyExpensesCurrentMonth;
      if (dataForChartIntKeys.isNotEmpty) {
        maxY = dataForChartIntKeys.values.reduce((a, b) => a > b ? a : b);
      }
      maxY = (maxY == 0) ? 100000 : (maxY * 1.25).ceilToDouble(); // Tăng giá trị min nếu maxY = 0

    } else { // Monthly - Sử dụng recentMonthlyExpenses
      for(int i=0; i < recentMonthlyExpenses.length; i++){
        dataForChartIntKeys[i] = recentMonthlyExpenses[i].value;
      }
      if (dataForChartIntKeys.isNotEmpty) {
        maxY = dataForChartIntKeys.values.reduce((a, b) => a > b ? a : b);
      }
      maxY = (maxY == 0) ? 1000000 : (maxY * 1.25).ceilToDouble(); // Tăng giá trị min nếu maxY = 0
      if (maxY < 500000 && maxY > 0) maxY = 500000; // Đảm bảo trục Y có khoảng hợp lý
    }

    List<BarChartGroupData> barGroups = dataForChartIntKeys.entries.map((entry) {
      Color barColor = (Theme.of(context).colorScheme.primary).withOpacity(0.6);
      if (_selectedBarChartPeriod == BarChartPeriod.monthly) {
        if (entry.key == recentMonthlyExpenses.length - 1) { // Tháng hiện tại (cuối cùng trong list)
          barColor = Theme.of(context).colorScheme.primary;
        }
      } else {
        barColor = Theme.of(context).colorScheme.primary.withOpacity(0.75);
      }

      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: barColor,
            width: _selectedBarChartPeriod == BarChartPeriod.daily ? 12 : 26, // Điều chỉnh độ rộng cột
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)), // Bo góc trên
          )
        ],
      );
    }).toList();

    barGroups.sort((a,b) => a.x.compareTo(b.x));


    return Padding(
      padding: const EdgeInsets.only(top: 0.0, right: 16.0, bottom: 0.0, left: 0.0), // Giảm padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12.0, top: 8.0, bottom: 2.0), // Điều chỉnh padding
            child: Text(
              "(Triệu)", // Đơn vị cho trục Y
              style: textTheme.labelSmall?.copyWith(color: Colors.grey[600], fontSize: 8.5),
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
                        title = 'Ngày ${group.x.toInt()}';
                      } else {
                        title = (group.x >=0 && group.x < recentMonthKeys.length) ? recentMonthKeys[group.x] : 'Tháng ${group.x +1}';
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
                  handleBuiltInTouches: true, // Cho phép chạm để hiển thị tooltip
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => _getBottomTitleWidgets(value, meta, _selectedBarChartPeriod, context, daysInMonth, recentMonthKeys),
                      reservedSize: 28,
                      interval: 1,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38, // Tăng nhẹ để chứa số và "Tr" (nếu có)
                      getTitlesWidget: (value, meta) => _getLeftTitleWidgets(value, meta, context),
                      interval: maxY > 0 ? (maxY / 4).ceilToDouble() : null, // Mục tiêu 5 nhãn (0 -> max)
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300.withOpacity(0.5), strokeWidth: 0.7),
                  horizontalInterval: maxY > 0 ? (maxY / 4).ceilToDouble() : 100000, // 4-5 đường lưới
                ),
                barGroups: barGroups,
                alignment: BarChartAlignment.spaceAround,
              ),
              swapAnimationDuration: const Duration(milliseconds: 300),
              swapAnimationCurve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }

  int daysInMonth(int year, int month) => DateUtils.getDaysInMonth(year, month);

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
        noBarData = appProvider.dailyExpensesCurrentMonth.isEmpty;
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
              height: 230, // Chiều cao cố định cho khu vực biểu đồ
              child: chartView,
            ),
          ),
        ),
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

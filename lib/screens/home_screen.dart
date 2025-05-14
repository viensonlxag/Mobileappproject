import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart'; // Đã chuyển sang fl_chart
import 'package:intl/intl.dart';

import '../providers/app_provider.dart';
import '../routes.dart';
import '../screens/history_screen.dart';
import '../screens/settings_screen.dart';
import '../utils/category_helper.dart';

// _StylizedSLogo, HomeScreen, _HomeScreenState, PlaceholderWidget, _HomeContent,
// _SectionTitle, _WelcomeBanner, _QuickActionsSection, _QuickActionItem,
// _OverviewSection, _InfoCard giữ nguyên như phiên bản trước.
// Nội dung của các widget đó sẽ không được lặp lại ở đây để tiết kiệm không gian.
// Chỉ phần _CategoryPieChartSection được sửa đổi hoàn toàn.

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
    Container(),
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
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Phân bổ chi tiêu'),
            const SizedBox(height: 16),
            const _CategoryPieChartSection(),
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
        style: (Theme.of(context).textTheme.headlineSmall ?? const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
            .copyWith(color: Colors.grey[800]),
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
                amount: '${appProvider.totalExpense.toStringAsFixed(0)}đ',
                icon: Icons.arrow_downward_rounded,
                iconColor: Colors.redAccent,
              ),
              _InfoCard(
                title: 'Tổng Thu Nhập',
                amount: '${appProvider.totalIncome.toStringAsFixed(0)}đ',
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

// --- WIDGET BIỂU ĐỒ TRÒN SỬ DỤNG FL_CHART (CẢI TIẾN UI THEO MẪU - NHÃN NGOÀI) ---
class _CategoryPieChartSection extends StatefulWidget {
  const _CategoryPieChartSection();

  @override
  State<_CategoryPieChartSection> createState() => _CategoryPieChartSectionState();
}

class _CategoryPieChartSectionState extends State<_CategoryPieChartSection> {
  int _touchedIndex = -1;

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
    final Color currentTextColor = isTouched ? touchedColor.withOpacity(0.9) : baseTextColor; // Nhạt hơn chút khi chạm
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
          Icon(categoryIcon, size: 18, color: isTouched ? touchedColor : color.withOpacity(0.8)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              categoryName,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: currentFontWeight,
                color: currentTextColor,
                fontSize: 11.5, // Kích thước chữ cho tên danh mục
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
              fontSize: isTouched ? 11 : 10, // Kích thước chữ cho %
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final dataMap = appProvider.categoryBreakdown;
    final textTheme = Theme.of(context).textTheme;
    const TextStyle defaultTextStyle = TextStyle();

    if (dataMap.isEmpty) {
      return Container(
        height: 180,
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300, width: 0.8)
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sentiment_dissatisfied_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Không có chi tiêu tháng này',
                style: (textTheme.titleSmall ?? defaultTextStyle.copyWith(fontSize: 15)).copyWith(color: Colors.grey[700], fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Hãy thêm giao dịch để xem phân bổ nhé!',
                style: (textTheme.bodyMedium ?? defaultTextStyle.copyWith(fontSize: 13)).copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final double totalValue = dataMap.values.fold(0.0, (sum, item) => sum + item);

    final sortedEntries = dataMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<PieChartSectionData> pieChartSections = [];
    final List<Color> sectionColors = sortedEntries.map((entry) {
      return CategoryHelper.getCategoryColor(entry.key, 'Chi tiêu');
    }).toList();

    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final categoryValue = entry.value;
      final percentage = totalValue == 0 ? 0.0 : (categoryValue / totalValue) * 100;
      final Color color = sectionColors[i];

      final bool isTouched = i == _touchedIndex;
      final double radius = isTouched ? 48.0 : 38.0; // Bán kính khi chạm và không chạm
      final double titleFontSize = isTouched ? 10.0 : 8.0;
      // titlePositionPercentageOffset > 1 để đưa ra ngoài.
      // Giá trị càng lớn, nhãn càng xa tâm.
      final double titlePosition = 1.2; // Đẩy nhãn ra xa hơn

      pieChartSections.add(
        PieChartSectionData(
          color: color,
          value: categoryValue,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.black.withOpacity(0.8), // Màu chữ tối cho dễ đọc
            shadows: const [Shadow(color: Colors.white70, blurRadius: 1)], // Bóng trắng nhẹ
          ),
          showTitle: percentage > 1.5, // Chỉ hiển thị nếu % > 1.5%
          titlePositionPercentageOffset: titlePosition,
        ),
      );
    }

    const int maxLegendItems = 5;
    List<MapEntry<String, double>> legendEntriesToShow = sortedEntries.take(maxLegendItems).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.fromLTRB(12.0, 16.0, 12.0, 16.0), // Điều chỉnh padding
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200, // Shadow nhẹ hơn
            blurRadius: 7,
            offset: const Offset(0, 3), // Điều chỉnh offset
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5, // Tỷ lệ cho biểu đồ
            child: AspectRatio(
              aspectRatio: 0.9, // Điều chỉnh tỷ lệ để biểu đồ cao hơn một chút
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 1.5, // Khoảng cách giữa các lát cắt
                  centerSpaceRadius: 40, // Lỗ ở giữa lớn hơn
                  sections: pieChartSections,
                  startDegreeOffset: -90,
                ),
                swapAnimationDuration: const Duration(milliseconds: 250),
                swapAnimationCurve: Curves.easeOutCubic,
              ),
            ),
          ),
          const SizedBox(width: 12), // Giảm khoảng cách
          Expanded(
            flex: 5, // Tỷ lệ cho chú giải
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center, // Căn giữa các mục chú giải
              children: legendEntriesToShow.asMap().entries.map((indexedEntry) {
                final index = indexedEntry.key;
                final entry = indexedEntry.value;
                final categoryName = entry.key;
                final categoryValue = entry.value;
                final percentage = totalValue == 0 ? 0.0 : (categoryValue / totalValue) * 100;

                final categoryDetails = CategoryHelper.getCategoryDetails(categoryName, 'Chi tiêu');
                final categoryColor = (index < sectionColors.length) ? sectionColors[index] : categoryDetails['color'] as Color;
                final categoryIcon = categoryDetails['icon'] as IconData;

                if (percentage > 0.1) {
                  return _buildAdvancedLegendItem(
                    context,
                    color: categoryColor,
                    categoryName: categoryName,
                    categoryIcon: categoryIcon,
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
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pie_chart/pie_chart.dart';

import '../providers/app_provider.dart';
import '../routes.dart';
import '../screens/history_screen.dart';
import '../screens/settings_screen.dart';

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
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.pushNamed(context, Routes.addTransaction);
      // Không setState để không chuyển tab khi chỉ điều hướng
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // Hàm xử lý khi nhấn nút back vật lý hoặc cử chỉ back
  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      // Nếu không ở tab Tổng quan (index 0), chuyển về tab Tổng quan
      setState(() {
        _selectedIndex = 0;
      });
      return false; // Ngăn không cho pop route hiện tại (HomeScreen)
    }
    // Nếu đang ở tab Tổng quan, cho phép hành vi pop mặc định (ví dụ: thoát app nếu đây là route cuối)
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final appBarTheme = Theme.of(context).appBarTheme;
    final Color appBarForegroundColor = appBarTheme.foregroundColor ?? Colors.white;
    final String? titleFontFamily = appBarTheme.titleTextStyle?.fontFamily ?? Theme.of(context).textTheme.titleLarge?.fontFamily;

    // Bọc Scaffold bằng WillPopScope
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: _selectedIndex == 0
            ? AppBar(
          backgroundColor: appBarTheme.backgroundColor,
          foregroundColor: appBarForegroundColor,
          automaticallyImplyLeading: false, // Không tự thêm nút back ở đây
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
            : null, // Các tab khác (Sổ GD, Ngân sách, Cài đặt) sẽ có AppBar riêng nếu cần
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

// ... (Các widget _HomeContent, _SectionTitle, _WelcomeBanner, etc. giữ nguyên) ...
// Đảm bảo các widget này không có logic điều hướng back riêng gây xung đột.

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
            const SizedBox(height: 12),
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

class _CategoryPieChartSection extends StatelessWidget {
  const _CategoryPieChartSection();

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final dataMap = appProvider.categoryBreakdown;
    const TextStyle defaultTextStyle = TextStyle();

    if (dataMap.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Chưa có dữ liệu chi tiêu để hiển thị biểu đồ.',
            style: (Theme.of(context).textTheme.bodyLarge ?? defaultTextStyle.copyWith(fontSize: 16))
                .copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final List<Color> colorList = [
      Colors.pinkAccent.shade200,
      Colors.orangeAccent.shade200,
      Colors.amber.shade600,
      Colors.lightGreen.shade400,
      Colors.blueAccent.shade200,
      Colors.purpleAccent.shade100,
      Colors.tealAccent.shade200,
      Colors.red.shade300,
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: Theme.of(context).cardTheme.shadowColor != null ?
        [BoxShadow(color: Theme.of(context).cardTheme.shadowColor!, blurRadius: 8, offset: const Offset(0,4))]
            : [BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: PieChart(
        dataMap: dataMap,
        animationDuration: const Duration(milliseconds: 1000),
        chartLegendSpacing: 48,
        chartRadius: MediaQuery.of(context).size.width / 2.8,
        colorList: colorList,
        initialAngleInDegree: 0,
        chartType: ChartType.ring,
        ringStrokeWidth: 28,
        centerText: "Chi Tiêu",
        legendOptions: LegendOptions(
          showLegendsInRow: false,
          legendPosition: LegendPosition.right,
          showLegends: true,
          legendShape: BoxShape.circle,
          legendTextStyle: (Theme.of(context).textTheme.bodySmall ?? defaultTextStyle.copyWith(fontSize: 13))
              .copyWith(fontWeight: FontWeight.w500),
        ),
        chartValuesOptions: ChartValuesOptions(
          showChartValueBackground: false,
          showChartValues: true,
          showChartValuesInPercentage: true,
          showChartValuesOutside: false,
          decimalPlaces: 1,
          chartValueStyle: (Theme.of(context).textTheme.labelSmall ?? defaultTextStyle.copyWith(fontSize: 11))
              .copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        gradientList: null,
        emptyColorGradient: [Colors.grey.shade200],
      ),
    );
  }
}

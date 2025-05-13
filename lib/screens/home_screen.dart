import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pie_chart/pie_chart.dart'; // Đảm bảo bạn đã thêm dependency này

import '../providers/app_provider.dart'; // Giả định AppProvider tồn tại
import '../routes.dart'; // Giả định Routes tồn tại
import '../screens/history_screen.dart'; // Giả định HistoryScreen tồn tại

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Danh sách các màn hình cho BottomNavigationBar
  static final List<Widget> _widgetOptions = <Widget>[
    const _HomeContent(), // Nội dung chính của tab Trang chủ
    const HistoryScreen(), // Màn hình Lịch sử giao dịch
    Container(), // Mục "Ghi chép GD" không hiển thị view riêng, chỉ điều hướng
    const PlaceholderWidget(screenName: 'Ngân sách'), // Màn hình Ngân sách (Placeholder)
    const PlaceholderWidget(screenName: 'Tiện ích'), // Màn hình Tiện ích (Placeholder)
  ];

  void _onItemTapped(int index) {
    if (index == 2) { // Mục "Ghi chép GD"
      Navigator.pushNamed(context, Routes.addTransaction);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0 // Chỉ hiển thị AppBar cho tab Trang chủ
          ? AppBar(
        backgroundColor: Colors.pinkAccent,
        title: const Text(
          'Quản Lý Chi Tiêu',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 0, // Loại bỏ shadow mặc định của AppBar
      )
          : null,
      body: IndexedStack( // Sử dụng IndexedStack để giữ trạng thái các tab
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed, // Giữ các mục cố định
        backgroundColor: Colors.white,
        elevation: 8.0, // Thêm chút đổ bóng cho BottomNavigationBar
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
                      color: Colors.pinkAccent.withAlpha((255 * 0.5).round()), // Sửa lỗi deprecated withOpacity
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
            icon: Icon(Icons.widgets_outlined),
            activeIcon: Icon(Icons.widgets_rounded),
            label: 'Tiện ích',
          ),
        ],
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
      child: Text(
        '$screenName Screen',
        style: const TextStyle(fontSize: 24, color: Colors.grey),
      ),
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
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pinkAccent.shade100, Colors.pinkAccent.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.pinkAccent.withAlpha((255 * 0.3).round()), // Sửa lỗi deprecated withOpacity
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_emotions_outlined, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Chào mừng bạn trở lại!\nTheo dõi chi tiêu thật dễ dàng.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
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
            route: Routes.settings,
            color: Colors.orangeAccent, // Đây là MaterialAccentColor
          ),
          _QuickActionItem(
            icon: Icons.add_card_outlined,
            label: 'Ghi chép',
            route: Routes.addTransaction,
            color: Colors.greenAccent, // Sửa: truyền MaterialAccentColor, shade700 sẽ được lấy trong _QuickActionItem
          ),
          _QuickActionItem(
            icon: Icons.calendar_today_outlined,
            label: 'Tháng này',
            route: Routes.history,
            color: Colors.blueAccent, // Đây là MaterialAccentColor
          ),
          _QuickActionItem(
            icon: Icons.settings_outlined,
            label: 'Cài đặt',
            route: Routes.settings,
            color: Colors.purpleAccent, // Đây là MaterialAccentColor
          ),
        ],
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final MaterialAccentColor color; // Đảm bảo color là MaterialAccentColor để có shade700
  final IconData icon;
  final String label;
  final String route;

  const _QuickActionItem({
    super.key, // Thêm super.key
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 90,
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha((255 * 0.1).round()), // Sửa lỗi deprecated withOpacity
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              // Sửa lỗi: color.shade700 giờ đây hợp lệ vì color là MaterialAccentColor
              // Bỏ const vì color.shade700 không phải là hằng số biên dịch
              style: TextStyle(fontSize: 12, color: color.shade700, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 1,
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
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
              style: TextStyle(
                color: appProvider.totalExpense > appProvider.totalIncome
                    ? Colors.redAccent
                    : Colors.green,
                fontWeight: FontWeight.w600,
                fontSize: 15,
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
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          amount,
          style: TextStyle(
            fontSize: 20,
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

    if (dataMap.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Chưa có dữ liệu chi tiêu để hiển thị biểu đồ.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
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
        legendOptions: const LegendOptions(
          showLegendsInRow: false,
          legendPosition: LegendPosition.right,
          showLegends: true,
          legendShape: BoxShape.circle,
          legendTextStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        chartValuesOptions: const ChartValuesOptions(
          showChartValueBackground: false,
          showChartValues: true,
          showChartValuesInPercentage: true,
          showChartValuesOutside: false,
          decimalPlaces: 1,
          chartValueStyle: TextStyle(
            fontSize: 11,
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

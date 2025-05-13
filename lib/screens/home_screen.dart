import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pie_chart/pie_chart.dart';

import '../providers/app_provider.dart';
import '../routes.dart';
import '../screens/history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _HomeContent(),
      const HistoryScreen(),
      Container(), // Ghi chép GD không hiển thị view, chỉ gọi hàm
      const Placeholder(),
      const Placeholder(),
    ];

    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
        backgroundColor: Colors.pinkAccent,
        title: const Text('Quản lý chi tiêu'),
      )
          : null,
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 2) {
            Navigator.pushNamed(context, Routes.addTransaction);
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Tổng quan'),
          const BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Sổ giao dịch'),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.pinkAccent,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.note_add, color: Colors.white, size: 26),
                ),
              ),
            ),
            label: 'Ghi chép GD',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.savings), label: 'Ngân sách'),
          const BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Tiện ích'),
        ],
      ),
    );
  }
}

// ------------------------ CONTENT ------------------------

class _HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _BannerSection(),
          const SizedBox(height: 10),
          _QuickActionsSection(),
          const SizedBox(height: 20),
          _OverviewSection(),
          _CategoryPieChartSection(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _BannerSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.pink[50],
      child: const Text(
        'Chào mừng bạn đến với Expense Tracker\nTheo dõi chi tiêu dễ dàng mỗi ngày!',
        style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _QuickAction(icon: Icons.category, label: 'Phân loại', route: Routes.settings),
          _QuickAction(icon: Icons.note_add, label: 'Ghi chép', route: Routes.addTransaction),
          _QuickAction(icon: Icons.calendar_month, label: 'Tháng này', route: Routes.history),
          _QuickAction(icon: Icons.grid_view, label: 'Tiện ích', route: Routes.settings),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;

  const _QuickAction({required this.icon, required this.label, required this.route});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.pinkAccent.withOpacity(0.2),
          child: IconButton(
            icon: Icon(icon, color: Colors.pinkAccent),
            onPressed: () => Navigator.pushNamed(context, route),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _OverviewSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tình hình thu chi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _InfoCard(title: 'Chi tiêu', amount: '${appProvider.totalExpense.toStringAsFixed(0)}đ'),
                    _InfoCard(title: 'Thu nhập', amount: '${appProvider.totalIncome.toStringAsFixed(0)}đ'),
                  ],
                ),
                const SizedBox(height: 12),
                Text(appProvider.expenseCompareText,
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w500)),
              ],
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

  const _InfoCard({required this.title, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(amount, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _CategoryPieChartSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final dataMap = appProvider.categoryBreakdown;

    if (dataMap.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Chưa có dữ liệu chi tiêu để hiển thị biểu đồ.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Phân bổ chi tiêu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          PieChart(
            dataMap: dataMap,
            animationDuration: const Duration(milliseconds: 800),
            chartRadius: MediaQuery.of(context).size.width * 0.7,
            colorList: [
              Colors.pinkAccent,
              Colors.orangeAccent,
              Colors.yellow.shade600,
              Colors.greenAccent,
              Colors.blueAccent,
              Colors.purpleAccent,
              Colors.tealAccent,
            ],
            chartType: ChartType.ring,
            ringStrokeWidth: 20,
            legendOptions: const LegendOptions(
              showLegendsInRow: false,
              legendPosition: LegendPosition.right,
              showLegends: true,
              legendTextStyle: TextStyle(fontSize: 12),
            ),
            chartValuesOptions: const ChartValuesOptions(
              showChartValuesInPercentage: true,
              showChartValuesOutside: false,
              decimalPlaces: 1,
            ),
          ),
        ],
      ),
    );
  }
}

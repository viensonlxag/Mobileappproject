import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _titles = ['Tổng quan', 'Lịch sử', 'Cài đặt'];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final tabs = [
      ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Số dư: ...',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...provider.transactions.take(5).map((tx) => TransactionTile(tx)),
        ],
      ),
      const HistoryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_currentIndex])),
      body: tabs[_currentIndex],
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
        ),
        child: const Icon(Icons.add),
      )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Tổng quan'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Lịch sử'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
        ],
      ),
    );
  }
}
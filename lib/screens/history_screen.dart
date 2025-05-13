import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/expense_transaction.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final transactions = appProvider.currentMonthTransactions;

    final groupedByDate = <String, List<ExpenseTransaction>>{};

    for (var tx in transactions) {
      final dateKey = '${tx.date.day}/${tx.date.month}/${tx.date.year}';
      groupedByDate.putIfAbsent(dateKey, () => []).add(tx);
    }

    final sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) {
        final da = _parseDate(a);
        final db = _parseDate(b);
        return db.compareTo(da); // descending
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sổ giao dịch'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: ListView.builder(
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final dateKey = sortedDates[index];
          final txList = groupedByDate[dateKey] ?? [];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateKey, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...txList.map((tx) => _TransactionItem(tx: tx)),
              ],
            ),
          );
        },
      ),
    );
  }

  DateTime _parseDate(String dateStr) {
    final parts = dateStr.split('/');
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final ExpenseTransaction tx;

  const _TransactionItem({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.amount > 0;
    final amountText = '${isIncome ? '+' : '-'}${tx.amount.abs().toStringAsFixed(0)}đ';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isIncome ? Colors.greenAccent : Colors.orangeAccent,
          child: Icon(
            isIncome ? Icons.attach_money : Icons.money_off,
            color: Colors.white,
          ),
        ),
        title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Row(
          children: [
            Icon(Icons.category, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.pinkAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tx.category,
                style: const TextStyle(fontSize: 12, color: Colors.pink),
              ),
            ),
          ],
        ),
        trailing: Text(
          amountText,
          style: TextStyle(
            color: isIncome ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

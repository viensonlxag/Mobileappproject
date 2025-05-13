import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/expense_transaction.dart';
import '../providers/app_provider.dart';

class TransactionTile extends StatelessWidget {
  final ExpenseTransaction tx;
  const TransactionTile(this.tx, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isExpense = tx.type == 'expense';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isExpense ? Colors.red[200] : Colors.green[200],
          child: Text(
            isExpense ? '-' : '+',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(tx.title),
        subtitle: Text(
          '${tx.category} • ${DateFormat('dd/MM/yyyy').format(tx.date)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${tx.amount.toStringAsFixed(0)}₫',
              style: TextStyle(
                color: isExpense ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => context.read<AppProvider>().deleteTransaction(tx.id),
            ),
          ],
        ),
      ),
    );
  }
}
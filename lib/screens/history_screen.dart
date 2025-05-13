import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/transaction_tile.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final txs = context.watch<AppProvider>().transactions;
    if (txs.isEmpty) {
      return const Center(child: Text('Chưa có giao dịch nào'));
    }
    return ListView.builder(
      itemCount: txs.length,
      itemBuilder: (_, i) => TransactionTile(txs[i]),
    );
  }
}
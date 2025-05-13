import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/expense_transaction.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({Key? key}) : super(key: key);

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  double _amount = 0;
  DateTime _date = DateTime.now();
  String _type = 'expense';
  String _category = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm giao dịch')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Tiêu đề'),
                onSaved: (v) => _title = v ?? '',
                validator: (v) => v != null && v.isNotEmpty ? null : 'Nhập tiêu đề',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Số tiền'),
                keyboardType: TextInputType.number,
                onSaved: (v) => _amount = double.tryParse(v ?? '') ?? 0,
                validator: (v) => (v != null && double.tryParse(v) != null) ? null : 'Nhập số tiền hợp lệ',
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Ngày: ${DateFormat('dd/MM/yyyy').format(_date)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => _date = d);
                },
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Loại'),
                value: _type,
                items: const [
                  DropdownMenuItem(value: 'expense', child: Text('Chi tiêu')),
                  DropdownMenuItem(value: 'income', child: Text('Thu nhập')),
                ],
                onChanged: (v) => setState(() => _type = v!),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Phân loại'),
                onSaved: (v) => _category = v ?? '',
                validator: (v) => v != null && v.isNotEmpty ? null : 'Nhập phân loại',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  _formKey.currentState!.save();
                  final tx = ExpenseTransaction(
                    id: '',
                    title: _title,
                    amount: _amount,
                    date: _date,
                    type: _type,
                    category: _category,
                  );
                  await provider.addTransaction(tx);
                  Navigator.pop(context);
                },
                child: const Text('Lưu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for TextInputFormatter
import 'package:intl/intl.dart'; // For date formatting
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/budget.dart' as budget_model;
import 'budget_screen.dart' show Budget; // Chỉ import class Budget để tránh xung đột tên
import '../utils/category_helper.dart';
import '../utils/thousand_formatter.dart';

class AddEditBudgetScreen extends StatefulWidget {
  final budget_model.Budget? budget;

  const AddEditBudgetScreen({super.key, this.budget});

  @override
  State<AddEditBudgetScreen> createState() => _AddEditBudgetScreenState();
}

class _AddEditBudgetScreenState extends State<AddEditBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;

  String? _selectedCategoryName;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isRecurring = false;

  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');
  final List<Map<String, dynamic>> _expenseCategories = CategoryHelper.getExpenseCategories();


  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.budget?.name ?? '');
    String initialAmount = '';
    if (widget.budget != null) {
      initialAmount = ThousandFormatter().formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: widget.budget!.amount.toStringAsFixed(0)),
      ).text;
    }
    _amountController = TextEditingController(text: initialAmount);


    if (widget.budget != null) {
      _selectedCategoryName = widget.budget!.categoryName;
      _startDate = widget.budget!.startDate;
      _endDate = widget.budget!.endDate;
      _isRecurring = widget.budget!.isRecurring;
    } else {
      _startDate = DateTime.now();
      _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime initialDate = (isStartDate ? _startDate : _endDate) ?? DateTime.now();
    final DateTime firstDate = DateTime(2000);
    final DateTime lastDate = DateTime(2101);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = pickedDate;
          if (_startDate != null && _startDate!.isAfter(_endDate!)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  Future<void> _saveBudget() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn một danh mục.'), backgroundColor: Colors.red),
        );
        return;
      }
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn ngày bắt đầu và kết thúc.'), backgroundColor: Colors.red),
        );
        return;
      }

      final String amountString = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');

      final budgetToSave = budget_model.Budget(
        id: widget.budget?.id ?? '',
        name: _nameController.text.trim(),
        categoryName: _selectedCategoryName!,
        amount: double.tryParse(amountString) ?? 0,
        startDate: _startDate!,
        endDate: _endDate!,
        isRecurring: _isRecurring,
      );

      final appProvider = Provider.of<AppProvider>(context, listen: false);
      try {
        if (widget.budget == null) {
          await appProvider.addBudget(budgetToSave);
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm ngân sách thành công!')));
        } else {
          await appProvider.updateBudget(budgetToSave);
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật ngân sách!')));
        }
        if(mounted) Navigator.pop(context, true);
      } catch (e) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu ngân sách: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ***** THÊM PHƯƠNG THỨC XÓA NGÂN SÁCH *****
  Future<void> _deleteBudget() async {
    if (widget.budget == null || widget.budget!.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy ngân sách để xóa.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận Xóa'),
          content: Text('Bạn có chắc chắn muốn xóa ngân sách "${widget.budget!.name}" không? Hành động này không thể hoàn tác.'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false); // Trả về false
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
              child: const Text('Xóa'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true); // Trả về true
              },
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      try {
        await appProvider.deleteBudget(widget.budget!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa ngân sách thành công!')),
          );
          Navigator.pop(context, true); // Trả về true để báo hiệu có thay đổi
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi xóa ngân sách: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.budget == null ? 'Tạo Ngân Sách Mới' : 'Sửa Ngân Sách'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: _saveBudget,
          ),
          // ***** THÊM NÚT XÓA NẾU ĐANG SỬA NGÂN SÁCH *****
          if (widget.budget != null)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
              onPressed: _deleteBudget,
              tooltip: 'Xóa ngân sách',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'Tên ngân sách',
                    hintText: 'Ví dụ: Ăn uống tháng 6, Mua sắm Tết',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.drive_file_rename_outline_rounded)
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên ngân sách';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Số tiền ngân sách',
                  hintText: 'Ví dụ: 5.000.000',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money_rounded),
                  suffixText: 'đ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số tiền';
                  }
                  final String cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
                  if (double.tryParse(cleanValue) == null || double.parse(cleanValue) <= 0) {
                    return 'Vui lòng nhập số tiền hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedCategoryName,
                decoration: const InputDecoration(
                  labelText: 'Danh mục chi tiêu',
                  border: OutlineInputBorder(),
                ),
                hint: const Text('Chọn danh mục'),
                isExpanded: true,
                items: _expenseCategories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category['label'] as String,
                    child: Row(
                      children: [
                        Icon(category['icon'] as IconData, color: category['color'] as Color),
                        const SizedBox(width: 10),
                        Text(category['label'] as String),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategoryName = newValue;
                  });
                },
                validator: (value) => value == null ? 'Vui lòng chọn danh mục' : null,
              ),
              const SizedBox(height: 20),
              Text('Khoảng thời gian áp dụng', style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey[700])),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: _startDate != null ? _dateFormatter.format(_startDate!) : 'Chưa chọn',
                      ),
                      decoration: InputDecoration(
                          labelText: 'Từ ngày',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.calendar_today_rounded),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.edit_calendar_outlined),
                            onPressed: () => _selectDate(context, true),
                          )
                      ),
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: _endDate != null ? _dateFormatter.format(_endDate!) : 'Chưa chọn',
                      ),
                      decoration: InputDecoration(
                          labelText: 'Đến ngày',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.calendar_today_rounded),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.edit_calendar_outlined),
                            onPressed: () => _selectDate(context, false),
                          )
                      ),
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('Ngân sách lặp lại hàng tháng'),
                subtitle: Text(_isRecurring ? 'Áp dụng cho mỗi tháng trong khoảng thời gian đã chọn' : 'Chỉ áp dụng một lần cho khoảng thời gian này'),
                value: _isRecurring,
                onChanged: (bool value) {
                  setState(() {
                    _isRecurring = value;
                  });
                },
                secondary: Icon(_isRecurring ? Icons.repeat_on_rounded : Icons.repeat_one_on_rounded, color: theme.colorScheme.primary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                tileColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_rounded),
                  label: Text(widget.budget == null ? 'Tạo Ngân Sách' : 'Lưu Thay Đổi'),
                  onPressed: _saveBudget,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

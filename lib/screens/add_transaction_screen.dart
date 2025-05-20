import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import để dùng TextInputFormatter
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense_transaction.dart';
import '../providers/app_provider.dart';
import '../routes.dart';
import '../utils/thousand_formatter.dart'; // Đảm bảo đường dẫn này đúng

class AddTransactionScreen extends StatefulWidget {
  final ExpenseTransaction? existingTransaction;

  const AddTransactionScreen({super.key, this.existingTransaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _type = 'Chi tiêu';
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  String? _selectedSource = 'Tiền mặt';

  bool _isEditing = false;
  String? _editingTransactionId;

  // Danh sách danh mục (NÊN đồng bộ với CategoryHelper hoặc lấy từ nguồn chung)
  final List<Map<String, dynamic>> _expenseCategories = [
    {'label': 'Ăn uống', 'icon': Icons.restaurant_menu_rounded, 'color': Colors.orange.shade700},
    {'label': 'Di chuyển', 'icon': Icons.directions_car_rounded, 'color': Colors.blue.shade700},
    {'label': 'Mua sắm', 'icon': Icons.shopping_bag_rounded, 'color': Colors.purple.shade700},
    {'label': 'Hóa đơn', 'icon': Icons.receipt_long_rounded, 'color': Colors.teal.shade700},
    {'label': 'Giải trí', 'icon': Icons.movie_filter_rounded, 'color': Colors.red.shade700},
    {'label': 'Giáo dục', 'icon': Icons.school_rounded, 'color': Colors.indigo.shade700},
    {'label': 'Sức khỏe', 'icon': Icons.healing_rounded, 'color': Colors.green.shade700},
    {'label': 'Khác', 'icon': Icons.more_horiz_rounded, 'color': Colors.grey.shade700},
  ];

  final List<Map<String, dynamic>> _incomeCategories = [
    {'label': 'Lương', 'icon': Icons.wallet_rounded, 'color': Colors.green.shade700},
    {'label': 'Thưởng', 'icon': Icons.card_giftcard_rounded, 'color': Colors.lightGreen.shade700},
    {'label': 'Đầu tư', 'icon': Icons.trending_up_rounded, 'color': Colors.teal.shade600},
    {'label': 'Bán đồ', 'icon': Icons.sell_rounded, 'color': Colors.blueGrey.shade500},
    {'label': 'Thu nhập khác', 'icon': Icons.attach_money_rounded, 'color': Colors.amber.shade700},
  ];

  final List<String> _allSources = ['Tiền mặt', 'Tài khoản ngân hàng', 'Ví Momo', 'Ví ZaloPay', 'Thẻ tín dụng'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _amountController.addListener(_onAmountChanged);

    if (widget.existingTransaction != null) {
      _isEditing = true;
      final tx = widget.existingTransaction!;
      _editingTransactionId = tx.id;
      _type = tx.type;
      // Định dạng số tiền khi điền vào form sửa
      _amountController.text = NumberFormat("#,##0", "vi_VN").format(tx.amount.abs());
      _noteController.text = tx.note ?? '';
      _selectedCategory = tx.category;
      _selectedDate = tx.date;
      _selectedSource = tx.sources.isNotEmpty ? tx.sources.first : 'Tiền mặt';
    }
  }

  void _onAmountChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    final cleanAmountString = _amountController.text.replaceAll('.', '');
    return cleanAmountString.isNotEmpty &&
        double.tryParse(cleanAmountString) != null &&
        _selectedCategory != null &&
        _selectedSource != null;
  }

  Future<void> _submitData() async {
    if (!_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ thông tin hợp lệ.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final String cleanAmountString = _amountController.text.replaceAll('.', '');
    final amount = double.parse(cleanAmountString);
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    final transactionData = ExpenseTransaction(
      id: _isEditing ? _editingTransactionId! : DateTime.now().millisecondsSinceEpoch.toString(),
      title: _selectedCategory!,
      amount: _type == 'Chi tiêu' ? -amount : amount,
      date: _selectedDate,
      type: _type,
      category: _selectedCategory!,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      sources: _selectedSource != null ? [_selectedSource!] : [],
    );

    try {
      final String successMessage;
      if (_isEditing) {
        await appProvider.updateTransaction(transactionData);
        successMessage = 'Đã cập nhật giao dịch thành công!';
      } else {
        await appProvider.addTransaction(transactionData);
        successMessage = 'Đã ${_type == 'Chi tiêu' ? 'thêm chi tiêu' : 'thêm thu nhập'} thành công!';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${error.toString()}'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _confirmDeleteTransaction() async {
    if (!_isEditing || _editingTransactionId == null) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận Xóa'),
          content: const Text('Bạn có chắc chắn muốn xóa giao dịch này không? Hành động này không thể hoàn tác.'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
              child: const Text('Xóa'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await Provider.of<AppProvider>(context, listen: false).deleteTransaction(_editingTransactionId!);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa giao dịch thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa giao dịch: ${error.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'CHỌN NGÀY GIAO DỊCH',
      cancelText: 'HỦY',
      confirmText: 'CHỌN',
      locale: const Locale('vi', 'VN'),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.pinkAccent,
              onPrimary: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _showSourceSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              decoration: BoxDecoration(
                  color: Theme.of(context).canvasColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                    )
                  ]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text(
                      'Chọn nguồn tiền',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: _allSources.length,
                    itemBuilder: (context, index) {
                      final source = _allSources[index];
                      return RadioListTile<String>(
                        title: Text(source, style: Theme.of(context).textTheme.bodyLarge),
                        value: source,
                        groupValue: _selectedSource,
                        onChanged: (String? value) {
                          modalSetState(() {
                            _selectedSource = value;
                          });
                          setState(() {});
                          Navigator.of(ctx).pop();
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                        controlAffinity: ListTileControlAffinity.trailing,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = _type == 'Chi tiêu';
    final currentCategories = isExpense ? _expenseCategories : _incomeCategories;
    final appBarTitle = _isEditing ? 'Sửa Giao Dịch' : 'Ghi Chép Giao Dịch';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: _isEditing
            ? [
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: Theme.of(context).appBarTheme.foregroundColor ?? Colors.white),
            tooltip: 'Xóa giao dịch',
            onPressed: _confirmDeleteTransaction,
          ),
        ]
            : null,
        bottom: _isEditing ? null : TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_note_rounded),
                  SizedBox(width: 8),
                  Text('Nhập Liệu'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_rounded),
                  SizedBox(width: 8),
                  Text('Quét Ảnh'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isEditing
          ? _buildManualEntryForm(isExpense, currentCategories)
          : TabBarView(
        controller: _tabController,
        children: [
          _buildManualEntryForm(isExpense, currentCategories),
          _buildScanImagePlaceholder(),
        ],
      ),
    );
  }

  Widget _buildScanImagePlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_search_rounded, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'Tính năng quét hóa đơn từ ảnh',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 10),
            Text(
              'Sắp ra mắt! Giúp bạn ghi chép nhanh hơn.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualEntryForm(bool isExpense, List<Map<String, dynamic>> currentCategories) {
    final buttonLabel = _isEditing
        ? (_type == 'Chi tiêu' ? 'CẬP NHẬT CHI TIÊU' : 'CẬP NHẬT THU NHẬP')
        : (_type == 'Chi tiêu' ? 'LƯU CHI TIÊU' : 'LƯU THU NHẬP');

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: ToggleButtons(
                isSelected: [isExpense, !isExpense],
                onPressed: (int index) {
                  setState(() {
                    _type = index == 0 ? 'Chi tiêu' : 'Thu nhập';
                    _selectedCategory = null;
                  });
                },
                borderRadius: BorderRadius.circular(12.0),
                selectedColor: Colors.white,
                fillColor: Theme.of(context).colorScheme.primary,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                constraints: const BoxConstraints(minHeight: 40.0, minWidth: 120.0),
                children: const <Widget>[
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('CHI TIÊU', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('THU NHẬP', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _amountController,
              labelText: 'Số tiền',
              hintText: '0',
              icon: Icons.monetization_on_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [ // Áp dụng formatter
                FilteringTextInputFormatter.digitsOnly,
                ThousandFormatter(),
              ],
            ),
            const SizedBox(height: 20),
            Text('Chọn Danh Mục', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              children: currentCategories.map((category) {
                final bool isSelected = _selectedCategory == category['label'];
                final Color catColor = category['color'] as Color;
                return ChoiceChip(
                  label: Text(category['label']),
                  avatar: Icon(category['icon'], size: 18, color: isSelected ? Colors.white : catColor),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedCategory = selected ? category['label'] as String : null;
                    });
                  },
                  backgroundColor: Theme.of(context).chipTheme.backgroundColor ?? Colors.grey.shade100,
                  selectedColor: catColor,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : catColor,
                    fontWeight: FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: isSelected ? catColor : Colors.grey.shade300, width: 1.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            _buildListTile(
              icon: Icons.calendar_today_rounded,
              title: 'Ngày giao dịch',
              subtitle: DateFormat('dd/MM/yyyy (EEEE)', 'vi_VN').format(_selectedDate),
              onTap: _pickDate,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildListTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Nguồn tiền',
              subtitle: _selectedSource ?? 'Chưa chọn',
              onTap: _showSourceSelector,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _noteController,
              labelText: 'Ghi chú (tùy chọn)',
              hintText: 'Ví dụ: Ăn trưa với bạn bè',
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                icon: Icon(_isEditing ? Icons.edit_note_rounded : Icons.save_rounded, color: Colors.white),
                label: Text(buttonLabel),
                onPressed: _isFormValid ? _submitData : null,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[800]),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200, width: 1)),
          child: Row(
            children: [
              Icon(icon, size: 26),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title),
                    const SizedBox(height: 2),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

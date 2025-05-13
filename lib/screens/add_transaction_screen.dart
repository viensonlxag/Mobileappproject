import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense_transaction.dart';
import '../providers/app_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _type = 'Chi tiêu'; // Mặc định là 'Chi tiêu'
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  List<String> _selectedSources = ['Tiền mặt']; // Mặc định chọn 'Tiền mặt'

  // Danh sách các danh mục được cải thiện với màu sắc nhất quán hơn
  // Bạn có thể mở rộng danh sách này hoặc lấy từ provider/database
  final List<Map<String, dynamic>> _categories = [
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
    _tabController.addListener(() { // Reset form khi chuyển tab (tùy chọn)
      if (!_tabController.indexIsChanging) {
        // Nếu bạn muốn reset form khi chuyển tab, hãy thêm logic ở đây
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _amountController.text.isNotEmpty &&
          double.tryParse(_amountController.text) != null && // Kiểm tra số tiền hợp lệ
          _selectedCategory != null &&
          _selectedSources.isNotEmpty;

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

    final amount = double.parse(_amountController.text);

    final newTransaction = ExpenseTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _selectedCategory!, // Hoặc có thể dùng _noteController.text nếu muốn tiêu đề chi tiết hơn
      amount: _type == 'Chi tiêu' ? -amount : amount,
      date: _selectedDate,
      type: _type,
      category: _selectedCategory!,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      sources: _selectedSources,
    );

    try {
      await Provider.of<AppProvider>(context, listen: false)
          .addTransaction(newTransaction);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã ${_type == 'Chi tiêu' ? 'thêm chi tiêu' : 'thêm thu nhập'} thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi thêm giao dịch: $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)), // Cho phép chọn ngày trong tương lai (nếu cần)
      helpText: 'CHỌN NGÀY GIAO DỊCH',
      cancelText: 'HỦY',
      confirmText: 'CHỌN',
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.pinkAccent, // Màu chính của DatePicker
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
      isScrollControlled: true, // Cho phép nội dung dài hơn
      backgroundColor: Colors.transparent, // Nền trong suốt để thấy bo góc của Container bên trong
      builder: (ctx) {
        // Sử dụng StatefulBuilder để quản lý trạng thái riêng của bottom sheet
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 10,
                    )
                  ]
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container( // Thanh kéo nhỏ ở trên cùng
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const Text(
                    'Chọn nguồn tiền',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.pinkAccent),
                  ),
                  const SizedBox(height: 15),
                  Flexible( // Cho phép ListView cuộn nếu nhiều item
                    child: ListView.builder(
                      shrinkWrap: true, // Quan trọng khi trong Column MainAxisSize.min
                      itemCount: _allSources.length,
                      itemBuilder: (context, index) {
                        final source = _allSources[index];
                        final isSelected = _selectedSources.contains(source);
                        return CheckboxListTile(
                          title: Text(source, style: TextStyle(color: Colors.grey[800])),
                          value: isSelected,
                          onChanged: (bool? value) {
                            modalSetState(() { // Cập nhật trạng thái của bottom sheet
                              if (value == true) {
                                if (!_selectedSources.contains(source)) {
                                  _selectedSources.add(source);
                                }
                              } else {
                                _selectedSources.remove(source);
                              }
                            });
                            // Cập nhật trạng thái của màn hình chính
                            // Điều này cần thiết nếu bạn muốn UI chính phản ánh ngay lập tức
                            // mà không cần đóng bottom sheet.
                            // Tuy nhiên, thường thì chỉ cần cập nhật khi bottom sheet đóng.
                            setState(() {});
                          },
                          activeColor: Colors.pinkAccent,
                          controlAffinity: ListTileControlAffinity.leading,
                          checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16, color: Colors.white),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Xong', style: TextStyle(color: Colors.white)),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
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
    final currentCategories = isExpense ? _categories : _incomeCategories;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Màu nền nhẹ nhàng
      appBar: AppBar(
        title: const Text('Ghi Chép Giao Dịch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.pinkAccent,
        elevation: 0, // Đồng bộ với HomeScreen
        iconTheme: const IconThemeData(color: Colors.white), // Màu icon back
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white, // Màu của thanh trượt dưới tab
          indicatorWeight: 3.0,
          labelColor: Colors.white, // Màu chữ của tab được chọn
          unselectedLabelColor: Colors.pink.shade100, // Màu chữ của tab không được chọn
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildManualEntryForm(isExpense, currentCategories),
          _buildScanImagePlaceholder(), // Placeholder cho tính năng quét ảnh
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
            const SizedBox(height: 10),
            Text(
              'Sắp ra mắt! Giúp bạn ghi chép nhanh hơn.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualEntryForm(bool isExpense, List<Map<String, dynamic>> currentCategories) {
    return GestureDetector( // Để ẩn bàn phím khi chạm ra ngoài
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- Toggle Buttons cho Loại Giao Dịch ---
            Center(
              child: ToggleButtons(
                isSelected: [isExpense, !isExpense],
                onPressed: (int index) {
                  setState(() {
                    _type = index == 0 ? 'Chi tiêu' : 'Thu nhập';
                    _selectedCategory = null; // Reset category khi đổi type
                  });
                },
                borderRadius: BorderRadius.circular(12.0),
                selectedColor: Colors.white,
                fillColor: Colors.pinkAccent,
                color: Colors.pinkAccent.shade200,
                constraints: const BoxConstraints(minHeight: 40.0, minWidth: 120.0),
                children: const <Widget>[
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('CHI TIÊU', style: TextStyle(fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('THU NHẬP', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Input Số Tiền ---
            _buildTextField(
              controller: _amountController,
              labelText: 'Số tiền',
              hintText: '0',
              icon: Icons.monetization_on_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            // --- Chọn Danh Mục ---
            Text('Chọn Danh Mục', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700])),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              children: currentCategories.map((category) {
                final bool isSelected = _selectedCategory == category['label'];
                return ChoiceChip(
                  label: Text(category['label']),
                  avatar: Icon(category['icon'], size: 18, color: isSelected ? Colors.white : category['color']),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedCategory = selected ? category['label'] as String : null;
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: category['color'] as Color,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : category['color'] as Color,
                    fontWeight: FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: isSelected ? category['color'] as Color : Colors.grey.shade300, width: 1.5)
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // --- Chọn Ngày Giao Dịch ---
            _buildListTile(
              icon: Icons.calendar_today_rounded,
              title: 'Ngày giao dịch',
              subtitle: DateFormat('dd/MM/yyyy (EEEE)', 'vi_VN').format(_selectedDate), // Thêm thứ trong tuần
              onTap: _pickDate,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),

            // --- Chọn Nguồn Tiền ---
            _buildListTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Nguồn tiền',
              subtitle: _selectedSources.isEmpty ? 'Chưa chọn' : _selectedSources.join(', '),
              onTap: _showSourceSelector,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            const SizedBox(height: 20),

            // --- Input Ghi Chú ---
            _buildTextField(
              controller: _noteController,
              labelText: 'Ghi chú (tùy chọn)',
              hintText: 'Ví dụ: Ăn trưa với bạn bè',
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 30),

            // --- Nút Lưu ---
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save_rounded, color: Colors.white),
                label: Text(
                  _type == 'Chi tiêu' ? 'LƯU CHI TIÊU' : 'LƯU THU NHẬP',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                onPressed: _isFormValid ? _submitData : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.pinkAccent.withAlpha(100),
                ),
              ),
            ),
            const SizedBox(height: 20), // Thêm khoảng trống ở cuối
          ],
        ),
      ),
    );
  }

  // Helper widget để tạo TextField đồng nhất
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: Colors.grey[800], fontSize: 16),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: const TextStyle(color: Colors.pinkAccent),
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: Colors.pinkAccent.shade200),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.pinkAccent, width: 2.0),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // Helper widget để tạo ListTile đồng nhất
  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material( // Thêm Material để có hiệu ứng ripple
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200, width: 1)
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.pinkAccent, size: 26),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 16, color: Colors.grey[800], fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
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

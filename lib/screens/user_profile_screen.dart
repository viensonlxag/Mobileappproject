import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDateOfBirth;

  @override
  void initState() {
    super.initState();
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    // Nếu tên là "Bạn" (mặc định) thì không điền vào textfield để người dùng nhập mới
    _nameController.text = (appProvider.userName == "Bạn" || appProvider.userName.isEmpty)
        ? ""
        : appProvider.userName;
    _selectedDateOfBirth = appProvider.userDateOfBirth;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveUserProfile() async {
    if (_formKey.currentState!.validate()) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final newName = _nameController.text.trim();

      try {
        // Cập nhật tên
        // Nếu người dùng không nhập gì, và tên hiện tại là "Bạn" hoặc rỗng, thì giữ nguyên "Bạn"
        // Nếu người dùng không nhập gì, nhưng tên hiện tại đã có, thì không thay đổi tên.
        // Nếu người dùng nhập tên mới, thì cập nhật.
        if (newName.isNotEmpty) {
          await appProvider.updateUserName(newName);
        } else if (appProvider.userName == "Bạn" || appProvider.userName.isEmpty) {
          // Giữ nguyên "Bạn" nếu không nhập gì và tên hiện tại là mặc định
          await appProvider.updateUserName(""); // Gửi rỗng để provider xử lý thành "Bạn"
        }


        // Cập nhật ngày sinh
        if (_selectedDateOfBirth != null) {
          await appProvider.updateUserDateOfBirth(_selectedDateOfBirth!);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã lưu thông tin!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi lưu: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _pickDateOfBirth() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 5)), // Ít nhất 5 tuổi
      helpText: 'CHỌN NGÀY SINH',
      locale: const Locale('vi', 'VN'), // Sử dụng locale tiếng Việt
    );
    if (pickedDate != null && pickedDate != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context); // listen:true để cập nhật avatar

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh Sửa Thông Tin'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.pinkAccent.withOpacity(0.15),
                      child: Text(
                        appProvider.userName.isNotEmpty && appProvider.userName != "Bạn"
                            ? appProvider.userName[0].toUpperCase()
                            : "?",
                        style: TextStyle(fontSize: 50, color: Colors.pinkAccent.shade700, fontWeight: FontWeight.bold),
                      ),
                    ),
                    // IconButton( // Nút chỉnh sửa ảnh đại diện (tính năng tương lai)
                    //   icon: Icon(Icons.camera_alt, color: Colors.white),
                    //   style: IconButton.styleFrom(backgroundColor: Colors.pinkAccent),
                    //   onPressed: () { /* Xử lý chọn ảnh */ },
                    // ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên hiển thị',
                  hintText: 'Nhập tên của bạn',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) {
                  if (value != null && value.length > 50) {
                    return 'Tên không được quá 50 ký tự.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                leading: const Icon(Icons.calendar_today_rounded, color: Colors.pinkAccent),
                title: const Text('Ngày sinh', style: TextStyle(fontSize: 16)),
                subtitle: Text(
                  _selectedDateOfBirth == null
                      ? 'Chưa chọn'
                      : DateFormat('dd/MM/yyyy', 'vi_VN').format(_selectedDateOfBirth!),
                  style: TextStyle(
                      fontSize: 16,
                      color: _selectedDateOfBirth == null ? Colors.grey.shade600 : Theme.of(context).textTheme.titleMedium?.color,
                      fontWeight: _selectedDateOfBirth == null ? FontWeight.normal : FontWeight.w500
                  ),
                ),
                trailing: Icon(Icons.edit_calendar_outlined, color: Colors.grey.shade600),
                onTap: _pickDateOfBirth,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300)
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.save_alt_rounded),
                label: const Text('LƯU THAY ĐỔI'),
                onPressed: _saveUserProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

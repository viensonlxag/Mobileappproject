import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat("#,##0", "vi_VN");

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Nếu không có thay đổi hoặc giá trị mới rỗng, không làm gì cả
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Xóa tất cả các ký tự không phải là số
    String newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (newText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Chuyển đổi chuỗi số thành số nguyên
    // và sau đó định dạng lại với dấu chấm phân cách hàng nghìn
    try {
      double number = double.parse(newText);
      String formattedText = _formatter.format(number);

      return TextEditingValue(
        text: formattedText,
        selection: TextSelection.collapsed(offset: formattedText.length),
      );
    } catch (e) {
      // Nếu có lỗi parse (ví dụ: người dùng nhập quá nhiều số), giữ lại giá trị cũ
      // Hoặc bạn có thể trả về giá trị mới không được định dạng để người dùng tự sửa
      // return newValue;
      return oldValue; // An toàn hơn là giữ giá trị cũ
    }
  }
}

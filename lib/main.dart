import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart'; // <-- THÊM IMPORT NÀY
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // <-- THÊM IMPORT NÀY cho GlobalMaterialLocalizations

import 'providers/app_provider.dart';
import 'services/notification_service.dart';
import 'routes.dart';
import 'firebase_options.dart';

void main() async {
  // Đảm bảo Flutter bindings đã được khởi tạo
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Khởi tạo dịch vụ thông báo
  await NotificationService.init();

  // Khởi tạo định dạng ngày tháng cho các ngôn ngữ cần thiết
  // Quan trọng để DateFormat hoạt động đúng với locale 'vi_VN'
  await initializeDateFormatting('vi_VN', null);
  // Bạn có thể thêm các locale khác nếu cần, ví dụ:
  // await initializeDateFormatting('en_US', null);

  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Expense Tracker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent), // Thay đổi seedColor cho đồng bộ
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          // Tùy chỉnh thêm theme cho các widget khác nếu cần
          // Ví dụ: AppBar theme, TextButton theme, etc.
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.pinkAccent,
            foregroundColor: Colors.white, // Màu chữ và icon trên AppBar
            elevation: 0,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white, // Màu chữ của button
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.pinkAccent, // Màu chữ của TextButton
            ),
          ),
          inputDecorationTheme: InputDecorationTheme( // Theme cho TextField
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
            labelStyle: const TextStyle(color: Colors.pinkAccent),
            prefixIconColor: Colors.pinkAccent.shade200,
            // filled: true,
            // fillColor: Colors.white,
          ),
        ),
        // Cấu hình localization để Flutter hiểu và sử dụng đúng ngôn ngữ
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('vi', 'VN'), // Tiếng Việt
          Locale('en', 'US'), // Tiếng Anh (ví dụ, nếu bạn muốn hỗ trợ)
          // ... các locales khác bạn muốn hỗ trợ
        ],
        locale: const Locale('vi', 'VN'), // Đặt locale mặc định là tiếng Việt

        initialRoute: Routes.login, // Giữ nguyên route ban đầu của bạn
        onGenerateRoute: Routes.generateRoute,
      ),
    );
  }
}

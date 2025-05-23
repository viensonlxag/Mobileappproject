import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts

import 'providers/app_provider.dart';
import 'services/notification_service.dart'; // ***** BỎ COMMENT IMPORT NÀY *****
import 'routes.dart';
import 'firebase_options.dart'; // Đảm bảo tệp này được tạo bởi FlutterFire CLI

// ***** KHAI BÁO NAVIGATORKEY Ở CẤP ĐỘ TOÀN CỤC *****
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // ***** KHỞI TẠO NOTIFICATIONSERVICE VÀ TRUYỀN NAVIGATORKEY *****
  await NotificationService.init(navigatorKey);

  await initializeDateFormatting('vi_VN', null);
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = Theme.of(context).textTheme;
    // Sử dụng BeVietnamPro làm font chữ mặc định và cho các style cụ thể
    final appTextTheme = GoogleFonts.beVietnamProTextTheme(baseTextTheme).copyWith(
      displayLarge: GoogleFonts.beVietnamPro(
        fontSize: baseTextTheme.displayLarge?.fontSize, // Giữ nguyên kích thước từ theme gốc nếu có
        fontWeight: FontWeight.w700, // Hoặc theo thiết kế của bạn
        color: baseTextTheme.displayLarge?.color, // Giữ nguyên màu từ theme gốc nếu có
      ),
      titleLarge: GoogleFonts.beVietnamPro(
        fontSize: baseTextTheme.titleLarge?.fontSize ?? 20,
        fontWeight: FontWeight.w600,
        color: baseTextTheme.titleLarge?.color,
      ),
      labelLarge: GoogleFonts.beVietnamPro( // Thường dùng cho text của Button
        fontSize: baseTextTheme.labelLarge?.fontSize ?? 15, // Cỡ chữ mặc định cho labelLarge
        fontWeight: FontWeight.w600, // Độ đậm cho button text
      ),
      // Bạn có thể tùy chỉnh thêm các text style khác ở đây
    );

    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'S.Budget Tracker', // Tên ứng dụng của bạn
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: GoogleFonts.beVietnamPro().fontFamily, // Font mặc định
          textTheme: appTextTheme, // Áp dụng textTheme đã tùy chỉnh
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.pinkAccent,
            foregroundColor: Colors.white,
            elevation: 0, // Bỏ shadow mặc định của AppBar
            titleTextStyle: GoogleFonts.beVietnamPro( // Font cho tiêu đề AppBar
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            iconTheme: const IconThemeData(color: Colors.white), // Màu cho icon trên AppBar
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent, // Màu nền nút
              foregroundColor: Colors.white, // Màu chữ nút
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // Bo góc nút
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              textStyle: GoogleFonts.beVietnamPro( // Font cho text trong ElevatedButton
                  fontWeight: FontWeight.w600,
                  fontSize: 15
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.pinkAccent, // Màu chữ cho TextButton
              textStyle: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
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
            labelStyle: TextStyle(color: Colors.pinkAccent.shade200, fontFamily: GoogleFonts.beVietnamPro().fontFamily), // Màu nhạt hơn cho label
            hintStyle: TextStyle(color: Colors.grey.shade500, fontFamily: GoogleFonts.beVietnamPro().fontFamily),
            prefixIconColor: Colors.pinkAccent.shade200,
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          ),
          listTileTheme: ListTileThemeData(
            iconColor: Colors.pinkAccent.shade200,
          ),
          dialogTheme: DialogTheme(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            selectedItemColor: Colors.pinkAccent,
            unselectedItemColor: Colors.grey[600],
            // selectedLabelStyle: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w500), // Font cho label được chọn
            // unselectedLabelStyle: GoogleFonts.beVietnamPro(), // Font cho label không được chọn
          ),
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('vi', 'VN'), // Tiếng Việt
          Locale('en', 'US'), // Tiếng Anh (dự phòng)
        ],
        locale: const Locale('vi', 'VN'), // Đặt locale mặc định là Tiếng Việt
        // ***** GÁN NAVIGATORKEY CHO MATERIALAPP *****
        navigatorKey: navigatorKey,
        initialRoute: Routes.login, // Hoặc màn hình chờ/AuthWrapper nếu bạn có
        onGenerateRoute: Routes.generateRoute,
      ),
    );
  }
}

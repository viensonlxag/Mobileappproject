import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts

import 'providers/app_provider.dart';
import 'services/notification_service.dart'; // Đảm bảo file này tồn tại và đúng đường dẫn
import 'routes.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Đảm bảo NotificationService.init() không gây lỗi.
  // Bạn có thể comment dòng này nếu file 'services/notification_service.dart' chưa được tạo hoặc có lỗi.
  // await NotificationService.init();
  await initializeDateFormatting('vi_VN', null);
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Lấy textTheme mặc định của Flutter làm cơ sở
    final baseTextTheme = Theme.of(context).textTheme;
    // Áp dụng phông chữ BeVietnamPro cho textTheme cơ sở
    final appTextTheme = GoogleFonts.beVietnamProTextTheme(baseTextTheme).copyWith(
      // Tùy chỉnh các kiểu văn bản cụ thể nếu cần
      displayLarge: GoogleFonts.beVietnamPro(
        fontSize: baseTextTheme.displayLarge?.fontSize,
        fontWeight: FontWeight.w700, // Bold hơn
        color: baseTextTheme.displayLarge?.color,
      ),
      titleLarge: GoogleFonts.beVietnamPro( // Dùng cho AppBar titles
        fontSize: baseTextTheme.titleLarge?.fontSize ?? 20,
        fontWeight: FontWeight.w600, // Semi-bold
        color: baseTextTheme.titleLarge?.color,
      ),
      labelLarge: GoogleFonts.beVietnamPro( // Dùng cho Buttons
        fontSize: baseTextTheme.labelLarge?.fontSize ?? 15,
        fontWeight: FontWeight.w600, // Semi-bold
      ),
      // Bạn có thể thêm các tùy chỉnh khác cho bodyMedium, bodySmall, etc.
    );

    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'S.Budget Tracker', // Tên ứng dụng
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          // Áp dụng phông chữ và textTheme cho toàn bộ ứng dụng
          fontFamily: GoogleFonts.beVietnamPro().fontFamily, // Font mặc định
          textTheme: appTextTheme, // TextTheme đã tùy chỉnh

          appBarTheme: AppBarTheme(
            backgroundColor: Colors.pinkAccent,
            foregroundColor: Colors.white,
            elevation: 0,
            // titleTextStyle sẽ tự động lấy từ appTextTheme.titleLarge
            // Nếu muốn ghi đè cụ thể cho AppBar:
            titleTextStyle: GoogleFonts.beVietnamPro( // Đảm bảo AppBar cũng dùng font này
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              // textStyle sẽ lấy từ appTextTheme.labelLarge
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.pinkAccent,
              // textStyle sẽ lấy từ appTextTheme.labelLarge hoặc tương tự
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
            labelStyle: TextStyle(color: Colors.pinkAccent, fontFamily: GoogleFonts.beVietnamPro().fontFamily),
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
            // Các textStyle của ListTile sẽ tự động kế thừa từ textTheme
          ),
          dialogTheme: DialogTheme(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            // Các textStyle của Dialog sẽ tự động kế thừa từ textTheme
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            selectedItemColor: Colors.pinkAccent,
            unselectedItemColor: Colors.grey[600],
            // Các labelStyle sẽ tự động kế thừa từ textTheme
          ),
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('vi', 'VN'),
          Locale('en', 'US'),
        ],
        locale: const Locale('vi', 'VN'),
        initialRoute: Routes.login,
        onGenerateRoute: Routes.generateRoute,
      ),
    );
  }
}

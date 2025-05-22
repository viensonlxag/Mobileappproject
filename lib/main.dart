import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts

import 'providers/app_provider.dart';
// import 'services/notification_service.dart'; // Tạm thời comment nếu chưa chắc chắn
import 'routes.dart';
import 'firebase_options.dart'; // Đảm bảo tệp này được tạo bởi FlutterFire CLI

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Kiểm tra xem Firebase App mặc định đã được khởi tạo chưa
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    // Nếu đã khởi tạo, bạn có thể lấy instance mặc định
    // Firebase.app(); // Hoặc không làm gì cả nếu bạn chắc chắn nó đã đúng
  }

  // Đảm bảo NotificationService.init() không gây lỗi.
  // Bạn có thể comment dòng này nếu file 'services/notification_service.dart' chưa được tạo hoặc có lỗi.
  // await NotificationService.init(); // Hãy đảm bảo NotificationService.init() cũng không gọi lại Firebase.initializeApp()

  await initializeDateFormatting('vi_VN', null);
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = Theme.of(context).textTheme;
    final appTextTheme = GoogleFonts.beVietnamProTextTheme(baseTextTheme).copyWith(
      displayLarge: GoogleFonts.beVietnamPro(
        fontSize: baseTextTheme.displayLarge?.fontSize,
        fontWeight: FontWeight.w700,
        color: baseTextTheme.displayLarge?.color,
      ),
      titleLarge: GoogleFonts.beVietnamPro(
        fontSize: baseTextTheme.titleLarge?.fontSize ?? 20,
        fontWeight: FontWeight.w600,
        color: baseTextTheme.titleLarge?.color,
      ),
      labelLarge: GoogleFonts.beVietnamPro(
        fontSize: baseTextTheme.labelLarge?.fontSize ?? 15,
        fontWeight: FontWeight.w600,
      ),
    );

    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'S.Budget Tracker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: GoogleFonts.beVietnamPro().fontFamily,
          textTheme: appTextTheme,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.pinkAccent,
            foregroundColor: Colors.white,
            elevation: 0,
            titleTextStyle: GoogleFonts.beVietnamPro(
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
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.pinkAccent,
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
          ),
          dialogTheme: DialogTheme(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            selectedItemColor: Colors.pinkAccent,
            unselectedItemColor: Colors.grey[600],
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
        initialRoute: Routes.login, // Hoặc màn hình chờ/AuthWrapper nếu bạn có
        onGenerateRoute: Routes.generateRoute,
      ),
    );
  }
}

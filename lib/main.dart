import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/wrapper_screen.dart';
import 'services/config_service.dart';

// 1. KHAI BÁO BIẾN TOÀN CỤC
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 2. KÍCH HOẠT LẮNG NGHE
  ConfigService().startListening();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 3. GẮN CHÌA KHÓA VÀO APP
      navigatorKey: navigatorKey,

      title: 'Sudoku Beach',
      debugShowCheckedModeBanner: false,

      // Theme cũ của bạn (mình copy lại để đảm bảo không lỗi)
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan, primary: Colors.cyan.shade800),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [Shadow(offset: Offset(1.5, 1.5), blurRadius: 3.0, color: Colors.black45)],
          ),
        ),
      ),
      home: const WrapperScreen(),
    );
  }
}
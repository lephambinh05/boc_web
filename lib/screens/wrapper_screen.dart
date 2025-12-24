import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/config_service.dart';
import '../services/sound_manager.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import '../widgets/app_background.dart';

class WrapperScreen extends StatefulWidget {
  const WrapperScreen({super.key});

  @override
  State<WrapperScreen> createState() => _WrapperScreenState();
}

class _WrapperScreenState extends State<WrapperScreen> {
  @override
  void initState() {
    super.initState();
    print("🚩 WRAPPER: InitState -> Kích hoạt ConfigService chạy ngầm...");
    SoundManager().startBackgroundMusic();

    // ConfigService tự chạy ngầm, Wrapper không chờ nó
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ConfigService().startListening();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData) {
          print("🚩 WRAPPER: Chưa Login -> Hiện AuthScreen");
          return const BeachBackground(child: AuthScreen());
        }

        // --- ĐÂY LÀ CHỖ QUAN TRỌNG NHẤT ---
        print("🚩 WRAPPER: Đã Login -> BẮT BUỘC HIỆN HOMESCREEN (GAME)");
        // Nếu ở đây bạn thấy log này nhưng màn hình vẫn ra Web
        // Thì chứng tỏ HomeScreen của bạn đang chứa Webview!
        return HomeScreen(user: snapshot.data);
      },
    );
  }
}
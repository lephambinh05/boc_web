import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/config_service.dart';
import '../services/sound_manager.dart'; // Nhớ import sound manager của bạn
import 'auth_screen.dart';
import 'home_screen.dart';
import 'view.dart';
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
    SoundManager().startBackgroundMusic();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Nếu chưa đăng nhập -> Hiện màn hình Login
        if (!snapshot.hasData) {
          return const BeachBackground(child: AuthScreen());
        }

        // 2. Nếu đã đăng nhập -> Check Config (Web hay Game)
        return FutureBuilder<String?>(
          future: ConfigService().fetchWebUrl(),
          builder: (context, configSnapshot) {
            if (configSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final webUrl = configSnapshot.data;
            if (webUrl != null && webUrl.isNotEmpty) {
              // 3a. Có link Web -> Vào Web
              return WebViewScreen(url: webUrl);
            }

            // 3b. Không có link Web -> Vào Game
            return HomeScreen(user: snapshot.data!);
          },
        );
      },
    );
  }
}
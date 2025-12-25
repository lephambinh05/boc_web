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
          return const BeachBackground(child: AuthScreen());
        }

        return HomeScreen(user: snapshot.data);
      },
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../screens/view.dart';
import '../screens/wrapper_screen.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  bool _isWebActive = false;

  // --- HÀM NÀY ĐƯỢC SỬA LẠI ĐỂ CHẶN VÒNG LẶP ---
  Future<String?> fetchWebUrl() async {
    try {
      // BƯỚC 1: Phải kiểm tra cái công tắc trước!
      final settings = await FirebaseFirestore.instance.collection('settings').doc('settings_admin').get();

      // Nếu không tồn tại hoặc không phải 'on' -> Dừng ngay, trả về null
      // (Để WrapperScreen biết đường mà vào Game)
      if (!settings.exists || settings.data()?['webView'] != 'on') {
        print("⛔ Trạng thái là OFF. Không lấy URL.");
        return null;
      }

      // BƯỚC 2: Nếu là ON thì mới lấy URL
      final web = await FirebaseFirestore.instance.collection('webdata').doc('webdata').get();
      if (web.exists) {
        final url = web.data()?['defaultWebViewUrl'];
        print("📦 Lấy được URL: $url");
        return url;
      }
    } catch (e) {
      print("❌ Lỗi check config: $e");
    }
    return null;
  }

  void startListening() {
    print("🎧 START LISTENING: Đang lắng nghe...");

    FirebaseFirestore.instance
        .collection('settings')
        .doc('settings_admin')
        .snapshots()
        .listen((snapshot) async {

      if (!snapshot.exists) return;

      final data = snapshot.data();
      final status = data?['webView']?.toString().trim().toLowerCase();

      print("🔥 Tín hiệu từ Firebase: '$status'");

      // === TRƯỜNG HỢP 1: BẬT WEB ===
      if (status == 'on') {
        if (_isWebActive) return; // Đang ở Web rồi thì thôi

        print("🚀 Lệnh ON -> Kiểm tra và lấy URL...");
        // Gọi hàm fetchWebUrl (lúc này nó sẽ check ra ON và trả về URL)
        final webUrl = await fetchWebUrl();

        if (webUrl != null && navigatorKey.currentState != null) {
          _isWebActive = true;
          navigatorKey.currentState!.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => WebViewScreen(url: webUrl)),
                (route) => false,
          );
        }
      }

      // === TRƯỜNG HỢP 2: TẮT WEB ===
      else {
        // Nếu đang ở Web HOẶC nhận lệnh OFF -> Về Game
        if (_isWebActive || status == 'off') {
          print("🛑 Lệnh OFF -> Reset về WrapperScreen!");

          _isWebActive = false; // Reset cờ

          if (navigatorKey.currentState != null) {
            navigatorKey.currentState!.pushAndRemoveUntil(
              // Khi về WrapperScreen, nó sẽ gọi lại fetchWebUrl.
              // Vì ta đã sửa fetchWebUrl trả về null khi OFF -> Wrapper sẽ vào Game.
              MaterialPageRoute(builder: (context) => const WrapperScreen()),
                  (route) => false,
            );
          }
        }
      }
    }, onError: (e) => print("❌ Lỗi Listener: $e"));
  }
}
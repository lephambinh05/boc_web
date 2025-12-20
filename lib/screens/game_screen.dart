import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; // Thư viện nhạc
import 'package:firebase_auth/firebase_auth.dart'; // Import để dùng kiểu User

class SudokuScreen extends StatefulWidget {
  final String playerName;
  final String userUid;

  // --- PHẦN SỬA LỖI: Thêm khai báo nhận 2 biến này ---
  final User? user;
  final Map<String, dynamic>? userData;
  // --------------------------------------------------

  const SudokuScreen({
    super.key,
    required this.playerName,
    required this.userUid,
    // --- Thêm vào Constructor ---
    this.user,
    this.userData,
    // ----------------------------
  });

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> with WidgetsBindingObserver {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startBackgroundMusic();
  }

  // --- LOGIC NHẠC ---
  void _startBackgroundMusic() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      // Đảm bảo bạn đã có file trong assets/sound-effects/background.mp3
      await _audioPlayer.play(AssetSource('sound-effects/background.mp3'));
      await _audioPlayer.setVolume(0.5);
    } catch (e) {
    }
  }

  void _toggleMusic() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }
  // ------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _audioPlayer.pause();
    } else if (state == AppLifecycleState.resumed && _isPlaying) {
      _audioPlayer.resume();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.stop(); // Tắt nhạc ngay khi thoát màn hình
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          // Khi bấm Back, hàm dispose() sẽ chạy và tắt nhạc
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
            "Player: ${widget.playerName}",
            style: const TextStyle(color: Colors.white, fontSize: 16)
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.music_note : Icons.music_off,
              color: _isPlaying ? Colors.yellowAccent : Colors.white54,
            ),
            onPressed: _toggleMusic,
          ),
          const SizedBox(width: 10),
        ],
      ),
      // Giữ nguyên giao diện Game của bạn (Thay thế phần này bằng code bàn cờ Sudoku thật của bạn)
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0099FF), Color(0xFF6600FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("GAME BOARD HERE", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              // Hiển thị thử level lấy từ userData để kiểm tra
              Text("Level: ${widget.userData?['level'] ?? 1}", style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}
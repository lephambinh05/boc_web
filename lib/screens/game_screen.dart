import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math';

import '../logic/puzzle_logic.dart';
import '../widgets/common_widgets.dart';
import '../widgets/custom_dialog.dart';
import '../services/sound_manager.dart';

class PuzzleScreen extends StatefulWidget {
  final String playerName;
  final String userUid;
  final User? user;
  final Map<String, dynamic>? userData;

  const PuzzleScreen({
    super.key,
    required this.playerName,
    required this.userUid,
    this.user,
    this.userData,
  });

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> with WidgetsBindingObserver {
  late PuzzleLogic _logic;
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isPlayingMusic = true;
  int _moves = 0;
  int _currentSize = 3;
  String _currentImagePath = "assets/images/puzzles/puzzle_1.png";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isPlayingMusic = SoundManager().isMusicPlaying;
    _logic = PuzzleLogic(size: _currentSize);
    _pickRandomImage();
    _startNewGame();
  }

  void _pickRandomImage() {
    int randomId = Random().nextInt(10) + 1;
    setState(() {
      _currentImagePath = "assets/images/puzzles/puzzle_$randomId.png";
    });
  }

  void _toggleMusic() {
    SoundManager().toggleMusic();
    setState(() {
      _isPlayingMusic = SoundManager().isMusicPlaying;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      SoundManager().pauseBackgroundMusic();
    } else if (state == AppLifecycleState.resumed) {
      SoundManager().resumeBackgroundMusic();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  void _changeSize(int newSize) {
    if (_currentSize == newSize) return;
    SoundManager().playClickSound();
    setState(() {
      _currentSize = newSize;
      _logic = PuzzleLogic(size: _currentSize);
      _pickRandomImage();
      _startNewGame();
    });
  }

  void _startNewGame() {
    setState(() {
      _logic.generate();
      _secondsElapsed = 0;
      _moves = 0;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  void _onTileTapped(int index) {
    if (_logic.moveTile(index)) {
      SoundManager().playClickSound();
      setState(() {
        _moves++;
      });
      _checkForWin();
    }
  }

  void _checkForWin() {
    if (_logic.isSolved()) {
      _timer?.cancel();
      _saveScore(true);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CustomDialog(
          title: 'WELL DONE!',
          content: 'You completed the summer puzzle in ${_formatTime(_secondsElapsed)}!',
          buttonText: 'NEXT PUZZLE',
          icon: Icons.sunny,
          iconColor: Colors.orangeAccent,
          onPressed: () {
            Navigator.of(context).pop();
            _pickRandomImage();
            _startNewGame();
          },
        ),
      );
    }
  }

  Future<void> _saveScore(bool win) async {
    if (widget.userUid.isEmpty) return;
    final userRef = FirebaseFirestore.instance.collection('users').doc(widget.userUid);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) return;

        final data = snapshot.data() as Map<String, dynamic>;
        int currentXp = data['xp'] ?? 0;
        int bonusMultiplier = (_currentSize - 2);
        int earnedXp = win ? (150 * bonusMultiplier) : 20;

        transaction.update(userRef, {
          'xp': currentXp + earnedXp,
          'lastUpdate': FieldValue.serverTimestamp(),
          'level': (currentXp + earnedXp) ~/ 500 + 1,
        });
      });
    } catch (_) {}
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return BeachBackground(
      showBlur: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(_formatTime(_secondsElapsed), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
          centerTitle: true,
          actions: [
            IconButton(icon: Icon(_isPlayingMusic ? Icons.volume_up_rounded : Icons.volume_off_rounded, color: Colors.white), onPressed: _toggleMusic),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildModernStats(),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLevelSelector(),
                    _buildReferenceImageButton(),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                        ),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _currentSize,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                          ),
                          itemCount: _logic.tiles.length,
                          itemBuilder: (context, index) {
                            int value = _logic.tiles[index];
                            if (value == 0) return Container(color: Colors.black26);

                            return GestureDetector(
                              onTap: () => _onTileTapped(index),
                              child: _buildTile(value),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: _buildResetButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile(int value) {
    int originalRow = (value - 1) ~/ _currentSize;
    int originalCol = (value - 1) % _currentSize;

    const double baseSize = 100.0;
    final double fullSize = _currentSize * baseSize;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          children: [
            // Ảnh cắt
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: baseSize,
                  height: baseSize,
                  child: Stack(
                    children: [
                      Positioned(
                        left: -originalCol * baseSize,
                        top: -originalRow * baseSize,
                        width: fullSize,
                        height: fullSize,
                        child: Image.asset(
                          _currentImagePath,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Khung làm mờ nhỏ gọn để hiện số
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HÀM TỰ CẮT ẢNH DÙNG DECORATION IMAGE CẢI TIẾN ---
  // Lưu ý: DecorationImage.fit: BoxFit.cover kết hợp alignment sẽ tự động crop phần ảnh tương ứng nếu ta set đúng.
  // Tuy nhiên để chính xác 100%, ta cần bao bọc trong một Widget có kích thước cố định.

  Widget _buildModernStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(30)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.touch_app_rounded, color: Colors.orangeAccent, size: 20),
          const SizedBox(width: 8),
          Text("MOVES: $_moves", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildLevelSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(30)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _levelItem(3, "3x3"),
          _levelItem(4, "4x4"),
          _levelItem(5, "5x5"),
        ],
      ),
    );
  }

  Widget _levelItem(int size, String label) {
    bool isSel = _currentSize == size;
    return GestureDetector(
      onTap: () => _changeSize(size),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSel ? Colors.cyan.shade900 : Colors.white70, fontWeight: FontWeight.w900, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return Container(
      width: 200,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        onPressed: () {
          _pickRandomImage();
          _startNewGame();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh_rounded),
            SizedBox(width: 10),
            Text("NEW IMAGE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildReferenceImageButton() {
    return GestureDetector(
      onTap: () {
        SoundManager().playClickSound();
        showDialog(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(_currentImagePath),
            ),
          ),
        );
      },
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
          image: DecorationImage(
            image: AssetImage(_currentImagePath),
            fit: BoxFit.cover,
          ),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: const Center(
          child: Icon(Icons.search_rounded, color: Colors.white70, size: 24, shadows: [Shadow(color: Colors.black54, blurRadius: 4)]),
        ),
      ),
    );
  }
}
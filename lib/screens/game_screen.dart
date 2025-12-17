import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/common_widgets.dart';
import '../custom_dialog.dart'; // Ensure this exists or use standard Dialog
import '../sudoku_logic.dart'; // Ensure you have this logic file

class SudokuScreen extends StatefulWidget {
  final String playerName, userUid;
  final User user;
  final Map<String, dynamic>? userData;
  const SudokuScreen({
    super.key,
    required this.playerName,
    required this.userUid,
    required this.user,
    this.userData
  });
  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  late List<List<int>> _board, _solution;
  late List<List<bool>> _initialBoard, _errorBoard, _correctBoard;
  int? _selectedRow, _selectedCol;

  Timer? _timer;
  Timer? _errorTimer;

  int _secondsElapsed = 0;
  int _level = 1;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _errorTimer?.cancel();
    super.dispose();
  }

  void _startNewGame() {
    final gen = SudokuGenerator();
    // Logic: Higher level = fewer filled squares (Max 64 empty)
    int emptySquares = 30 + ((_level - 1) * 3);
    if (emptySquares > 64) emptySquares = 64;

    final puzzle = gen.generate(difficulty: emptySquares);

    _solution = puzzle.solution;
    _board = puzzle.puzzle.map((r) => List<int>.from(r)).toList();
    _initialBoard = puzzle.puzzle.map((r) => r.map((c) => c != 0).toList()).toList();

    _resetErrorAndCorrectStatus();

    _secondsElapsed = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) { if(mounted) setState(() => _secondsElapsed++); });
  }

  void _resetErrorAndCorrectStatus() {
    if (!mounted) return;
    setState(() {
      _errorBoard = List.generate(9, (_) => List.generate(9, (_) => false));
      _correctBoard = List.generate(9, (_) => List.generate(9, (_) => false));
    });
  }

  // --- PAUSE DIALOG (MODERN UI) ---
  void _pauseGame() {
    _timer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('GAME PAUSED', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0277BD), letterSpacing: 1.0)),
                const SizedBox(height: 10),
                Text('Level $_level / 20', style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 30),

                _buildDialogButton("RESUME", Colors.orange, () {
                  Navigator.pop(context);
                  _timer = Timer.periodic(const Duration(seconds: 1), (t) { if(mounted) setState(() => _secondsElapsed++); });
                }),
                const SizedBox(height: 12),
                _buildDialogButton("RESTART LEVEL", Colors.teal, () {
                  Navigator.pop(context);
                  _startNewGame();
                }),
                const SizedBox(height: 12),
                _buildDialogButton("QUIT GAME", Colors.redAccent, () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Go back to Home
                }, isOutlined: true),
              ]
          ),
        ),
      ),
    );
  }

  Widget _buildDialogButton(String text, Color color, VoidCallback onPressed, {bool isOutlined = false}) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: isOutlined
          ? OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(side: BorderSide(color: color, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
        child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      )
          : ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), elevation: 2),
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _onCellTapped(int r, int c) {
    setState(() {
      _selectedRow = r;
      _selectedCol = c;
    });
    _errorTimer?.cancel();
    _resetErrorAndCorrectStatus();
  }

  void _onNumber(int n) {
    if (_selectedRow != null && _selectedCol != null && !_initialBoard[_selectedRow!][_selectedCol!]) {
      setState(() {
        _board[_selectedRow!][_selectedCol!] = n;
        _errorTimer?.cancel();
        _resetErrorAndCorrectStatus();
      });
    }
  }

  void _checkSolution() {
    bool hasError = false;
    List<List<bool>> tempError = List.generate(9, (_) => List.generate(9, (_) => false));
    List<List<bool>> tempCorrect = List.generate(9, (_) => List.generate(9, (_) => false));

    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        int val = _board[r][c];
        if (val == 0) continue;

        // Check Row & Column
        for (int i = 0; i < 9; i++) {
          if (i != c && _board[r][i] == val) { tempError[r][i] = true; tempError[r][c] = true; hasError = true; }
          if (i != r && _board[i][c] == val) { tempError[i][c] = true; tempError[r][c] = true; hasError = true; }
        }

        // Check 3x3 Subgrid
        int startRow = (r ~/ 3) * 3;
        int startCol = (c ~/ 3) * 3;
        for (int i = 0; i < 3; i++) {
          for (int j = 0; j < 3; j++) {
            int r2 = startRow + i;
            int c2 = startCol + j;
            if ((r2 != r || c2 != c) && _board[r2][c2] == val) {
              tempError[r2][c2] = true; tempError[r][c] = true; hasError = true;
            }
          }
        }

        if (_board[r][c] == _solution[r][c]) {
          tempCorrect[r][c] = true;
        }
      }
    }

    setState(() {
      _errorBoard = tempError;
      _correctBoard = tempCorrect;
    });

    _errorTimer?.cancel();
    _errorTimer = Timer(const Duration(seconds: 3), () {
      _resetErrorAndCorrectStatus();
    });

    bool isFull = !_board.any((r) => r.contains(0));
    if (!hasError && isFull) {
      _onWin();
    }
  }

  void _onWin() async {
    _timer?.cancel();
    _errorTimer?.cancel();

    final userRef = FirebaseFirestore.instance.collection('users').doc(widget.userUid);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      if (snap.exists) {
        final d = snap.data()!;
        int bonusXP = 100 + (_level * 10);
        tx.update(userRef, {'xp': (d['xp'] ?? 0) + bonusXP, 'rp': (d['rp'] ?? 0) + 25, 'winStreak': (d['winStreak'] ?? 0) + 1});
      }
    });

    if (mounted) {
      if (_level >= 20) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => CustomDialog(
            title: 'SUDOKU MASTER!',
            content: 'Congratulations! You have conquered all 20 levels!',
            buttonText: 'RESTART JOURNEY',
            icon: Icons.emoji_events,
            iconColor: Colors.amber,
            onPressed: () {
              Navigator.pop(context);
              setState(() { _level = 1; });
              _startNewGame();
            },
          ),
        );
      } else {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => CustomDialog(
            title: 'LEVEL $_level COMPLETE!',
            content: 'Excellent! Ready for the next challenge?',
            buttonText: 'NEXT LEVEL >>',
            icon: Icons.star_rounded,
            iconColor: Colors.amber,
            onPressed: () {
              Navigator.pop(context);
              setState(() { _level++; });
              _startNewGame();
            },
          ),
        );
      }
    }
  }

  // --- UI WIDGETS ---

  Widget _buildLevelBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.signal_cellular_alt_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            'LVL $_level',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBadge() {
    String timeStr = '${_secondsElapsed ~/ 60}:${(_secondsElapsed % 60).toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Text(
            timeStr,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BeachBackground(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 20,
          title: Align(alignment: Alignment.centerLeft, child: _buildLevelBadge()),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            _buildTimerBadge(),
            const SizedBox(width: 10),
            // Header button with Glass effect
            Container(
              margin: const EdgeInsets.only(right: 15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.pause_rounded, color: Colors.white),
                onPressed: _pauseGame,
              ),
            ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 20),

              // --- THE GRID ---
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.width,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85), // Glass Effect
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [BoxShadow(blurRadius: 20, color: Colors.black12, offset: Offset(0, 10))],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 9),
                              itemCount: 81,
                              itemBuilder: (ctx, i) {
                                int r = i ~/ 9, c = i % 9;
                                bool isSelected = _selectedRow == r && _selectedCol == c;

                                // Thinner borders
                                BorderSide borderSide = const BorderSide(color: Colors.black12, width: 0.5);
                                BorderSide thickBorderSide = const BorderSide(color: Colors.black54, width: 1.5);

                                return GestureDetector(
                                  onTap: () => _onCellTapped(r, c),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.cyan.withOpacity(0.15) : Colors.transparent,
                                      border: Border(
                                        top: (r % 3 == 0) ? thickBorderSide : borderSide,
                                        left: (c % 3 == 0) ? thickBorderSide : borderSide,
                                        right: (c == 8) ? thickBorderSide : borderSide,
                                        bottom: (r == 8) ? thickBorderSide : borderSide,
                                      ),
                                    ),
                                    child: Center(
                                        child: Text(
                                            _board[r][c] == 0 ? '' : _board[r][c].toString(),
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: _initialBoard[r][c] ? FontWeight.w900 : FontWeight.w600,
                                                color: _errorBoard[r][c]
                                                    ? Colors.red.shade700
                                                    : (_correctBoard[r][c] ? Colors.green.shade700 : (_initialBoard[r][c] ? Colors.black87 : Colors.blue.shade800))
                                            )
                                        )
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // --- CONTROLS ---
              SudokuControls(
                onNumberTapped: _onNumber,
                onClearTapped: () {
                  if(_selectedRow!=null && !_initialBoard[_selectedRow!][_selectedCol!]) {
                    setState(() {
                      _board[_selectedRow!][_selectedCol!] = 0;
                      _errorTimer?.cancel();
                      _resetErrorAndCorrectStatus();
                    });
                  }
                },
                onValidateTapped: _checkSolution,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SudokuControls extends StatelessWidget {
  final Function(int) onNumberTapped;
  final VoidCallback onClearTapped, onValidateTapped;
  const SudokuControls({super.key, required this.onNumberTapped, required this.onClearTapped, required this.onValidateTapped});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9), // Glass background
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          // Number Row
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(9, (i) => _buildNumBtn(i + 1))
          ),
          const SizedBox(height: 15),
          // Action Row
          Row(
            children: [
              Expanded(child: _buildActionBtn("CLEAR", Icons.backspace_outlined, Colors.redAccent, onClearTapped)),
              const SizedBox(width: 15),
              Expanded(child: _buildActionBtn("CHECK", Icons.check_circle_outline, const Color(0xFF009688), onValidateTapped)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumBtn(int num) {
    return InkWell(
      onTap: () => onNumberTapped(num),
      child: Container(
        width: 32,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 4, offset: const Offset(0,2))],
          border: Border.all(color: Colors.blue.withOpacity(0.2)),
        ),
        child: Center(
            child: Text(
                '$num',
                style: const TextStyle(color: Colors.blue, fontSize: 18, fontWeight: FontWeight.bold)
            )
        ),
      ),
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          ],
        ),
      ),
    );
  }
}
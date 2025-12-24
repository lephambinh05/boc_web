import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import '../logic/sudoku_logic.dart';
import '../widgets/common_widgets.dart';
import '../widgets/custom_dialog.dart';
import '../services/sound_manager.dart'; // Trỏ đúng vào thư mục services

class SudokuScreen extends StatefulWidget {
  final String playerName;
  final String userUid;
  final User? user;
  final Map<String, dynamic>? userData;

  const SudokuScreen({
    super.key,
    required this.playerName,
    required this.userUid,
    this.user,
    this.userData,
  });

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> with WidgetsBindingObserver {
  // Game State
  late List<List<int>> _board;
  late List<List<int>> _solution;
  late List<List<bool>> _initialBoard;
  late List<List<bool>> _errorBoard;
  late List<List<bool>> _correctBoard;
  
  int? _selectedRow;
  int? _selectedCol;
  
  Timer? _timer;
  int _secondsElapsed = 0;
  bool _isPlayingMusic = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Sync local state with SoundManager
    _isPlayingMusic = SoundManager().isMusicPlaying;
    _startNewGame();
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

  // --- LOGIC GAME ---
  void _startNewGame() {
    final generator = SudokuGenerator();
    final generatedPuzzle = generator.generate(difficulty: 40);

    _solution = generatedPuzzle.solution;
    final puzzle = generatedPuzzle.puzzle;

    _board = puzzle.map((row) => List<int>.from(row)).toList();
    _initialBoard = puzzle.map((row) => row.map((cell) => cell != 0).toList()).toList();
    
    _errorBoard = List.generate(9, (_) => List.generate(9, (_) => false));
    _correctBoard = List.generate(9, (_) => List.generate(9, (_) => false));
    
    _secondsElapsed = 0;
    _selectedRow = null;
    _selectedCol = null;
    
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

  void _onCellTapped(int row, int col) {
    SoundManager().playClickSound();
    setState(() {
      _selectedRow = row;
      _selectedCol = col;
    });
  }

  void _onNumberTapped(int number) {
    if (_selectedRow == null || _selectedCol == null) return;
    if (_initialBoard[_selectedRow!][_selectedCol!]) return;

    SoundManager().playClickSound();

    setState(() {
      _board[_selectedRow!][_selectedCol!] = number;
      _errorBoard[_selectedRow!][_selectedCol!] = false; 
      _updateErrors();
    });
    
    _checkForWin();
  }

  void _onClearTapped() {
    if (_selectedRow == null || _selectedCol == null) return;
    if (_initialBoard[_selectedRow!][_selectedCol!]) return;

    SoundManager().playClickSound();
    setState(() {
      _board[_selectedRow!][_selectedCol!] = 0;
      _errorBoard[_selectedRow!][_selectedCol!] = false;
      _updateErrors();
    });
  }

  void _updateErrors() {
    for(int r=0; r<9; r++) {
      for(int c=0; c<9; c++) {
        _errorBoard[r][c] = false;
      }
    }

    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final val = _board[r][c];
        if (val == 0) continue;

        for (int i = 0; i < 9; i++) {
          if (i != c && _board[r][i] == val) {
            _errorBoard[r][i] = true;
            _errorBoard[r][c] = true;
          }
        }
        for (int i = 0; i < 9; i++) {
          if (i != r && _board[i][c] == val) {
            _errorBoard[i][c] = true;
            _errorBoard[r][c] = true;
          }
        }
        int startRow = r - r % 3;
        int startCol = c - c % 3;
        for (int i = 0; i < 3; i++) {
          for (int j = 0; j < 3; j++) {
            int curR = startRow + i;
            int curC = startCol + j;
            if ((curR != r || curC != c) && _board[curR][curC] == val) {
              _errorBoard[curR][curC] = true;
              _errorBoard[r][c] = true;
            }
          }
        }
      }
    }
  }

  void _onValidateTapped() {
     SoundManager().playClickSound();
    setState(() {
       _updateErrors();
       for(int r=0; r<9; r++){
         for(int c=0; c<9; c++){
           if(!_initialBoard[r][c] && _board[r][c] != 0) {
             if(_board[r][c] == _solution[r][c]) {
               _correctBoard[r][c] = true;
             } else {
               _errorBoard[r][c] = true;
             }
           }
         }
       }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if(mounted) {
        setState(() {
          _correctBoard = List.generate(9, (_) => List.generate(9, (_) => false));
        });
      }
    });
  }

  void _checkForWin() {
    bool isFull = true;
    bool isCorrect = true;

    for(int r=0; r<9; r++){
      for(int c=0; c<9; c++){
        if(_board[r][c] == 0) {
          isFull = false;
          break;
        }
        if(_board[r][c] != _solution[r][c]) {
          isCorrect = false;
        }
      }
    }

    if (isFull && isCorrect) {
      _timer?.cancel();
      _saveScore(true);
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CustomDialog(
          title: 'CHIẾN THẮNG!',
          content: 'Chúc mừng ${widget.playerName}!\nBạn đã hoàn thành trong ${_formatTime(_secondsElapsed)}.',
          buttonText: 'CHƠI TIẾP',
          icon: Icons.emoji_events_rounded,
          iconColor: Colors.amber,
          onPressed: () {
            Navigator.of(context).pop();
            setState(() {
              _startNewGame();
            });
          },
        ),
      );
    }
  }

  Future<void> _saveScore(bool win) async {
    if(widget.userUid.isEmpty) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(widget.userUid);
    
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        
        if (!snapshot.exists) return;
        
        final data = snapshot.data() as Map<String, dynamic>;
        int currentXp = data['xp'] ?? 0;
        int currentRp = data['rp'] ?? 0;
        int currentStreak = data['winStreak'] ?? 0;

        transaction.update(userRef, {
          'xp': currentXp + (win ? 100 : 10),
          'rp': currentRp + (win ? 20 : 5),
          'winStreak': win ? currentStreak + 1 : 0,
          'lastUpdate': FieldValue.serverTimestamp(),
        });
      });
    } catch(e) {
      debugPrint("Lỗi save score: $e");
    }
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
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () {
              SoundManager().playClickSound();
              Navigator.pop(context);
            },
          ),
          title: Column(
            children: [
              Text(widget.playerName, style: const TextStyle(fontSize: 16, color: Colors.white70)),
              Text(_formatTime(_secondsElapsed), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(_isPlayingMusic ? Icons.music_note : Icons.music_off, color: Colors.white),
              onPressed: _toggleMusic,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 9),
                        itemCount: 81,
                        itemBuilder: (context, index) {
                          int row = index ~/ 9;
                          int col = index % 9;
                          
                          bool isInitial = _initialBoard[row][col];
                          bool isSelected = (row == _selectedRow && col == _selectedCol);
                          bool isError = _errorBoard[row][col];
                          bool isCorrect = _correctBoard[row][col];
                          
                          Color? bgColor = Colors.transparent;
                          if (isError) bgColor = Colors.red.withOpacity(0.3);
                          else if (isCorrect) bgColor = Colors.green.withOpacity(0.3);
                          else if (isSelected) bgColor = Colors.cyan.withOpacity(0.3);
                          else if (_selectedRow != null && _selectedCol != null && 
                                   (row == _selectedRow || col == _selectedCol)) {
                             bgColor = Colors.cyan.withOpacity(0.1);
                          }

                          double topW = (row % 3 == 0) ? 2.0 : 0.5;
                          double leftW = (col % 3 == 0) ? 2.0 : 0.5;
                          double rightW = (col == 8) ? 2.0 : 0.5;
                          double bottomW = (row == 8) ? 2.0 : 0.5;

                          return GestureDetector(
                            onTap: () => _onCellTapped(row, col),
                            child: Container(
                              decoration: BoxDecoration(
                                color: bgColor,
                                border: Border(
                                  top: BorderSide(color: Colors.black87, width: topW),
                                  left: BorderSide(color: Colors.black87, width: leftW),
                                  right: BorderSide(color: Colors.black87, width: rightW),
                                  bottom: BorderSide(color: Colors.black87, width: bottomW),
                                )
                              ),
                              child: Center(
                                child: Text(
                                  _board[row][col] == 0 ? '' : '${_board[row][col]}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: isInitial ? FontWeight.w900 : FontWeight.w500,
                                    color: isInitial ? Colors.black87 : Colors.blue.shade900,
                                  ),
                                ),
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
            Container(
              padding: const EdgeInsets.only(bottom: 30, left: 10, right: 10, top: 15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(9, (index) {
                      int num = index + 1;
                      return GestureDetector(
                        onTap: () => _onNumberTapped(num),
                        child: Container(
                          width: 36, height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.cyan.shade700, width: 1.5),
                            boxShadow: [
                               BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 3, offset: const Offset(0, 3))
                            ]
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$num',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.cyan.shade800),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _onClearTapped,
                        icon: const Icon(Icons.backspace_outlined, size: 22),
                        label: const Text("XÓA", style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                          elevation: 4,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _onValidateTapped,
                        icon: const Icon(Icons.check_circle_outline, size: 22),
                        label: const Text("KIỂM TRA", style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                            elevation: 4,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

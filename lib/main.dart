import 'package:flutter/material.dart';
import 'dart:async';

// Firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// WebView import
import 'package:webview_flutter/webview_flutter.dart';
// Import cho Android WebView (tùy chọn)
import 'package:webview_flutter_android/webview_flutter_android.dart';
// Import cho iOS WebView (tùy chọn)
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'custom_dialog.dart';
import 'sudoku_logic.dart';

// Hàm main được cập nhật để khởi tạo Firebase
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sudoku Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey.shade900, // Màu hạt chính là xám đậm
          brightness: Brightness.light,
        ).copyWith(surface: Colors.grey.shade100),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey.shade100, // Nền trắng xám
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey.shade900, // AppBar màu đen
          foregroundColor: Colors.white, // Chữ trắng
          elevation: 8,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: const EdgeInsets.all(16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            backgroundColor: Colors.grey.shade700, // Nút xám đậm
            foregroundColor: Colors.white,
            elevation: 5,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade800, // TextButton màu xám đậm
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade400, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.shade700, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.grey.shade700),
          floatingLabelStyle: TextStyle(color: Colors.grey.shade900),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}

class GameScore {
  final String playerName;
  final int score;
  GameScore({required this.playerName, required this.score});

  factory GameScore.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return GameScore(
      playerName: data['playerName'] ?? 'Anonymous',
      score: data['score'] ?? 0,
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = true; // Bắt đầu ở trạng thái loading

  @override
  void initState() {
    super.initState();
    _checkWebViewStatus();
  }

  Future<void> _checkWebViewStatus() async {
    try {
      final settingsDoc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('settings_admin')
          .get();

      if (settingsDoc.exists && settingsDoc.data()?['webView'] == 'on') {
        final webDataDoc = await FirebaseFirestore.instance
            .collection('webdata')
            .doc('webdata')
            .get();

        if (webDataDoc.exists) {
          final data = webDataDoc.data() as Map<String, dynamic>;
          final url = data['defaultWebViewUrl'];
          final title = data['gameTitle'];
          final keywords = data['keywords'];
          final logoAsset = data['logo'];

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => WebViewScreen(
                  title: title ?? 'Web Game',
                  url: url ?? 'https://google.com',
                  logoAsset: logoAsset,
                  keywords: keywords,
                ),
              ),
            );
          }
        } else {
          // Nếu không tìm thấy data webview, vẫn ở lại màn hình chính
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        // Nếu webview off hoặc không tồn tại, ở lại màn hình chính
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // Bất kỳ lỗi nào cũng sẽ ở lại màn hình chính
      debugPrint("Error checking webview status: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sudoku Game'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            elevation: 10,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.grid_on_sharp, size: 80, color: Colors.grey.shade800),
                  const SizedBox(height: 24),
                  const Text(
                    'Chào mừng đến với Sudoku!',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Rèn luyện trí não với trò chơi cổ điển!',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nhập tên của bạn',
                      prefixIcon: Icon(Icons.person, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 60),
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      if (_nameController.text.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SudokuScreen(playerName: _nameController.text),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Vui lòng nhập tên để bắt đầu!'),
                            backgroundColor: Colors.red.shade400,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    },
                    child: const Text('Bắt đầu chơi'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RankingScreen()),
                      );
                    },
                    child: const Text('Xem Bảng Xếp Hạng'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class SudokuScreen extends StatefulWidget {
  final String playerName;
  const SudokuScreen({super.key, required this.playerName});
  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  late List<List<int>> _board;
  late List<List<int>> _solution;
  late List<List<bool>> _initialBoard;
  late List<List<bool>> _errorBoard;
  late List<List<bool>> _correctBoard;
  int? _selectedRow;
  int? _selectedCol;
  Timer? _timer;
  int _secondsElapsed = 0;

  late final Widget sudokuControls;

  @override
  void initState() {
    super.initState();
    _startNewGame();

    sudokuControls = SudokuControls(
      onNumberTapped: _onNumberTapped,
      onClearTapped: _onClearTapped,
      onValidateTapped: _validateBoard,
    );
  }

  void _startNewGame() {
    final generator = SudokuGenerator();
    final generatedPuzzle = generator.generate(difficulty: 45);

    _solution = generatedPuzzle.solution;
    final puzzle = generatedPuzzle.puzzle;

    _board = puzzle.map((row) => List<int>.from(row)).toList();
    _initialBoard = puzzle.map((row) => row.map((cell) => cell != 0).toList()).toList();
    _errorBoard = List.generate(9, (_) => List.generate(9, (_) => false));
    _correctBoard = List.generate(9, (_) => List.generate(9, (_) => false));
    _secondsElapsed = 0;
    _selectedRow = null;
    _selectedCol = null;
    startTimer();
  }

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _addScoreToFirebase(String playerName, int score) async {
    try {
      await FirebaseFirestore.instance.collection('rankings').add({
        'playerName': playerName,
        'score': score,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error saving score: $e");
    }
  }

  void _onCellTapped(int row, int col) {
    if (!_initialBoard[row][col]) {
      setState(() {
        _selectedRow = row;
        _selectedCol = col;
      });
    }
  }

  void _onNumberTapped(int number) {
    if (_selectedRow != null && _selectedCol != null) {
      setState(() {
        _board[_selectedRow!][_selectedCol!] = number;
        _correctBoard = List.generate(9, (_) => List.generate(9, (_) => false));
        _updateErrors();
      });
    }
  }

  void _onClearTapped() {
    if (_selectedRow != null && _selectedCol != null) {
      setState(() {
        _board[_selectedRow!][_selectedCol!] = 0;
        _correctBoard = List.generate(9, (_) => List.generate(9, (_) => false));
        _updateErrors();
      });
    }
  }

  void _updateErrors() {
    _errorBoard = List.generate(9, (_) => List.generate(9, (_) => false));
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final val = _board[r][c];
        if (val == 0) continue;
        bool hasConflict = false;
        for (int i = 0; i < 9; i++) {
          if (i != c && _board[r][i] == val) {
            hasConflict = true;
            _errorBoard[r][i] = true;
          }
        }
        for (int i = 0; i < 9; i++) {
          if (i != r && _board[i][c] == val) {
            hasConflict = true;
            _errorBoard[i][c] = true;
          }
        }
        int startRow = r - r % 3, startCol = c - c % 3;
        for (int i = 0; i < 3; i++) {
          for (int j = 0; j < 3; j++) {
            if ((startRow + i) != r &&
                (startCol + j) != c &&
                _board[startRow + i][startCol + j] == val) {
              hasConflict = true;
              _errorBoard[startRow + i][startCol + j] = true;
            }
          }
        }
        if (hasConflict) _errorBoard[r][c] = true;
      }
    }
    _checkForWinCondition();
  }

  void _validateBoard() {
    _updateErrors();
    final newCorrectBoard =
        List.generate(9, (_) => List.generate(9, (_) => false));
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (!_initialBoard[r][c] &&
            _board[r][c] != 0 &&
            !_errorBoard[r][c]) {
          newCorrectBoard[r][c] = true;
        }
      }
    }
    setState(() => _correctBoard = newCorrectBoard);
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: 'Kiểm tra hoàn tất',
        content: 'Các nước đi đúng đã được tô màu xanh.',
        buttonText: 'OK',
        onPressed: () => Navigator.of(context).pop(),
        icon: Icons.check_circle_outline,
        iconColor: Colors.green,
      ),
    );
  }

  void _checkForWinCondition() {
    bool isBoardFull = !_board.any((row) => row.contains(0));
    bool hasErrors = _errorBoard.any((row) => row.contains(true));
    if (isBoardFull && !hasErrors) {
      _timer?.cancel();
      final score = (3600 - _secondsElapsed).clamp(0, 3600);
      _addScoreToFirebase(widget.playerName, score);
      final message = '''Chúc mừng! Bạn đã giải đúng!
Điểm của bạn: $score''';

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CustomDialog(
          title: 'Hoàn thành!',
          content: message,
          buttonText: 'Tuyệt vời!',
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
          icon: Icons.emoji_events,
          iconColor: Colors.amber,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sudoku - ${widget.playerName}'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Center(
              child: Text(
                '${(_secondsElapsed ~/ 60).toString().padLeft(2, '0')}:${(_secondsElapsed % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 9,
                          mainAxisSpacing: 0,
                          crossAxisSpacing: 0,
                        ),
                        itemCount: 81,
                        itemBuilder: (context, index) {
                          int row = index ~/ 9, col = index % 9;
                          bool isSelected = _selectedRow == row && _selectedCol == col;
                          bool isInitial = _initialBoard[row][col];
                          bool isError = _errorBoard[row][col];
                          bool isCorrect = _correctBoard[row][col];
                          bool isSameArea = (_selectedRow != null && _selectedCol != null) &&
                              ((row == _selectedRow || col == _selectedCol) ||
                                  (row ~/ 3 == _selectedRow! ~/ 3 && col ~/ 3 == _selectedCol! ~/ 3));

                          Color? cellColor;
                          if (isError) {
                            cellColor = Colors.red.shade100;
                          } else if (isCorrect) {
                            cellColor = Colors.green.shade100;
                          } else if (isSelected) {
                            cellColor = Colors.grey.shade200;
                          } else if (isSameArea) {
                            cellColor = Colors.grey.shade50;
                          } else {
                            cellColor = Colors.white;
                          }

                          final defaultBorderColor = Colors.black;
                          final thinBorderWidth = 1.0;
                          final thickBorderWidth = 2.5;

                          return GestureDetector(
                            onTap: () => _onCellTapped(row, col),
                            child: Container(
                              decoration: BoxDecoration(
                                color: cellColor,
                                border: Border(
                                  top: BorderSide(
                                    width: row % 3 == 0 ? thickBorderWidth : thinBorderWidth,
                                    color: defaultBorderColor,
                                  ),
                                  left: BorderSide(
                                    width: col % 3 == 0 ? thickBorderWidth : thinBorderWidth,
                                    color: defaultBorderColor,
                                  ),
                                  right: BorderSide(
                                    width: col == 8 ? thickBorderWidth : 0,
                                    color: defaultBorderColor,
                                  ),
                                  bottom: BorderSide(
                                    width: row == 8 ? thickBorderWidth : 0,
                                    color: defaultBorderColor,
                                  ),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _board[row][col] == 0 ? '' : _board[row][col].toString(),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: isInitial ? FontWeight.bold : FontWeight.w600,
                                    color: isError
                                        ? Colors.red.shade800
                                        : (isInitial
                                            ? Colors.black87
                                            : Colors.grey.shade800),
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
            sudokuControls,
          ],
        ),
      ),
    );
  }
}

class SudokuControls extends StatelessWidget {
  final ValueChanged<int> onNumberTapped;
  final VoidCallback onClearTapped;
  final VoidCallback onValidateTapped;

  const SudokuControls({
    super.key,
    required this.onNumberTapped,
    required this.onClearTapped,
    required this.onValidateTapped,
  });

  Widget _buildNumberButton(int number) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: () => onNumberTapped(number),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            splashFactory: NoSplash.splashFactory,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: Colors.grey.shade700, // Nút số xám
            foregroundColor: Colors.white,
            elevation: 4,
          ),
          child: Text(
            '$number',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton(1),
              _buildNumberButton(2),
              _buildNumberButton(3),
              _buildNumberButton(4),
              _buildNumberButton(5),
              _buildNumberButton(6),
              _buildNumberButton(7),
              _buildNumberButton(8),
              _buildNumberButton(9),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onClearTapped,
                  icon: const Icon(Icons.clear_all, size: 24),
                  label: const Text('Xóa'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade400, // Xám hổ phách nhạt
                      foregroundColor: Colors.white,
                      splashFactory: NoSplash.splashFactory,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onValidateTapped,
                  icon: const Icon(Icons.check_circle_outline, size: 24),
                  label: const Text('Kiểm tra'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade400, // Xám xanh lá nhạt
                      foregroundColor: Colors.white,
                      splashFactory: NoSplash.splashFactory,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng Xếp Hạng'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rankings')
            .orderBy('score', descending: true)
            .limit(20)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(
                'Đã xảy ra lỗi khi tải dữ liệu: ${snapshot.error}',
                style: TextStyle(color: Colors.red.shade700, fontSize: 16),
                textAlign: TextAlign.center,
            ));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có ai trên bảng xếp hạng.'));
          }

          final rankings = snapshot.data!.docs
              .map((doc) => GameScore.fromFirestore(doc))
              .toList();

          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: rankings.length,
            itemBuilder: (context, index) {
              final score = rankings[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 4,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade700, // Avatar xám đậm
                    radius: 24,
                    child: Text(
                      '#${index + 1}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                    ),
                  ),
                  title: Text(score.playerName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey)), // Tên xám
                  trailing: Text(
                    '${score.score} điểm',
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade800, // Điểm xám đậm
                        fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 10),
          );
        },
      ),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  final String title;
  final String url;
  final String? logoAsset;
  final String? keywords;

  const WebViewScreen({
    super.key,
    required this.title,
    required this.url,
    this.logoAsset,
    this.keywords,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView is loading (progress: $progress%)');
          },
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Web resource error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('allowing navigation to ${request.url}');
            return NavigationDecision.navigate;
          },
          onHttpError: (HttpResponseError error) {
            debugPrint('HTTP error: ${error.response}');
          },
        ),
      )
      ..addJavaScriptChannel(
        'Toaster',
        onMessageReceived: (JavaScriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        },
      )
      ..loadRequest(Uri.parse(widget.url));

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.logoAsset != null && widget.logoAsset!.isNotEmpty) ...[
              Image.asset(widget.logoAsset!, height: 30),
              const SizedBox(height: 4),
            ],
            Text(widget.title, style: const TextStyle(fontSize: 18)),
            if (widget.keywords != null) ...[
              Text(
                widget.keywords!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
            ],
          ],
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

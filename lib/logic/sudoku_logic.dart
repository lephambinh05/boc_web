import 'dart:math';

// Lớp để chứa cặp puzzle và solution, được chuyển từ main.dart qua
class SudokuPuzzle {
  final List<List<int>> puzzle;
  final List<List<int>> solution;

  SudokuPuzzle({required this.puzzle, required this.solution});
}

class SudokuGenerator {
  List<List<int>> board = List.generate(9, (_) => List.generate(9, (_) => 0));
  final int _size = 9;
  final int _boxSize = 3;

  /// Phương thức công khai để tạo một puzzle mới
  /// [difficulty] là số ô trống sẽ được tạo ra. Càng cao càng khó.
  SudokuPuzzle generate({int difficulty = 45}) {
    // 1. Dọn dẹp bàn cờ
    board = List.generate(9, (_) => List.generate(9, (_) => 0));

    // 2. Điền bàn cờ với một lời giải hoàn chỉnh
    _fillBoard(board);

    // 3. Sao chép lại lời giải này để lưu trữ
    final solution = board.map((row) => List<int>.from(row)).toList();

    // 4. Đục lỗ trên bàn cờ để tạo thành câu đố
    _pokeHoles(board, difficulty);
    final puzzle = board.map((row) => List<int>.from(row)).toList();

    return SudokuPuzzle(puzzle: puzzle, solution: solution);
  }

  // Điền vào bàn cờ bằng thuật toán backtracking
  bool _fillBoard(List<List<int>> currentBoard) {
    for (int r = 0; r < _size; r++) {
      for (int c = 0; c < _size; c++) {
        if (currentBoard[r][c] == 0) {
          final numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9]..shuffle();
          for (int num in numbers) {
            if (_isValid(currentBoard, r, c, num)) {
              currentBoard[r][c] = num;
              if (_fillBoard(currentBoard)) {
                return true;
              }
              currentBoard[r][c] = 0; // backtrack
            }
          }
          return false;
        }
      }
    }
    return true; // Bàn cờ đã được điền đầy
  }
  
  // Tạo câu đố bằng cách xóa các con số
  void _pokeHoles(List<List<int>> currentBoard, int holes) {
    final random = Random();
    int removed = 0;
    while (removed < holes) {
      int r = random.nextInt(_size);
      int c = random.nextInt(_size);
      if (currentBoard[r][c] != 0) {
        currentBoard[r][c] = 0;
        removed++;
      }
    }
  }

  // Kiểm tra xem một số có hợp lệ tại một vị trí nhất định không
  bool _isValid(List<List<int>> board, int row, int col, int num) {
    // Kiểm tra hàng
    for (int i = 0; i < _size; i++) {
      if (board[row][i] == num) {
        return false;
      }
    }

    // Kiểm tra cột
    for (int i = 0; i < _size; i++) {
      if (board[i][col] == num) {
        return false;
      }
    }

    // Kiểm tra ô 3x3
    int startRow = row - row % _boxSize;
    int startCol = col - col % _boxSize;
    for (int i = 0; i < _boxSize; i++) {
      for (int j = 0; j < _boxSize; j++) {
        if (board[i + startRow][j + startCol] == num) {
          return false;
        }
      }
    }
    return true;
  }
}

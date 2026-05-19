import 'dart:math';

class PuzzleLogic {
  final int size; 
  late List<int> tiles;

  PuzzleLogic({this.size = 3}) {
    _initBoard();
  }

  void _initBoard() {
    // Tạo danh sách 1, 2, 3... (size*size - 1) và cuối cùng là 0
    tiles = List.generate(size * size - 1, (index) => index + 1);
    tiles.add(0); // Ô trống ở cuối
  }

  void generate() {
    _initBoard();
    Random random = Random();
    int shuffleMoves = size * size * 20; // Tăng số bước xáo trộn theo kích thước
    
    int emptyIndex = tiles.indexOf(0);

    for (int i = 0; i < shuffleMoves; i++) {
      List<int> neighbors = _getNeighbors(emptyIndex);
      int moveIndex = neighbors[random.nextInt(neighbors.length)];
      
      int temp = tiles[emptyIndex];
      tiles[emptyIndex] = tiles[moveIndex];
      tiles[moveIndex] = temp;
      
      emptyIndex = moveIndex;
    }
  }

  List<int> _getNeighbors(int index) {
    List<int> neighbors = [];
    int row = index ~/ size;
    int col = index % size;

    if (row > 0) neighbors.add(index - size); 
    if (row < size - 1) neighbors.add(index + size); 
    if (col > 0) neighbors.add(index - 1); 
    if (col < size - 1) neighbors.add(index + 1); 

    return neighbors;
  }

  bool moveTile(int index) {
    int emptyIndex = tiles.indexOf(0);
    List<int> neighbors = _getNeighbors(emptyIndex);

    if (neighbors.contains(index)) {
      tiles[emptyIndex] = tiles[index];
      tiles[index] = 0;
      return true;
    }
    return false;
  }

  bool isSolved() {
    // Kiểm tra 1, 2, 3...
    for (int i = 0; i < tiles.length - 1; i++) {
      if (tiles[i] != i + 1) return false;
    }
    // Ô cuối cùng phải là 0
    return tiles.last == 0;
  }
}

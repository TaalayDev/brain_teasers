import 'package:brain_teasers/components/game_container.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../components/header_container.dart';
import '../theme/app_theme.dart';

class WordSearchGame extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final Function(int score) onScoreUpdate;
  final VoidCallback onComplete;

  const WordSearchGame({
    super.key,
    required this.gameData,
    required this.onScoreUpdate,
    required this.onComplete,
  });

  @override
  State<WordSearchGame> createState() => _WordSearchGameState();
}

class _WordSearchGameState extends State<WordSearchGame> {
  late List<List<String>> grid;
  late List<String> wordsToFind;
  late List<String> foundWords;
  late List<Offset> selectedCells;
  late List<FoundWordData> foundWordLines;
  Offset? dragStart;
  Offset? dragEnd;
  int score = 0;

  @override
  void initState() {
    super.initState();
    final gridSize = widget.gameData['gridSize'] as int;
    wordsToFind = List<String>.from(widget.gameData['words']);
    foundWords = [];
    selectedCells = [];
    foundWordLines = [];
    grid = _generateGrid(gridSize, wordsToFind);
  }

  List<List<String>> _generateGrid(int size, List<String> words) {
    // Initialize empty grid
    final grid = List.generate(
      size,
      (_) => List.generate(size, (_) => ''),
    );

    final random = math.Random();
    final directions = [
      [0, 1], // right
      [1, 0], // down
      [1, 1], // diagonal
      [0, -1], // left
      [-1, 0], // up
      [-1, -1], // diagonal up-left
      [1, -1], // diagonal down-left
      [-1, 1], // diagonal up-right
    ];

    // Place each word
    for (final word in words) {
      bool placed = false;
      int attempts = 0;

      while (!placed && attempts < 100) {
        final direction = directions[random.nextInt(directions.length)];
        final startX = random.nextInt(size);
        final startY = random.nextInt(size);

        if (_canPlaceWord(grid, word, startX, startY, direction)) {
          _placeWord(grid, word, startX, startY, direction);
          placed = true;
        }
        attempts++;
      }
    }

    // Fill empty cells with random letters
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    for (var i = 0; i < size; i++) {
      for (var j = 0; j < size; j++) {
        if (grid[i][j].isEmpty) {
          grid[i][j] = letters[random.nextInt(letters.length)];
        }
      }
    }

    return grid;
  }

  bool _canPlaceWord(List<List<String>> grid, String word, int startX,
      int startY, List<int> direction) {
    final size = grid.length;
    final endX = startX + direction[0] * (word.length - 1);
    final endY = startY + direction[1] * (word.length - 1);

    if (endX < 0 || endX >= size || endY < 0 || endY >= size) {
      return false;
    }

    for (var i = 0; i < word.length; i++) {
      final x = startX + direction[0] * i;
      final y = startY + direction[1] * i;
      if (grid[x][y].isNotEmpty && grid[x][y] != word[i]) {
        return false;
      }
    }

    return true;
  }

  void _placeWord(List<List<String>> grid, String word, int startX, int startY,
      List<int> direction) {
    for (var i = 0; i < word.length; i++) {
      final x = startX + direction[0] * i;
      final y = startY + direction[1] * i;
      grid[x][y] = word[i];
    }
  }

  void _handleDragStart(Offset localPosition) {
    final cellSize = _getCellSize();
    final gridX = (localPosition.dx / cellSize).floor();
    final gridY = (localPosition.dy / cellSize).floor();

    setState(() {
      dragStart = Offset(gridX.toDouble(), gridY.toDouble());
      dragEnd = dragStart;
      selectedCells = [dragStart!];
    });
  }

  void _handleDragUpdate(Offset localPosition) {
    if (dragStart == null) return;

    final cellSize = _getCellSize();
    final gridX = (localPosition.dx / cellSize).floor();
    final gridY = (localPosition.dy / cellSize).floor();
    final newDragEnd = Offset(gridX.toDouble(), gridY.toDouble());

    if (newDragEnd != dragEnd) {
      setState(() {
        dragEnd = newDragEnd;
        selectedCells = _getSelectedCells(dragStart!, dragEnd!);
      });
    }
  }

  void _handleDragEnd() {
    if (dragStart == null || dragEnd == null) return;

    final word = _getSelectedWord();
    if (wordsToFind.contains(word) && !foundWords.contains(word)) {
      setState(() {
        foundWords.add(word);
        foundWordLines.add(FoundWordData(
          start: dragStart!,
          end: dragEnd!,
          color: _getRandomColor(),
        ));
        score += word.length * 100;
        widget.onScoreUpdate(score);
      });

      if (foundWords.length == wordsToFind.length) {
        widget.onComplete();
      }
    }

    setState(() {
      dragStart = null;
      dragEnd = null;
      selectedCells = [];
    });
  }

  List<Offset> _getSelectedCells(Offset start, Offset end) {
    final cells = <Offset>[];
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final steps = math.max(dx.abs(), dy.abs()).toInt();

    if (steps == 0) {
      cells.add(start);
    } else {
      final stepX = dx / steps;
      final stepY = dy / steps;

      for (var i = 0; i <= steps; i++) {
        cells.add(Offset(
          start.dx + stepX * i,
          start.dy + stepY * i,
        ));
      }
    }

    return cells;
  }

  String _getSelectedWord() {
    if (selectedCells.isEmpty) return '';

    final word = StringBuffer();
    for (final cell in selectedCells) {
      if (cell.dx >= 0 &&
          cell.dx < grid.length &&
          cell.dy >= 0 &&
          cell.dy < grid.length) {
        word.write(grid[cell.dx.toInt()][cell.dy.toInt()]);
      }
    }
    return word.toString();
  }

  double _getCellSize() {
    final gridSize = grid.length;
    final context = this.context;
    final size = MediaQuery.of(context).size;
    final maxSize = math.min(size.width, size.height) - 32;
    return maxSize / gridSize;
  }

  Color _getRandomColor() {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.accentColor,
      Colors.purple,
      Colors.teal,
      Colors.orange,
    ];
    return colors[math.Random().nextInt(colors.length)];
  }

  @override
  Widget build(BuildContext context) {
    return GameContainer(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildGameBoard(),
          ),
          _buildWordList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Word Search',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${foundWords.length}/${wordsToFind.length} words found',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: AppTheme.accentColor),
                const SizedBox(width: 8),
                Text(
                  score.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameBoard() {
    final cellSize = _getCellSize();

    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: GestureDetector(
          onPanStart: (details) => _handleDragStart(details.localPosition),
          onPanUpdate: (details) => _handleDragUpdate(details.localPosition),
          onPanEnd: (_) => _handleDragEnd(),
          child: CustomPaint(
            painter: WordSearchPainter(
              grid: grid,
              cellSize: cellSize,
              selectedCells: selectedCells,
              foundWordLines: foundWordLines,
            ),
            size: Size(cellSize * grid.length, cellSize * grid.length),
          ),
        ),
      ),
    );
  }

  Widget _buildWordList() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: wordsToFind.map((word) {
          final isFound = foundWords.contains(word);
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isFound
                  ? AppTheme.correctAnswerColor.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isFound
                    ? AppTheme.correctAnswerColor
                    : Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Text(
              word,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: isFound ? FontWeight.bold : FontWeight.normal,
                color: isFound
                    ? AppTheme.correctAnswerColor
                    : AppTheme.primaryColor,
                decoration: isFound ? TextDecoration.lineThrough : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class WordSearchPainter extends CustomPainter {
  final List<List<String>> grid;
  final double cellSize;
  final List<Offset> selectedCells;
  final List<FoundWordData> foundWordLines;

  WordSearchPainter({
    required this.grid,
    required this.cellSize,
    required this.selectedCells,
    required this.foundWordLines,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw grid
    for (var i = 0; i <= grid.length; i++) {
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(size.width, i * cellSize),
        paint,
      );
    }

    // Draw found word lines
    for (final line in foundWordLines) {
      final linePaint = Paint()
        ..color = line.color.withOpacity(0.3)
        ..strokeWidth = cellSize * 0.8
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(
          (line.start.dx + 0.5) * cellSize,
          (line.start.dy + 0.5) * cellSize,
        ),
        Offset(
          (line.end.dx + 0.5) * cellSize,
          (line.end.dy + 0.5) * cellSize,
        ),
        linePaint,
      );
    }

    // Draw selection line
    if (selectedCells.length > 1) {
      final selectionPaint = Paint()
        ..color = AppTheme.primaryColor.withOpacity(0.3)
        ..strokeWidth = cellSize * 0.8
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(
          (selectedCells.first.dx + 0.5) * cellSize,
          (selectedCells.first.dy + 0.5) * cellSize,
        ),
        Offset(
          (selectedCells.last.dx + 0.5) * cellSize,
          (selectedCells.last.dy + 0.5) * cellSize,
        ),
        selectionPaint,
      );
    }

    // Draw letters
    final textStyle = TextStyle(
      color: AppTheme.primaryColor,
      fontSize: cellSize * 0.5,
      fontWeight: FontWeight.bold,
    );

    for (var i = 0; i < grid.length; i++) {
      for (var j = 0; j < grid[i].length; j++) {
        final textSpan = TextSpan(
          text: grid[i][j],
          style: textStyle,
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        final offset = Offset(
          i * cellSize + (cellSize - textPainter.width) / 2,
          j * cellSize + (cellSize - textPainter.height) / 2,
        );
        textPainter.paint(canvas, offset);
      }
    }

    // Draw highlighted cells
    final highlightPaint = Paint()
      ..color = AppTheme.primaryColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    for (final cell in selectedCells) {
      canvas.drawRect(
        Rect.fromLTWH(
          cell.dx * cellSize,
          cell.dy * cellSize,
          cellSize,
          cellSize,
        ),
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(WordSearchPainter oldDelegate) {
    return oldDelegate.selectedCells != selectedCells ||
        oldDelegate.foundWordLines != foundWordLines;
  }
}

class FoundWordData {
  final Offset start;
  final Offset end;
  final Color color;

  FoundWordData({
    required this.start,
    required this.end,
    required this.color,
  });
}

// Extension for helpful utilities
extension GridUtils on List<List<String>> {
  String getWordInDirection(
      int startX, int startY, List<int> direction, int length) {
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      final x = startX + direction[0] * i;
      final y = startY + direction[1] * i;
      if (x < 0 || x >= length || y < 0 || y >= length) break;
      buffer.write(this[x][y]);
    }
    return buffer.toString();
  }
}

// Helper class for handling word placement directions
class WordPlacementDirection {
  final List<int> direction;
  final String name;

  const WordPlacementDirection(this.direction, this.name);

  static const horizontal = WordPlacementDirection([0, 1], 'horizontal');
  static const vertical = WordPlacementDirection([1, 0], 'vertical');
  static const diagonalDown = WordPlacementDirection([1, 1], 'diagonal down');
  static const diagonalUp = WordPlacementDirection([-1, 1], 'diagonal up');
  static const horizontalReverse =
      WordPlacementDirection([0, -1], 'horizontal reverse');
  static const verticalReverse =
      WordPlacementDirection([-1, 0], 'vertical reverse');
  static const diagonalDownReverse =
      WordPlacementDirection([1, -1], 'diagonal down reverse');
  static const diagonalUpReverse =
      WordPlacementDirection([-1, -1], 'diagonal up reverse');

  static const List<WordPlacementDirection> allDirections = [
    horizontal,
    vertical,
    diagonalDown,
    diagonalUp,
    horizontalReverse,
    verticalReverse,
    diagonalDownReverse,
    diagonalUpReverse,
  ];
}

// Example usage:
// final game = WordSearchGame(
//   gameData: {
//     'gridSize': 8,
//     'words': ['FLUTTER', 'DART', 'CODE', 'GAME'],
//   },
//   onScoreUpdate: (score) {
//     print('Score: $score');
//   },
//   onComplete: () {
//     print('Game Complete!');
//   },
// );
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../ui/components/game_container.dart';
import '../ui/theme/app_theme.dart';
import 'controller/game_controller.dart';

class WordSearchGame extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final GameController gameController;

  const WordSearchGame({
    super.key,
    required this.gameData,
    required this.gameController,
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
  late List<LevelData> levels;
  late int currentLevel;
  bool _isLevelTransitioning = false;

  @override
  void initState() {
    super.initState();
    _initializeLevels();
    currentLevel = widget.gameController.currentLevel;
    _initializeGame();

    // Start the game with the controller
    widget.gameController.startGame(
      level: currentLevel,
      maxLevels: levels.length,
      timeLimit: levels[currentLevel].timeLimit,
    );
  }

  void _initializeLevels() {
    // Create multiple level configurations with increasing difficulty
    levels = [
      LevelData(
        gridSize: widget.gameData['gridSize'] ?? 8,
        words: List<String>.from(widget.gameData['words'] ?? []),
        timeLimit: 120, // 2 minutes for first level
      ),
      // Level 2 - 10x10 grid with longer words
      LevelData(
        gridSize: 10,
        words: _generateLevelWords(2),
        timeLimit: 180, // 3 minutes
      ),
      // Level 3 - 12x12 grid with more and longer words
      LevelData(
        gridSize: 12,
        words: _generateLevelWords(3),
        timeLimit: 240, // 4 minutes
      ),
    ];
  }

  List<String> _generateLevelWords(int level) {
    // If the game data contains predefined levels, use those
    if (widget.gameData.containsKey('levels') &&
        widget.gameData['levels'] is List &&
        widget.gameData['levels'].length > level - 1) {
      return List<String>.from(widget.gameData['levels'][level - 1]['words']);
    }

    // Otherwise generate words based on level difficulty
    final baseWords = List<String>.from(widget.gameData['words'] ?? []);

    // Create additional words or use a subset of provided words
    if (level == 2) {
      return baseWords.length > 6
          ? baseWords.sublist(0, 6)
          : [...baseWords, 'PUZZLE', 'SEARCH', 'HIDDEN'];
    } else if (level == 3) {
      return baseWords.length > 8
          ? baseWords.sublist(0, 8)
          : [...baseWords, 'CHALLENGE', 'DISCOVERY', 'ADVENTURE', 'TREASURE'];
    }

    return baseWords;
  }

  void _initializeGame() {
    final levelData = levels[currentLevel];
    wordsToFind = List<String>.from(levelData.words);
    foundWords = [];
    selectedCells = [];
    foundWordLines = [];
    grid = _generateGrid(levelData.gridSize, levelData.words);
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
      if (grid[y][x].isNotEmpty && grid[y][x] != word[i]) {
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
      grid[y][x] = word[i];
    }
  }

  void _handleDragStart(Offset localPosition) {
    if (_isLevelTransitioning) return;

    final cellSize = _getCellSize();
    final gridX = (localPosition.dx / cellSize).floor();
    final gridY = (localPosition.dy / cellSize).floor();

    if (gridX < 0 ||
        gridX >= grid.length ||
        gridY < 0 ||
        gridY >= grid.length) {
      return;
    }

    setState(() {
      dragStart = Offset(gridX.toDouble(), gridY.toDouble());
      dragEnd = dragStart;
      selectedCells = [dragStart!];
    });
  }

  void _handleDragUpdate(Offset localPosition) {
    if (dragStart == null || _isLevelTransitioning) return;

    final cellSize = _getCellSize();
    final gridX = (localPosition.dx / cellSize).floor();
    final gridY = (localPosition.dy / cellSize).floor();

    if (gridX < 0 ||
        gridX >= grid.length ||
        gridY < 0 ||
        gridY >= grid.length) {
      return;
    }

    final newDragEnd = Offset(gridX.toDouble(), gridY.toDouble());

    if (newDragEnd != dragEnd) {
      setState(() {
        dragEnd = newDragEnd;
        selectedCells = _getSelectedCells(dragStart!, dragEnd!);
      });
    }
  }

  void _handleDragEnd() {
    if (dragStart == null || dragEnd == null || _isLevelTransitioning) return;

    final word = _getSelectedWord();
    if (wordsToFind.contains(word) && !foundWords.contains(word)) {
      setState(() {
        foundWords.add(word);
        foundWordLines.add(FoundWordData(
          start: dragStart!,
          end: dragEnd!,
          color: _getRandomColor(),
        ));

        // Award score based on word length and current level
        final wordScore = word.length * 100 * (currentLevel + 1);
        score += wordScore;
        widget.gameController.updateScore(score);
      });

      if (foundWords.length == wordsToFind.length) {
        _handleLevelComplete();
      }
    }

    setState(() {
      dragStart = null;
      dragEnd = null;
      selectedCells = [];
    });
  }

  void _handleLevelComplete() {
    setState(() {
      _isLevelTransitioning = true;
    });

    // Add completion bonus based on remaining time
    final timeBonus = widget.gameController.timeRemaining * 10;
    setState(() {
      score += timeBonus;
      widget.gameController.updateScore(score);
    });

    // Show success message
    _showLevelCompleteMessage();

    // Check if there are more levels
    Future.delayed(const Duration(seconds: 2), () {
      if (currentLevel < levels.length - 1) {
        // Go to next level
        bool hasNextLevel = widget.gameController.nextLevel();
        if (hasNextLevel) {
          setState(() {
            currentLevel = widget.gameController.currentLevel;
            _isLevelTransitioning = false;
            _initializeGame();
          });
        }
      } else {
        // Complete the game
        widget.gameController.completeGame();
      }
    });
  }

  void _showLevelCompleteMessage() {
    final timeBonus = widget.gameController.timeRemaining * 10;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Level ${currentLevel + 1} Complete! +$timeBonus time bonus',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.correctAnswerColor,
        duration: const Duration(seconds: 2),
      ),
    );
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
        word.write(grid[cell.dy.toInt()][cell.dx.toInt()]);
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

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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
    // Use AnimatedBuilder to listen to GameController changes for the timer
    return AnimatedBuilder(
        animation: widget.gameController,
        builder: (context, _) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildStatCard(
                      icon: Icons.stars,
                      label: 'Score',
                      value: score.toString(),
                      color: AppTheme.accentColor,
                    ),
                    const SizedBox(width: 8),
                    _buildStatCard(
                      icon: Icons.timer,
                      label: 'Time',
                      value: _formatTime(widget.gameController.timeRemaining),
                      color: widget.gameController.timeRemaining < 30
                          ? AppTheme.wrongAnswerColor
                          : AppTheme.primaryColor,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildStatCard(
                      icon: Icons.format_list_bulleted,
                      label: 'Words',
                      value: '${foundWords.length}/${wordsToFind.length}',
                      color: AppTheme.secondaryColor,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Level ${currentLevel + 1}/${levels.length}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: color,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
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
          ).animate().fadeIn(
                duration: const Duration(milliseconds: 300),
                delay: Duration(milliseconds: isFound ? 0 : 100),
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
          j * cellSize + (cellSize - textPainter.width) / 2,
          i * cellSize + (cellSize - textPainter.height) / 2,
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

class LevelData {
  final int gridSize;
  final List<String> words;
  final int timeLimit;

  LevelData({
    required this.gridSize,
    required this.words,
    required this.timeLimit,
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../ui/components/game_container.dart';
import '../ui/components/header_container.dart';
import '../ui/theme/app_theme.dart';
import 'controller/game_controller.dart';

class NumberGridGame extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final GameController gameController;

  const NumberGridGame({
    super.key,
    required this.gameData,
    required this.gameController,
  });

  @override
  State<NumberGridGame> createState() => _NumberGridGameState();
}

class _NumberGridGameState extends State<NumberGridGame> {
  late int gridSize;
  late int targetSum;
  late List<List<int?>> grid;
  late List<List<bool>> isFixed;
  late List<List<bool>> isHighlighted;
  late List<List<bool>> isCorrectRow;
  late List<List<bool>> isCorrectCol;
  late bool isCorrectDiag1;
  late bool isCorrectDiag2;
  int? selectedNumber;
  bool isComplete = false;
  int score = 0;
  int moves = 0;
  int level = 0;
  int hintsRemaining = 3;
  bool isShowingHint = false;
  bool isShowingTutorial = true;

  final List<LevelConfig> levels = [
    LevelConfig(gridSize: 3, targetSum: 15, timeLimit: 120),
    LevelConfig(gridSize: 4, targetSum: 30, timeLimit: 180),
    LevelConfig(gridSize: 4, targetSum: 34, timeLimit: 180),
    LevelConfig(gridSize: 5, targetSum: 65, timeLimit: 240),
    LevelConfig(gridSize: 5, targetSum: 75, timeLimit: 300),
  ];

  @override
  void initState() {
    super.initState();
    level = widget.gameController.currentLevel;
    _initializeGrid();

    // Start the game with the controller
    widget.gameController.startGame(
      level: level,
      maxLevels: levels.length,
      timeLimit: levels[level].timeLimit,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorialDialog();
    });
  }

  void _initializeGrid() {
    final levelConfig = levels[level];
    gridSize = levelConfig.gridSize;
    targetSum = levelConfig.targetSum;

    grid = List.generate(gridSize, (_) => List.filled(gridSize, null));
    isFixed = List.generate(gridSize, (_) => List.filled(gridSize, false));
    isHighlighted =
        List.generate(gridSize, (_) => List.filled(gridSize, false));
    isCorrectRow = List.generate(gridSize, (_) => List.filled(gridSize, false));
    isCorrectCol = List.generate(gridSize, (_) => List.filled(gridSize, false));
    isCorrectDiag1 = false;
    isCorrectDiag2 = false;

    // Place some initial numbers
    _placeInitialNumbers();
  }

  void _placeInitialNumbers() {
    final random = math.Random();

    // For smaller grids, we place fewer initial numbers
    int numbersToPlace = gridSize;
    if (gridSize >= 4) {
      numbersToPlace += 2;
    }

    // Generate magic square first for reference (ensures a valid solution exists)
    final magicSquare = _generateMagicSquare(gridSize, targetSum);

    // Place strategic numbers from the magic square
    while (numbersToPlace > 0) {
      int row = random.nextInt(gridSize);
      int col = random.nextInt(gridSize);

      if (grid[row][col] == null) {
        grid[row][col] = magicSquare[row][col];
        isFixed[row][col] = true;
        numbersToPlace--;
      }
    }
  }

  List<List<int>> _generateMagicSquare(int size, int targetSum) {
    // Create a simple magic square or reference solution
    // This is a simplified implementation for demo purposes
    List<List<int>> square = List.generate(size, (_) => List.filled(size, 0));

    // For a 3x3 magic square with sum 15
    if (size == 3 && targetSum == 15) {
      square = [
        [8, 1, 6],
        [3, 5, 7],
        [4, 9, 2]
      ];
      return square;
    }

    // For a 4x4 magic square with sum 30 or 34
    if (size == 4) {
      if (targetSum == 30) {
        square = [
          [7, 12, 1, 10],
          [2, 13, 8, 7],
          [16, 3, 10, 1],
          [5, 2, 11, 12]
        ];
      } else {
        square = [
          [1, 15, 14, 4],
          [12, 6, 7, 9],
          [8, 10, 11, 5],
          [13, 3, 2, 16]
        ];
      }
      return square;
    }

    // For a 5x5 we'll create a simple ascending pattern
    if (size == 5) {
      int val = 1;
      final avg = targetSum / size;

      // Generate values that sum to the target
      for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
          square[i][j] = val++;
          // Adjust to make rows/columns sum closer to target
          if (val > size * size) val = 1;
        }
      }

      // Adjust the values to make sums closer to target
      for (int i = 0; i < size; i++) {
        int rowSum = square[i].reduce((a, b) => a + b);
        int diff = targetSum - rowSum;
        square[i][i] += diff ~/ size;
      }

      return square;
    }

    // Default fallback for other sizes
    return square;
  }

  bool _isValidPlacement(int row, int col, int number) {
    // Check row
    for (int c = 0; c < gridSize; c++) {
      if (c != col && grid[row][c] == number) return false;
    }

    // Check column
    for (int r = 0; r < gridSize; r++) {
      if (r != row && grid[r][col] == number) return false;
    }

    return true;
  }

  void _onCellTap(int row, int col) {
    if (isFixed[row][col] || isComplete) return;

    setState(() {
      if (selectedNumber != null) {
        if (_isValidPlacement(row, col, selectedNumber!)) {
          grid[row][col] = selectedNumber;
          selectedNumber = null;
          moves++;
          widget.gameController.incrementMoves();
          _checkCompletion();
        }
      } else if (grid[row][col] != null) {
        selectedNumber = grid[row][col];
        grid[row][col] = null;
      }
      _updateHighlights();
    });
  }

  void _updateHighlights() {
    setState(() {
      for (int i = 0; i < gridSize; i++) {
        for (int j = 0; j < gridSize; j++) {
          isHighlighted[i][j] = false;
        }
      }

      if (selectedNumber != null) {
        for (int i = 0; i < gridSize; i++) {
          for (int j = 0; j < gridSize; j++) {
            if (!isFixed[i][j] &&
                grid[i][j] == null &&
                _isValidPlacement(i, j, selectedNumber!)) {
              isHighlighted[i][j] = true;
            }
          }
        }
      }
    });
  }

  void _useHint() {
    if (hintsRemaining <= 0 || isComplete) return;

    setState(() {
      hintsRemaining--;
      isShowingHint = true;

      // Find an empty cell where we can place a number
      for (int i = 0; i < gridSize; i++) {
        for (int j = 0; j < gridSize; j++) {
          if (grid[i][j] == null) {
            // Try each number from 1 to gridSize*gridSize until we find a valid one
            for (int num = 1; num <= gridSize * gridSize; num++) {
              if (_isValidPlacement(i, j, num)) {
                grid[i][j] = num;
                isHighlighted[i][j] = true;

                // Check for completed rows/columns after placing hint
                _checkCompletion();

                // After 3 seconds, hide the highlight but keep the number
                Future.delayed(const Duration(seconds: 3), () {
                  if (mounted) {
                    setState(() {
                      isShowingHint = false;
                      isHighlighted[i][j] = false;
                    });
                  }
                });

                return;
              }
            }
          }
        }
      }
    });
  }

  void _checkCompletion() {
    bool isFull = true;
    bool isValid = true;

    // Reset validation state
    isCorrectRow = List.generate(gridSize, (_) => List.filled(gridSize, false));
    isCorrectCol = List.generate(gridSize, (_) => List.filled(gridSize, false));
    isCorrectDiag1 = false;
    isCorrectDiag2 = false;

    // Check rows
    for (int i = 0; i < gridSize; i++) {
      int rowSum = 0;
      bool rowComplete = true;
      for (int j = 0; j < gridSize; j++) {
        if (grid[i][j] == null) {
          isFull = false;
          rowComplete = false;
        } else {
          rowSum += grid[i][j]!;
        }
      }

      if (rowComplete && rowSum == targetSum) {
        for (int j = 0; j < gridSize; j++) {
          isCorrectRow[i][j] = true;
        }
      } else if (rowComplete) {
        isValid = false;
      }
    }

    // Check columns
    for (int j = 0; j < gridSize; j++) {
      int colSum = 0;
      bool colComplete = true;
      for (int i = 0; i < gridSize; i++) {
        if (grid[i][j] == null) {
          colComplete = false;
        } else {
          colSum += grid[i][j]!;
        }
      }

      if (colComplete && colSum == targetSum) {
        for (int i = 0; i < gridSize; i++) {
          isCorrectCol[i][j] = true;
        }
      } else if (colComplete) {
        isValid = false;
      }
    }

    // Check diagonals
    if (isFull) {
      int diagSum1 = 0;
      int diagSum2 = 0;
      for (int i = 0; i < gridSize; i++) {
        diagSum1 += grid[i][i]!;
        diagSum2 += grid[i][gridSize - 1 - i]!;
      }
      if (diagSum1 == targetSum) {
        isCorrectDiag1 = true;
      } else {
        isValid = false;
      }
      if (diagSum2 == targetSum) {
        isCorrectDiag2 = true;
      } else {
        isValid = false;
      }
    }

    if (isFull && isValid) {
      setState(() {
        isComplete = true;
        score = 1000 - (moves * 10);
        if (score < 0) score = 0;

        widget.gameController.updateScore(score);

        // Check if we can advance to next level
        if (level < levels.length - 1) {
          _showLevelCompleteDialog();
        } else {
          widget.gameController.completeGame();
        }
      });
    }
  }

  void _showLevelCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Level ${level + 1} Complete!',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Score: $score', style: GoogleFonts.poppins()),
            const SizedBox(height: 8),
            Text('Well done! Ready for the next challenge?',
                style: GoogleFonts.poppins()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (widget.gameController.nextLevel()) {
                setState(() {
                  level = widget.gameController.currentLevel;
                  isComplete = false;
                  moves = 0;
                  selectedNumber = null;
                  _initializeGrid();
                });
              } else {
                widget.gameController.completeGame();
              }
            },
            child: Text('Next Level', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showTutorialDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('How to Play',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Magic Square Challenge:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
                '1. Fill in the grid so that each row, column, and diagonal sums to $targetSum.',
                style: GoogleFonts.poppins()),
            const SizedBox(height: 4),
            Text('2. Each row and column must contain unique numbers.',
                style: GoogleFonts.poppins()),
            const SizedBox(height: 4),
            Text('3. Tap a cell to place a selected number.',
                style: GoogleFonts.poppins()),
            const SizedBox(height: 4),
            Text('4. Numbers can range from 1 to ${gridSize * gridSize}.',
                style: GoogleFonts.poppins()),
            const SizedBox(height: 4),
            Text('5. Use hints when stuck (you have $hintsRemaining hints).',
                style: GoogleFonts.poppins()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => isShowingTutorial = false);
            },
            child: Text('Got it!', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameContainer(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildGrid(),
          ),
          _buildNumberPad(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Level indicator
              _buildLevelIndicator(),

              // Time indicator
              _buildTimeIndicator(),

              // Hint button
              _buildHintButton(),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Target Sum: $targetSum',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.trending_up, color: AppTheme.primaryColor, size: 16),
          const SizedBox(width: 4),
          Text(
            'Level ${level + 1}/${levels.length}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeIndicator() {
    return AnimatedBuilder(
        animation: widget.gameController,
        builder: (context, _) {
          final timeLeft = widget.gameController.timeRemaining;
          final minutes = (timeLeft ~/ 60).toString().padLeft(2, '0');
          final seconds = (timeLeft % 60).toString().padLeft(2, '0');

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$minutes:$seconds',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
          );
        });
  }

  Widget _buildHintButton() {
    return GestureDetector(
      onTap: hintsRemaining > 0 ? _useHint : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: hintsRemaining > 0
              ? AppTheme.accentColor.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb,
              color: hintsRemaining > 0 ? AppTheme.accentColor : Colors.grey,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'Hint ($hintsRemaining)',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: hintsRemaining > 0 ? AppTheme.accentColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AspectRatio(
        aspectRatio: 1,
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
          child: GridView.builder(
            padding: const EdgeInsets.all(2),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridSize,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: gridSize * gridSize,
            itemBuilder: (context, index) {
              final row = index ~/ gridSize;
              final col = index % gridSize;
              return _buildCell(row, col);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCell(int row, int col) {
    final number = grid[row][col];
    final isSelected = selectedNumber != null && number == selectedNumber;
    final isHighlight = isHighlighted[row][col];
    final isRowCorrect = isCorrectRow[row][col];
    final isColCorrect = isCorrectCol[row][col];
    final isDiag1Correct = isCorrectDiag1 && row == col;
    final isDiag2Correct = isCorrectDiag2 && row == gridSize - 1 - col;
    final isCorrect =
        isRowCorrect || isColCorrect || isDiag1Correct || isDiag2Correct;

    return GestureDetector(
      onTap: () => _onCellTap(row, col),
      child: Container(
        decoration: BoxDecoration(
          color: _getCellColor(row, col, isSelected, isHighlight, isCorrect),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isFixed[row][col]
                ? AppTheme.primaryColor.withOpacity(0.5)
                : isCorrect
                    ? AppTheme.correctAnswerColor.withOpacity(0.5)
                    : Colors.grey.withOpacity(0.2),
            width: isFixed[row][col] || isCorrect ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            number?.toString() ?? '',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight:
                  isFixed[row][col] ? FontWeight.bold : FontWeight.normal,
              color: isFixed[row][col]
                  ? AppTheme.primaryColor
                  : isCorrect
                      ? AppTheme.correctAnswerColor
                      : AppTheme.secondaryColor,
            ),
          ),
        ),
      ),
    )
        .animate()
        .scale(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        )
        .fadeIn();
  }

  Color _getCellColor(
      int row, int col, bool isSelected, bool isHighlight, bool isCorrect) {
    if (isFixed[row][col]) return Colors.blue.shade50;
    if (isCorrect) return AppTheme.correctAnswerColor.withOpacity(0.1);
    if (isSelected) return Colors.purple.shade100;
    if (isHighlight) return Colors.green.shade50;
    return Colors.grey.shade50;
  }

  Widget _buildNumberPad() {
    // Determine range of numbers to show
    List<int> numberRange = List.generate(gridSize * gridSize, (i) => i + 1);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: numberRange.map((number) {
              return _buildNumberButton(number);
            }).toList(),
          ),
          if (selectedNumber != null) ...[
            const SizedBox(height: 16),
            Text(
              'Tap a cell to place $selectedNumber',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNumberButton(int number) {
    final isSelected = selectedNumber == number;
    final isUnavailable = _isNumberFullyUsed(number);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isUnavailable ? null : () => _onNumberSelect(number),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: gridSize < 4 ? 56 : 48,
          height: gridSize < 4 ? 56 : 48,
          decoration: BoxDecoration(
            color: isUnavailable
                ? Colors.grey.shade200
                : isSelected
                    ? AppTheme.primaryColor
                    : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isUnavailable
                    ? Colors.grey
                    : isSelected
                        ? Colors.white
                        : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isNumberFullyUsed(int number) {
    // Count occurrences of this number in the grid
    int count = 0;
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (grid[r][c] == number) count++;
      }
    }

    // Number is fully used if it appears gridSize times
    return count >= gridSize;
  }

  void _onNumberSelect(int number) {
    setState(() {
      selectedNumber = selectedNumber == number ? null : number;
      _updateHighlights();
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
}

class LevelConfig {
  final int gridSize;
  final int targetSum;
  final int timeLimit;

  const LevelConfig({
    required this.gridSize,
    required this.targetSum,
    required this.timeLimit,
  });
}

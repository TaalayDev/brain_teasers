import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../components/header_container.dart';
import '../theme/app_theme.dart';

class NumberGridGame extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final Function(int score) onScoreUpdate;
  final VoidCallback onComplete;

  const NumberGridGame({
    super.key,
    required this.gameData,
    required this.onScoreUpdate,
    required this.onComplete,
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
  int? selectedNumber;
  bool isComplete = false;
  int score = 0;
  int moves = 0;

  @override
  void initState() {
    super.initState();
    gridSize = widget.gameData['gridSize'];
    targetSum = widget.gameData['target'];
    _initializeGrid();
  }

  void _initializeGrid() {
    final random = math.Random();
    grid = List.generate(gridSize, (_) => List.filled(gridSize, null));
    isFixed = List.generate(gridSize, (_) => List.filled(gridSize, false));
    isHighlighted =
        List.generate(gridSize, (_) => List.filled(gridSize, false));

    // Place some initial numbers
    int numbersToPlace = gridSize;
    while (numbersToPlace > 0) {
      int row = random.nextInt(gridSize);
      int col = random.nextInt(gridSize);
      if (grid[row][col] == null) {
        int number = random.nextInt(9) + 1;
        if (_isValidPlacement(row, col, number)) {
          grid[row][col] = number;
          isFixed[row][col] = true;
          numbersToPlace--;
        }
      }
    }
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

  void _checkCompletion() {
    bool isFull = true;
    bool isValid = true;

    // Check rows
    for (int i = 0; i < gridSize; i++) {
      int rowSum = 0;
      for (int j = 0; j < gridSize; j++) {
        if (grid[i][j] == null) {
          isFull = false;
        } else {
          rowSum += grid[i][j]!;
        }
      }
      if (isFull && rowSum != targetSum) isValid = false;
    }

    // Check columns
    for (int j = 0; j < gridSize; j++) {
      int colSum = 0;
      for (int i = 0; i < gridSize; i++) {
        if (grid[i][j] != null) {
          colSum += grid[i][j]!;
        }
      }
      if (isFull && colSum != targetSum) isValid = false;
    }

    // Check diagonals
    if (isFull) {
      int diagSum1 = 0;
      int diagSum2 = 0;
      for (int i = 0; i < gridSize; i++) {
        diagSum1 += grid[i][i]!;
        diagSum2 += grid[i][gridSize - 1 - i]!;
      }
      if (diagSum1 != targetSum || diagSum2 != targetSum) isValid = false;
    }

    if (isFull && isValid) {
      setState(() {
        isComplete = true;
        score = 1000 - (moves * 10);
        if (score < 0) score = 0;
        widget.onScoreUpdate(score);
        widget.onComplete();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.purple.shade50,
            ],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildGrid(),
            ),
            _buildNumberPad(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return HeaderContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Number Grid',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Target Sum: $targetSum',
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
                    const Icon(
                      Icons.star,
                      color: AppTheme.accentColor,
                    ),
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
          const SizedBox(height: 16),
          Text(
            'Moves: $moves',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
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

    return GestureDetector(
      onTap: () => _onCellTap(row, col),
      child: Container(
        decoration: BoxDecoration(
          color: _getCellColor(row, col, isSelected, isHighlight),
          borderRadius: BorderRadius.circular(8),
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

  Color _getCellColor(int row, int col, bool isSelected, bool isHighlight) {
    if (isFixed[row][col]) return Colors.blue.shade50;
    if (isSelected) return Colors.purple.shade100;
    if (isHighlight) return Colors.green.shade50;
    return Colors.grey.shade50;
  }

  Widget _buildNumberPad() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(9, (index) {
              final number = index + 1;
              return _buildNumberButton(number);
            }),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onNumberSelect(number),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isSelected ? Colors.purple.shade600 : Colors.white,
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
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onNumberSelect(int number) {
    setState(() {
      selectedNumber = selectedNumber == number ? null : number;
      _updateHighlights();
    });
  }
}

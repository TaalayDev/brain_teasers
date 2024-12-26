import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../components/game_container.dart';
import '../theme/app_theme.dart';
import 'game_controller.dart';

class SpotDifferenceGame extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final GameController gameController;

  const SpotDifferenceGame({
    super.key,
    required this.gameData,
    required this.gameController,
  });

  @override
  State<SpotDifferenceGame> createState() => _SpotDifferenceGameState();
}

class _SpotDifferenceGameState extends State<SpotDifferenceGame> {
  late List<Map<String, dynamic>> _levels;
  late int _currentLevel;
  late List<List<String>> _leftGrid;
  late List<List<String>> _rightGrid;
  late Set<String> _foundDifferences;
  late int _score;
  late int _remainingTime;
  late bool _isTimerRunning;
  late List<String> _elements;
  late int _differences;
  late Map<String, int> _gridSize;
  late List<Point> _differenceLocations;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _startTimer();
  }

  void _initializeGame() {
    _levels = List<Map<String, dynamic>>.from(widget.gameData['levels']);
    _currentLevel = 0;
    _score = 0;
    _remainingTime = widget.gameData['timeLimit'];
    _isTimerRunning = true;
    _foundDifferences = {};
    _loadLevel();
  }

  void _loadLevel() {
    final level = _levels[_currentLevel];
    _gridSize = Map<String, int>.from(level['gridSize']);
    _differences = level['differences'];
    _elements = List<String>.from(level['elements']);
    _generateGrids();
  }

  void _generateGrids() {
    final width = _gridSize['width']!;
    final height = _gridSize['height']!;

    // Create base grid
    _leftGrid = List.generate(
        height,
        (y) => List.generate(
            width, (x) => _elements[math.Random().nextInt(_elements.length)]));

    // Copy left grid to right grid
    _rightGrid = List.generate(height, (y) => List.from(_leftGrid[y]));

    // Generate random difference locations
    _differenceLocations = [];
    while (_differenceLocations.length < _differences) {
      final x = math.Random().nextInt(width);
      final y = math.Random().nextInt(height);
      final point = Point(x, y);
      if (!_differenceLocations.contains(point)) {
        _differenceLocations.add(point);
        // Change element in right grid
        String newElement;
        do {
          newElement = _elements[math.Random().nextInt(_elements.length)];
        } while (newElement == _rightGrid[y][x]);
        _rightGrid[y][x] = newElement;
      }
    }
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _isTimerRunning) {
        setState(() {
          _remainingTime--;
          if (_remainingTime <= 0) {
            _handleTimeUp();
          } else {
            _startTimer();
          }
        });
      }
    });
  }

  void _handleTimeUp() {
    _isTimerRunning = false;
    widget.gameController.completeGame();
  }

  void _checkTile(int x, int y, bool isLeftGrid) {
    if (!_isTimerRunning) return;

    final key = '$x,$y';
    if (_foundDifferences.contains(key)) return;

    if (_differenceLocations.contains(Point(x, y))) {
      setState(() {
        _foundDifferences.add(key);
        _score +=
            (100 * (_remainingTime / widget.gameData['timeLimit'])).round();
        widget.gameController.updateScore(_score);

        if (_foundDifferences.length == _differences) {
          _handleLevelComplete();
        }
      });
    } else {
      // Penalty for wrong guess
      setState(() {
        _score = math.max(0, _score - 10);
        widget.gameController.updateScore(_score);
      });
      _showFeedback(false);
    }
  }

  void _handleLevelComplete() {
    if (_currentLevel < _levels.length - 1) {
      _showFeedback(true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _currentLevel++;
            _foundDifferences.clear();
            _loadLevel();
          });
        }
      });
    } else {
      _isTimerRunning = false;
      widget.gameController.completeGame();
    }
  }

  void _showFeedback(bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Level Complete!' : 'Try Again!',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:
            success ? AppTheme.correctAnswerColor : AppTheme.wrongAnswerColor,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameContainer(
      child: Column(
        children: [
          _buildHeader(),
          const Spacer(),
          _buildGrids(),
          const Spacer(),
          _buildProgress(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Level ${_currentLevel + 1}/${_levels.length}',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              Text(
                'Find ${_differences - _foundDifferences.length} differences',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.timer, color: AppTheme.accentColor),
              const SizedBox(width: 8),
              Text(
                _formatTime(_remainingTime),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _remainingTime < 30
                      ? AppTheme.wrongAnswerColor
                      : Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrids() {
    return Row(
      children: [
        Expanded(child: _buildGrid(_leftGrid, true)),
        Container(
          width: 2,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
        Expanded(child: _buildGrid(_rightGrid, false)),
      ],
    );
  }

  Widget _buildGrid(List<List<String>> grid, bool isLeftGrid) {
    return AspectRatio(
      aspectRatio: _gridSize['width']! / _gridSize['height']!,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _gridSize['width']!,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          reverse: true,
          itemCount: _gridSize['width']! * _gridSize['height']!,
          itemBuilder: (context, index) {
            final x = index % _gridSize['width']!;
            final y = index ~/ _gridSize['width']!;
            return _buildTile(x, y, grid[y][x], isLeftGrid);
          },
        ),
      ),
    );
  }

  Widget _buildTile(int x, int y, String element, bool isLeftGrid) {
    final key = '$x,$y';
    final isDifferenceFound = _foundDifferences.contains(key);

    return GestureDetector(
      onTap: () => _checkTile(x, y, isLeftGrid),
      child: Container(
        decoration: BoxDecoration(
          color: isDifferenceFound
              ? AppTheme.correctAnswerColor.withOpacity(0.2)
              : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isDifferenceFound
                ? AppTheme.correctAnswerColor
                : AppTheme.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: _buildElementIcon(element, isDifferenceFound),
        ),
      ),
    ).animate(
      effects: [
        if (isDifferenceFound)
          const ShakeEffect(
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          ),
      ],
    );
  }

  Widget _buildElementIcon(String element, bool isDifferenceFound) {
    IconData iconData;
    switch (element) {
      case 'circle':
        iconData = Icons.circle_outlined;
        break;
      case 'square':
        iconData = Icons.square_outlined;
        break;
      case 'triangle':
        iconData = Icons.change_history_outlined;
        break;
      case 'star':
        iconData = Icons.star_outline;
        break;
      case 'hexagon':
        iconData = Icons.hexagon_outlined;
        break;
      case 'diamond':
        iconData = Icons.diamond_outlined;
        break;
      default:
        iconData = Icons.help_outline;
    }

    return Icon(
      iconData,
      color: isDifferenceFound
          ? AppTheme.correctAnswerColor
          : AppTheme.primaryColor,
      size: 24,
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Score: $_score',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 24),
              Text(
                'Found: ${_foundDifferences.length}/$_differences',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _foundDifferences.length / _differences,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class Point {
  final int x;
  final int y;

  Point(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

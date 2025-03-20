import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../ui/components/game_container.dart';
import '../ui/theme/app_theme.dart';
import 'controller/game_controller.dart';

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
  int _hintsRemaining = 3;
  bool _isShowingHint = false;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    _levels = List<Map<String, dynamic>>.from(widget.gameData['levels']);
    _currentLevel = widget.gameController.currentLevel;
    _score = 0;
    _remainingTime = widget.gameData['timeLimit'] ?? 180;
    _isTimerRunning = true;
    _foundDifferences = {};
    _loadLevel();

    // Start the game with controller
    widget.gameController.startGame(
      timeLimit: _remainingTime,
      level: _currentLevel,
      maxLevels: _levels.length,
    );
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

  void _checkTile(int x, int y, bool isLeftGrid) {
    if (!_isTimerRunning) return;

    final key = '$x,$y';
    if (_foundDifferences.contains(key)) return;

    if (_differenceLocations.contains(Point(x, y))) {
      setState(() {
        _foundDifferences.add(key);
        _streak++;

        // Calculate points based on streak
        final basePoints = 100;
        final streakBonus = _streak * 10;
        final timeBonus = (widget.gameController.timeRemaining / 10).round();
        final totalPoints = basePoints + streakBonus + timeBonus;

        _score += totalPoints;
        widget.gameController.updateScore(_score);
        widget.gameController.updateStreak(true);

        if (_foundDifferences.length == _differences) {
          _handleLevelComplete();
        }
      });

      _showFeedback(true, 1);
    } else {
      // Penalty for wrong guess
      setState(() {
        _score = math.max(0, _score - 10);
        _streak = 0;
        widget.gameController.updateScore(_score);
        widget.gameController.updateStreak(false);
      });
      _showFeedback(false);
    }
  }

  void _handleLevelComplete() {
    if (_currentLevel < _levels.length - 1) {
      widget.gameController.nextLevel();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _currentLevel = widget.gameController.currentLevel;
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

  void _showFeedback(bool success, [int points = 0]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Found a difference! +$points points' : 'Try Again!',
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

  void _useHint() {
    if (_hintsRemaining <= 0) return;

    setState(() {
      _hintsRemaining--;
      _isShowingHint = true;

      // Highlight a random unfound difference
      final unfoundDifferences = _differenceLocations
          .where(
              (point) => !_foundDifferences.contains('${point.x},${point.y}'))
          .toList();

      if (unfoundDifferences.isNotEmpty) {
        final randomDiff = unfoundDifferences[
            math.Random().nextInt(unfoundDifferences.length)];
        // Trigger a visual hint for this difference
        _showHintAt(randomDiff);
      }
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isShowingHint = false;
        });
      }
    });
  }

  void _showHintAt(Point point) {
    // This would be implemented to show a visual hint at the specified point
    // For now, we'll just show the snackbar message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Look around position (${point.x}, ${point.y})',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.accentColor,
        duration: const Duration(seconds: 2),
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
            child: _buildGrids(),
          ),
          _buildProgress(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
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
                    'Level ${_currentLevel + 1}/${_levels.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.8),
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
              _buildStatCards(),
            ],
          ),
          const SizedBox(height: 8),
          _buildControlButtons(),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        _buildStatCard(
          icon: Icons.bolt,
          label: 'Streak',
          value: _streak.toString(),
          color: AppTheme.accentColor,
        ),
        const SizedBox(width: 8),
        _buildTimeDisplay(),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: color,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
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

  Widget _buildTimeDisplay() {
    return AnimatedBuilder(
      animation: widget.gameController,
      builder: (context, child) {
        final timeLeft = widget.gameController.timeRemaining;
        final minutes = (timeLeft ~/ 60).toString().padLeft(2, '0');
        final seconds = (timeLeft % 60).toString().padLeft(2, '0');

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.amber,
                    ),
                  ),
                  Text(
                    '$minutes:$seconds',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: timeLeft < 30
                          ? AppTheme.wrongAnswerColor
                          : Colors.amber,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _hintsRemaining > 0 ? _useHint : null,
            icon: const Icon(Icons.lightbulb_outline),
            label: Text('Use Hint (${_hintsRemaining})'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.amber,
              backgroundColor: Colors.amber.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(vertical: 8),
              disabledForegroundColor: Colors.grey.withOpacity(0.5),
              disabledBackgroundColor: Colors.grey.withOpacity(0.1),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.star, color: AppTheme.primaryColor, size: 16),
              const SizedBox(width: 4),
              Text(
                _score.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
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
    final isDifferenceHinted = _isShowingHint &&
        _differenceLocations.contains(Point(x, y)) &&
        !_foundDifferences.contains(key);

    return GestureDetector(
      onTap: () => _checkTile(x, y, isLeftGrid),
      child: Container(
        decoration: BoxDecoration(
          color: isDifferenceFound
              ? AppTheme.correctAnswerColor.withOpacity(0.2)
              : isDifferenceHinted
                  ? AppTheme.accentColor.withOpacity(0.2)
                  : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isDifferenceFound
                ? AppTheme.correctAnswerColor
                : isDifferenceHinted
                    ? AppTheme.accentColor
                    : AppTheme.primaryColor.withOpacity(0.3),
            width: isDifferenceFound || isDifferenceHinted ? 2 : 1,
          ),
        ),
        child: Center(
          child: _buildElementIcon(
            element,
            isDifferenceFound,
            isDifferenceHinted,
          ),
        ),
      ),
    ).animate(
      effects: [
        if (isDifferenceFound)
          const ShakeEffect(
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          ),
        // if (isDifferenceHinted)
        //   const PulseEffect(
        //     duration: Duration(milliseconds: 1000),
        //     curve: Curves.easeInOut,
        //   ),
      ],
    );
  }

  Widget _buildElementIcon(
      String element, bool isDifferenceFound, bool isDifferenceHinted) {
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

    Color iconColor;
    if (isDifferenceFound) {
      iconColor = AppTheme.correctAnswerColor;
    } else if (isDifferenceHinted) {
      iconColor = AppTheme.accentColor;
    } else {
      iconColor = AppTheme.primaryColor;
    }

    return Icon(
      iconData,
      color: iconColor,
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
                'Found: ${_foundDifferences.length}/$_differences',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _foundDifferences.length / _differences,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
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

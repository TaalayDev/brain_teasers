import 'package:brain_teasers/components/game_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../theme/app_theme.dart';

class VisualSearchGame extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final Function(int score) onScoreUpdate;
  final VoidCallback onComplete;

  const VisualSearchGame({
    super.key,
    required this.gameData,
    required this.onScoreUpdate,
    required this.onComplete,
  });

  @override
  State<VisualSearchGame> createState() => _VisualSearchGameState();
}

class _VisualSearchGameState extends State<VisualSearchGame> {
  late List<Map<String, dynamic>> _levels;
  late int _currentLevel;
  late List<GridItem> _grid;
  late Set<Point> _foundTargets;
  late int _score;
  late int _remainingTime;
  late bool _isTimerRunning;
  late int _targetCount;
  late GridItem _targetItem;

  final List<ItemVariant> _shapes = [
    ItemVariant(Icons.circle, 'Circle'),
    ItemVariant(Icons.square, 'Square'),
    ItemVariant(
      MaterialCommunityIcons.vector_triangle,
      'Triangle',
    ),
    ItemVariant(Icons.diamond, 'Diamond'),
    ItemVariant(Icons.hexagon, 'Hexagon'),
    ItemVariant(Icons.star, 'Star'),
  ];

  final List<Color> _colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
  ];

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
    _foundTargets = {};
    _loadLevel();
  }

  void _loadLevel() {
    final level = _levels[_currentLevel];
    final gridSize = level['gridSize'];
    _targetCount = level['targetCount'];
    final distractorTypes = level['distractorTypes'];

    // Select target properties
    final targetShape = _shapes[math.Random().nextInt(_shapes.length)];
    final targetColor = _colors[math.Random().nextInt(_colors.length)];
    _targetItem = GridItem(targetShape, targetColor, true);

    // Generate grid
    _grid = [];
    int targetCount = 0;

    // Create distractor variations
    List<GridItem> distractors = [];
    for (int i = 0; i < distractorTypes; i++) {
      ItemVariant shape = _shapes[math.Random().nextInt(_shapes.length)];
      Color color = _colors[math.Random().nextInt(_colors.length)];

      // Ensure distractors are different from target
      while (shape == targetShape && color == targetColor) {
        shape = _shapes[math.Random().nextInt(_shapes.length)];
        color = _colors[math.Random().nextInt(_colors.length)];
      }

      distractors.add(GridItem(shape, color, false));
    }

    // Fill grid
    for (int i = 0; i < gridSize['width'] * gridSize['height']; i++) {
      if (targetCount < _targetCount) {
        // Add target with some probability
        if (math.Random().nextDouble() < 0.2) {
          _grid.add(_targetItem);
          targetCount++;
          continue;
        }
      }

      // Add random distractor
      _grid.add(distractors[math.Random().nextInt(distractors.length)]);
    }

    // Ensure we have exact number of targets by replacing/adding if needed
    while (targetCount < _targetCount) {
      final index = math.Random().nextInt(_grid.length);
      if (!_grid[index].isTarget) {
        _grid[index] = _targetItem;
        targetCount++;
      }
    }

    // Shuffle grid
    _grid.shuffle();

    _remainingTime = widget.gameData['timeLimit'];
    _isTimerRunning = true;
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
    widget.onComplete();
  }

  void _onItemTap(int index) {
    if (!_isTimerRunning) return;

    final item = _grid[index];
    final point = Point(
      (index % _levels[_currentLevel]['gridSize']['width']).toInt(),
      index ~/ _levels[_currentLevel]['gridSize']['width'],
    );

    if (item.isTarget && !_foundTargets.contains(point)) {
      setState(() {
        _foundTargets.add(point);
        _score += 100;
        widget.onScoreUpdate(_score);

        if (_foundTargets.length == _targetCount) {
          _handleLevelComplete();
        }
      });
    } else if (!item.isTarget) {
      setState(() {
        _score = math.max(0, _score - 20);
        widget.onScoreUpdate(_score);
      });
      _showIncorrectFeedback();
    }
  }

  void _handleLevelComplete() {
    _isTimerRunning = false;

    if (_currentLevel < _levels.length - 1) {
      _showLevelCompleteFeedback();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _currentLevel++;
            _foundTargets.clear();
            _loadLevel();
          });
        }
      });
    } else {
      widget.onComplete();
    }
  }

  void _showIncorrectFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Wrong item! -20 points',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.wrongAnswerColor,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showLevelCompleteFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Level Complete! +100 bonus points',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.correctAnswerColor,
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
          _buildTarget(),
          Expanded(child: _buildGrid()),
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
                'Find $_targetCount targets',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
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
              Text(
                'Score: $_score',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTarget() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Find: ',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
            child: Icon(
              _targetItem.variant.icon,
              color: _targetItem.color,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  double _getGridIconSize() {
    final gridSize = _levels[_currentLevel]['gridSize'];
    final width = MediaQuery.of(context).size.width;
    final itemWidth = width / gridSize['width'];
    return itemWidth * 0.5;
  }

  Widget _buildGrid() {
    final gridSize = _levels[_currentLevel]['gridSize'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridSize['width'],
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _grid.length,
        itemBuilder: (context, index) {
          final point = Point(
            (index % gridSize['width']).toInt(),
            index ~/ gridSize['width'],
          );
          final isFound = _foundTargets.contains(point);

          return GestureDetector(
            onTap: () => _onItemTap(index),
            child: Container(
              decoration: BoxDecoration(
                color: isFound
                    ? AppTheme.correctAnswerColor.withOpacity(0.2)
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isFound
                      ? AppTheme.correctAnswerColor
                      : Colors.grey.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                _grid[index].variant.icon,
                color: _grid[index].color,
                size: _getGridIconSize(),
              ),
            ),
          ).animate(
            effects: [
              if (isFound)
                const ShakeEffect(
                  duration: Duration(milliseconds: 500),
                ),
            ],
          );
        },
      ),
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
                'Found: ${_foundTargets.length}/$_targetCount',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _foundTargets.length / _targetCount,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.4),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.primaryColor,
            ),
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

class ItemVariant {
  final IconData icon;
  final String name;

  ItemVariant(this.icon, this.name);
}

class GridItem {
  final ItemVariant variant;
  final Color color;
  final bool isTarget;

  GridItem(this.variant, this.color, this.isTarget);
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

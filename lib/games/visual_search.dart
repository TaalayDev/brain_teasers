import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../components/game_container.dart';
import '../theme/app_theme.dart';
import 'game_controller.dart';

class VisualSearchGame extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final GameController gameController;

  const VisualSearchGame({
    super.key,
    required this.gameData,
    required this.gameController,
  });

  @override
  State<VisualSearchGame> createState() => _VisualSearchGameState();
}

class _VisualSearchGameState extends State<VisualSearchGame>
    with TickerProviderStateMixin {
  late List<Map<String, dynamic>> _levels;
  late int _currentLevel;
  late List<GridItem> _grid;
  late Set<Point> _foundTargets;
  late int _targetCount;
  late GridItem _targetItem;
  late int _gridSize;
  late AnimationController _celebrationController;

  bool _isLevelComplete = false;
  bool _showTutorial = true;
  bool _showingHint = false;
  int _hintsRemaining = 3;

  final List<ItemVariant> _shapes = [
    ItemVariant(Icons.circle, 'Circle'),
    ItemVariant(Icons.square, 'Square'),
    ItemVariant(MaterialCommunityIcons.vector_triangle, 'Triangle'),
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
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _initializeGame();

    // Show tutorial on first launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_showTutorial) {
        _showTutorialDialog();
      }
    });
  }

  void _initializeGame() {
    _levels = _generateLevels();
    _currentLevel = widget.gameController.currentLevel;
    _foundTargets = {};
    _loadLevel();

    // Initialize game controller
    widget.gameController.startGame(
      timeLimit: _levels[_currentLevel]['timeLimit'],
      level: _currentLevel,
      maxLevels: _levels.length,
    );
  }

  List<Map<String, dynamic>> _generateLevels() {
    // Use provided levels or generate our own
    if (widget.gameData.containsKey('levels')) {
      return List<Map<String, dynamic>>.from(widget.gameData['levels']);
    }

    // Generate increasingly difficult levels
    return [
      {
        'gridSize': {'width': 6, 'height': 6},
        'targetCount': 3,
        'distractorTypes': 2,
        'timeLimit': 60,
      },
      {
        'gridSize': {'width': 8, 'height': 8},
        'targetCount': 4,
        'distractorTypes': 3,
        'timeLimit': 75,
      },
      {
        'gridSize': {'width': 10, 'height': 10},
        'targetCount': 5,
        'distractorTypes': 4,
        'timeLimit': 90,
      },
      {
        'gridSize': {'width': 12, 'height': 12},
        'targetCount': 6,
        'distractorTypes': 5,
        'timeLimit': 105,
      },
      {
        'gridSize': {'width': 14, 'height': 14},
        'targetCount': 7,
        'distractorTypes': 6,
        'timeLimit': 120,
      },
    ];
  }

  void _loadLevel() {
    final level = _levels[_currentLevel];
    _gridSize = level['gridSize']['width'];
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
      while ((shape.icon == targetShape.icon && color == targetColor) ||
          distractors
              .any((d) => d.variant.icon == shape.icon && d.color == color)) {
        shape = _shapes[math.Random().nextInt(_shapes.length)];
        color = _colors[math.Random().nextInt(_colors.length)];
      }

      distractors.add(GridItem(shape, color, false));
    }

    // Generate more realistic grid array
    final totalCells = _gridSize * _gridSize;
    _grid = List.filled(totalCells, GridItem(targetShape, targetColor, false));

    // Place targets randomly
    final positions = List<int>.generate(totalCells, (i) => i);
    positions.shuffle();

    // Place target items
    for (int i = 0; i < _targetCount; i++) {
      if (i < positions.length) {
        _grid[positions[i]] = _targetItem;
      }
    }

    // Fill remaining positions with distractors
    for (int i = _targetCount; i < positions.length; i++) {
      _grid[positions[i]] =
          distractors[math.Random().nextInt(distractors.length)];
    }
  }

  void _onItemTap(int index) {
    if (_isLevelComplete) return;

    final item = _grid[index];
    final point = Point(
      (index % _gridSize).toInt(),
      index ~/ _gridSize,
    );

    if (item.isTarget && !_foundTargets.contains(point)) {
      setState(() {
        _foundTargets.add(point);

        // Add points with a bonus for speed
        final speedBonus = (widget.gameController.timeRemaining / 10).round();
        final itemScore = 100 + speedBonus;

        widget.gameController
            .updateScore(widget.gameController.score + itemScore);

        // Show visual feedback
        _showSuccessFeedback(point, itemScore);

        if (_foundTargets.length == _targetCount) {
          _handleLevelComplete();
        }
      });
    } else if (!item.isTarget) {
      // Penalty for incorrect selection
      final penalty = 20;
      widget.gameController
          .updateScore(math.max(0, widget.gameController.score - penalty));

      // Show visual feedback
      _showIncorrectFeedback(point, penalty);
    }
  }

  void _showSuccessFeedback(Point point, int score) {
    // Show success popup at the tapped location
    final offset = _gridToScreenOffset(point);

    _showFloatingScore(offset, score, true);
  }

  void _showIncorrectFeedback(Point point, int penalty) {
    // Show error popup at the tapped location
    final offset = _gridToScreenOffset(point);

    _showFloatingScore(offset, penalty, false);
  }

  Offset _gridToScreenOffset(Point point) {
    // Approximate conversion from grid coordinates to screen coordinates
    // This would need adjustment based on actual grid rendering size
    final cellSize = MediaQuery.of(context).size.width / _gridSize;
    return Offset(
      (point.x + 0.5) * cellSize,
      (point.y + 0.5) * cellSize + 150, // Adjust for header height
    );
  }

  void _showFloatingScore(Offset position, int points, bool isPositive) {
    final overlay = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx - 30,
        top: position.dy - 30,
        child: Material(
          color: Colors.transparent,
          child: Text(
            isPositive ? '+$points' : '-$points',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isPositive
                  ? AppTheme.correctAnswerColor
                  : AppTheme.wrongAnswerColor,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 2,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 150.ms)
              .then()
              .slideY(
                  begin: 0,
                  end: -0.3,
                  duration: 600.ms,
                  curve: Curves.easeOutCubic)
              .fadeOut(begin: 0.7, duration: 300.ms),
        ),
      ),
    );

    Overlay.of(context).insert(overlay);
    Future.delayed(const Duration(milliseconds: 800), () {
      overlay.remove();
    });
  }

  void _handleLevelComplete() {
    _isLevelComplete = true;
    _celebrationController.forward(from: 0.0);

    // Add level completion bonus
    final timeBonus = widget.gameController.timeRemaining * 10;
    final levelBonus = (_currentLevel + 1) * 200;
    final completionBonus = timeBonus + levelBonus;

    widget.gameController
        .updateScore(widget.gameController.score + completionBonus);

    // Show completion message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Level Complete! +$completionBonus bonus',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.correctAnswerColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Move to next level after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        if (_currentLevel < _levels.length - 1) {
          setState(() {
            _currentLevel++;
            _foundTargets.clear();
            _isLevelComplete = false;
            _loadLevel();
            widget.gameController.nextLevel();
          });
        } else {
          widget.gameController.completeGame();
        }
      }
    });
  }

  void _useHint() {
    if (_hintsRemaining <= 0 || _isLevelComplete || _showingHint) return;

    setState(() {
      _hintsRemaining--;
      _showingHint = true;
    });

    // Show a target briefly
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showingHint = false;
        });
      }
    });
  }

  void _showTutorialDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Visual Search Challenge',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search,
              size: 48,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Find all instances of the target item in the grid!',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '• Look at the target shown at the top\n'
              '• Find all ${_targetCount} matching items\n'
              '• Tap on each matching item\n'
              '• Complete the level before time runs out\n'
              '• Use hints if you get stuck',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _showTutorial = false;
              });
              Navigator.of(context).pop();
            },
            child: Text(
              'Let\'s Start!',
              style: GoogleFonts.poppins(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameContainer(
      child: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              _buildTarget(),
              Expanded(child: _buildGrid()),
              _buildProgress(),
            ],
          ),
          if (_isLevelComplete) _buildCelebrationOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: widget.gameController,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildStatCard(
                        icon: Icons.stars,
                        label: 'Score',
                        value: widget.gameController.score.toString(),
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
                  Row(
                    children: [
                      IconButton(
                        onPressed: _hintsRemaining > 0 ? _useHint : null,
                        icon: Stack(
                          children: [
                            Icon(
                              Icons.lightbulb,
                              color: _hintsRemaining > 0
                                  ? Colors.amber
                                  : Colors.grey.withOpacity(0.5),
                              size: 28,
                            ),
                            if (_hintsRemaining > 0)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    _hintsRemaining.toString(),
                                    style: GoogleFonts.poppins(
                                      color: Colors.amber,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        tooltip: 'Use hint',
                      ),
                      IconButton(
                        onPressed: _showTutorialDialog,
                        icon: const Icon(
                          Icons.help_outline,
                          color: Colors.white,
                        ),
                        tooltip: 'How to play',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Level ${_currentLevel + 1}/${_levels.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Find: ${_foundTargets.length}/$_targetCount',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
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
                  fontSize: 16,
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

  Widget _buildTarget() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Find all:  ',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              _targetItem.variant.icon,
              color: _targetItem.color,
              size: 36,
            )
                .animate(
                  onPlay: (controller) => controller.repeat(),
                )
                .then(delay: 2000.ms)
                .shimmer(duration: 1000.ms, color: Colors.white10),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableSize =
              math.min(constraints.maxWidth, constraints.maxHeight);
          return Center(
            child: SizedBox(
              width: availableSize,
              height: availableSize,
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _gridSize,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: _grid.length,
                itemBuilder: (context, index) {
                  final point = Point(
                    (index % _gridSize).toInt(),
                    index ~/ _gridSize,
                  );
                  final isFound = _foundTargets.contains(point);
                  final item = _grid[index];
                  final showHint = _showingHint &&
                      item.isTarget &&
                      !_foundTargets.contains(point);

                  return _buildGridItem(index, item, isFound, showHint);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridItem(int index, GridItem item, bool isFound, bool showHint) {
    return GestureDetector(
      onTap: () => _onItemTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isFound
              ? AppTheme.correctAnswerColor.withOpacity(0.2)
              : showHint
                  ? Colors.amber.withOpacity(0.3)
                  : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isFound
                ? AppTheme.correctAnswerColor
                : showHint
                    ? Colors.amber
                    : Colors.grey.withOpacity(0.2),
            width: isFound || showHint ? 2 : 1,
          ),
          boxShadow: [
            if (isFound || showHint)
              BoxShadow(
                color: (isFound ? AppTheme.correctAnswerColor : Colors.amber)
                    .withOpacity(0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Center(
          child: Icon(
            item.variant.icon,
            color: item.color,
            size: 24,
          ),
        ),
      ).animate(
        effects: [
          if (isFound)
            const ShakeEffect(
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            ),
          // if (showHint)
          //   const PulseEffect(
          //     duration: Duration(seconds: 2),
          //     curve: Curves.easeInOut,
          //   ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _foundTargets.length / _targetCount,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryColor,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrationOverlay() {
    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, _) {
        return IgnorePointer(
          child: Stack(
            children: [
              // Overlay background
              Container(
                color: Colors.black
                    .withOpacity(0.3 * _celebrationController.value),
              ),

              // Confetti effect
              ...List.generate(40, (index) {
                final random = math.Random();
                final size = random.nextDouble() * 10 + 5;
                final color = _colors[random.nextInt(_colors.length)];
                final angle = random.nextDouble() * 2 * math.pi;
                final distance = random.nextDouble() * 300 + 50;
                final delay = random.nextDouble() * 0.5;

                return Positioned(
                  left: MediaQuery.of(context).size.width / 2,
                  top: MediaQuery.of(context).size.height / 2,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.8),
                      shape: random.nextBool()
                          ? BoxShape.circle
                          : BoxShape.rectangle,
                    ),
                  )
                      .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true),
                      )
                      .fadeIn(
                        delay: Duration(milliseconds: (delay * 1000).toInt()),
                        duration: const Duration(milliseconds: 500),
                      )
                      // .moveBy(
                      //   delay: Duration(milliseconds: (delay * 1000).toInt()),
                      //   duration: const Duration(seconds: 2),
                      //   begin: const Offset(0, 0),
                      //   end: Offset(
                      //     math.cos(angle) * distance,
                      //     math.sin(angle) * distance,
                      //   ),
                      // )
                      .rotate(
                        duration: const Duration(seconds: 1),
                        begin: 0,
                        end: random.nextDouble() * 2 * math.pi,
                      ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../theme/app_theme.dart';
import '../components/game_container.dart';

class FlowConnectGame extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final Function(int score) onScoreUpdate;
  final VoidCallback onComplete;

  const FlowConnectGame({
    super.key,
    required this.gameData,
    required this.onScoreUpdate,
    required this.onComplete,
  });

  @override
  State<FlowConnectGame> createState() => _FlowConnectGameState();
}

class _FlowConnectGameState extends State<FlowConnectGame> {
  late FlowLevel level;
  late List<List<CellData>> grid;
  late List<FlowPath> paths;
  late List<Color> colors;
  FlowPath? currentPath;
  bool isComplete = false;
  int moves = 0;
  int score = 1000;
  int timeRemaining = 0;
  int currentLevel = 0;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _startTimer();
  }

  void _initializeGame() {
    String difficulty = 'easy';
    if (currentLevel < 3) {
      level = FlowLevels.getLevel(difficulty, currentLevel);
    } else if (currentLevel < 6) {
      difficulty = 'medium';
      level = FlowLevels.getLevel(difficulty, currentLevel - 3);
    } else {
      difficulty = 'hard';
      level = FlowLevels.getLevel(difficulty, currentLevel - 6);
    }

    timeRemaining = level.timeLimit;
    colors = FlowLevels.levelColors;

    // Initialize empty grid
    grid = List.generate(
      level.gridSize,
      (y) => List.generate(
        level.gridSize,
        (x) => CellData(x: x, y: y),
      ),
    );

    // Place endpoints from level definition
    for (final pointPair in level.points) {
      for (final point in pointPair) {
        grid[point.y][point.x].color = FlowLevels.levelColors[point.colorIndex];
        grid[point.y][point.x].isEndpoint = true;
      }
    }

    // Place obstacles
    for (final obstacle in level.obstacles) {
      grid[obstacle.y][obstacle.x].isObstacle = true;
    }

    paths = [];
  }

  void _placePairs() {
    final random = math.Random();
    final gridSize = level.gridSize;
    final numPairs = 4;

    for (int i = 0; i < numPairs; i++) {
      // Place first endpoint
      int x1, y1, x2, y2;
      do {
        x1 = random.nextInt(gridSize);
        y1 = random.nextInt(gridSize);
      } while (grid[y1][x1].color != null);

      // Place second endpoint
      do {
        x2 = random.nextInt(gridSize);
        y2 = random.nextInt(gridSize);
      } while (grid[y2][x2].color != null || (x1 == x2 && y1 == y2));

      grid[y1][x1].color = colors[i];
      grid[y1][x1].isEndpoint = true;
      grid[y2][x2].color = colors[i];
      grid[y2][x2].isEndpoint = true;
    }
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || isComplete) return;

      setState(() {
        timeRemaining--;
        if (timeRemaining <= 0) {
          _handleTimeout();
        } else {
          _startTimer();
        }
      });
    });
  }

  void _handleTimeout() {
    // Handle game over due to time running out
    widget.onComplete();
  }

  void _onPanStart(DragStartDetails details) {
    final pos = _getGridPosition(details.localPosition);
    if (!_isValidPosition(pos)) return;

    final cell = grid[pos.dy.toInt()][pos.dx.toInt()];
    if (cell.color == null || !cell.isEndpoint) return;

    // Remove existing path for this color if it exists
    paths.removeWhere((path) => path.color == cell.color);

    setState(() {
      currentPath = FlowPath(
        color: cell.color!,
        points: [pos],
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (currentPath == null) return;

    final pos = _getGridPosition(details.localPosition);
    if (!_isValidPosition(pos)) return;

    // Only add point if it's adjacent to last point
    final lastPoint = currentPath!.points.last;
    if (!_isAdjacent(lastPoint, pos)) return;

    // Don't allow crossing other paths except at endpoints
    if (!_canMoveTo(pos)) return;

    setState(() {
      if (pos != currentPath!.points.last) {
        currentPath!.points.add(pos);
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (currentPath == null) return;

    final lastPoint = currentPath!.points.last;
    final lastCell = grid[lastPoint.dy.toInt()][lastPoint.dx.toInt()];

    // Check if path ends at matching endpoint
    if (lastCell.color == currentPath!.color && lastCell.isEndpoint) {
      setState(() {
        paths.add(currentPath!);
        _checkCompletion();
      });
    }

    setState(() {
      currentPath = null;
    });
  }

  void _checkCompletion() {
    // Count unique colors in paths
    final connectedColors = paths.map((p) => p.color).toSet();
    final totalColors = grid
        .expand((row) => row)
        .where((cell) => cell.isEndpoint && !cell.isObstacle)
        .map((cell) => cell.color)
        .toSet();

    if (connectedColors.length == totalColors.length) {
      isComplete = true;
      score = _calculateScore();
      widget.onScoreUpdate(score);

      if (currentLevel < 8) {
        currentLevel++;
        _initializeGame();
        _startTimer();
      } else {
        widget.onComplete();
      }
    }
  }

  int _calculateScore() {
    return math.max(0, 1000 - (moves * 10));
  }

  bool _isValidPosition(Offset pos) {
    return pos.dx >= 0 &&
        pos.dx < level.gridSize &&
        pos.dy >= 0 &&
        pos.dy < level.gridSize;
  }

  bool _isAdjacent(Offset a, Offset b) {
    return (a.dx - b.dx).abs() + (a.dy - b.dy).abs() == 1;
  }

  bool _canMoveTo(Offset pos) {
    final lastPoint = currentPath!.points.last;
    final cell = grid[pos.dy.toInt()][pos.dx.toInt()];

    if (cell.isObstacle) {
      return false; // Cannot move through obstacles
    }

    // Prevent moving back onto our own path
    if (currentPath!.points.contains(pos)) {
      return false; // disallow stepping on previously visited cells in the current path
    }

    if (cell.isEndpoint && cell.color == currentPath!.color) {
      return true;
    }

    if (cell.color != null && cell.color != currentPath!.color) {
      return false;
    }

    if (cell.color == null && paths.any((path) => path.points.contains(pos))) {
      return false;
    }

    return true;
  }

  Offset _getGridPosition(Offset localPosition) {
    final cellSize = MediaQuery.of(context).size.width / level.gridSize;
    return Offset(
      (localPosition.dx / cellSize).floorToDouble(),
      (localPosition.dy / cellSize).floorToDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameContainer(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: _buildGameBoard(),
              ),
            ),
          ),
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
                'Flow Connect',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Connect matching colors',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () {
              _initializeGame();
            },
            child: Container(
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
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameBoard() {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: CustomPaint(
        painter: FlowGridPainter(
          grid: grid,
          paths: paths,
          currentPath: currentPath,
          gridSize: level.gridSize,
        ),
      ),
    );
  }
}

class CellData {
  final int x;
  final int y;
  Color? color;
  bool isEndpoint;
  bool isObstacle;

  CellData({
    required this.x,
    required this.y,
    this.color,
    this.isEndpoint = false,
    this.isObstacle = false,
  });
}

class FlowPath {
  final Color color;
  final List<Offset> points;

  FlowPath({
    required this.color,
    required this.points,
  });
}

class FlowGridPainter extends CustomPainter {
  final List<List<CellData>> grid;
  final List<FlowPath> paths;
  final FlowPath? currentPath;
  final int gridSize;

  FlowGridPainter({
    required this.grid,
    required this.paths,
    required this.currentPath,
    required this.gridSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / gridSize;

    // Draw grid
    final gridPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i <= gridSize; i++) {
      final pos = i * cellSize;
      canvas.drawLine(
        Offset(pos, 0),
        Offset(pos, size.height),
        gridPaint,
      );
      canvas.drawLine(
        Offset(0, pos),
        Offset(size.width, pos),
        gridPaint,
      );
    }

    // Draw completed paths
    final pathPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = cellSize * 0.3
      ..strokeCap = StrokeCap.round;

    for (final path in paths) {
      pathPaint.color = path.color.withOpacity(0.5);
      _drawPath(canvas, path.points, cellSize, pathPaint);
    }

    // Draw current path
    if (currentPath != null) {
      pathPaint.color = currentPath!.color.withOpacity(0.5);
      _drawPath(canvas, currentPath!.points, cellSize, pathPaint);
    }

    // Draw endpoints
    final dotPaint = Paint()..style = PaintingStyle.fill;

    for (final row in grid) {
      for (final cell in row) {
        if (cell.isEndpoint && cell.color != null) {
          dotPaint.color = cell.color!;
          canvas.drawCircle(
            Offset(
              (cell.x + 0.5) * cellSize,
              (cell.y + 0.5) * cellSize,
            ),
            cellSize * 0.3,
            dotPaint,
          );
        }
      }
    }

    // Draw obstacles
    final obstaclePaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.fill;

    for (final row in grid) {
      for (final cell in row) {
        if (cell.isObstacle) {
          canvas.drawRect(
            Rect.fromLTWH(
              cell.x * cellSize,
              cell.y * cellSize,
              cellSize,
              cellSize,
            ),
            obstaclePaint,
          );

          // Draw diagonal lines for obstacles
          final linePaint = Paint()
            ..color = Colors.grey.shade600
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0;

          final x = cell.x * cellSize;
          final y = cell.y * cellSize;
          final x2 = x + cellSize;
          final y2 = y + cellSize;

          canvas.drawLine(
            Offset(x, y),
            Offset(x2, y2),
            linePaint,
          );

          canvas.drawLine(
            Offset(x2, y),
            Offset(x, y2),
            linePaint,
          );
        }
      }
    }
  }

  void _drawPath(
      Canvas canvas, List<Offset> points, double cellSize, Paint paint) {
    if (points.isEmpty) return;

    final path = Path();
    path.moveTo(
      (points[0].dx + 0.5) * cellSize,
      (points[0].dy + 0.5) * cellSize,
    );

    for (int i = 1; i < points.length; i++) {
      path.lineTo(
        (points[i].dx + 0.5) * cellSize,
        (points[i].dy + 0.5) * cellSize,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(FlowGridPainter oldDelegate) => true;
}

class FlowLevel {
  final List<List<LevelPoint>> points;
  final int gridSize;
  final String difficulty;
  final int timeLimit;
  final String description;
  final List<LevelPoint> obstacles;

  const FlowLevel({
    required this.points,
    required this.gridSize,
    required this.difficulty,
    required this.timeLimit,
    required this.description,
    this.obstacles = const [],
  });
}

class LevelPoint {
  final int x;
  final int y;
  final int colorIndex;

  const LevelPoint(this.x, this.y, this.colorIndex);
}

class FlowLevels {
  static const List<Color> levelColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.pink,
  ];

  static final List<FlowLevel> easyLevels = [
    const FlowLevel(
      points: [
        [LevelPoint(0, 0, 0), LevelPoint(3, 2, 0)], // Red
        [LevelPoint(2, 1, 1), LevelPoint(4, 0, 1)], // Blue
        [LevelPoint(0, 1, 3), LevelPoint(3, 1, 3)], // Yellow
        [LevelPoint(0, 4, 2), LevelPoint(4, 4, 2)], // Green
      ],
      gridSize: 5,
      difficulty: 'easy',
      timeLimit: 60,
      description: 'Connect matching colors! (Easy)',
    ),
    const FlowLevel(
      points: [
        [LevelPoint(0, 0, 1), LevelPoint(1, 2, 1)], // Red - Blue
        [LevelPoint(0, 2, 3), LevelPoint(3, 1, 3)], // Green - Yellow
        [
          LevelPoint(1, 0, 4),
          LevelPoint(1, 3, 4)
        ], // Red - Blue (opposite side)
        [LevelPoint(3, 0, 2), LevelPoint(4, 4, 2)], // Green - Blue
      ],
      gridSize: 5,
      difficulty: 'easy',
      timeLimit: 75,
      description: 'Connect matching colors! (Easy)',
    ),
    const FlowLevel(
      points: [
        [LevelPoint(0, 0, 1), LevelPoint(1, 4, 1)], // Blue
        [LevelPoint(2, 1, 0), LevelPoint(3, 2, 0)], // Red
        [LevelPoint(4, 0, 2), LevelPoint(4, 4, 2)], // Green
      ],
      gridSize: 5,
      difficulty: 'easy',
      timeLimit: 90,
      description: 'Connect matching colors! (Easy)',
      obstacles: [
        LevelPoint(2, 2, -1),
      ],
    ),
  ];

  static final List<FlowLevel> mediumLevels = [
    const FlowLevel(
      points: [
        [LevelPoint(0, 0, 0), LevelPoint(5, 5, 0)], // Red
        [LevelPoint(0, 5, 1), LevelPoint(5, 0, 1)], // Blue
        [LevelPoint(2, 2, 2), LevelPoint(3, 3, 2)], // Green
        [LevelPoint(2, 3, 3), LevelPoint(3, 2, 3)], // Yellow
        [LevelPoint(0, 2, 4), LevelPoint(5, 3, 4)], // Purple
      ],
      gridSize: 6,
      difficulty: 'medium',
      timeLimit: 120,
      description: 'Five color challenge',
    ),
    const FlowLevel(
      points: [
        [LevelPoint(0, 0, 0), LevelPoint(4, 4, 0)], // Red
        [LevelPoint(1, 1, 1), LevelPoint(3, 3, 1)], // Blue
        [LevelPoint(2, 0, 2), LevelPoint(2, 4, 2)], // Green
        [LevelPoint(0, 2, 3), LevelPoint(4, 2, 3)], // Yellow
        [LevelPoint(1, 3, 4), LevelPoint(3, 1, 4)], // Purple
      ],
      gridSize: 5,
      difficulty: 'medium',
      timeLimit: 150,
      description: 'Interweaved paths',
    ),
    const FlowLevel(
      points: [
        [LevelPoint(0, 0, 0), LevelPoint(5, 5, 0)], // Red
        [LevelPoint(5, 0, 1), LevelPoint(0, 5, 1)], // Blue
        [LevelPoint(2, 0, 2), LevelPoint(3, 5, 2)], // Green
        [LevelPoint(0, 2, 3), LevelPoint(5, 3, 3)], // Yellow
        [LevelPoint(2, 2, 4), LevelPoint(3, 3, 4)], // Purple
      ],
      gridSize: 6,
      difficulty: 'medium',
      timeLimit: 180,
      description: 'Complex crossings',
    ),
  ];

  static final List<FlowLevel> hardLevels = [
    const FlowLevel(
      points: [
        [LevelPoint(0, 0, 0), LevelPoint(6, 6, 0)], // Red
        [LevelPoint(0, 6, 1), LevelPoint(6, 0, 1)], // Blue
        [LevelPoint(3, 0, 2), LevelPoint(3, 6, 2)], // Green
        [LevelPoint(0, 3, 3), LevelPoint(6, 3, 3)], // Yellow
        [LevelPoint(2, 2, 4), LevelPoint(4, 4, 4)], // Purple
      ],
      gridSize: 7,
      difficulty: 'hard',
      timeLimit: 240,
      description: 'Obstacle course',
      obstacles: [
        LevelPoint(3, 3, -1),
        LevelPoint(2, 4, -1),
        LevelPoint(4, 2, -1),
      ],
    ),
    const FlowLevel(
      points: [
        [LevelPoint(0, 0, 0), LevelPoint(5, 5, 0)], // Red
        [LevelPoint(0, 5, 1), LevelPoint(5, 0, 1)], // Blue
        [LevelPoint(2, 0, 2), LevelPoint(3, 5, 2)], // Green
        [LevelPoint(0, 2, 3), LevelPoint(5, 3, 3)], // Yellow
        [LevelPoint(1, 1, 4), LevelPoint(4, 4, 4)], // Purple
      ],
      gridSize: 6,
      difficulty: 'hard',
      timeLimit: 300,
      description: 'Strategic blocks',
      obstacles: [
        LevelPoint(2, 2, -1),
        LevelPoint(3, 3, -1),
        LevelPoint(2, 3, -1),
        LevelPoint(3, 2, -1),
      ],
    ),
    const FlowLevel(
      points: [
        [LevelPoint(0, 0, 0), LevelPoint(7, 7, 0)], // Red
        [LevelPoint(7, 0, 1), LevelPoint(0, 7, 1)], // Blue
        [LevelPoint(3, 0, 2), LevelPoint(4, 7, 2)], // Green
        [LevelPoint(0, 3, 3), LevelPoint(7, 4, 3)], // Yellow
        [LevelPoint(2, 2, 4), LevelPoint(5, 5, 4)], // Purple
        [LevelPoint(5, 2, 5), LevelPoint(2, 5, 5)], // Orange
      ],
      gridSize: 8,
      difficulty: 'hard',
      timeLimit: 360,
      description: 'Master challenge',
      obstacles: [
        LevelPoint(3, 3, -1),
        LevelPoint(3, 4, -1),
        LevelPoint(4, 3, -1),
        LevelPoint(4, 4, -1),
        LevelPoint(1, 1, -1),
        LevelPoint(6, 6, -1),
      ],
    ),
  ];

  static FlowLevel getLevel(String difficulty, int index) {
    switch (difficulty) {
      case 'easy':
        return easyLevels[index];
      case 'medium':
        return mediumLevels[index];
      case 'hard':
        return hardLevels[index];
      default:
        return easyLevels[index];
    }
  }
}

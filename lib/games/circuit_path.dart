import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:math' as math;

import '../components/game_container.dart';
import '../components/header_container.dart';
import '../theme/app_theme.dart';

class CircuitPathGame extends ConsumerStatefulWidget {
  final Map<String, dynamic> gameData;
  final Function(int score) onScoreUpdate;
  final VoidCallback onComplete;

  const CircuitPathGame({
    super.key,
    required this.gameData,
    required this.onScoreUpdate,
    required this.onComplete,
  });

  @override
  ConsumerState<CircuitPathGame> createState() => _CircuitPathGameState();
}

class _CircuitPathGameState extends ConsumerState<CircuitPathGame> {
  late List<List<CircuitTile>> grid;
  late Point startPoint;
  late Point endPoint;
  late int gridSize;
  int moves = 0;
  int score = 1000;
  bool isComplete = false;
  List<Point> currentPath = [];
  bool isAnimating = false;

  bool isShowingHint = false;
  bool isSimulating = false;
  List<int> correctRotations = [];
  int hintsRemaining = 3;

  @override
  void initState() {
    super.initState();
    gridSize = 7; //widget.gameData['gridSize'] ?? 7;
    _initializeGrid();
  }

  void _showSolutionHint() {
    //if (hintsRemaining <= 0) return;

    setState(() {
      hintsRemaining--;
      isShowingHint = true;

      // Store current rotations
      final currentRotations =
          grid.expand((row) => row.map((tile) => tile.rotation)).toList();

      // Temporarily set rotations to solution
      for (int i = 0; i < grid.length; i++) {
        for (int j = 0; j < grid[i].length; j++) {
          grid[i][j].rotation = correctRotations[i * gridSize + j];
        }
      }

      // Reset after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            isShowingHint = false;
            // Restore original rotations
            int index = 0;
            for (int i = 0; i < grid.length; i++) {
              for (int j = 0; j < grid[i].length; j++) {
                grid[i][j].rotation = currentRotations[index++];
              }
            }
          });
        }
      });

      // Apply score penalty for using hint
      score = math.max(0, score - 50);
      widget.onScoreUpdate(score);
    });
  }

  void _startSimulation() {
    if (isSimulating) return;

    setState(() {
      isSimulating = true;
      _checkSolution();
    });
  }

  void _checkSolution() {
    // Implementation for checking if the current circuit is correct
    // Compare current rotations with correctRotations
    bool isCorrect = true;
    for (int i = 0; i < grid.length; i++) {
      for (int j = 0; j < grid[i].length; j++) {
        if (grid[i][j].rotation != correctRotations[i * gridSize + j]) {
          isCorrect = false;
          break;
        }
      }
      if (!isCorrect) break;
    }

    setState(() {
      if (isCorrect) {
        isComplete = true;
        widget.onComplete();
      }
      isSimulating = false;
    });
  }

  void _initializeGrid() {
    grid = List.generate(
      gridSize,
      (y) => List.generate(
        gridSize,
        (x) => CircuitTile(
          type: TileType.empty,
          rotation: math.Random().nextInt(4) * 90,
        ),
      ),
    );

    startPoint = Point(0, gridSize ~/ 2);
    endPoint = Point(gridSize - 1, gridSize ~/ 2);

    // Set start and end tiles
    grid[startPoint.y][startPoint.x] = CircuitTile(
      type: TileType.start,
      isLocked: true,
    );
    grid[endPoint.y][endPoint.x] = CircuitTile(
      type: TileType.end,
      isLocked: true,
    );

    // Add random circuit pieces
    _addRandomCircuitPieces();

    // Initialize solution
    _initializeSolution();
  }

  void _initializeSolution() {
    correctRotations = [];
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        correctRotations.add(grid[y][x].rotation);
      }
    }

    // Randomly rotate tiles to create the puzzle
    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (!grid[y][x].isLocked) {
          grid[y][x].rotation = math.Random().nextInt(4) * 90;
        }
      }
    }
  }

  void _addRandomCircuitPieces() {
    final types = [
      TileType.straight,
      TileType.corner,
      TileType.tJunction,
      TileType.cross,
    ];

    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        if (grid[y][x].type == TileType.empty) {
          grid[y][x] = CircuitTile(
            type: types[math.Random().nextInt(types.length)],
            rotation: math.Random().nextInt(4) * 90,
          );
        }
      }
    }
  }

  void _rotateTile(int x, int y) {
    if (isComplete || isAnimating) return;
    if (grid[y][x].isLocked) return;

    setState(() {
      grid[y][x].rotate();
      moves++;
      _checkPath();
    });
  }

  void _checkPath() {
    currentPath = [];
    bool isValidPath = _findPath(startPoint, Direction.right);

    if (isValidPath) {
      setState(() {
        isComplete = true;
        score = _calculateScore();
        _animateSuccess();
      });
    }
  }

  bool _findPath(Point current, Direction fromDirection) {
    if (!_isValidPoint(current)) return false;
    if (current == endPoint) {
      return grid[current.y][current.x].canConnect(fromDirection);
    }

    final tile = grid[current.y][current.x];
    if (!tile.canConnect(fromDirection)) return false;

    currentPath.add(current);

    final nextDirections = _getNextDirections(tile, fromDirection);
    for (final direction in nextDirections) {
      final next = _getNextPoint(current, direction);
      if (_findPath(next, direction)) return true;
    }

    currentPath.removeLast();
    return false;
  }

  List<Direction> _getNextDirections(
    CircuitTile tile,
    Direction fromDirection,
  ) {
    final normalizedFrom = _normalizeDirection(fromDirection, tile.rotation);
    final directions = <Direction>[];

    switch (tile.type) {
      case TileType.straight:
        if (normalizedFrom == Direction.up) directions.add(Direction.down);
        if (normalizedFrom == Direction.down) directions.add(Direction.up);
        break;
      case TileType.corner:
        if (normalizedFrom == Direction.left) directions.add(Direction.up);
        if (normalizedFrom == Direction.down) directions.add(Direction.right);
        break;
      case TileType.tJunction:
        if (normalizedFrom != Direction.left) {
          directions.addAll([
            Direction.up,
            Direction.right,
            Direction.down,
          ]..remove(_opposite(normalizedFrom)));
        }
        break;
      case TileType.cross:
        directions.addAll(Direction.values..remove(_opposite(normalizedFrom)));
        break;
      default:
        break;
    }

    return directions.map((d) => _rotateDirection(d, -tile.rotation)).toList();
  }

  Direction _normalizeDirection(Direction direction, int rotation) {
    final normalized = (direction.index - (rotation ~/ 90)) % 4;
    return Direction.values[normalized];
  }

  Direction _opposite(Direction direction) {
    return Direction.values[(direction.index + 2) % 4];
  }

  Direction _rotateDirection(Direction direction, int rotation) {
    final rotated = (direction.index + (rotation ~/ 90)) % 4;
    return Direction.values[rotated];
  }

  Point _getNextPoint(Point current, Direction direction) {
    switch (direction) {
      case Direction.up:
        return Point(current.x, current.y - 1);
      case Direction.right:
        return Point(current.x + 1, current.y);
      case Direction.down:
        return Point(current.x, current.y + 1);
      case Direction.left:
        return Point(current.x - 1, current.y);
    }
  }

  bool _isValidPoint(Point p) {
    return p.x >= 0 && p.x < gridSize && p.y >= 0 && p.y < gridSize;
  }

  int _calculateScore() {
    return math.max(0, 1000 - (moves * 10));
  }

  void _animateSuccess() {
    setState(() => isAnimating = true);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        widget.onScoreUpdate(score);
        widget.onComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameContainer(
      child: Column(
        children: [
          Divider(height: 0, color: Colors.grey.withOpacity(0.3)),
          _buildHeader(),
          Expanded(
            child: Center(
              child: _buildGrid(),
            ),
          ),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return HeaderContainer(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Circuit Path',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Connect start to end',
                style: GoogleFonts.poppins(
                  fontSize: 14,
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

  Widget _buildGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridSize,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: gridSize * gridSize,
          itemBuilder: (context, index) {
            final x = index % gridSize;
            final y = index ~/ gridSize;
            return _buildTile(x, y);
          },
        ),
      ),
    );
  }

  Widget _buildTile(int x, int y) {
    final tile = grid[y][x];
    final isInPath = currentPath.contains(Point(x, y));

    return GestureDetector(
      onTap: () => _rotateTile(x, y),
      child: Container(
        decoration: BoxDecoration(
          color: isInPath
              ? AppTheme.correctAnswerColor.withOpacity(0.2)
              : Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: TweenAnimationBuilder(
          duration: const Duration(milliseconds: 300),
          tween: Tween<double>(
            begin: (tile.rotation - 90) / 360,
            end: tile.rotation / 360,
          ),
          builder: (context, double value, child) {
            return Transform.rotate(
              angle: value * 2 * math.pi,
              child: CustomPaint(
                painter: CircuitTilePainter(
                  type: tile.type,
                  isLocked: tile.isLocked,
                  isInPath: isInPath,
                  isAnimating: isAnimating && isInPath,
                ),
              ),
            );
          },
        ),
      ).animate(
        effects: [
          if (isAnimating && isInPath)
            const ShakeEffect(
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: !isSimulating ? _startSimulation : null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: _showSolutionHint,
            icon: const Icon(Icons.lightbulb),
            label: Text('Hint ($hintsRemaining)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: isSimulating
                ? null
                : () {
                    setState(() {
                      _initializeGrid();
                      isSimulating = false;
                      isComplete = false;
                      hintsRemaining = 3;
                      score = 0;
                      moves = 0;
                    });
                  },
            icon: const Icon(Icons.refresh),
            label: const Text('Reset'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

enum TileType { empty, straight, corner, tJunction, cross, start, end }

enum Direction { up, right, down, left }

class CircuitTile {
  final TileType type;
  int rotation;
  final bool isLocked;

  CircuitTile({
    required this.type,
    this.rotation = 0,
    this.isLocked = false,
  });

  void rotate() {
    if (!isLocked) rotation = (rotation + 90) % 360;
  }

  bool canConnect(Direction direction) {
    switch (type) {
      case TileType.straight:
        return direction == Direction.up || direction == Direction.down;
      case TileType.corner:
        return direction == Direction.left || direction == Direction.down;
      case TileType.tJunction:
        return true;
      case TileType.cross:
        return true;
      default:
        return false;
    }
  }
}

class CircuitTilePainter extends CustomPainter {
  final TileType type;
  final bool isLocked;
  final bool isInPath;
  final bool isAnimating;

  CircuitTilePainter({
    required this.type,
    required this.isLocked,
    required this.isInPath,
    required this.isAnimating,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = isInPath
          ? AppTheme.correctAnswerColor
          : isLocked
              ? AppTheme.primaryColor
              : AppTheme.secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    if (isAnimating) {
      paint.color = AppTheme.correctAnswerColor;
      paint.strokeWidth = 6;
    }

    switch (type) {
      case TileType.straight:
        _drawStraight(canvas, size, paint);
        break;
      case TileType.corner:
        _drawCorner(canvas, size, paint);
        break;
      case TileType.tJunction:
        _drawTJunction(canvas, size, paint);
        break;
      case TileType.cross:
        _drawCross(canvas, size, paint);
        break;
      case TileType.start:
        _drawStart(canvas, size, paint);
        break;
      case TileType.end:
        _drawEnd(canvas, size, paint);
        break;
      default:
        break;
    }
  }

  void _drawStraight(Canvas canvas, Size size, Paint paint) {
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  void _drawCorner(Canvas canvas, Size size, Paint paint) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width / 2, size.height / 2)
      ..lineTo(size.width, size.height / 2);
    canvas.drawPath(path, paint);
  }

  void _drawTJunction(Canvas canvas, Size size, Paint paint) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width / 2, size.height)
      ..moveTo(size.width / 2, size.height / 2)
      ..lineTo(size.width, size.height / 2);
    canvas.drawPath(path, paint);
  }

  void _drawCross(Canvas canvas, Size size, Paint paint) {
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  void _drawStart(Canvas canvas, Size size, Paint paint) {
    canvas.drawLine(
      Offset(size.width / 2, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    final iconPaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 3, size.height / 2),
      size.width / 6,
      iconPaint,
    );
  }

  _drawEnd(Canvas canvas, Size size, Paint paint) {
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width / 2, size.height / 2),
      paint,
    );

    final iconPaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.fill;

    final rect = Rect.fromCenter(
      center: Offset(2 * size.width / 3, size.height / 2),
      width: size.width / 3,
      height: size.width / 3,
    );
    canvas.drawRect(rect, iconPaint);
  }

  @override
  bool shouldRepaint(CircuitTilePainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.isLocked != isLocked ||
        oldDelegate.isInPath != isInPath ||
        oldDelegate.isAnimating != isAnimating;
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

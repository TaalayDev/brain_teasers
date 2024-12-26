import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../theme/app_theme.dart';
import 'game_controller.dart';

enum TileType {
  straight, // ║
  corner, // ╚
  tJunction, // ╠
  cross, // ╬
  empty, // □
  start, // ▶
  end // ◆
}

class CircuitTile {
  TileType type;
  int rotation; // 0, 90, 180, 270 degrees
  bool isEnergized;
  final bool isLocked;

  CircuitTile({
    required this.type,
    this.rotation = 0,
    this.isEnergized = false,
    this.isLocked = false,
  });

  void rotate() {
    if (!isLocked) {
      rotation = (rotation + 90) % 360;
    }
  }

  bool canConnect(Direction direction) {
    final normalizedDirection =
        Direction.values[(direction.index - (rotation ~/ 90)) % 4];

    switch (type) {
      case TileType.straight:
        return normalizedDirection == Direction.up ||
            normalizedDirection == Direction.down;
      case TileType.corner:
        return normalizedDirection == Direction.up ||
            normalizedDirection == Direction.right;
      case TileType.tJunction:
        return normalizedDirection != Direction.left;
      case TileType.cross:
        return true;
      case TileType.empty:
        return false;
      case TileType.start:
        return normalizedDirection == Direction.right;
      case TileType.end:
        return normalizedDirection == Direction.left;
    }
  }
}

enum Direction {
  up,
  right,
  down,
  left,
}

class CircuitFlowGame extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final GameController gameController;

  const CircuitFlowGame({
    super.key,
    required this.gameData,
    required this.gameController,
  });

  @override
  State<CircuitFlowGame> createState() => _CircuitFlowGameState();
}

class _CircuitFlowGameState extends State<CircuitFlowGame> {
  late List<List<CircuitTile>> grid;
  late int gridSize;
  int moves = 0;
  int score = 0;
  bool isComplete = false;
  Point startPoint = Point(0, 0); // Default starting point
  Point endPoint = Point(0, 0);

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    gridSize = widget.gameData['gridSize'] ?? 6;
    grid = _generateGrid();
    _findStartAndEnd();
    _checkCircuit();
  }

  List<List<CircuitTile>> _generateGrid() {
    final random = math.Random();
    final grid = List.generate(
      gridSize,
      (y) => List.generate(
        gridSize,
        (x) => CircuitTile(
          type: TileType.empty,
          rotation: random.nextInt(4) * 90,
        ),
      ),
    );

    // Place start and end points
    grid[0][0] = CircuitTile(type: TileType.start, isLocked: true);
    grid[gridSize - 1][gridSize - 1] =
        CircuitTile(type: TileType.end, isLocked: true);

    // Generate random path
    _generatePath(grid);

    return grid;
  }

  void _generatePath(List<List<CircuitTile>> grid) {
    final random = math.Random();
    var current = Point(0, 0);
    final end = Point(gridSize - 1, gridSize - 1);
    final path = <Point>[current];

    while (current != end) {
      final possibleMoves = _getValidMoves(current, path);
      if (possibleMoves.isEmpty) break;

      final next = possibleMoves[random.nextInt(possibleMoves.length)];
      _placeTile(grid, current, next);
      path.add(next);
      current = next;
    }

    // Fill remaining empty spaces with random tiles
    for (var y = 0; y < gridSize; y++) {
      for (var x = 0; x < gridSize; x++) {
        if (grid[y][x].type == TileType.empty) {
          grid[y][x] = CircuitTile(
            type: TileType.values[random.nextInt(4)],
            rotation: random.nextInt(4) * 90,
          );
        }
      }
    }
  }

  List<Point> _getValidMoves(Point current, List<Point> path) {
    final moves = <Point>[];
    final directions = [
      Point(0, -1), // up
      Point(1, 0), // right
      Point(0, 1), // down
      Point(-1, 0), // left
    ];

    for (final dir in directions) {
      final next = Point(
        current.x + dir.x,
        current.y + dir.y,
      );

      if (_isValidPoint(next) && !path.contains(next)) {
        moves.add(next);
      }
    }

    return moves;
  }

  void _placeTile(List<List<CircuitTile>> grid, Point current, Point next) {
    final dx = next.x - current.x;
    final dy = next.y - current.y;

    TileType tileType;
    int rotation = 0;

    if (dx.abs() + dy.abs() == 1) {
      if (dx.abs() == 1) {
        tileType = TileType.straight;
        rotation = 90;
      } else {
        tileType = TileType.straight;
        rotation = 0;
      }
    } else {
      tileType = TileType.corner;
      if (dx == 1 && dy == -1) rotation = 0;
      if (dx == 1 && dy == 1) rotation = 270;
      if (dx == -1 && dy == 1) rotation = 180;
      if (dx == -1 && dy == -1) rotation = 90;
    }

    grid[current.y][current.x] = CircuitTile(
      type: tileType,
      rotation: rotation,
    );
  }

  bool _isValidPoint(Point p) {
    return p.x >= 0 && p.x < gridSize && p.y >= 0 && p.y < gridSize;
  }

  void _findStartAndEnd() {
    for (var y = 0; y < gridSize; y++) {
      for (var x = 0; x < gridSize; x++) {
        if (grid[y][x].type == TileType.start) {
          startPoint = Point(x, y);
        } else if (grid[y][x].type == TileType.end) {
          endPoint = Point(x, y);
        }
      }
    }
  }

  void _onTileTap(int x, int y) {
    if (isComplete) return;

    setState(() {
      grid[y][x].rotate();
      moves++;
      _checkCircuit();
    });
  }

  void _checkCircuit() {
    // Reset energized state
    for (var row in grid) {
      for (var tile in row) {
        tile.isEnergized = false;
      }
    }

    // Start from start point and follow the path
    bool isValidCircuit = _followCircuit(startPoint, Direction.right);

    if (isValidCircuit && !isComplete) {
      setState(() {
        isComplete = true;
        score = _calculateScore();
        widget.gameController.updateScore(score);
        widget.gameController.completeGame();
      });
    }
  }

  bool _followCircuit(Point current, Direction fromDirection) {
    if (!_isValidPoint(current)) return false;
    if (grid[current.y][current.x].type == TileType.end) {
      return grid[current.y][current.x].canConnect(fromDirection);
    }

    final tile = grid[current.y][current.x];
    if (!tile.canConnect(fromDirection)) return false;
    tile.isEnergized = true;

    final nextDirections = _getNextDirections(tile, fromDirection);
    for (final direction in nextDirections) {
      final next = _getNextPoint(current, direction);
      if (_followCircuit(next, direction)) return true;
    }

    tile.isEnergized = false;
    return false;
  }

  List<Direction> _getNextDirections(
      CircuitTile tile, Direction fromDirection) {
    // Implementation of getting possible next directions based on tile type and rotation
    // Returns list of valid directions
    return [Direction.right]; // Simplified for this example
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

  int _calculateScore() {
    final baseScore = 1000;
    final movesPenalty = moves * 10;
    return math.max(0, baseScore - movesPenalty);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Center(
            child: _buildGrid(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Moves: $moves',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Score: $score',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridSize,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: gridSize * gridSize,
      itemBuilder: (context, index) {
        final x = index % gridSize;
        final y = index ~/ gridSize;
        return _buildTile(x, y);
      },
    );
  }

  Widget _buildTile(int x, int y) {
    final tile = grid[y][x];

    return GestureDetector(
      onTap: () => _onTileTap(x, y),
      child: Transform.rotate(
        angle: tile.rotation * math.pi / 180,
        child: Container(
          decoration: BoxDecoration(
            color: tile.isEnergized
                ? AppTheme.correctAnswerColor
                : AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: _getTileIcon(tile.type),
          ),
        ),
      ).animate().scale(
            duration: const Duration(milliseconds: 200),
          ),
    );
  }

  Widget _getTileIcon(TileType type) {
    switch (type) {
      case TileType.straight:
        return const Icon(Icons.drag_handle, color: Colors.white);
      case TileType.corner:
        return const Icon(Icons.turn_right, color: Colors.white);
      case TileType.tJunction:
        return const Icon(Icons.account_tree, color: Colors.white);
      case TileType.cross:
        return const Icon(Icons.add, color: Colors.white);
      case TileType.empty:
        return const Icon(Icons.block, color: Colors.white);
      case TileType.start:
        return const Icon(Icons.play_arrow, color: Colors.white);
      case TileType.end:
        return const Icon(Icons.stop, color: Colors.white);
    }
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

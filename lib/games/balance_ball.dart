import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class BalanceBallGame extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final Function(int score) onScoreUpdate;
  final VoidCallback onComplete;

  const BalanceBallGame({
    super.key,
    required this.gameData,
    required this.onScoreUpdate,
    required this.onComplete,
  });

  @override
  State<BalanceBallGame> createState() => _BalanceBallGameState();
}

class _BalanceBallGameState extends State<BalanceBallGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late double ballX;
  late double ballY;
  late double velocityX;
  late double velocityY;
  late bool isGameOver;
  late int score;
  late int time;
  Timer? gameTimer;
  Timer? physicsTimer;
  late List<Obstacle> obstacles;
  late Point goal;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  // Physics constants
  late final double gravity = 0.1; //widget.gameData['gravity'] ?? 9.81;
  late final double friction = widget.gameData['friction'] ?? 0.01;
  final double ballRadius = 10.0;
  final double maxVelocity = 20.0;
  final double accelerometerSensitivity = 2.0;

  double accelerometerX = 0.0;
  double accelerometerY = 0.0;

  final double bounceCoefficient = 0.7; // Controls how bouncy collisions are
  final double collisionPadding = 0.02; // Small buffer for collision detection

  // Maze parameters
  final int mazeRows = 10;
  final int mazeCols = 10;
  late List<List<Cell>> mazeGrid;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _initializeGame();
  }

  void _initializeGame() {
    ballX = -1.0 + (1.0 / mazeCols); // Start near the top-left corner
    ballY = -1.0 + (1.0 / mazeRows);
    velocityX = 0.0;
    velocityY = 0.0;
    isGameOver = false;
    score = 0;
    time = 0;

    mazeGrid = _generateMaze(mazeRows, mazeCols);
    obstacles = _generateObstaclesFromMaze(mazeGrid);
    goal = _placeGoalInMaze();

    // Start timers
    gameTimer = Timer.periodic(const Duration(seconds: 1), _updateTime);
    physicsTimer = Timer.periodic(
      const Duration(milliseconds: 16), // ~60 FPS
      _updatePhysics,
    );

    // Listen to accelerometer
    _accelerometerSubscription = accelerometerEventStream().listen(
      _onAccelerometerEvent,
    );
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    setState(() {
      accelerometerX = event.x * accelerometerSensitivity;
      accelerometerY = event.y * accelerometerSensitivity;
    });
    // _updatePhysics(gameTimer!);
  }

  List<List<Cell>> _generateMaze(int rows, int cols) {
    List<List<Cell>> grid = List.generate(
      rows,
      (r) => List.generate(cols, (c) => Cell(row: r, col: c)),
    );

    Set<Cell> visited = {};
    List<Cell> stack = [];

    Cell current = grid[0][0];
    visited.add(current);

    while (true) {
      List<Cell> neighbors = _getUnvisitedNeighbors(current, grid, visited);
      if (neighbors.isNotEmpty) {
        Cell next = neighbors[Random().nextInt(neighbors.length)];
        _removeWallBetween(current, next);
        stack.add(current);
        current = next;
        visited.add(current);
      } else if (stack.isNotEmpty) {
        current = stack.removeLast();
      } else {
        break;
      }
    }

    return grid;
  }

  List<Cell> _getUnvisitedNeighbors(
    Cell cell,
    List<List<Cell>> grid,
    Set<Cell> visited,
  ) {
    List<Cell> neighbors = [];

    int row = cell.row;
    int col = cell.col;
    if (row > 0 && !visited.contains(grid[row - 1][col])) {
      neighbors.add(grid[row - 1][col]);
    }
    if (row < mazeRows - 1 && !visited.contains(grid[row + 1][col])) {
      neighbors.add(grid[row + 1][col]);
    }
    if (col > 0 && !visited.contains(grid[row][col - 1])) {
      neighbors.add(grid[row][col - 1]);
    }
    if (col < mazeCols - 1 && !visited.contains(grid[row][col + 1])) {
      neighbors.add(grid[row][col + 1]);
    }

    return neighbors;
  }

  void _removeWallBetween(Cell current, Cell next) {
    int dx = next.col - current.col;
    int dy = next.row - current.row;

    if (dx == 1) {
      // Next is to the right
      current.walls[1] = false;
      next.walls[3] = false;
    } else if (dx == -1) {
      // Next is to the left
      current.walls[3] = false;
      next.walls[1] = false;
    } else if (dy == 1) {
      // Next is below
      current.walls[2] = false;
      next.walls[0] = false;
    } else if (dy == -1) {
      // Next is above
      current.walls[0] = false;
      next.walls[2] = false;
    }
  }

  List<Obstacle> _generateObstaclesFromMaze(List<List<Cell>> maze) {
    List<Obstacle> obstacles = [];

    double cellWidth = 2.0 / mazeCols;
    double cellHeight = 2.0 / mazeRows;

    for (int r = 0; r < mazeRows; r++) {
      for (int c = 0; c < mazeCols; c++) {
        Cell cell = maze[r][c];
        double x = -1.0 + c * cellWidth;
        double y = -1.0 + r * cellHeight;

        // Top wall
        if (cell.walls[0]) {
          obstacles.add(Obstacle(
            x: x + cellWidth / 2,
            y: y,
            width: cellWidth,
            height: 0.01,
          ));
        }
        // Right wall
        if (cell.walls[1]) {
          obstacles.add(Obstacle(
            x: x + cellWidth,
            y: y + cellHeight / 2,
            width: 0.01,
            height: cellHeight,
          ));
        }
        // Bottom wall
        if (cell.walls[2]) {
          obstacles.add(Obstacle(
            x: x + cellWidth / 2,
            y: y + cellHeight,
            width: cellWidth,
            height: 0.01,
          ));
        }
        // Left wall
        if (cell.walls[3]) {
          obstacles.add(Obstacle(
            x: x,
            y: y + cellHeight / 2,
            width: 0.01,
            height: cellHeight,
          ));
        }
      }
    }

    return obstacles;
  }

  Point _placeGoalInMaze() {
    // Place the goal at the bottom-right corner
    double cellWidth = 2.0 / mazeCols;
    double cellHeight = 2.0 / mazeRows;

    double x = -1.0 + (mazeCols - 1) * cellWidth + cellWidth / 2;
    double y = -1.0 + (mazeRows - 1) * cellHeight + cellHeight / 2;

    return Point(x, y);
  }

  void _updateTime(Timer timer) {
    if (!isGameOver) {
      setState(() {
        time++;
        score = max(0, 1000 - time * 10);
        widget.onScoreUpdate(score);
      });
    }
  }

  void _updatePhysics(Timer timer) {
    if (isGameOver) return;

    setState(() {
      // Apply gravity based on accelerometer data
      final gravityX = -accelerometerX / gravity;
      final gravityY = accelerometerY / gravity;

      // Update velocities
      velocityX += gravityX * 0.016;
      velocityY += gravityY * 0.016;

      // Apply friction
      velocityX *= (1 - friction);
      velocityY *= (1 - friction);

      // Limit maximum velocity
      velocityX = velocityX.clamp(-maxVelocity, maxVelocity);
      velocityY = velocityY.clamp(-maxVelocity, maxVelocity);

      // Store previous position for collision resolution
      double previousX = ballX;
      double previousY = ballY;

      // Update position
      ballX += velocityX * 0.016;
      ballY += velocityY * 0.016;

      // Check boundaries with bounce effect
      if (ballX < -1.0) {
        ballX = -1.0;
        velocityX = -velocityX * bounceCoefficient;
      } else if (ballX > 1.0) {
        ballX = 1.0;
        velocityX = -velocityX * bounceCoefficient;
      }
      if (ballY < -1.0) {
        ballY = -1.0;
        velocityY = -velocityY * bounceCoefficient;
      } else if (ballY > 1.0) {
        ballY = 1.0;
        velocityY = -velocityY * bounceCoefficient;
      }

      // Check collisions with all obstacles
      bool hadCollision;
      int maxIterations = 3; // Prevent infinite loops
      int iteration = 0;

      do {
        hadCollision = false;
        iteration++;

        for (final obstacle in obstacles) {
          if (_checkCollision(obstacle)) {
            _handleCollision(obstacle);
            //hadCollision = true;
          }
        }
      } while (hadCollision && iteration < maxIterations);

      // If still in collision after max iterations, revert to previous position
      if (hadCollision) {
        ballX = previousX;
        ballY = previousY;
        velocityX *= 0.5; // Reduce velocity to prevent getting stuck
        velocityY *= 0.5;
      }

      // Check if ball reached the goal
      if (_checkGoal()) {
        _handleVictory();
      }
    });
  }

  bool _checkCollision(Obstacle obstacle) {
    final ballLeft = ballX - ballRadius / 100;
    final ballRight = ballX + ballRadius / 100;
    final ballTop = ballY - ballRadius / 100;
    final ballBottom = ballY + ballRadius / 100;

    final obstacleLeft = obstacle.x - obstacle.width / 4;
    final obstacleRight = obstacle.x + obstacle.width / 4;
    final obstacleTop = obstacle.y - obstacle.height / 4;
    final obstacleBottom = obstacle.y + obstacle.height / 4;

    return ballRight > obstacleLeft &&
        ballLeft < obstacleRight &&
        ballBottom > obstacleTop &&
        ballTop < obstacleBottom;
  }

  void _handleCollision(Obstacle obstacle) {
    // Simple collision response
    final overlapX = min(
      (ballX + ballRadius / 100) - (obstacle.x - obstacle.width / 2),
      (obstacle.x + obstacle.width / 2) - (ballX - ballRadius / 100),
    );
    final overlapY = min(
      (ballY + ballRadius / 100) - (obstacle.y - obstacle.height / 2),
      (obstacle.y + obstacle.height / 2) - (ballY - ballRadius / 100),
    );

    if (overlapX < overlapY) {
      // Collided horizontally
      if (ballX < obstacle.x) {
        ballX -= overlapX;
      } else {
        ballX += overlapX;
      }
      velocityX = -velocityX * 0.5;
    } else {
      // Collided vertically
      if (ballY < obstacle.y) {
        ballY -= overlapY;
      } else {
        ballY += overlapY;
      }
      velocityY = -velocityY * 0.5;
    }
  }

  bool _checkGoal() {
    return (ballX - goal.x).abs() < 0.05 && (ballY - goal.y).abs() < 0.05;
  }

  void _handleVictory() {
    isGameOver = true;
    gameTimer?.cancel();
    physicsTimer?.cancel();
    _accelerometerSubscription?.cancel();
    widget.onComplete();
  }

  @override
  void dispose() {
    _controller.dispose();
    gameTimer?.cancel();
    physicsTimer?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _buildGameArea(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            icon: Icons.stars,
            label: 'Score',
            value: score.toString(),
            color: Colors.orange,
          ),
          _buildStatCard(
            icon: Icons.timer,
            label: 'Time',
            value: '$time s',
            color: Colors.blue,
          ),
        ],
      ),
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
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                ),
              ),
              Text(
                value,
                style: TextStyle(
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

  Widget _buildGameArea() {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        setState(() {
          accelerometerY = details.primaryDelta! / 2;
        });
        _updatePhysics(gameTimer!);
      },
      onHorizontalDragUpdate: (details) {
        setState(() {
          accelerometerX = -details.primaryDelta! / 2;
        });
        _updatePhysics(gameTimer!);
      },
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: GamePainter(
                  ballX: ballX,
                  ballY: ballY,
                  ballRadius: ballRadius,
                  obstacles: obstacles,
                  goal: goal,
                  controller: _controller,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Obstacle {
  final double x;
  final double y;
  final double width;
  final double height;

  Obstacle({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}

class Cell {
  final int row;
  final int col;
  final List<bool> walls = [true, true, true, true]; // Top, Right, Bottom, Left

  Cell({required this.row, required this.col});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cell &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;
}

class GamePainter extends CustomPainter {
  final double ballX;
  final double ballY;
  final double ballRadius;
  final List<Obstacle> obstacles;
  final Point goal;
  final AnimationController controller;

  GamePainter({
    required this.ballX,
    required this.ballY,
    required this.ballRadius,
    required this.obstacles,
    required this.goal,
    required this.controller,
  }) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Draw obstacles
    final obstaclePaint = Paint()..color = Colors.grey;
    for (final obstacle in obstacles) {
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(
            (obstacle.x * size.width / 2) + center.dx,
            (obstacle.y * size.height / 2) + center.dy,
          ),
          width: obstacle.width * size.width / 2,
          height: obstacle.height * size.height / 2,
        ),
        obstaclePaint,
      );
    }

    // Draw goal
    final goalPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(
      Offset(
        (goal.x * size.width / 2) + center.dx,
        (goal.y * size.height / 2) + center.dy,
      ),
      ballRadius * 1.5,
      goalPaint,
    );

    // Draw ball
    final ballPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final ballPosition = Offset(
      (ballX * size.width / 2) + center.dx,
      (ballY * size.height / 2) + center.dy,
    );

    // Draw ball shadow
    canvas.drawCircle(
      ballPosition + const Offset(2, 2),
      ballRadius,
      shadowPaint,
    );

    // Draw ball
    canvas.drawCircle(
      ballPosition,
      ballRadius,
      ballPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flame/components.dart' hide Timer;
import 'package:flame_forge2d/flame_forge2d.dart' hide Particle;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flame/particles.dart';
import 'dart:async';
import 'dart:math';

import '../theme/app_theme.dart';
import 'components/ball.dart';
import 'components/collectible_star.dart';
import 'components/goal.dart';
import 'components/wall.dart';
import 'game_controller.dart';

class _QueryCallback implements QueryCallback {
  final bool Function(Fixture fixture) _reportFixture;

  _QueryCallback(this._reportFixture);

  @override
  bool reportFixture(Fixture fixture) {
    return _reportFixture(fixture);
  }
}

class BalanceBallGame extends Forge2DGame {
  final Map<String, dynamic> gameData;
  final GameController gameController;

  late BallBody ball;
  late GoalBody goal;
  late List<WallBody> walls = [];
  int score = 1000;
  int time = 0;
  bool isGameOver = false;
  Vector2 gravity = Vector2.zero();
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  Timer? gameTimer;

  // New gameplay elements
  bool isGameStarted = false;
  int collectiblesGathered = 0;
  int totalCollectibles = 5;
  List<CollectibleStarBody> collectibles = [];
  double sensitivity = 1.0;
  int lives = 3;
  List<Vector2> checkpoints = [];
  Vector2? lastCheckpoint;

  // late List<HazardZone> hazardZones = [];
  late List<TrailComponent> ballTrail = [];
  double trailOpacity = 0.0;

  final int mazeRows = 10;
  final int mazeCols = 10;

  BalanceBallGame({
    required this.gameData,
    required this.gameController,
  }) : super();

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Add maze walls
    _generateMaze();

    // Add collectibles
    _addCollectibles();

    _startGame();
  }

  void _startGame() {
    // Start accelerometer with smoothing
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        // Apply smoothing filter
        final targetGravity =
            Vector2(-event.x * 9.81, event.y * 9.81) * sensitivity;
        world.gravity.lerp(targetGravity, 0.1);
      },
    );

    gameTimer = Timer.periodic(const Duration(seconds: 1), _updateTime);
  }

  void _updateTime(Timer timer) {
    if (!isGameOver) {
      time++;
      score = (1000 - time * 10).clamp(0, 1000);
      gameController.updateScore(score);
    }
  }

  void _addCollectibles() {
    final random = Random();
    final size = camera.visibleWorldRect;
    final cellWidth = size.width / mazeCols;
    final cellHeight = size.height / mazeRows;

    // Keep track of valid spawn positions
    List<Vector2> validPositions = [];

    // Generate valid positions by checking center of each cell
    for (int row = 0; row < mazeRows; row++) {
      for (int col = 0; col < mazeCols; col++) {
        final position = Vector2(
          -size.width / 2 + cellWidth * (col + 0.5),
          -size.height / 2 + cellHeight * (row + 0.5),
        );

        // Check if position is clear of walls using Box2D query
        bool isValid = true;
        world.queryAABB(
          _QueryCallback((Fixture fixture) {
            if (fixture.body.userData is WallBody) {
              isValid = false;
              return false;
            }
            return true;
          }),
          AABB.withVec2(
              Vector2(
                position.x - cellWidth * 0.3,
                position.y - cellHeight * 0.3,
              ),
              Vector2(
                position.x + cellWidth * 0.3,
                position.y + cellHeight * 0.3,
              )),
        );

        if (isValid) {
          validPositions.add(position);
        }
      }
    }

    // Ensure we have enough valid positions
    if (validPositions.length < totalCollectibles) {
      print('Warning: Not enough valid positions for collectibles');
      return;
    }

    // Randomly select positions from valid ones
    validPositions.shuffle(random);
    for (int i = 0; i < totalCollectibles; i++) {
      if (i < validPositions.length) {
        final collectible = CollectibleStarBody(validPositions[i]);
        collectibles.add(collectible);
        world.add(collectible);
      }
    }
  }

  void _generateMaze() {
    final cells = List.generate(
      mazeRows,
      (r) => List.generate(mazeCols, (c) => Cell(row: r, col: c)),
    );

    // Use your existing maze generation algorithm
    Set<Cell> visited = {};
    List<Cell> stack = [];
    Cell current = cells[0][0];
    visited.add(current);

    while (true) {
      final neighbors = _getUnvisitedNeighbors(current, cells, visited);
      if (neighbors.isNotEmpty) {
        final next = neighbors[Random().nextInt(neighbors.length)];
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

    // Convert maze cells to Flame wall components
    _addWallsFromMaze(cells);

    // Add ball and goal after walls
    _addBallAndGoal();
  }

  void _addWallsFromMaze(List<List<Cell>> maze) {
    final size = camera.visibleWorldRect;

    final cellWidth = (size.width / mazeCols);
    final cellHeight = (size.height / mazeRows) - 0.1;
    const wallThickness = 0.3; // Box2D units

    final offsetX = (-size.width / 2);
    final offsetY = (-size.height / 2) + 0.5;

    for (var r = 0; r < mazeRows; r++) {
      for (var c = 0; c < mazeCols; c++) {
        final cell = maze[r][c];
        final x = offsetX + c * cellWidth;
        final y = offsetY + r * cellHeight;

        if (cell.walls[0]) {
          // Top
          world.add(WallBody(
            Vector2(x + cellWidth / 2, y),
            Vector2(cellWidth, wallThickness),
          ));
        }
        if (cell.walls[1]) {
          // Right
          world.add(WallBody(
            Vector2(x + cellWidth, y + cellHeight / 2),
            Vector2(wallThickness, cellHeight),
          ));
        }
        if (cell.walls[2]) {
          // Bottom
          world.add(WallBody(
            Vector2(x + cellWidth / 2, y + cellHeight),
            Vector2(cellWidth, wallThickness),
          ));
        }
        if (cell.walls[3]) {
          // Left
          world.add(WallBody(
            Vector2(x, y + cellHeight / 2),
            Vector2(wallThickness, cellHeight),
          ));
        }
      }
    }
  }

  void _addBallAndGoal() {
    final size = camera.visibleWorldRect.size;
    final cellWidth = size.width / mazeCols;
    final cellHeight = size.height / mazeRows;

    final offsetX = -size.width / 2;
    final offsetY = -size.height / 2;

    // Add ball at start
    ball = BallBody(Vector2(
      offsetX + cellWidth * 0.5,
      offsetY + cellHeight * 0.5,
    ));
    world.add(ball);

    // Add goal at end
    goal = GoalBody(Vector2(
      offsetX + cellWidth * (mazeCols - 0.55),
      offsetY + cellHeight * (mazeRows - 0.35),
    ));
    world.add(goal);
  }

  void _updateBallEffects(double dt) {
    // Update ball trail effect
    trailOpacity = (ball.body.linearVelocity.length > 3)
        ? (trailOpacity + dt).clamp(0.0, 0.3)
        : (trailOpacity - dt).clamp(0.0, 0.3);

    if (trailOpacity > 0) {
      ballTrail.add(TrailComponent(
        position: ball.position.clone(),
        radius: ball.radius,
        opacity: trailOpacity,
      ));
    }

    // Remove old trail particles
    ballTrail.removeWhere((trail) {
      trail.opacity -= dt * 2;
      if (trail.opacity <= 0) {
        trail.removeFromParent();
        return true;
      }
      return false;
    });

    // Add rolling effect when ball is moving
    if (ball.body.linearVelocity.length > 1) {
      final particlePos = ball.position +
          Vector2(
            Random().nextDouble() * 0.4 - 0.2,
            Random().nextDouble() * 0.4 - 0.2,
          );

      add(ParticleSystemComponent(
        particle: Particle.generate(
          count: 1,
          lifespan: 0.3,
          generator: (i) => AcceleratedParticle(
            acceleration: Vector2(0, 9.8),
            speed: Vector2.zero(),
            position: particlePos,
            child: CircleParticle(
              radius: 0.1,
              paint: Paint()..color = AppTheme.primaryColor.withOpacity(0.2),
            ),
          ),
        ),
      ));
    }
  }

  List<Cell> _getUnvisitedNeighbors(
      Cell cell, List<List<Cell>> grid, Set<Cell> visited) {
    List<Cell> neighbors = [];
    final directions = [
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1]
    ];

    for (final dir in directions) {
      final newRow = cell.row + dir[0];
      final newCol = cell.col + dir[1];
      if (newRow >= 0 &&
          newRow < mazeRows &&
          newCol >= 0 &&
          newCol < mazeCols &&
          !visited.contains(grid[newRow][newCol])) {
        neighbors.add(grid[newRow][newCol]);
      }
    }

    return neighbors;
  }

  void _removeWallBetween(Cell current, Cell next) {
    final dx = next.col - current.col;
    final dy = next.row - current.row;

    if (dx == 1) {
      current.walls[1] = false;
      next.walls[3] = false;
    } else if (dx == -1) {
      current.walls[3] = false;
      next.walls[1] = false;
    } else if (dy == 1) {
      current.walls[2] = false;
      next.walls[0] = false;
    } else if (dy == -1) {
      current.walls[0] = false;
      next.walls[2] = false;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!isGameOver && isGameStarted) {
      _checkCollisions();
      _updateBallEffects(dt);
    }
  }

  void _checkCollisions() {
    // Check collectibles
    collectibles.removeWhere((collectible) {
      if (ball.position.distanceTo(collectible.position) <
          ball.radius + collectible.radius) {
        collectiblesGathered++;
        score += 100;
        gameController.updateScore(score);
        collectible.removeFromParent();
        _showCollectEffect(collectible.position);
        return true;
      }
      return false;
    });

    // Check goal collision with all collectibles gathered
    if (collectiblesGathered == totalCollectibles &&
        ball.position.distanceTo(goal.position) < ball.radius + goal.radius) {
      _handleVictory();
    }

    // Check hazard collisions
    // if (_isInHazard(ball.position)) {
    //   _handleHazardCollision();
    // }
  }

  void _handleHazardCollision() {
    lives--;
    if (lives <= 0) {
      //_handleGameOver();
    } else {
      _respawnAtCheckpoint();
    }
  }

  void _respawnAtCheckpoint() {
    if (lastCheckpoint != null) {
      ball.body.setTransform(lastCheckpoint!, 0);
      ball.body.linearVelocity = Vector2.zero();
      ball.body.angularVelocity = 0;
    }
  }

  void _showCollectEffect(Vector2 position) {
    final particleComponent = ParticleSystemComponent(
      particle: Particle.generate(
        count: 20,
        lifespan: 0.5,
        generator: (i) {
          final angle = Random().nextDouble() * 2 * pi;
          final speed = Random().nextDouble() * 2 + 1;
          return AcceleratedParticle(
            acceleration: Vector2(0, 9.8),
            speed: Vector2(cos(angle), sin(angle)) * speed,
            position: position.clone(),
            child: CircleParticle(
              radius: 0.1,
              paint: Paint()..color = AppTheme.primaryColor,
            ),
          );
        },
      ),
    );
    world.add(particleComponent);
  }

  void _handleVictory() {
    isGameOver = true;
    gameTimer?.cancel();
    _accelerometerSubscription?.cancel();

    _addVictoryParticles();

    Future.delayed(const Duration(milliseconds: 1500), () {
      gameController.completeGame();
    });
  }

  void _addVictoryParticles() {
    final random = Random();
    const particleCount = 100;

    final particleSystem = ParticleSystemComponent(
      particle: Particle.generate(
        count: particleCount,
        lifespan: 1.5,
        generator: (i) {
          // Calculate random angle and speed for each particle
          final angle = random.nextDouble() * 2 * pi;
          final speed = random.nextDouble() * 3 + 2; // Speed between 2-5

          return AcceleratedParticle(
            acceleration: Vector2(0, 9.8), // Gravity effect
            speed: Vector2(cos(angle) * speed, sin(angle) * speed),
            position: goal.body.position.clone(),
            child: ComposedParticle(
              children: [
                // Glowing circle particle
                CircleParticle(
                  radius: 0.2,
                  paint: Paint()
                    ..color = AppTheme.correctAnswerColor.withOpacity(0.6)
                    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
                ),
                // Smaller solid circle for the core
                CircleParticle(
                  radius: 0.1,
                  paint: Paint()..color = AppTheme.correctAnswerColor,
                ),
              ],
            ),
          );
        },
      ),
    );

    // Add celebratory sound effect here if desired
    // audioPlayer.play('victory_sound.wav');

    // Add shine effect around the goal
    final shine = CircleComponent(
      radius: 1.0,
      position: goal.body.position.clone(),
      paint: Paint()
        ..color = AppTheme.correctAnswerColor.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    shine.add(
      ScaleEffect.by(
        Vector2.all(2.0),
        EffectController(
          duration: 0.5,
          curve: Curves.easeOut,
        ),
      )..onComplete = () {
          shine.removeFromParent();
        },
    );

    world.add(shine);
    world.add(particleSystem);
  }

  @override
  void onRemove() {
    gameTimer?.cancel();
    _accelerometerSubscription?.cancel();
    super.onRemove();
  }
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

class TrailComponent extends PositionComponent {
  final double radius;
  double opacity;

  TrailComponent({
    required Vector2 position,
    required this.radius,
    required this.opacity,
  }) : super(position: position);

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = AppTheme.primaryColor.withOpacity(opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }
}

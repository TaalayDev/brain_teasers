import 'package:flame/components.dart' hide Timer;
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart' hide Draggable;
import 'dart:math' as math;
import 'dart:async';

import '../theme/app_theme.dart';

class LevelConfig {
  final double targetFillLevel;
  final int timeLimit;
  final List<ObstacleTemplate> availableObstacles;

  LevelConfig({
    required this.targetFillLevel,
    required this.timeLimit,
    required this.availableObstacles,
  });
}

enum ObstacleType {
  platform, // Regular horizontal platform
  slope, // Angled platform
  funnel, // V-shaped funnel
}

class ObstacleTemplate {
  final ObstacleType type;
  int count;

  ObstacleTemplate({
    required this.type,
    required this.count,
  });
}

class GravityFlowGame extends Forge2DGame with TapDetector {
  final Map<String, dynamic> gameData;
  final Function(int score) onScoreUpdate;
  final VoidCallback onComplete;

  late LiquidContainer container;
  late List<LiquidParticle> particles = [];
  late List<Obstacle> obstacles = [];
  late Goal goal;
  late SourcePipe sourcePipe;
  bool isGameStarted = false;
  bool isGameOver = false;
  int score = 1000;
  double fillLevel = 0.0;
  final targetFillLevel = 0.8;
  Vector2? dragStart;

  // New variables for enhanced gameplay
  int remainingTime = 60; // 60 second time limit
  late Timer gameTimer;
  double particleEmissionRate = 0.5; // Particles per second
  double _timeSinceLastEmission = 0;
  bool isPaused = false;
  int stars = 0; // Star rating based on performance

  late List<PowerUp> powerUps = [];
  late List<MovingObstacle> movingObstacles = [];
  late List<Teleporter> teleporters = [];
  int currentLevel = 1;
  int maxLevels = 10;

  bool isTimeFrozen = false;
  bool isFlowBoosted = false;
  Duration freezeTimeRemaining = Duration.zero;

  late List<ObstacleTemplate> availableObstacles = [];
  late List<PlacedObstacle> placedObstacles = [];
  ObstacleTemplate? selectedTemplate;
  PlacedObstacle? selectedObstacle;

  bool isPlacementMode = true;

  Map<int, LevelConfig> levelConfigs = {
    1: LevelConfig(
      targetFillLevel: 0.6,
      timeLimit: 90,
      availableObstacles: [
        ObstacleTemplate(type: ObstacleType.platform, count: 3),
        ObstacleTemplate(type: ObstacleType.slope, count: 2),
      ],
    ),
    2: LevelConfig(
      targetFillLevel: 0.7,
      timeLimit: 80,
      availableObstacles: [
        ObstacleTemplate(type: ObstacleType.platform, count: 3),
        ObstacleTemplate(type: ObstacleType.slope, count: 2),
        ObstacleTemplate(type: ObstacleType.funnel, count: 1),
      ],
    ),
    // Add more levels...
  };

  static const double particleRadius = 0.2;
  static const double smoothingRadius = 1.0;
  static const double pressureConstant = 200.0;
  static const double restDensity = 1.0;
  static const double viscosity = 0.1;
  static const double surfaceTension = 0.05;
  static const double damping = 1.0;

  GravityFlowGame({
    required this.gameData,
    required this.onScoreUpdate,
    required this.onComplete,
  }) : super(gravity: Vector2(0, 0));

  // Helper getters from your code
  double get screenWidth => camera.visibleWorldRect.width;
  double get screenHeight => camera.visibleWorldRect.height;
  double get horizontalPadding => screenWidth * 0.1;
  double get verticalPadding => screenHeight * 0.1;
  double get playableWidth => screenWidth - (2);
  double get playableHeight => screenHeight - (2);

  Vector2 screenToWorld(Vector2 position) {
    return Vector2(
      position.x - (screenWidth / 2),
      position.y - (screenHeight / 2),
    );
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    await _initializeGameObjects();
    // await _initializeLevelElements();

    // world.add(ObstacleSelector(
    //   position: Vector2(50, size.y - 100),
    //   onSelect: (template) {
    //     selectedTemplate = template;
    //     selectedObstacle = null;
    //   },
    //   availableObstacles: availableObstacles,
    // ));

    add(StartButton(
      position: Vector2(
        size.x * 0.5 - (size.x * 0.3),
        size.y * 0.88,
      ),
      size: Vector2(size.x * 0.6, 50),
      onPressed: startSimulation,
    ));
  }

  @override
  void onTapDown(TapDownInfo info) {
    super.onTapDown(info);
    if (!isPlacementMode) return;

    final worldPosition = screenToWorld(info.eventPosition.global);

    if (selectedTemplate != null && selectedTemplate!.count > 0) {
      _placeNewObstacle(worldPosition);
    }
  }

  void _placeNewObstacle(Vector2 position) {
    if (selectedTemplate == null) return;

    final obstacle = PlacedObstacle(
      template: selectedTemplate!,
      position: position,
      size: _getObstacleSize(selectedTemplate!.type),
    );

    placedObstacles.add(obstacle);
    world.add(obstacle);
    selectedTemplate!.count--;

    if (selectedTemplate!.count <= 0) {
      selectedTemplate = null;
    }
  }

  Vector2 _getObstacleSize(ObstacleType type) {
    switch (type) {
      case ObstacleType.platform:
        return Vector2(playableWidth * 0.2, playableHeight * 0.02);
      case ObstacleType.slope:
        return Vector2(playableWidth * 0.15, playableHeight * 0.02);
      case ObstacleType.funnel:
        return Vector2(playableWidth * 0.25, playableHeight * 0.04);
    }
  }

  void startSimulation() {
    isPlacementMode = false;
    world.gravity = Vector2(0, 9.81);
    startGame();
  }

  Future<void> _initializeLevelElements() async {
    final config = levelConfigs[currentLevel];
    if (config == null) return;

    // Clear existing elements
    availableObstacles.clear();
    placedObstacles.clear();

    // Initialize available obstacles for the level
    availableObstacles = config.availableObstacles;
  }

  void _addPowerUps(List<String> allowedTypes) {
    for (final type in allowedTypes) {
      final position = _getRandomPosition();
      final powerUp = PowerUp(
        position: position,
        type: type,
        onCollect: () => _activatePowerUp(type),
      );
      powerUps.add(powerUp);
      add(powerUp);
    }
  }

  void _addMovingObstacles(int count) {
    for (int i = 0; i < count; i++) {
      final startPosition = _getRandomPosition();
      final endPosition = _getRandomPosition();
      final speed = 0.5 + math.Random().nextDouble();
      final obstacle = MovingObstacle(
        startPosition: startPosition,
        endPosition: endPosition,
        speed: speed,
        size: Vector2(playableWidth * 0.25, playableHeight * 0.02),
      );
      movingObstacles.add(obstacle);
      add(obstacle);
    }
  }

  void _addTeleporters() {
    final entrance = _getRandomPosition();
    final exit = _getRandomPosition();

    final pair = TeleporterPair(
      entrance: Teleporter(position: entrance, isEntrance: true),
      exit: Teleporter(position: exit, isEntrance: false),
    );

    teleporters.add(pair.entrance);
    teleporters.add(pair.exit);
    add(pair.entrance);
    add(pair.exit);
  }

  void _activatePowerUp(String type) {
    switch (type) {
      case 'freeze':
        isTimeFrozen = true;
        freezeTimeRemaining = const Duration(seconds: 5);
        break;
      case 'boost':
        isFlowBoosted = true;
        for (final particle in particles) {
          particle.body.linearVelocity *= 1.5;
        }
        Future.delayed(const Duration(seconds: 3), () {
          isFlowBoosted = false;
          for (final particle in particles) {
            particle.body.linearVelocity /= 1.5;
          }
        });
        break;
    }
  }

  Future<void> _initializeGameObjects() async {
    // Container setup
    container = LiquidContainer(
      position: screenToWorld(Vector2(
        screenWidth / 2,
        (playableHeight * 0.5) + 1,
      )),
      size: Vector2(playableWidth, playableHeight - 2),
    );
    world.add(container);

    world.add(LiquidContainer(
      position: screenToWorld(Vector2(
        screenWidth * 0.8,
        screenHeight - verticalPadding - (playableHeight * 0.1),
      )),
      size: Vector2(playableWidth * 0.2, playableHeight * 0.15),
    ));

    // Goal setup
    goal = Goal(
      position: screenToWorld(Vector2(
        screenWidth * 0.8,
        screenHeight - verticalPadding - (playableHeight * 0.1),
      )),
      size: Vector2(playableWidth * 0.2, playableHeight * 0.15),
    );
    world.add(goal);

    // Generate initial obstacles
    _generateObstacles();

    // Create liquid particles
    _createLiquidParticles();
  }

  void togglePause() {
    isPaused = !isPaused;
    if (isPaused) {
      pauseEngine();
    } else {
      resumeEngine();
    }
  }

  void startGame() {
    print('Starting game...');
    isGameStarted = true;
    isPaused = false;
    world.gravity = Vector2(0, 9.81);

    // Start game timer
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isPaused) {
        remainingTime--;
        if (remainingTime <= 0) {
          _handleTimeUp();
        }
      }
    });
  }

  void _createInitialParticles(int count) {
    final startPosition = screenToWorld(Vector2(
      horizontalPadding + (playableWidth * 0.2),
      verticalPadding + (playableHeight * 0.15),
    ));

    const particleRadius = 0.2;
    const particleSpacing = 0.5;

    for (int i = 0; i < count; i++) {
      final particle = LiquidParticle(
        position: Vector2(
          startPosition.x + (i % 4) * particleSpacing,
          startPosition.y + (i ~/ 4) * particleSpacing,
        ),
        radius: particleRadius,
        density: 1.0,
      );
      particles.add(particle);
      world.add(particle);
    }
  }

  @override
  void update(double dt) {
    // if (isPaused) return;
    super.update(dt);

    if (isGameStarted && !isGameOver) {
      if (isTimeFrozen) {
        freezeTimeRemaining -= Duration(milliseconds: (dt * 1000).round());
        if (freezeTimeRemaining <= Duration.zero) {
          isTimeFrozen = false;
        }
      }

      // Handle teleportation
      for (final particle in particles) {
        for (final teleporter in teleporters) {
          if (teleporter.isEntrance &&
              (particle.position - teleporter.position).length < 0.5) {
            // Find exit teleporter
            final exit = teleporters.firstWhere((t) => !t.isEntrance);
            particle.body.setTransform(exit.position, 0);
            particle.body.linearVelocity *=
                1.2; // Add momentum after teleporting
          }
        }
      }

      _updateFillLevel();
      _checkWinCondition();

      // Particle emission system
      _timeSinceLastEmission += dt;
      if (_timeSinceLastEmission >= 1 / particleEmissionRate &&
          particles.length < 40) {
        _createInitialParticles(1);
        _timeSinceLastEmission = 0;
      }

      _updateParticles(dt);
    }
  }

  Vector2 _getRandomPosition() {
    final random = math.Random();
    return Vector2(
      horizontalPadding + (playableWidth * random.nextDouble()),
      verticalPadding + (playableHeight * random.nextDouble()),
    );
  }

  void _handleTimeUp() {
    isGameOver = true;
    gameTimer.cancel();

    // Calculate star rating
    stars = _calculateStars();
  }

  int _calculateStars() {
    if (fillLevel >= targetFillLevel) return 3;
    if (fillLevel >= targetFillLevel * 0.7) return 2;
    if (fillLevel >= targetFillLevel * 0.4) return 1;
    return 0;
  }

  void _restartGame() {
    // Reset game state
    isGameStarted = false;
    isGameOver = false;
    score = 1000;
    fillLevel = 0.0;
    remainingTime = 60;
    particles.clear();
    obstacles.clear();

    // Reinitialize game objects
    _initializeGameObjects();
  }

  void _generateObstacles() {
    final random = math.Random();

    // Define fixed obstacle positions for better gameplay
    final positions = [
      Vector2(0.3, 0.4), // Left side
      Vector2(0.7, 0.5), // Right side
      Vector2(0.5, 0.6), // Middle
      Vector2(0.2, 0.7), // Lower left
      Vector2(0.8, 0.3), // Upper right
    ];

    // Clear any existing obstacles
    obstacles.clear();

    // Create obstacles at predetermined positions with random rotations
    for (int i = 0; i < positions.length; i++) {
      final isRotatable = i < 3; // First 3 are rotatable
      final position = screenToWorld(Vector2(
        horizontalPadding + (playableWidth * positions[i].x),
        verticalPadding + (playableHeight * positions[i].y),
      ));

      final obstacle = Obstacle(
        position: position,
        size: Vector2(playableWidth * 0.25, playableHeight * 0.02),
        isRotatable: isRotatable,
      );
      obstacles.add(obstacle);
      world.add(obstacle);
    }
  }

  void _createLiquidParticles() {
    const spacing = particleRadius * 1.3;
    const rows = 20;
    const cols = 20;

    final startPosition = screenToWorld(Vector2(
      horizontalPadding + (playableWidth * 0.2),
      verticalPadding + (playableHeight * 0.15),
    ));

    final startX = startPosition.x;
    final startY = startPosition.y;

    for (var i = 0; i < rows; i++) {
      for (var j = 0; j < cols; j++) {
        final position = Vector2(
          startX + j * spacing + math.Random().nextDouble() * 0.1,
          startY + i * spacing + math.Random().nextDouble() * 0.1,
        );
        final particle = LiquidParticle(
          position: position,
          radius: particleRadius,
          density: restDensity,
        );
        particles.add(particle);
        world.add(particle);
      }
    }

    final pipePosition = Vector2(
      horizontalPadding + (playableWidth * 0.24),
      verticalPadding + (playableHeight * 0.14),
    );

    sourcePipe = SourcePipe(
      position: screenToWorld(pipePosition),
      size: Vector2(playableWidth * 0.1, playableHeight * 0.1),
    );
    world.add(sourcePipe);
  }

  int particlesInGoal = 0;
  void _updateFillLevel() {
    for (final particle in particles) {
      if (goal.containsPoint(particle.body.position)) {
        particlesInGoal++;
      }
    }
    fillLevel = particlesInGoal / particles.length;
    print('Fill level: $fillLevel');
    score = (1000 * fillLevel).round();
    onScoreUpdate(score);
  }

  void _checkWinCondition() {
    print('currentLevel $currentLevel');
    if (fillLevel >= levelConfigs[currentLevel]!.targetFillLevel) {
      if (currentLevel < maxLevels) {
        isGameStarted = false;
        _initializeGameObjects();
        // Show level complete overlay
        startGame();
        currentLevel++;
      } else {
        // Game complete
        isGameOver = true;
        onComplete();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Render timer
    if (isGameStarted && !isGameOver) {
      _renderTimer(canvas);
    }
  }

  void _renderTimer(Canvas canvas) {
    final textSpan = TextSpan(
      text: 'Time: ${remainingTime}s',
      style: TextStyle(
        color: remainingTime <= 10 ? Colors.red : Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            blurRadius: 2,
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(1, 1),
          ),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(screenWidth - textPainter.width - 20, 20),
    );
  }

  void _updateParticles(double dt) {
    // Calculate densities and pressures
    // for (final particle in particles) {
    //   particle.density = _calculateDensity(particle);
    //   particle.pressure = pressureConstant * (particle.density - restDensity);
    // }

    // Calculate and apply forces
    for (final particle in particles) {
      final pressureForce = _calculatePressureForce(particle);
      final viscosityForce = _calculateViscosityForce(particle);
      final surfaceForce = _calculateSurfaceForce(particle);

      // Apply forces
      final totalForce = pressureForce + viscosityForce + surfaceForce;
      final acceleration = totalForce / particle.density;
      particle.body.applyLinearImpulse(acceleration * dt);

      // Apply damping
      particle.body.linearVelocity.scale(damping);
    }
  }

  Vector2 _calculatePressureForce(LiquidParticle particle) {
    final force = Vector2.zero();

    for (final neighbor in particles) {
      if (neighbor == particle) continue;

      final diff = neighbor.position - particle.position;
      final dist = diff.length;
      if (dist < smoothingRadius) {
        final direction = diff.normalized();
        final pressure = (particle.pressure + neighbor.pressure) / 2;
        force.add(direction * pressure * _kernel(dist));
      }
    }

    return force;
  }

  Vector2 _calculateViscosityForce(LiquidParticle particle) {
    final force = Vector2.zero();

    for (final neighbor in particles) {
      if (neighbor == particle) continue;

      final diff = neighbor.position - particle.position;
      final dist = diff.length;
      if (dist < smoothingRadius) {
        final relativeVelocity =
            neighbor.body.linearVelocity - particle.body.linearVelocity;
        force.add(relativeVelocity * viscosity * _kernel(dist));
      }
    }

    return force;
  }

  Vector2 _calculateSurfaceForce(LiquidParticle particle) {
    final normal = _calculateSurfaceNormal(particle);
    final curvature = -normal.length;
    return normal * surfaceTension * curvature;
  }

  Vector2 _calculateSurfaceNormal(LiquidParticle particle) {
    final normal = Vector2.zero();

    for (final neighbor in particles) {
      if (neighbor == particle) continue;

      final diff = neighbor.position - particle.position;
      final dist = diff.length;
      if (dist < smoothingRadius) {
        normal.add(diff.normalized() * _kernel(dist));
      }
    }

    return normal;
  }

  double _calculateDensity(LiquidParticle particle) {
    double density = 0;

    for (final neighbor in particles) {
      final dist = (neighbor.position - particle.position).length;
      if (dist < smoothingRadius) {
        density += neighbor.mass * _kernel(dist);
      }
    }

    return density;
  }

  double _kernel(double distance) {
    // Poly6 kernel function
    if (distance >= smoothingRadius) return 0;
    final x = 1 - (distance * distance) / (smoothingRadius * smoothingRadius);
    return x * x * x;
  }
}

class TutorialOverlay extends PositionComponent with TapCallbacks {
  final VoidCallback onDismiss;

  TutorialOverlay({
    required Vector2 position,
    required Vector2 size,
    required this.onDismiss,
  }) : super(position: position, size: size);

  @override
  void render(Canvas canvas) {
    // Render semi-transparent background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = Colors.black.withOpacity(0.8),
    );

    // Render tutorial content
    const textSpan = TextSpan(
      children: [
        TextSpan(
          text: 'How to Play\n\n',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(
          text: '1. Rotate the yellow platforms to guide the liquid\n'
              '2. Fill the target container to 80%\n'
              '3. Complete the challenge before time runs out\n\n'
              'Tap to Start!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ],
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout(maxWidth: size.x - 40);
    textPainter.paint(
      canvas,
      Offset(
        (size.x - textPainter.width) / 2,
        (size.y - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool onTapUp(TapUpEvent event) {
    onDismiss();
    return true;
  }
}

class StartButton extends PositionComponent with TapCallbacks {
  final VoidCallback onPressed;
  bool isPressed = false;
  final bool isEnabled;

  StartButton({
    required Vector2 position,
    required Vector2 size,
    required this.onPressed,
    this.isEnabled = true,
  }) : super(position: position, size: size);

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final buttonRRect =
        RRect.fromRectAndRadius(rect, const Radius.circular(16));

    // Draw energetic background pattern
    _drawBackgroundPattern(canvas, buttonRRect);

    // Draw main button body with gradient
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        isPressed || !isEnabled
            ? AppTheme.primaryColor.withOpacity(0.7)
            : AppTheme.primaryColor,
        isPressed || !isEnabled
            ? AppTheme.accentColor.withOpacity(0.7)
            : AppTheme.accentColor,
      ],
    ).createShader(rect);

    canvas.drawRRect(
      buttonRRect,
      Paint()..shader = gradient,
    );

    // Add subtle inner shadow
    if (!isPressed && isEnabled) {
      canvas.drawRRect(
        buttonRRect,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.inner, 2)
          ..color = Colors.black.withOpacity(0.1),
      );
    }

    // Draw text with drop shadow
    final textSpan = TextSpan(
      text: 'START',
      style: TextStyle(
        color: Colors.white,
        fontSize: size.y * 0.4,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(1, 1),
            blurRadius: 2,
          ),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.x - textPainter.width) / 2,
        (size.y - textPainter.height) / 2,
      ),
    );
  }

  void _drawBackgroundPattern(Canvas canvas, RRect buttonRRect) {
    canvas.save();
    canvas.clipRRect(buttonRRect);

    final pattern = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 2;

    for (var i = 0; i < size.x; i += 10) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i + size.y, size.y),
        pattern,
      );
    }

    canvas.restore();
  }

  @override
  bool onTapDown(TapDownEvent event) {
    if (!isEnabled) return false;
    isPressed = true;
    return true;
  }

  @override
  bool onTapUp(TapUpEvent event) {
    if (!isEnabled) return false;
    isPressed = false;
    onPressed();
    return true;
  }

  @override
  bool onTapCancel(TapCancelEvent event) {
    isPressed = false;
    onPressed();
    return true;
  }
}

class Obstacle extends BodyComponent with DragCallbacks {
  final Vector2 size;
  final bool isRotatable;
  bool isDragging = false;
  Vector2 dragStart = Vector2.zero();
  Vector2 initialPosition = Vector2.zero();
  final Vector2 _position;

  Obstacle({
    required Vector2 position,
    required this.size,
    required this.isRotatable,
  }) : _position = position;

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: _position,
      type: BodyType.kinematic,
      angularDamping: 1.0,
    );

    final body = world.createBody(bodyDef);
    final shape = PolygonShape()
      ..setAsBox(size.x / 2, size.y / 2, Vector2.zero(), 0);

    final fixtureDef = FixtureDef(
      shape,
      density: 1.0,
      friction: 0.5,
      restitution: 0.2,
    );

    body.createFixture(fixtureDef);
    return body;
  }

  @override
  void render(Canvas canvas) {
    // Draw shadow
    canvas.drawRect(
      Rect.fromCenter(
        center: const Offset(0.05, 0.05),
        width: size.x,
        height: size.y,
      ),
      Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Draw platform with gradient
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: size.x,
      height: size.y,
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isRotatable ? AppTheme.accentColor : AppTheme.secondaryColor,
            (isRotatable ? AppTheme.accentColor : AppTheme.secondaryColor)
                .withOpacity(0.8),
          ],
        ).createShader(rect),
    );

    // Add grip marks for rotatable platforms
    if (isRotatable) {
      final spacing = size.x / 6;
      for (int i = -2; i <= 2; i++) {
        canvas.drawLine(
          Offset(i * spacing, -size.y / 3),
          Offset(i * spacing, size.y / 3),
          Paint()
            ..color = Colors.white.withOpacity(0.5)
            ..strokeWidth = 0.05,
        );
      }
    }
  }

  @override
  bool onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (!isRotatable) return false;
    isDragging = true;
    dragStart = event.canvasPosition;
    initialPosition = body.position.clone();
    return true;
  }

  @override
  bool onDragUpdate(DragUpdateEvent event) {
    if (!isDragging) return false;

    if (event.canvasStartPosition.y > dragStart.y) {
      // Dragging downward - rotate clockwise
      final angle = (event.canvasStartPosition.y - dragStart.y) * 0.01;
      body.setTransform(initialPosition, angle);
    } else if (event.canvasStartPosition.y < dragStart.y) {
      // Dragging upward - rotate counter-clockwise
      final angle = (event.canvasStartPosition.y - dragStart.y) * 0.01;
      body.setTransform(initialPosition, angle);
    }

    return true;
  }

  @override
  bool onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    isDragging = false;
    return true;
  }
}

class MovingObstacle extends Obstacle {
  final Vector2 startPosition;
  final Vector2 endPosition;
  final double speed;
  double progress = 0.0;
  bool movingForward = true;

  MovingObstacle({
    required this.startPosition,
    required this.endPosition,
    required this.speed,
    required super.size,
  }) : super(position: startPosition, isRotatable: false);

  @override
  void update(double dt) {
    if (movingForward) {
      progress += speed * dt;
      if (progress >= 1.0) {
        progress = 1.0;
        movingForward = false;
      }
    } else {
      progress -= speed * dt;
      if (progress <= 0.0) {
        progress = 0.0;
        movingForward = true;
      }
    }

    final newPosition = Vector2.copy(startPosition)
      ..lerp(endPosition, progress);
    body.setTransform(newPosition, body.angle);
  }
}

class LiquidParticle extends BodyComponent {
  final double radius;
  final Vector2 _position;
  double mass = 1.0;
  double density = 0.0;
  double pressure = 0.0;

  LiquidParticle({
    required Vector2 position,
    required this.radius,
    required this.density,
  }) : _position = position;

  @override
  Body createBody() {
    final shape = CircleShape()..radius = radius;
    final fixtureDef = FixtureDef(
      shape,
      density: density,
      friction: 0.1,
      restitution: 0.4,
      filter: Filter()..groupIndex = -1,
    );

    final bodyDef = BodyDef(
      position: _position,
      type: BodyType.dynamic,
      bullet: true,
      linearDamping: 0.1,
      angularDamping: 0.1,
    );

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    // Draw liquid particle with gradient
    final gradient = RadialGradient(
      center: Alignment.topLeft,
      radius: 1.2,
      colors: [
        Colors.lightBlue.withOpacity(0.9),
        Colors.blue.withOpacity(0.7),
      ],
    );

    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: Offset.zero, radius: radius),
        ),
    );

    // Add highlight
    canvas.drawCircle(
      const Offset(-0.05, -0.05),
      radius * 0.3,
      Paint()..color = Colors.white.withOpacity(0.3),
    );
  }
}

class Goal extends BodyComponent {
  final Vector2 size;
  final Vector2 _position;
  double _glowIntensity = 0.0;
  late Timer _glowTimer;

  Goal({
    required Vector2 position,
    required this.size,
  }) : _position = position {
    _glowTimer = Timer.periodic(
      const Duration(milliseconds: 1500),
      (_) => _updateGlow(),
    );
  }

  void _updateGlow() {
    _glowIntensity = (_glowIntensity == 0.0) ? 0.3 : 0.0;
  }

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: _position,
      type: BodyType.static,
    );

    final body = world.createBody(bodyDef);
    final shape = PolygonShape()
      ..setAsBox(
        size.x / 2,
        size.y / 2,
        Vector2.zero(),
        0,
      );

    final fixtureDef = FixtureDef(
      shape,
      isSensor: true,
    );

    body.createFixture(fixtureDef);
    return body;
  }

  @override
  void render(Canvas canvas) {
    // Draw outer glow
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: size.x + 0.4,
        height: size.y + 0.4,
      ),
      Paint()
        ..color = AppTheme.correctAnswerColor.withOpacity(_glowIntensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Draw goal area with gradient
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: size.x,
      height: size.y,
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.correctAnswerColor.withOpacity(0.4),
            AppTheme.correctAnswerColor.withOpacity(0.2),
          ],
        ).createShader(rect),
    );

    // Draw goal border
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = AppTheme.correctAnswerColor
        ..strokeWidth = 0.1,
    );

    // Draw arrow indicators
    _drawArrows(canvas);
  }

  void _drawArrows(Canvas canvas) {
    const arrowSize = 0.3;
    const arrowSpacing = 0.8;
    final paint = Paint()
      ..color = AppTheme.correctAnswerColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.1;

    for (int i = 0; i < 3; i++) {
      final x = -arrowSize + (i * arrowSpacing);
      final path = Path()
        ..moveTo(x, -arrowSize)
        ..lineTo(x + arrowSize, 0)
        ..lineTo(x, arrowSize);

      canvas.drawPath(path, paint);
    }
  }

  @override
  void onRemove() {
    _glowTimer.cancel();
    super.onRemove();
  }
}

class LiquidContainer extends BodyComponent {
  final Vector2 size;
  final Vector2 _position;

  LiquidContainer({
    required Vector2 position,
    required this.size,
  }) : _position = position;

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: _position,
      type: BodyType.static,
    );

    final body = world.createBody(bodyDef);

    // Create walls with proper thickness
    const wallThickness = 0.2;

    // Left wall
    final leftWall = PolygonShape()
      ..setAsBox(
        wallThickness / 2,
        size.y / 2,
        Vector2(-size.x / 2, 0),
        0,
      );
    body.createFixture(FixtureDef(leftWall, friction: 0.3, restitution: 0.2));

    // Bottom wall
    final bottomWall = PolygonShape()
      ..setAsBox(
        size.x / 2,
        wallThickness / 2,
        Vector2(0, size.y / 2),
        0,
      );
    body.createFixture(FixtureDef(bottomWall, friction: 0.3, restitution: 0.2));

    // Right wall
    final rightWall = PolygonShape()
      ..setAsBox(
        wallThickness / 2,
        size.y / 2,
        Vector2(size.x / 2, 0),
        0,
      );
    body.createFixture(FixtureDef(rightWall, friction: 0.3, restitution: 0.2));

    return body;
  }

  @override
  void render(Canvas canvas) {
    // Draw container shadow
    canvas.drawRect(
      Rect.fromCenter(
        center: const Offset(0.1, 0.1),
        width: size.x,
        height: size.y,
      ),
      Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Draw container background
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: size.x,
        height: size.y,
      ),
      Paint()
        ..color = AppTheme.primaryColor.withOpacity(0.1)
        ..style = PaintingStyle.fill,
    );

    // Draw container border with gradient
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: size.x,
      height: size.y,
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.7),
          ],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.2,
    );

    // Add corner accents
    const cornerSize = 0.5;
    final cornerPaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.2;

    // Top left corner
    canvas.drawLine(
      Offset(-size.x / 2, -size.y / 2),
      Offset(-size.x / 2 + cornerSize, -size.y / 2),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(-size.x / 2, -size.y / 2),
      Offset(-size.x / 2, -size.y / 2 + cornerSize),
      cornerPaint,
    );

    // Top right corner
    canvas.drawLine(
      Offset(size.x / 2, -size.y / 2),
      Offset(size.x / 2 - cornerSize, -size.y / 2),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.x / 2, -size.y / 2),
      Offset(size.x / 2, -size.y / 2 + cornerSize),
      cornerPaint,
    );

    // Bottom corners (if needed for visibility)
    canvas.drawLine(
      Offset(-size.x / 2, size.y / 2),
      Offset(-size.x / 2 + cornerSize, size.y / 2),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(-size.x / 2, size.y / 2),
      Offset(-size.x / 2, size.y / 2 - cornerSize),
      cornerPaint,
    );

    canvas.drawLine(
      Offset(size.x / 2, size.y / 2),
      Offset(size.x / 2 - cornerSize, size.y / 2),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.x / 2, size.y / 2),
      Offset(size.x / 2, size.y / 2 - cornerSize),
      cornerPaint,
    );
  }
}

class SourcePipe extends PositionComponent {
  SourcePipe({
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);

  @override
  void render(Canvas canvas) {
    // Draw pipe shadow
    canvas.drawRect(
      Rect.fromCenter(
        center: const Offset(0.1, 0.1),
        width: size.x,
        height: size.y,
      ),
      Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Draw pipe body with gradient
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: size.x,
      height: size.y,
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColorDark,
          ],
        ).createShader(rect),
    );

    // Draw pipe border
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = AppTheme.primaryColor
        ..strokeWidth = 0.2,
    );

    // Draw pipe cap
    final capSize = size.y * 0.2;
    final capRect = Rect.fromCenter(
      center: Offset(0, size.y / 2 - capSize / 3),
      width: size.x + capSize,
      height: capSize,
    );

    canvas.drawRect(
      capRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColorDark,
          ],
        ).createShader(capRect),
    );
  }
}

class PowerUp extends PositionComponent {
  final String type;
  final VoidCallback onCollect;
  bool isCollected = false;
  double _pulseScale = 1.0;
  bool _growing = true;

  PowerUp({
    required Vector2 position,
    required this.type,
    required this.onCollect,
  }) : super(position: position, size: Vector2.all(1.0));

  @override
  void update(double dt) {
    if (isCollected) return;

    // Pulsing animation
    if (_growing) {
      _pulseScale += dt;
      if (_pulseScale >= 1.2) {
        _growing = false;
      }
    } else {
      _pulseScale -= dt;
      if (_pulseScale <= 0.8) {
        _growing = true;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (isCollected) return;

    final paint = Paint()
      ..color = type == 'freeze' ? Colors.blue : Colors.yellow
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.scale(_pulseScale);

    // Draw power-up icon
    if (type == 'freeze') {
      _drawFreezeIcon(canvas, paint);
    } else {
      _drawBoostIcon(canvas, paint);
    }

    canvas.restore();
  }

  void _drawFreezeIcon(Canvas canvas, Paint paint) {
    // Draw snowflake-like shape
    for (int i = 0; i < 6; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 3);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: 0.8,
          height: 0.2,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  void _drawBoostIcon(Canvas canvas, Paint paint) {
    // Draw lightning bolt shape
    final path = Path()
      ..moveTo(0, -0.4)
      ..lineTo(0.2, 0)
      ..lineTo(-0.1, 0)
      ..lineTo(0, 0.4)
      ..lineTo(-0.2, 0)
      ..lineTo(0.1, 0)
      ..close();

    canvas.drawPath(path, paint);
  }
}

class Teleporter extends PositionComponent {
  final bool isEntrance;
  double _rotationAngle = 0.0;

  Teleporter({
    required Vector2 position,
    required this.isEntrance,
  }) : super(position: position, size: Vector2.all(1.0));

  @override
  void update(double dt) {
    _rotationAngle += dt * 2;
    if (_rotationAngle >= math.pi * 2) {
      _rotationAngle = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.rotate(_rotationAngle);

    final paint = Paint()
      ..color = isEntrance ? Colors.purple : Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.1;

    // Draw portal effect
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset.zero,
        0.3 + (i * 0.2),
        paint,
      );
    }

    canvas.restore();
  }
}

class TeleporterPair {
  final Teleporter entrance;
  final Teleporter exit;

  TeleporterPair({
    required this.entrance,
    required this.exit,
  });
}

class LevelCompleteOverlay extends BodyComponent with TapCallbacks {
  final Vector2 _position;
  final Vector2 size;
  final int stars;
  final VoidCallback onContinue;

  LevelCompleteOverlay({
    required Vector2 position,
    required this.size,
    required this.stars,
    required this.onContinue,
  }) : _position = position;

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: _position,
      type: BodyType.static,
    );

    final body = world.createBody(bodyDef);
    final shape = PolygonShape()..setAsBox(1, 1, Vector2.zero(), 0);

    final fixtureDef = FixtureDef(
      shape,
      isSensor: true,
    );

    body.createFixture(fixtureDef);
    return body;
  }

  @override
  void render(Canvas canvas) {
    // Render semi-transparent background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = Colors.black.withOpacity(0.8),
    );

    // Render level complete content
    final textSpan = TextSpan(
      text: 'Level Complete!\n\n',
      style: TextStyle(
        color: Colors.white,
        fontSize: size.y * 0.05,
        fontWeight: FontWeight.bold,
      ),
      children: [
        TextSpan(
          text: 'Stars: ' + '★' * stars,
          style: const TextStyle(
            color: Colors.yellow,
            fontSize: 32,
          ),
        ),
      ],
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.x - textPainter.width) / 2,
        (size.y - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool onTapUp(TapUpEvent event) {
    onContinue();
    return true;
  }
}

class PlacedObstacle extends Obstacle {
  final ObstacleTemplate template;

  PlacedObstacle({
    required this.template,
    required Vector2 position,
    required Vector2 size,
  }) : super(
          position: position,
          size: size,
          isRotatable: true,
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Add special rendering based on obstacle type
    switch (template.type) {
      case ObstacleType.platform:
        _renderPlatform(canvas);
        break;
      case ObstacleType.slope:
        _renderSlope(canvas);
        break;
      case ObstacleType.funnel:
        _renderFunnel(canvas);
        break;
    }
  }

  void _renderPlatform(Canvas canvas) {
    // Add grip marks
    final spacing = size.x / 6;
    for (int i = -2; i <= 2; i++) {
      canvas.drawLine(
        Offset(i * spacing, -size.y / 3),
        Offset(i * spacing, size.y / 3),
        Paint()
          ..color = Colors.white.withOpacity(0.5)
          ..strokeWidth = 0.05,
      );
    }
  }

  void _renderSlope(Canvas canvas) {
    // Add directional arrow
    final path = Path()
      ..moveTo(-size.x / 3, size.y / 2)
      ..lineTo(0, -size.y / 2)
      ..lineTo(size.x / 3, size.y / 2);

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.05,
    );
  }

  void _renderFunnel(Canvas canvas) {
    // Draw V-shape guides
    canvas.drawLine(
      Offset(-size.x / 4, -size.y / 2),
      Offset(0, size.y / 2),
      Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..strokeWidth = 0.05,
    );

    canvas.drawLine(
      Offset(size.x / 4, -size.y / 2),
      Offset(0, size.y / 2),
      Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..strokeWidth = 0.05,
    );
  }
}

class ObstacleSelector extends PositionComponent {
  final Function(ObstacleTemplate) onSelect;
  final List<ObstacleTemplate> availableObstacles;

  ObstacleSelector({
    required Vector2 position,
    required this.onSelect,
    required this.availableObstacles,
  }) : super(position: position);

  @override
  void render(Canvas canvas) {
    // Draw selector background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 300, 80),
      Paint()
        ..color = Colors.grey.withOpacity(0.2)
        ..style = PaintingStyle.fill,
    );

    // Draw available obstacles
    double offsetX = 20;
    for (final template in availableObstacles) {
      if (template.count > 0) {
        _drawObstaclePreview(canvas, template, offsetX);
        offsetX += 100;
      }
    }
  }

  void _drawObstaclePreview(
      Canvas canvas, ObstacleTemplate template, double x) {
    // Draw obstacle preview
    final previewRect = Rect.fromLTWH(x, 20, 60, 40);
    canvas.drawRect(
      previewRect,
      Paint()
        ..color = _getObstacleColor(template.type)
        ..style = PaintingStyle.fill,
    );

    // Draw count
    final textSpan = TextSpan(
      text: 'x${template.count}',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, Offset(x + 30, 65));
  }

  Color _getObstacleColor(ObstacleType type) {
    switch (type) {
      case ObstacleType.platform:
        return Colors.blue;
      case ObstacleType.slope:
        return Colors.green;
      case ObstacleType.funnel:
        return Colors.orange;
    }
  }
}

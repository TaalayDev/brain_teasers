import 'dart:async';
import 'dart:math';

import 'package:flame/events.dart';
import 'package:flame/components.dart' hide Timer;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game_controller.dart';

class ShapeShadowsGame extends World with Game, TapDetector {
  final Map<String, dynamic> gameData;
  final GameController gameController;

  int score = 0;
  int level = 1;
  bool isGameOver = false;
  bool isPaused = false;

  late List<ShapeObject> fallingShapes = [];
  late List<ShadowTarget> shadowTargets = [];
  late Timer spawnTimer;

  double spawnInterval = 3.0; // Seconds between shape spawns
  double shapeSpeed = 100.0; // Pixels per second
  int maxSimultaneousShapes = 3;
  int successfulMatches = 0;
  int missedShapes = 0;

  final Random random = Random();

  ShapeShadowsGame({
    required this.gameData,
    required this.gameController,
  });

  @override
  void onLoad() {
    Timer(const Duration(seconds: 1), () {
      _initializeGame();
      _startSpawning();
    });
  }

  void _initializeGame() async {
    // Create initial shadow targets
    _generateShadowTargets();

    // Add UI components
    add(ScoreDisplay());
  }

  void _generateShadowTargets() {
    shadowTargets.clear();
    final targetWidth = size.x / 4;
    final targetY = size.y - 100;

    for (int i = 0; i < 4; i++) {
      final shape = _generateRandomShape();
      final shadow = ShadowTarget(
        position: Vector2(
          targetWidth * i + targetWidth / 2,
          targetY,
        ),
        shape: shape,
        size: Vector2(60, 60),
      );
      shadowTargets.add(shadow);
      add(shadow);
    }
  }

  ShapeType _generateRandomShape() {
    final shapes = ShapeType.values;
    return shapes[random.nextInt(shapes.length)];
  }

  void _startSpawning() {
    spawnTimer = Timer.periodic(
      Duration(milliseconds: (spawnInterval * 1000).toInt()),
      (timer) {
        if (!isPaused &&
            !isGameOver &&
            fallingShapes.length < maxSimultaneousShapes) {
          _spawnShape();
        }
      },
    );
  }

  void _spawnShape() {
    final targetIndex = random.nextInt(shadowTargets.length);
    final targetShape = shadowTargets[targetIndex].shape;

    final shape = ShapeObject(
      position: Vector2(
        shadowTargets[targetIndex].position.x,
        -50, // Start above screen
      ),
      shape: targetShape,
      size: Vector2(60, 60),
      targetIndex: targetIndex,
    );

    fallingShapes.add(shape);
    add(shape);
  }

  @override
  void update(double dt) {
    if (isPaused || isGameOver) return;

    for (final shape in fallingShapes) {
      shape.position.y += shapeSpeed * dt;

      // Check for matches
      if (shape.position.y >=
          shadowTargets[shape.targetIndex].position.y - 10) {
        _handleShapeLanding(shape);
      }
    }

    fallingShapes.removeWhere((shape) => shape.shouldRemove);
  }

  void _handleShapeLanding(ShapeObject shape) {
    final target = shadowTargets[shape.targetIndex];

    if (shape.shape == target.shape) {
      // Successful match
      _handleSuccessfulMatch(shape);
    } else {
      // Failed match
      _handleFailedMatch(shape);
    }

    shape.shouldRemove = true;
  }

  void _handleSuccessfulMatch(ShapeObject shape) {
    successfulMatches++;
    score += 100 * level;
    gameController.updateScore(score);

    // Add success effects
    add(MatchEffectComponent(
      position: shape.position,
      color: Colors.green,
    ));

    // Check for level progression
    if (successfulMatches >= 10) {
      _levelUp();
    }
  }

  void _handleFailedMatch(ShapeObject shape) {
    missedShapes++;
    score = max(0, score - 50);
    gameController.updateScore(score);

    // Add failure effects
    add(MatchEffectComponent(
      position: shape.position,
      color: Colors.red,
    ));

    // Check for game over
    if (missedShapes >= 3) {
      _handleGameOver();
    }
  }

  void _levelUp() {
    level++;
    successfulMatches = 0;
    spawnInterval = max(1.0, spawnInterval - 0.2);
    shapeSpeed += 20;

    // Generate new shadow targets
    _generateShadowTargets();

    // Add level up effects
    add(LevelUpEffect());
  }

  void _handleGameOver() {
    isGameOver = true;
    spawnTimer.cancel();

    // Show game over overlay
    add(GameOverOverlay(
      score: score,
      level: level,
      onRestart: _restartGame,
    ));
  }

  void _restartGame() {
    isGameOver = false;
    score = 0;
    level = 1;
    successfulMatches = 0;
    missedShapes = 0;
    spawnInterval = 3.0;
    shapeSpeed = 100.0;

    // Clear existing shapes
    fallingShapes.clear();

    // Reinitialize game
    _initializeGame();
    _startSpawning();
  }
}

enum ShapeType {
  triangle,
  square,
  circle,
  hexagon,
  star,
}

class ShapeObject extends PositionComponent {
  final ShapeType shape;
  final int targetIndex;
  bool shouldRemove = false;
  double rotationAngle = 0;

  ShapeObject({
    required Vector2 position,
    required Vector2 size,
    required this.shape,
    required this.targetIndex,
  }) : super(position: position, size: size);

  @override
  void render(Canvas canvas) {
    // Draw shape with gradient and shadow
    final center = Offset(size.x / 2, size.y / 2);

    // Draw shadow
    canvas.save();
    canvas.translate(4, 4);
    _drawShape(
      canvas,
      center,
      Paint()..color = Colors.black.withOpacity(0.3),
    );
    canvas.restore();

    // Draw main shape
    final gradient = RadialGradient(
      center: const Alignment(-0.5, -0.5),
      radius: 1.2,
      colors: [
        Colors.white,
        _getShapeColor(),
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCenter(
          center: center,
          width: size.x,
          height: size.y,
        ),
      );

    _drawShape(canvas, center, paint);
  }

  Color _getShapeColor() {
    switch (shape) {
      case ShapeType.triangle:
        return Colors.red;
      case ShapeType.square:
        return Colors.blue;
      case ShapeType.circle:
        return Colors.green;
      case ShapeType.hexagon:
        return Colors.purple;
      case ShapeType.star:
        return Colors.orange;
    }
  }

  void _drawShape(Canvas canvas, Offset center, Paint paint) {
    switch (shape) {
      case ShapeType.triangle:
        _drawTriangle(canvas, center, paint);
        break;
      case ShapeType.square:
        _drawSquare(canvas, center, paint);
        break;
      case ShapeType.circle:
        _drawCircle(canvas, center, paint);
        break;
      case ShapeType.hexagon:
        _drawHexagon(canvas, center, paint);
        break;
      case ShapeType.star:
        _drawStar(canvas, center, paint);
        break;
    }
  }

  // Shape drawing implementations...
  void _drawTriangle(Canvas canvas, Offset center, Paint paint) {
    final path = Path();
    final radius = size.x * 0.4;

    for (int i = 0; i < 3; i++) {
      final angle = (i * 2 * pi / 3) - pi / 6;
      final point = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawSquare(Canvas canvas, Offset center, Paint paint) {
    final rect = Rect.fromCenter(
      center: center,
      width: size.x * 0.7,
      height: size.y * 0.7,
    );
    canvas.drawRect(rect, paint);
  }

  void _drawCircle(Canvas canvas, Offset center, Paint paint) {
    canvas.drawCircle(center, size.x * 0.35, paint);
  }

  void _drawHexagon(Canvas canvas, Offset center, Paint paint) {
    final path = Path();
    final radius = size.x * 0.35;

    for (int i = 0; i < 6; i++) {
      final angle = (i * 2 * pi / 6) - pi / 2;
      final point = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawStar(Canvas canvas, Offset center, Paint paint) {
    final path = Path();
    final outerRadius = size.x * 0.35;
    final innerRadius = outerRadius * 0.4;
    const points = 5;

    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (i * pi / points) - pi / 2;
      final point = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }
}

class ShadowTarget extends PositionComponent {
  final ShapeType shape;

  ShadowTarget({
    required Vector2 position,
    required Vector2 size,
    required this.shape,
  }) : super(position: position, size: size);

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);

    // Draw shadow outline
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawRect(
      Rect.fromLTWH(-5, -5, size.x + 10, size.y + 10),
      Paint()
        ..color = Colors.white.withOpacity(0.1)
        ..style = PaintingStyle.fill,
    );

    // Draw shape shadow
    final shapePaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final shapeObject = ShapeObject(
      position: Vector2.zero(),
      size: size,
      shape: shape,
      targetIndex: 0,
    );

    shapeObject._drawShape(canvas, center, shapePaint);
  }
}

// Effect components implementation...
class MatchEffectComponent extends PositionComponent {
  final Color color;
  double opacity = 1.0;
  final List<PathParticle> particles = [];
  final Random random = Random();

  MatchEffectComponent({
    required Vector2 position,
    required this.color,
  }) : super(position: position) {
    _initializeParticles();
  }

  void _initializeParticles() {
    for (int i = 0; i < 20; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final speed = random.nextDouble() * 200 + 100;
      final size = random.nextDouble() * 10 + 5;

      particles.add(PathParticle(
        position: Vector2.zero(),
        velocity: Vector2(cos(angle), sin(angle)) * speed,
        size: size,
        color: color,
      ));
    }
  }

  @override
  void update(double dt) {
    opacity -= dt;
    if (opacity <= 0) {
      removeFromParent();
      return;
    }

    for (final particle in particles) {
      particle.update(dt);
    }
  }

  @override
  void render(Canvas canvas) {
    for (final particle in particles) {
      particle.render(canvas, opacity);
    }

    // Draw expanding ring
    canvas.drawCircle(
      Offset.zero,
      50 * (1 - opacity),
      Paint()
        ..color = color.withOpacity(opacity * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}

class PathParticle {
  Vector2 position;
  Vector2 velocity;
  final double size;
  final Color color;
  double rotation = 0;

  PathParticle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.color,
  });

  void update(double dt) {
    position += velocity * dt;
    velocity.y += 500 * dt; // Gravity
    rotation += dt * 5;
  }

  void render(Canvas canvas, double opacity) {
    canvas.save();
    canvas.translate(position.x, position.y);
    canvas.rotate(rotation);

    final path = Path();
    path.addPolygon([
      Offset(-size / 2, -size / 2),
      Offset(size / 2, -size / 2),
      Offset(0, size / 2),
    ], true);

    canvas.drawPath(
      path,
      Paint()..color = color.withOpacity(opacity),
    );
    canvas.restore();
  }
}

class LevelUpEffect extends PositionComponent with HasGameRef {
  double opacity = 0.0;
  bool growing = true;
  final List<ShineParticle> shineParticles = [];

  LevelUpEffect() : super(position: Vector2.zero()) {
    _initializeShineParticles();
  }

  void _initializeShineParticles() {
    const numParticles = 12;
    for (int i = 0; i < numParticles; i++) {
      final angle = (i * 2 * pi) / numParticles;
      shineParticles.add(ShineParticle(angle));
    }
  }

  @override
  void update(double dt) {
    if (growing) {
      opacity += dt * 2;
      if (opacity >= 1.0) {
        growing = false;
      }
    } else {
      opacity -= dt;
      if (opacity <= 0) {
        removeFromParent();
        return;
      }
    }

    for (final particle in shineParticles) {
      particle.update(dt);
    }
  }

  @override
  void render(Canvas canvas) {
    final size = gameRef.size;
    final center = Offset(size.x / 2, size.y / 2);

    // Draw radial gradient background
    canvas.drawCircle(
      center,
      size.length,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withOpacity(opacity * 0.3),
            Colors.white.withOpacity(0),
          ],
        ).createShader(Rect.fromCenter(
          center: center,
          width: size.x,
          height: size.y,
        )),
    );

    // Draw shine particles
    canvas.save();
    canvas.translate(center.dx, center.dy);
    for (final particle in shineParticles) {
      particle.render(canvas, opacity);
    }
    canvas.restore();

    // Draw level up text
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'LEVEL UP!',
        style: TextStyle(
          color: Colors.white.withOpacity(opacity),
          fontSize: 48,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.blue.withOpacity(opacity),
              blurRadius: 10,
            ),
          ],
        ),
      ),
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
}

class ShineParticle {
  final double angle;
  double length = 0;
  double speed = 1;

  ShineParticle(this.angle);

  void update(double dt) {
    length += speed * dt;
    if (length > 1.5) {
      speed = -1;
    } else if (length < 0) {
      speed = 1;
    }
  }

  void render(Canvas canvas, double opacity) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(opacity),
          Colors.white.withOpacity(0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, 100 * length, 10));

    canvas.save();
    canvas.rotate(angle);
    canvas.drawRect(
      Rect.fromLTWH(0, -2, 100 * length, 4),
      paint,
    );
    canvas.restore();
  }
}

class ScoreDisplay extends PositionComponent with HasGameRef {
  final TextPainter _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.left,
  );

  @override
  void render(Canvas canvas) {
    final text = 'Score: 1';
    _textPainter.text = TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.black,
            blurRadius: 4,
          ),
        ],
      ),
    );

    _textPainter.layout();
    _textPainter.paint(canvas, Offset.zero);
  }
}

class GameOverOverlay extends PositionComponent with HasGameRef {
  final int score;
  final int level;
  final VoidCallback onRestart;
  final TextPainter _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );

  GameOverOverlay({
    required this.score,
    required this.level,
    required this.onRestart,
  });

  @override
  void render(Canvas canvas) {
    final size = gameRef.size;

    // Draw semi-transparent background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = Colors.black.withOpacity(0.7),
    );

    // Draw game over text
    _drawText(
      canvas,
      'Game Over',
      const Offset(0, -100),
      48,
      Colors.red,
    );

    // Draw score and level
    _drawText(
      canvas,
      'Score: $score',
      const Offset(0, 0),
      32,
      Colors.white,
    );

    _drawText(
      canvas,
      'Level: $level',
      const Offset(0, 50),
      32,
      Colors.white,
    );

    // Draw restart button
    final buttonRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y / 2 + 150),
        width: 200,
        height: 60,
      ),
      const Radius.circular(30),
    );

    canvas.drawRRect(
      buttonRect,
      Paint()..color = Colors.blue,
    );

    _drawText(
      canvas,
      'Restart',
      Offset(0, 150),
      24,
      Colors.white,
    );
  }

  void _drawText(
      Canvas canvas, String text, Offset offset, double fontSize, Color color) {
    _textPainter.text = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        shadows: const [
          Shadow(
            color: Colors.black,
            blurRadius: 4,
          ),
        ],
      ),
    );

    _textPainter.layout(
      minWidth: 0,
      maxWidth: gameRef.size.x,
    );

    _textPainter.paint(
      canvas,
      Offset(
        (gameRef.size.x - _textPainter.width) / 2,
        (gameRef.size.y - _textPainter.height) / 2 + offset.dy,
      ),
    );
  }

  @override
  bool onTapDown(TapDownEvent event) {
    final buttonRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(gameRef.size.x / 2, gameRef.size.y / 2 + 150),
        width: 200,
        height: 60,
      ),
      const Radius.circular(30),
    );

    if (buttonRect.contains(event.localPosition.toOffset())) {
      onRestart();
      return true;
    }
    return false;
  }
}

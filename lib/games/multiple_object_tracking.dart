import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flame_forge2d/flame_forge2d.dart' hide Particle;
import 'dart:math' as math;

import '../theme/app_theme.dart';

class MultipleObjectTrackingGame extends Forge2DGame {
  final Map<String, dynamic> gameData;
  final Function(int score) onScoreUpdate;
  final VoidCallback onComplete;

  late int targetCount;
  late int distractorCount;
  late double movementSpeed;
  late double duration;

  late List<TrackingBall> targetBalls = [];
  late List<TrackingBall> distractorBalls = [];
  late List<TrackingBall> selectedBalls = [];

  int score = 0;
  int phase = 0; // 0: Highlight, 1: Track, 2: Select
  double timeLeft = 0;
  bool isGameOver = false;

  MultipleObjectTrackingGame({
    required this.gameData,
    required this.onScoreUpdate,
    required this.onComplete,
  }) : super(zoom: 50, gravity: Vector2.zero());

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Initialize game parameters
    targetCount = gameData['targets'] ?? 3;
    distractorCount = gameData['distractors'] ?? 5;
    movementSpeed = gameData['speed'] ?? 5.0;
    duration = gameData['duration'] ?? 5.0;
    timeLeft = duration;

    addAll([
      _GameWorldComponent(
        onLoad: () {
          _addBoundaries();
          _initializeBalls();
          _startHighlightPhase();
        },
      ),
    ]);
  }

  void _addBoundaries() {
    final rect = camera.visibleWorldRect;
    final size = Vector2(rect.width, rect.height);

    final topLeft = Vector2(-size.x / 2, -size.y / 2);
    final bottomRight = Vector2(size.x / 2, size.y / 2);

    final walls = [
      // Top wall
      Wall(
        Vector2((bottomRight.x - topLeft.x) / 2 + topLeft.x, topLeft.y),
        Vector2(bottomRight.x - topLeft.x, 0.2),
      ),
      // Bottom wall
      Wall(
        Vector2((bottomRight.x - topLeft.x) / 2 + topLeft.x, bottomRight.y),
        Vector2(bottomRight.x - topLeft.x, 0.2),
      ),
      // Left wall
      Wall(
        Vector2(topLeft.x, (bottomRight.y - topLeft.y) / 2 + topLeft.y),
        Vector2(0.2, bottomRight.y - topLeft.y),
      ),
      // Right wall
      Wall(
        Vector2(bottomRight.x, (bottomRight.y - topLeft.y) / 2 + topLeft.y),
        Vector2(0.2, bottomRight.y - topLeft.y),
      ),
    ];

    walls.forEach(world.add);
  }

  void _initializeBalls() {
    final rect = camera.visibleWorldRect;
    final radius = math.min(rect.width, rect.height) * 0.02;

    // Create target balls
    for (int i = 0; i < targetCount; i++) {
      final position = _getRandomPosition(radius);
      final ball = TrackingBall(
        position: position,
        radius: radius,
        isTarget: true,
        speed: movementSpeed,
      );
      targetBalls.add(ball);
      world.add(ball);
    }

    // Create distractor balls
    for (int i = 0; i < distractorCount; i++) {
      final position = _getRandomPosition(radius);
      final ball = TrackingBall(
        position: position,
        radius: radius,
        isTarget: false,
        speed: movementSpeed,
      );
      distractorBalls.add(ball);
      world.add(ball);
    }
  }

  Vector2 _getRandomPosition(double radius) {
    final random = math.Random();
    final rect = camera.visibleWorldRect;
    final margin = radius * 2;

    return Vector2(
      rect.left + margin + random.nextDouble() * (rect.width - margin * 2),
      rect.top + margin + random.nextDouble() * (rect.height - margin * 2),
    );
  }

  void _startHighlightPhase() {
    phase = 0;
    for (final ball in targetBalls) {
      ball.highlight();
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (!isGameOver) {
        _startTrackingPhase();
      }
    });
  }

  void _startTrackingPhase() {
    phase = 1;
    for (final ball in [...targetBalls, ...distractorBalls]) {
      ball.startMoving();
    }

    timeLeft = duration;
  }

  void _startSelectionPhase() {
    phase = 2;
    for (final ball in [...targetBalls, ...distractorBalls]) {
      ball.stopMoving();
    }
  }

  void onBallTapped(TrackingBall ball) {
    if (phase != 2 || selectedBalls.length >= targetCount) return;

    selectedBalls.add(ball);
    ball.select();

    if (selectedBalls.length == targetCount) {
      _checkResults();
    }
  }

  void _checkResults() {
    int correctSelections = 0;

    for (final ball in selectedBalls) {
      if (ball.isTarget) {
        correctSelections++;
        _showCorrectSelectionEffect(ball);
      } else {
        _showIncorrectSelectionEffect(ball);
      }
    }

    score = (1000 * (correctSelections / targetCount)).round();
    onScoreUpdate(score);

    Future.delayed(const Duration(seconds: 1), () {
      if (correctSelections == targetCount) {
        onComplete();
      } else {
        isGameOver = true;
      }
    });
  }

  void _showCorrectSelectionEffect(TrackingBall ball) {
    final effect = ParticleSystemComponent(
      particle: Particle.generate(
        count: 20,
        lifespan: 0.5,
        generator: (i) {
          final angle = math.Random().nextDouble() * 2 * math.pi;
          final speed = math.Random().nextDouble() * 2 + 1;
          return AcceleratedParticle(
            acceleration: Vector2(0, 9.8),
            speed: Vector2(math.cos(angle), math.sin(angle)) * speed,
            position: ball.position.clone(),
            child: CircleParticle(
              radius: 0.05,
              paint: Paint()..color = AppTheme.correctAnswerColor,
            ),
          );
        },
      ),
    );

    world.add(effect);
  }

  void _showIncorrectSelectionEffect(TrackingBall ball) {
    final effect = ParticleSystemComponent(
      particle: Particle.generate(
        count: 10,
        lifespan: 0.5,
        generator: (i) {
          final angle = math.Random().nextDouble() * 2 * math.pi;
          return AcceleratedParticle(
            acceleration: Vector2.zero(),
            speed: Vector2(math.cos(angle), math.sin(angle)) * 2,
            position: ball.position.clone(),
            child: CircleParticle(
              radius: 0.05,
              paint: Paint()..color = AppTheme.wrongAnswerColor,
            ),
          );
        },
      ),
    );

    world.add(effect);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (phase == 1 && !isGameOver) {
      timeLeft -= dt;
      if (timeLeft <= 0) {
        _startSelectionPhase();
      }
    }
  }
}

class _GameWorldComponent extends Component
    with HasGameRef<MultipleObjectTrackingGame> {
  final VoidCallback _onLoad;

  _GameWorldComponent({required VoidCallback onLoad}) : _onLoad = onLoad;

  @override
  Future<void> onMount() async {
    final rect = game.camera.visibleWorldRect;
    if (rect.width > 0 && rect.height > 0) {
      _onLoad();
    } else {
      // Wait for next frame if camera rect is not ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onLoad();
      });
    }
  }
}

class TrackingBall extends BodyComponent with TapCallbacks {
  final double radius;
  final bool isTarget;
  final double speed;
  bool isHighlighted = false;
  bool isSelected = false;
  Vector2 velocity = Vector2.zero();
  late Paint _paint;
  final Vector2 _position;

  TrackingBall({
    required Vector2 position,
    required this.radius,
    required this.isTarget,
    required this.speed,
  }) : _position = position {
    _paint = Paint()..color = Colors.white;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    renderBody = true;
  }

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: _position,
      type: BodyType.dynamic,
      userData: this,
      linearDamping: 0,
      angularDamping: 0,
      bullet: true,
    );

    final body = world.createBody(bodyDef);
    final shape = CircleShape()..radius = radius;

    final fixtureDef = FixtureDef(
      shape,
      density: 1.0,
      friction: 0.0,
      restitution: 1.0,
      userData: this,
    );

    body.createFixture(fixtureDef);
    return body;
  }

  void highlight() {
    isHighlighted = true;
    _paint.color = AppTheme.primaryColor;
  }

  void select() {
    isSelected = true;
    _paint.color =
        isTarget ? AppTheme.correctAnswerColor : AppTheme.wrongAnswerColor;
  }

  void startMoving() {
    isHighlighted = false;
    _paint.color = Colors.white;

    final random = math.Random();
    final angle = random.nextDouble() * 2 * math.pi;
    velocity = Vector2(math.cos(angle), math.sin(angle)) * speed;
    body.linearVelocity = velocity;
  }

  void stopMoving() {
    body.linearVelocity = Vector2.zero();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset.zero,
      radius,
      _paint,
    );

    if (isHighlighted || isSelected) {
      canvas.drawCircle(
        Offset.zero,
        radius * 1.2,
        Paint()
          ..color = _paint.color.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.1,
      );
    }
  }

  @override
  bool onTapDown(event) {
    final game = findGame()! as MultipleObjectTrackingGame;
    game.onBallTapped(this);
    return true;
  }
}

class Wall extends BodyComponent {
  final Vector2 position;
  final Vector2 size;

  Wall(this.position, this.size);

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: position,
      type: BodyType.static,
    );

    final body = world.createBody(bodyDef);
    final shape = PolygonShape()
      ..setAsBox(size.x / 2, size.y / 2, Vector2.zero(), 0.0);
    body.createFixture(FixtureDef(shape));
    return body;
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: size.x,
      height: size.y,
    );

    canvas.drawRect(
      rect,
      Paint()..color = AppTheme.secondaryColor,
    );
  }
}

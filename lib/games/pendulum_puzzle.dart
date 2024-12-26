import 'package:flame/camera.dart';
import 'package:flame/components.dart' hide Timer;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

import '../theme/app_theme.dart';
import 'game_controller.dart';

class PendulumPuzzleGame extends Forge2DGame {
  final Map<String, dynamic> gameData;
  final GameController gameController;

  late int targetAngle;
  late Pendulum pendulum;
  late List<Obstacle> obstacles;
  late Goal goal;
  bool isGameStarted = false;
  bool isGameOver = false;
  int score = 1000;
  int remainingTime = 60;
  Timer? gameTimer;

  PendulumPuzzleGame({
    required this.gameData,
    required this.gameController,
  }) : super(gravity: Vector2(0, 9.8));

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // camera.viewport = FixedResolutionViewport(resolution: Vector2(1000, 1600));

    // Initialize game objects
    _initializeGame();

    // Start game timer
    _startTimer();
  }

  void _initializeGame() {
    // Create pendulum
    pendulum = Pendulum(
      position: Vector2(0, -5),
      length: 5.0,
      bobRadius: 0.5,
    );
    world.add(pendulum);

    // Create obstacles
    obstacles = _createObstacles();
    for (final obstacle in obstacles) {
      world.add(obstacle);
    }

    // Create goal
    goal = Goal(Vector2(4, 3));
    world.add(goal);

    // Set target angle (in degrees)
    targetAngle = 45;
  }

  List<Obstacle> _createObstacles() {
    return [
      Obstacle(Vector2(2, 0), Vector2(1, 0.2)), // Horizontal platform
      Obstacle(Vector2(-2, 2), Vector2(0.2, 2)), // Vertical wall
      Obstacle(Vector2(3, -2), Vector2(1, 0.2)), // Another platform
    ];
  }

  void _startTimer() {
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isGameOver) {
        timer.cancel();
        return;
      }

      remainingTime--;
      if (remainingTime <= 0) {
        _handleTimeUp();
      }
    });
  }

  void _handleTimeUp() {
    isGameOver = true;
    gameTimer?.cancel();
    gameController.loseLive();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!isGameOver && isGameStarted) {
      _checkGoal();
      _updateScore();
    }
  }

  void _checkGoal() {
    if (pendulum.isBobInGoal(goal)) {
      final angleDifference =
          (pendulum.angle * (180 / math.pi) - targetAngle).abs();
      if (angleDifference < 5) {
        // 5-degree tolerance
        _handleSuccess();
      }
    }
  }

  void _handleSuccess() {
    isGameOver = true;
    gameTimer?.cancel();
    gameController.completeGame();
  }

  void _updateScore() {
    // Update score based on time remaining and current angle difference
    final angleDifference =
        (pendulum.angle * (180 / math.pi) - targetAngle).abs();
    final angleScore = math.max(0, 1000 - (angleDifference * 10).round());
    final timeBonus = remainingTime * 10;
    score = math.max(0, angleScore + timeBonus);
    gameController.updateScore(score);
  }

  @override
  void onRemove() {
    gameTimer?.cancel();
    super.onRemove();
  }
}

class Pendulum extends BodyComponent {
  final Vector2 position;
  final double length;
  final double bobRadius;

  late Body pivotBody;
  late Body bobBody;
  late RevoluteJoint joint;

  Pendulum({
    required this.position,
    required this.length,
    required this.bobRadius,
  });

  double get angle => bobBody.angle;

  @override
  Body createBody() {
    // Create pivot point (fixed)
    final pivotDef = BodyDef(
      position: position,
      type: BodyType.static,
    );
    pivotBody = world.createBody(pivotDef);

    // Create bob (dynamic)
    final bobDef = BodyDef(
      position: position + Vector2(0, length),
      type: BodyType.dynamic,
      angularDamping: 0.5,
      linearDamping: 0.3,
    );
    bobBody = world.createBody(bobDef);

    // Create bob shape
    final shape = CircleShape()..radius = bobRadius;
    bobBody.createFixture(
      FixtureDef(shape, density: 1.0, friction: 0.5, restitution: 0.2),
    );

    // Create joint
    final jointDef = RevoluteJointDef()
      ..initialize(pivotBody, bobBody, position)
      ..enableMotor = true
      ..maxMotorTorque = 1000.0;

    joint = RevoluteJoint(jointDef);
    world.createJoint(joint);

    return pivotBody;
  }

  bool isBobInGoal(Goal goal) {
    final distance = (bobBody.position - goal.body.position).length;
    return distance < bobRadius + goal.radius;
  }

  @override
  void render(Canvas canvas) {
    // Draw rope
    canvas.drawLine(
      pivotBody.position.toOffset(),
      bobBody.position.toOffset(),
      Paint()
        ..color = AppTheme.primaryColor
        ..strokeWidth = 0.1
        ..style = PaintingStyle.stroke,
    );

    // Draw bob
    canvas.drawCircle(
      bobBody.position.toOffset(),
      bobRadius,
      Paint()..color = AppTheme.primaryColor,
    );

    // Draw pivot point
    canvas.drawCircle(
      pivotBody.position.toOffset(),
      0.2,
      Paint()..color = AppTheme.secondaryColor,
    );
  }
}

class Obstacle extends BodyComponent {
  final Vector2 position;
  final Vector2 size;

  Obstacle(this.position, this.size);

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: position,
      type: BodyType.static,
    );

    final body = world.createBody(bodyDef);
    final shape = PolygonShape()
      ..setAsBox(
        size.x / 2,
        size.y / 2,
        Vector2.zero(),
        0.0,
      );
    body.createFixture(FixtureDef(shape, friction: 0.3, restitution: 0.2));

    return body;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromCenter(
        center: position.toOffset(),
        width: size.x,
        height: size.y,
      ),
      Paint()..color = AppTheme.secondaryColor,
    );
  }
}

class Goal extends BodyComponent {
  final Vector2 position;
  final double radius = 0.8;

  Goal(this.position);

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: position,
      type: BodyType.static,
    );

    final body = world.createBody(bodyDef);
    final shape = CircleShape()..radius = radius;
    body.createFixture(FixtureDef(shape, isSensor: true));

    return body;
  }

  @override
  void render(Canvas canvas) {
    // Draw outer glow
    canvas.drawCircle(
      position.toOffset(),
      radius * 1.2,
      Paint()
        ..color = AppTheme.correctAnswerColor.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Draw goal
    canvas.drawCircle(
      position.toOffset(),
      radius,
      Paint()..color = AppTheme.correctAnswerColor.withOpacity(0.5),
    );

    // Draw inner circle
    canvas.drawCircle(
      position.toOffset(),
      radius * 0.5,
      Paint()..color = AppTheme.correctAnswerColor,
    );
  }
}

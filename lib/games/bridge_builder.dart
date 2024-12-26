import 'package:brain_teasers/games/components/goal.dart';
import 'package:brain_teasers/utils/boundaries.dart';
import 'package:flame/camera.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'components/ball.dart';

class BridgeBuilderGame extends Forge2DGame with TapCallbacks, DragCallbacks {
  final Function(int score) onScoreUpdate;
  final VoidCallback onComplete;

  late BallBody ball;
  late GoalBody goal;
  late List<Beam> beams = [];
  late List<AnchorPoint> anchorPoints = [];

  int remainingBeams = 5;
  int score = 1000;
  bool isSimulating = false;
  AnchorPoint? selectedAnchor;
  Vector2? beamEndPosition;

  BridgeBuilderGame({
    required this.onScoreUpdate,
    required this.onComplete,
  }) : super(gravity: Vector2.zero());

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Add boundaries
    final worldSize = Vector2(
      camera.visibleWorldRect.width,
      camera.visibleWorldRect.height,
    );
    final bounds = createBoundaries(worldSize);
    world.addAll(bounds);

    // Add ball
    ball = BallBody(
      Vector2(
        -worldSize.x / 3,
        -worldSize.y / 3,
      ),
      radius: 0.5,
    );
    world.add(ball);

    // Add goal
    goal = GoalBody(
      Vector2(
        worldSize.x / 3,
        worldSize.y / 3,
      ),
      radius: 0.3,
    );
    world.add(goal);

    startSimulation();

    // Create anchor points
    _createAnchorPoints(worldSize);
  }

  void _createAnchorPoints(Vector2 worldSize) {
    final gridSize = Vector2(4, 4); // 4x4 grid of anchor points
    final spacing = Vector2(
      worldSize.x / (gridSize.x + 1),
      worldSize.y / (gridSize.y + 1),
    );

    for (int y = 0; y < gridSize.y; y++) {
      for (int x = 0; x < gridSize.x; x++) {
        final position = Vector2(
          -worldSize.x / 2 + spacing.x * (x + 1),
          -worldSize.y / 2 + spacing.y * (y + 1),
        );
        final anchor = AnchorPoint(position: position);
        anchorPoints.add(anchor);
        world.add(anchor);
      }
    }
  }

  List<Wall> createBoundaries(Vector2 worldSize) {
    final halfWidth = worldSize.x / 2;
    final halfHeight = worldSize.y / 2;

    return [
      // Top wall
      Wall(
        Vector2(-halfWidth, -halfHeight),
        Vector2(halfWidth, -halfHeight),
      ),
      // Right wall
      Wall(
        Vector2(halfWidth, -halfHeight),
        Vector2(halfWidth, halfHeight),
      ),
      // Bottom wall
      Wall(
        Vector2(-halfWidth, halfHeight),
        Vector2(halfWidth, halfHeight),
      ),
      // Left wall
      Wall(
        Vector2(-halfWidth, -halfHeight),
        Vector2(-halfWidth, halfHeight),
      ),
    ];
  }

  @override
  bool onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (isSimulating || remainingBeams <= 0) return false;

    final worldPosition = screenToWorld(event.canvasPosition);

    // Find nearest anchor point within snap distance
    const snapDistance = 1.0;
    selectedAnchor = null;
    var minDistance = double.infinity;

    for (final anchor in anchorPoints) {
      final distance = (anchor.body.position - worldPosition).length;
      if (distance < snapDistance && distance < minDistance) {
        selectedAnchor = anchor;
        minDistance = distance;
      }
    }

    if (selectedAnchor != null) {
      beamEndPosition = worldPosition;
      return true;
    }
    return false;
  }

  @override
  bool onDragUpdate(DragUpdateEvent event) {
    if (selectedAnchor == null) return false;
    beamEndPosition = screenToWorld(event.canvasStartPosition);
    return true;
  }

  @override
  bool onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (selectedAnchor != null && beamEndPosition != null) {
      const snapDistance = 1.0;
      AnchorPoint? endAnchor;
      var minDistance = double.infinity;

      // Find nearest end anchor point
      for (final anchor in anchorPoints) {
        if (anchor != selectedAnchor) {
          final distance = (anchor.body.position - beamEndPosition!).length;
          if (distance < snapDistance && distance < minDistance) {
            endAnchor = anchor;
            minDistance = distance;
          }
        }
      }

      if (endAnchor != null) {
        // Create new beam between anchors
        final beam = Beam(
          start: selectedAnchor!.body.position,
          end: endAnchor.body.position,
        );
        beams.add(beam);
        add(beam);
        remainingBeams--;
      }
    }

    selectedAnchor = null;
    beamEndPosition = null;
    return false;
  }

  void startSimulation() {
    if (isSimulating || beams.isEmpty) return;

    isSimulating = true;
    world.gravity = Vector2(0, 9.81); // Standard gravity
    ball.body.setAwake(true);
    ball.body.applyLinearImpulse(Vector2(2, 0)); // Initial rightward momentum
  }

  void reset() {
    world.gravity = Vector2.zero();
    isSimulating = false;

    // Remove existing beams
    for (final beam in beams) {
      world.destroyBody(beam.body);
    }
    beams.clear();

    // Reset ball position
    ball.body.setTransform(Vector2(-15, -10), 0);
    ball.body.linearVelocityFromLocalPoint(Vector2.zero());
    ball.body.angularVelocity = 0;

    // Reset score and beams
    remainingBeams = 5;
    score = 1000;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isSimulating) {
      // Check if ball reached goal
      final distance = (ball.body.position - goal.body.position).length;
      if (distance < 2.0) {
        score = math.max(0, score - (remainingBeams * 100));
        onScoreUpdate(score);
        onComplete();
        reset();
      }

      // Check if ball is out of bounds
      final worldSize = Vector2(
        camera.visibleWorldRect.width,
        camera.visibleWorldRect.height,
      );
      if (ball.body.position.y > worldSize.y / 2) {
        score = math.max(0, score - 100);
        onScoreUpdate(score);
        reset();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw beam preview while dragging
    if (selectedAnchor != null && beamEndPosition != null) {
      canvas.drawLine(
        selectedAnchor!.body.position.toOffset(),
        beamEndPosition!.toOffset(),
        Paint()
          ..color = Colors.blue.withOpacity(0.5)
          ..strokeWidth = 0.2,
      );
    }
  }
}

class AnchorPoint extends BodyComponent {
  final Vector2 position;

  AnchorPoint({required this.position});

  @override
  Body createBody() {
    final shape = CircleShape()..radius = 0.3;

    final fixtureDef = FixtureDef(
      shape,
      density: 0.0,
      friction: 0.0,
    );

    final bodyDef = BodyDef(
      position: position,
      type: BodyType.static,
    );

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {
    // Draw shadow
    canvas.drawCircle(
      const Offset(0.05, 0.05),
      0.3,
      Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Draw anchor point
    canvas.drawCircle(
      Offset.zero,
      0.3,
      Paint()..color = Colors.red,
    );
  }
}

class Beam extends BodyComponent {
  final Vector2 start;
  final Vector2 end;

  Beam({required this.start, required this.end});

  @override
  Body createBody() {
    final center = (start + end) / 2;
    final length = (end - start).length;
    final angle = math.atan2(end.y - start.y, end.x - start.x);

    final shape = PolygonShape()
      ..setAsBox(
        length / 2,
        0.1,
        Vector2.zero(),
        0,
      );

    final fixtureDef = FixtureDef(
      shape,
      density: 1.0,
      friction: 0.5,
      restitution: 0.2,
    );

    final bodyDef = BodyDef(
      position: center,
      angle: angle,
      type: BodyType.static,
    );

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {
    final length = (end - start).length;

    // Draw shadow
    canvas.save();
    canvas.translate(0.05, 0.05);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: length,
        height: 0.2,
      ),
      Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.restore();

    // Draw beam
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: length,
        height: 0.2,
      ),
      Paint()..color = Colors.blue,
    );
  }
}

class Wall extends BodyComponent {
  final Vector2 start;
  final Vector2 end;

  Wall(this.start, this.end);

  @override
  Body createBody() {
    final shape = EdgeShape()..set(start, end);

    final fixtureDef = FixtureDef(
      shape,
      friction: 0.3,
      restitution: 0.2,
    );

    final bodyDef = BodyDef(
      type: BodyType.static,
    );

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawLine(
      start.toOffset(),
      end.toOffset(),
      Paint()
        ..color = Colors.grey
        ..strokeWidth = 0.1,
    );
  }
}

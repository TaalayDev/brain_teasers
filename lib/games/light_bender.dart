import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart' hide RaycastResult;
import 'package:flutter/material.dart';

class LightBenderGame extends Forge2DGame with TapDetector, ScrollDetector {
  LightBenderGame() : super(gravity: Vector2.zero());

  late LaserSource laserSource;
  late Target target;
  late List<GameObstacle> obstacles = [];
  late List<Mirror> mirrors = [];
  late List<Prism> prisms = [];
  late Vector2 worldSize;
  String? selectedTool;
  bool isComplete = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    worldSize = Vector2(
      camera.visibleWorldRect.width,
      camera.visibleWorldRect.height,
    );

    // Add boundaries
    final halfWidth = worldSize.x / 2;
    final halfHeight = worldSize.y / 2;

    world.add(Wall(
      Vector2(-halfWidth, -halfHeight),
      Vector2(halfWidth, -halfHeight),
    )); // Top
    world.add(Wall(
      Vector2(halfWidth, -halfHeight),
      Vector2(halfWidth, halfHeight),
    )); // Right
    world.add(Wall(
      Vector2(-halfWidth, halfHeight),
      Vector2(halfWidth, halfHeight),
    )); // Bottom
    world.add(Wall(
      Vector2(-halfWidth, -halfHeight),
      Vector2(-halfWidth, halfHeight),
    )); // Left

    // Add laser source
    laserSource = LaserSource(Vector2(-halfWidth + 2, 0));
    world.add(laserSource);

    // Add target
    target = Target(Vector2(halfWidth - 2, 0));
    world.add(target);

    // Add initial obstacle
    final obstacle = GameObstacle(
      Vector2(-1, 0),
      size: Vector2(4, 0.4),
      angle: math.pi / 4,
    );
    world.add(obstacle);
    obstacles.add(obstacle);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _updateLaserPath();
  }

  void _updateLaserPath() {
    // Clear existing laser visuals
    children.whereType<LaserBeam>().forEach((beam) => beam.removeFromParent());

    Vector2 currentPos = laserSource.position.clone();
    Vector2 direction = Vector2(1, 0); // Initial direction
    int bounces = 0;
    const maxBounces = 10;

    while (bounces < maxBounces) {
      final rayResult = _castRay(currentPos, direction);
      if (rayResult != null) {
        // Add visible laser beam
        world.add(LaserBeam(currentPos, rayResult.point));

        if (rayResult.body is Mirror) {
          // Handle mirror reflection
          direction = _reflect(direction, rayResult.normal);
          currentPos = rayResult.point;
          bounces++;
        } else if (rayResult.body is Prism) {
          // Handle prism refraction with color splitting
          _createPrismBeams(rayResult.point, direction);
          break;
        } else if (rayResult.body is Target) {
          if (!isComplete) {
            isComplete = true;
            target.activate();
          }
          break;
        } else {
          break;
        }
      } else {
        // Add final beam segment
        world.add(LaserBeam(
          currentPos,
          currentPos + direction * (worldSize.x / 2),
        ));
        break;
      }
    }
  }

  RaycastResult? _castRay(Vector2 start, Vector2 direction) {
    RaycastResult? closestHit;
    var closestDistance = double.infinity;

    world.raycast(
      RayCastCallbackImpl(
        (fixture, point, normal, fraction) {
          final distance = (point - start).length;
          if (distance < closestDistance) {
            closestDistance = distance;

            closestHit = RaycastResult(
              fixture.body,
              point,
              normal,
            );
          }
          // Continue searching for more fixtures
          return 1.0;
        },
      ),
      start,
      start + direction * worldSize.x,
    );

    return closestHit;
  }

  Vector2 _reflect(Vector2 direction, Vector2 normal) {
    final dot = direction.dot(normal);
    return direction - (normal * (2 * dot));
  }

  void _createPrismBeams(Vector2 point, Vector2 direction) {
    final angles = [-math.pi / 8, 0, math.pi / 8]; // Refraction angles
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
    ];

    for (int i = 0; i < angles.length; i++) {
      final refractedDir = _rotate(direction, angles[i].toDouble());
      world.add(LaserBeam(
        point,
        point + refractedDir * (worldSize.x / 2),
        color: colors[i],
      ));
    }
  }

  Vector2 _rotate(Vector2 v, double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return Vector2(
      v.x * cos - v.y * sin,
      v.x * sin + v.y * cos,
    );
  }

  @override
  bool onTapDown(TapDownInfo info) {
    if (selectedTool == null) return false;

    final worldPoint = screenToWorld(info.eventPosition.widget);

    switch (selectedTool) {
      case 'mirror':
        final mirror = Mirror(worldPoint);
        world.add(mirror);
        mirrors.add(mirror);
        break;
      case 'prism':
        final prism = Prism(worldPoint);
        world.add(prism);
        prisms.add(prism);
        break;
    }

    return true;
  }
}

class LaserSource extends BodyComponent {
  final Vector2 startPosition;

  LaserSource(this.startPosition);

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: startPosition,
      type: BodyType.static,
    );

    final shape = CircleShape()..radius = 0.5;
    final fixtureDef = FixtureDef(shape);

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset.zero,
      0.5,
      Paint()..color = Colors.amber,
    );
  }
}

class LaserBeam extends Component {
  final Vector2 start;
  final Vector2 end;
  final Color color;

  LaserBeam(this.start, this.end, {this.color = Colors.amber});

  @override
  void render(Canvas canvas) {
    canvas.drawLine(
      start.toOffset(),
      end.toOffset(),
      Paint()
        ..color = color
        ..strokeWidth = 0.1
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }
}

class Mirror extends BodyComponent {
  final Vector2 position;

  Mirror(this.position);

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: position,
      type: BodyType.static,
    );

    final shape = PolygonShape()..setAsBox(1.0, 0.1, Vector2.zero(), 0);
    final fixtureDef = FixtureDef(shape);

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: 2.0,
      height: 0.2,
    );

    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.grey[300]!
        ..style = PaintingStyle.fill,
    );

    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.05,
    );
  }
}

class Prism extends BodyComponent {
  final Vector2 position;

  Prism(this.position);

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: position,
      type: BodyType.static,
    );

    final vertices = [
      Vector2(0, -0.866),
      Vector2(0.5, 0.433),
      Vector2(-0.5, 0.433),
    ];

    final shape = PolygonShape()..set(vertices);
    final fixtureDef = FixtureDef(shape);

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {
    final path = Path()
      ..moveTo(0, -0.866)
      ..lineTo(0.5, 0.433)
      ..lineTo(-0.5, 0.433)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.05,
    );
  }
}

class Target extends BodyComponent {
  final Vector2 position;
  bool isActive = false;

  Target(this.position);

  void activate() {
    isActive = true;
  }

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: position,
      type: BodyType.static,
    );

    final shape = CircleShape()..radius = 0.5;
    final fixtureDef = FixtureDef(shape);

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset.zero,
      0.5,
      Paint()
        ..color = isActive ? Colors.amber : Colors.green
        ..style = PaintingStyle.fill,
    );
  }
}

class GameObstacle extends BodyComponent {
  final Vector2 position;
  final Vector2 size;
  final double angle;

  GameObstacle(
    this.position, {
    required this.size,
    this.angle = 0,
  });

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: position,
      type: BodyType.static,
      angle: angle,
    );

    final shape = PolygonShape()
      ..setAsBox(size.x / 2, size.y / 2, Vector2.zero(), 0);
    final fixtureDef = FixtureDef(shape);

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: size.x,
        height: size.y,
      ),
      Paint()..color = Colors.grey[700]!,
    );
  }
}

class Wall extends BodyComponent {
  final Vector2 start;
  final Vector2 end;

  Wall(this.start, this.end);

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: Vector2.zero(),
      type: BodyType.static,
    );

    final shape = EdgeShape()..set(start, end);
    final fixtureDef = FixtureDef(shape);

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}

class RayCastCallbackImpl extends RayCastCallback {
  final Function(
    Fixture fixture,
    Vector2 point,
    Vector2 normal,
    double fraction,
  ) callback;

  RayCastCallbackImpl(this.callback);

  @override
  double reportFixture(
    Fixture fixture,
    Vector2 point,
    Vector2 normal,
    double fraction,
  ) {
    return callback(fixture, point, normal, fraction);
  }
}

class RaycastResult {
  final Body body;
  final Vector2 point;
  final Vector2 normal;

  RaycastResult(this.body, this.point, this.normal);
}

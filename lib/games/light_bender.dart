import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart' hide RaycastResult;
import 'package:flutter/material.dart';

class LightBenderGame extends Forge2DGame with TapDetector {
  LightBenderGame() : super(gravity: Vector2.zero());

  late LaserSource laserSource;
  late Target target;
  List<GameObstacle> obstacles = [];
  List<Mirror> mirrors = [];
  List<Prism> prisms = [];
  late Vector2 worldSize;
  String? selectedTool;
  bool isComplete = false;
  int currentLevelIndex = 0;

  final List<LevelData> levelData = [
    LevelData(
      laserSourcePosition: Vector2(-8 + 2, 0),
      laserSourceAngle: 0,
      targetPosition: Vector2(8 - 2, 0),
      targetRequiredColor: 'white',
      obstacleData: [
        ObstacleData(Vector2(-1, 0), Vector2(4, 0.4), math.pi / 4),
      ],
    ),
    LevelData(
      laserSourcePosition: Vector2(-8 + 2, -4 + 2),
      laserSourceAngle: math.pi / 4,
      targetPosition: Vector2(8 - 2, 4 - 2),
      targetRequiredColor: 'red',
      obstacleData: [
        ObstacleData(Vector2(0, 0), Vector2(2, 2), 0),
        ObstacleData(Vector2(3, 3), Vector2(1, 1), math.pi / 6),
      ],
    ),
  ];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    worldSize =
        Vector2(camera.visibleWorldRect.width, camera.visibleWorldRect.height);
    final halfWidth = worldSize.x / 2;
    final halfHeight = worldSize.y / 2;

    // Add boundaries
    world.addAll([
      Wall(Vector2(-halfWidth, -halfHeight),
          Vector2(halfWidth, -halfHeight)), // Top
      Wall(Vector2(halfWidth, -halfHeight),
          Vector2(halfWidth, halfHeight)), // Right
      Wall(Vector2(-halfWidth, halfHeight),
          Vector2(halfWidth, halfHeight)), // Bottom
      Wall(Vector2(-halfWidth, -halfHeight),
          Vector2(-halfWidth, halfHeight)), // Left
    ]);

    // Load initial level
    loadLevel();

    // Add tool selection UI
    add(ToolSelectionComponent(this)..priority = 100);
  }

  void loadLevel() {
    if (currentLevelIndex >= levelData.length) {
      print('Game Completed!');
      return;
    }

    final level = levelData[currentLevelIndex];

    // Remove existing components
    world.remove(laserSource);
    world.remove(target);
    obstacles.forEach(world.remove);
    mirrors.forEach(world.remove);
    prisms.forEach(world.remove);
    obstacles.clear();
    mirrors.clear();
    prisms.clear();

    // Add new components
    laserSource = LaserSource(level.laserSourcePosition)
      ..angle = level.laserSourceAngle;
    world.add(laserSource);
    target =
        Target(level.targetPosition, requiredColor: level.targetRequiredColor);
    world.add(target);
    for (final obsData in level.obstacleData) {
      final obs = GameObstacle(obsData.position,
          size: obsData.size, angle: obsData.angle);
      world.add(obs);
      obstacles.add(obs);
    }

    isComplete = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _updateLaserPath();
  }

  void _updateLaserPath() {
    children.whereType<LaserBeam>().forEach((beam) => beam.removeFromParent());

    List<Ray> activeRays = [
      Ray(
          laserSource.position,
          Vector2(math.cos(laserSource.angle), math.sin(laserSource.angle)),
          'white'),
    ];
    int iterations = 0;
    const maxIterations = 100;

    while (activeRays.isNotEmpty && iterations < maxIterations) {
      iterations++;
      List<Ray> newRays = [];

      for (final ray in activeRays) {
        final rayResult = _castRay(ray.position, ray.direction);
        if (rayResult != null) {
          world.add(LaserBeam(ray.position, rayResult.point,
              color: _getColor(ray.color)));
          final hitBody = rayResult.body;

          if (hitBody is Mirror) {
            final reflectedDir = _reflect(ray.direction, rayResult.normal);
            newRays.add(Ray(rayResult.point, reflectedDir, ray.color));
          } else if (hitBody is Prism && ray.color == 'white') {
            final angles = [-math.pi / 8, 0, math.pi / 8];
            final colors = ['red', 'green', 'blue'];
            for (int i = 0; i < 3; i++) {
              final newDir = _rotate(ray.direction, angles[i].toDouble());
              newRays.add(Ray(rayResult.point, newDir, colors[i]));
            }
          } else if (hitBody is Target) {
            if ((hitBody as Target).requiredColor == null ||
                (hitBody as Target).requiredColor == ray.color) {
              if (!isComplete) {
                isComplete = true;
                target.activate();
                Future.delayed(Duration(seconds: 2), () {
                  currentLevelIndex++;
                  if (currentLevelIndex < levelData.length)
                    loadLevel();
                  else
                    print('Game Completed!');
                });
              }
            }
          }
        } else {
          final endPoint = ray.position + ray.direction * worldSize.x;
          world.add(
              LaserBeam(ray.position, endPoint, color: _getColor(ray.color)));
        }
      }
      activeRays = newRays;
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
            closestHit = RaycastResult(fixture.body, point, normal);
          }
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

  Vector2 _rotate(Vector2 v, double angle) {
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return Vector2(v.x * cos - v.y * sin, v.x * sin + v.y * cos);
  }

  Color _getColor(String color) {
    switch (color) {
      case 'white':
        return Colors.white;
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      default:
        return Colors.white;
    }
  }

  @override
  bool onTapDown(TapDownInfo info) {
    final screenPoint = info.eventPosition.widget;
    final worldPoint = screenToWorld(screenPoint);
    final screenSize = size;

    if (screenPoint.y > screenSize.y * 0.9) {
      selectedTool = screenPoint.x < screenSize.x / 2 ? 'mirror' : 'prism';
    } else if (selectedTool != null) {
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
    }
    return true;
  }
}

class LevelData {
  final Vector2 laserSourcePosition;
  final double laserSourceAngle;
  final Vector2 targetPosition;
  final String? targetRequiredColor;
  final List<ObstacleData> obstacleData;

  LevelData({
    required this.laserSourcePosition,
    required this.laserSourceAngle,
    required this.targetPosition,
    this.targetRequiredColor,
    required this.obstacleData,
  });
}

class ObstacleData {
  final Vector2 position;
  final Vector2 size;
  final double angle;

  ObstacleData(this.position, this.size, this.angle);
}

class ToolSelectionComponent extends Component {
  final LightBenderGame game;

  ToolSelectionComponent(this.game);

  @override
  void render(Canvas canvas) {
    final screenSize = game.size;
    final buttonWidth = screenSize.x / 2;
    final buttonHeight = screenSize.y * 0.1;
    final mirrorRect = Rect.fromLTWH(
        0, screenSize.y - buttonHeight, buttonWidth, buttonHeight);
    final prismRect = Rect.fromLTWH(
        buttonWidth, screenSize.y - buttonHeight, buttonWidth, buttonHeight);

    canvas.drawRect(
      mirrorRect,
      Paint()
        ..color = game.selectedTool == 'mirror' ? Colors.blue : Colors.grey,
    );
    canvas.drawRect(
      prismRect,
      Paint()..color = game.selectedTool == 'prism' ? Colors.blue : Colors.grey,
    );

    final textStyle = TextStyle(color: Colors.white, fontSize: 16);
    final mirrorText = TextPainter(
      text: TextSpan(text: 'Mirror', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final prismText = TextPainter(
      text: TextSpan(text: 'Prism', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    mirrorText.paint(
        canvas,
        Offset(mirrorRect.center.dx - mirrorText.width / 2,
            mirrorRect.center.dy - mirrorText.height / 2));
    prismText.paint(
        canvas,
        Offset(prismRect.center.dx - prismText.width / 2,
            prismRect.center.dy - prismText.height / 2));
  }
}

class LaserSource extends BodyComponent {
  final Vector2 startPosition;
  double angle = 0;

  LaserSource(this.startPosition);

  @override
  Body createBody() {
    final bodyDef = BodyDef(position: startPosition, type: BodyType.static);
    final shape = CircleShape()..radius = 0.5;
    return world.createBody(bodyDef)..createFixture(FixtureDef(shape));
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset.zero, 0.5, Paint()..color = Colors.amber);
  }
}

class LaserBeam extends Component {
  final Vector2 start;
  final Vector2 end;
  final Color color;

  LaserBeam(this.start, this.end, {this.color = Colors.white});

  @override
  void render(Canvas canvas) {
    canvas.drawLine(
      start.toOffset(),
      end.toOffset(),
      Paint()
        ..color = color
        ..strokeWidth = 0.2
        ..strokeCap = StrokeCap.round,
    );
  }
}

class Mirror extends BodyComponent {
  final Vector2 position;

  Mirror(this.position);

  @override
  Body createBody() {
    final bodyDef = BodyDef(position: position, type: BodyType.static);
    final shape = PolygonShape()..setAsBox(1.0, 0.1, Vector2.zero(), 0);
    return world.createBody(bodyDef)..createFixture(FixtureDef(shape));
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromCenter(center: Offset.zero, width: 2.0, height: 0.2);
    canvas.drawRect(rect, Paint()..color = Colors.grey[300]!);
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
    final bodyDef = BodyDef(position: position, type: BodyType.static);
    final vertices = [
      Vector2(0, -0.866),
      Vector2(0.5, 0.433),
      Vector2(-0.5, 0.433)
    ];
    final shape = PolygonShape()..set(vertices);
    return world.createBody(bodyDef)..createFixture(FixtureDef(shape));
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
  final String? requiredColor;
  bool isActive = false;

  Target(this.position, {this.requiredColor});

  void activate() => isActive = true;

  @override
  Body createBody() {
    final bodyDef = BodyDef(position: position, type: BodyType.static);
    final shape = CircleShape()..radius = 0.5;
    return world.createBody(bodyDef)..createFixture(FixtureDef(shape));
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

  GameObstacle(this.position, {required this.size, this.angle = 0});

  @override
  Body createBody() {
    final bodyDef =
        BodyDef(position: position, type: BodyType.static, angle: angle);
    final shape = PolygonShape()
      ..setAsBox(size.x / 2, size.y / 2, Vector2.zero(), 0);
    return world.createBody(bodyDef)..createFixture(FixtureDef(shape));
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: size.x, height: size.y),
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
    final bodyDef = BodyDef(type: BodyType.static);
    final shape = EdgeShape()..set(start, end);
    return world.createBody(bodyDef)..createFixture(FixtureDef(shape));
  }
}

class Ray {
  Vector2 position;
  Vector2 direction;
  String color;

  Ray(this.position, this.direction, this.color);
}

class RayCastCallbackImpl extends RayCastCallback {
  final Function(Fixture, Vector2, Vector2, double) callback;

  RayCastCallbackImpl(this.callback);

  @override
  double reportFixture(
      Fixture fixture, Vector2 point, Vector2 normal, double fraction) {
    return callback(fixture, point, normal, fraction);
  }
}

class RaycastResult {
  final Body body;
  final Vector2 point;
  final Vector2 normal;

  RaycastResult(this.body, this.point, this.normal);
}

import 'dart:math';

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class CollectibleStarBody extends BodyComponent {
  final Vector2 _position;
  double _rotationAngle = 0;

  CollectibleStarBody(this._position);

  double get radius => 0.5;

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: _position,
      type: BodyType.static,
    );

    final body = world.createBody(bodyDef);
    final shape = CircleShape()..radius = radius;
    body.createFixture(FixtureDef(shape, isSensor: true));
    return body;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _rotationAngle += dt * 2;
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.rotate(_rotationAngle);

    // Draw spinning star shape
    final path = Path();
    const points = 5;
    const innerRadius = 0.3;
    const outerRadius = 0.5;

    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (i * pi) / points;
      final x = cos(angle) * radius;
      final y = sin(angle) * radius;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Draw glow effect
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.accentColor.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Draw star
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.accentColor
        ..style = PaintingStyle.fill,
    );

    canvas.restore();
  }
}

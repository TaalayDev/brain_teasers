import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class WallBody extends BodyComponent {
  final Vector2 _position;
  final Vector2 size;

  WallBody(this._position, this.size);

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: _position,
      userData: this,
    );

    final wall = world.createBody(bodyDef);

    final shape = PolygonShape()
      ..setAsBox(
        size.x / 2, // halfWidth
        size.y / 2, // halfHeight
        Vector2.zero(), // center offset relative to body position
        0.0, // angle in radians
      );

    final fixtureDef = FixtureDef(
      shape,
      friction: 0.3,
      restitution: 0.2,
    );
    paint.strokeWidth = 1;

    wall.createFixture(fixtureDef);
    return wall;
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: size.x,
      height: size.y,
    );

    // Draw shadow
    canvas.drawRect(
      rect.shift(const Offset(0.02, 0.02)),
      Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    canvas.drawRect(
      rect,
      Paint()..color = AppTheme.secondaryColor,
    );
  }
}

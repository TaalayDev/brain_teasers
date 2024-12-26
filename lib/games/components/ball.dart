import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class BallBody extends BodyComponent {
  final Vector2 startPosition;
  final double radius;

  BallBody(
    this.startPosition, {
    this.radius = 1,
  });

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: startPosition,
      type: BodyType.dynamic,
      bullet: true, // Enable continuous collision detection
      linearDamping: 0.1,
      angularDamping: 0.1,
    );

    final ball = world.createBody(bodyDef);

    final shape = CircleShape()..radius = 1;
    final fixtureDef = FixtureDef(
      shape,
      restitution: 0.7,
      density: 1.0,
      friction: 0.2,
    );

    ball.createFixture(fixtureDef);
    return ball;
  }

  @override
  void render(Canvas canvas) {
    // Draw shadow
    canvas.drawCircle(
      const Offset(0.1, 0.1),
      radius,
      Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Draw metallic ball with gradient
    final gradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      radius: 0.8,
      colors: [
        Colors.white,
        AppTheme.primaryColor,
        AppTheme.primaryColor.withOpacity(0.8),
      ],
      stops: const [0.0, 0.3, 1.0],
    );

    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: Offset.zero, radius: radius),
        ),
    );

    // Add reflection highlight
    canvas.drawCircle(
      const Offset(-0.3, -0.3),
      radius * 0.3,
      Paint()..color = Colors.white.withOpacity(0.6),
    );
  }
}

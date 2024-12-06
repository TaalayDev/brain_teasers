import 'dart:math';

import 'package:flame_forge2d/flame_forge2d.dart' hide Particle;
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class GoalBody extends BodyComponent {
  double _pulseValue = 0.0;
  double _glowValue = 0.0;
  final Vector2 _position;

  GoalBody(this._position);

  double get radius => 1.5;

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: _position,
      userData: this,
    );

    final goal = world.createBody(bodyDef);

    final shape = CircleShape()..radius = radius;
    final fixtureDef = FixtureDef(
      shape,
      isSensor: true,
    );

    goal.createFixture(fixtureDef);
    return goal;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulseValue += dt;
    if (_pulseValue > 1) {
      _pulseValue -= 1;
    }

    _glowValue += dt * 2;
    if (_glowValue > 1) {
      _glowValue -= 1;
    }
  }

  @override
  void render(Canvas canvas) {
    final pulseRadius = radius * (1.0 + sin(_pulseValue * pi) * 0.1);

    // Draw outer glow
    canvas.drawCircle(
      Offset.zero,
      pulseRadius * 1.2,
      Paint()
        ..color = AppTheme.correctAnswerColor.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Draw goal with gradient
    final gradient = RadialGradient(
      colors: [
        AppTheme.correctAnswerColor.withOpacity(0.8),
        AppTheme.correctAnswerColor,
      ],
      stops: const [0.7, 1.0],
    ).createShader(Rect.fromCircle(
      center: Offset.zero,
      radius: pulseRadius,
    ));

    canvas.drawCircle(
      Offset.zero,
      pulseRadius,
      Paint()..shader = gradient,
    );

    // Draw concentric rings
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(
        Offset.zero,
        pulseRadius * i / 3,
        Paint()
          ..color = Colors.white.withOpacity(0.5 - (i * 0.1))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.05,
      );
    }

    // Draw particle effects
    if (_pulseValue < 10) {
      _drawParticles(canvas);
    }

    // Draw inner circle
    canvas.drawCircle(
      Offset.zero,
      radius / 2,
      Paint()..color = Colors.white.withOpacity(0.8),
    );
  }

  void _drawParticles(Canvas canvas) {
    final random = Random();
    const particleCount = 8;

    for (var i = 0; i < particleCount; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final distance = radius * (0.8 + random.nextDouble() * 0.4);

      canvas.drawCircle(
        Offset(
          cos(angle) * distance,
          sin(angle) * distance,
        ),
        0.1,
        Paint()
          ..color = Colors.white.withOpacity(0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
      );
    }
  }
}

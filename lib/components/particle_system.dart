import 'dart:math';

import 'package:flutter/material.dart';

class ParticleSystem extends StatefulWidget {
  final Offset position;
  final Color color;

  const ParticleSystem({
    super.key,
    required this.position,
    required this.color,
  });

  @override
  State<ParticleSystem> createState() => _ParticleSystemState();
}

class _ParticleSystemState extends State<ParticleSystem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> particles;
  final random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _initializeParticles();
    _controller.forward();
  }

  void _initializeParticles() {
    particles = List.generate(12, (index) {
      final angle = (index * (2 * pi / 12)) + random.nextDouble() * 0.4;
      final velocity = random.nextDouble() * 2 + 2;

      return Particle(
        color: widget.color.withOpacity(0.8),
        angle: angle,
        velocity: velocity,
        decay: random.nextDouble() * 0.1 + 0.9,
        size: random.nextDouble() * 4 + 4,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(200, 200),
          painter: ParticlePainter(
            particles: particles,
            progress: _controller.value,
            startPosition: widget.position,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class Particle {
  final Color color;
  final double angle;
  final double velocity;
  final double decay;
  final double size;

  Particle({
    required this.color,
    required this.angle,
    required this.velocity,
    required this.decay,
    required this.size,
  });

  Offset getPosition(double progress, Offset startPosition) {
    final distance = velocity * progress * 100;
    final decayedProgress = pow(decay, progress * 10).toDouble();

    return Offset(
      startPosition.dx + cos(angle) * distance,
      startPosition.dy + sin(angle) * distance + (progress * progress * 200),
    );
  }

  double getSize(double progress) {
    return size * (1 - progress);
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  final Offset startPosition;

  ParticlePainter({
    required this.particles,
    required this.progress,
    required this.startPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity((1 - progress) * 0.8)
        ..style = PaintingStyle.fill;

      final position = particle.getPosition(progress, startPosition);
      final currentSize = particle.getSize(progress);

      canvas.drawCircle(position, currentSize, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

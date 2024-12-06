import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame/game.dart';
import '../theme/app_theme.dart';

import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/particles.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  late final BrainGearsGame _game;

  @override
  void initState() {
    super.initState();
    _game = BrainGearsGame();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Flame Game Background
            Positioned.fill(
              child: GameWidget(
                game: _game,
              ),
            ),

            // Content Overlay
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo
                  Container(
                    width: size.width * 0.4,
                    height: size.width * 0.4,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.psychology,
                      size: size.width * 0.25,
                      color: Colors.white,
                    ),
                  )
                      .animate()
                      .scale(
                    duration: AppTheme.mediumAnimation,
                    curve: Curves.easeOut,
                  )
                      .then()
                      .shimmer(
                    duration: AppTheme.slowAnimation,
                    color: Colors.white54,
                  ),

                  const SizedBox(height: 32),

                  // App Name
                  Text(
                    'BrainTeasers',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      .animate()
                      .fadeIn(
                    duration: AppTheme.mediumAnimation,
                    delay: AppTheme.quickAnimation,
                  )
                      .slideY(
                    begin: 0.2,
                    duration: AppTheme.mediumAnimation,
                    curve: Curves.easeOut,
                  ),

                  const SizedBox(height: 16),

                  // Tagline
                  Text(
                    'Train Your Brain, One Puzzle at a Time',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: brightness == Brightness.light
                          ? Colors.black54
                          : Colors.white54,
                    ),
                  )
                      .animate()
                      .fadeIn(
                    duration: AppTheme.mediumAnimation,
                    delay: AppTheme.mediumAnimation,
                  ),

                  const SizedBox(height: 48),

                  // Loading Indicator
                  const CircularProgressIndicator()
                      .animate()
                      .scale(
                    duration: AppTheme.quickAnimation,
                    delay: AppTheme.mediumAnimation,
                  )
                      .fadeIn(
                    duration: AppTheme.quickAnimation,
                    delay: AppTheme.mediumAnimation,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Gear extends CircleComponent with CollisionCallbacks {
  final Vector2 velocity;
  double angularVelocity;
  final double gearSize;

  Gear({
    required Vector2 position,
    required this.gearSize,
    required this.velocity,
    required this.angularVelocity,
  }) : super(
    position: position,
    radius: gearSize / 2,
    anchor: Anchor.center,
    paint: Paint()
      ..color = AppTheme.primaryColor.withOpacity(0.8)
      ..style = PaintingStyle.fill,
  ) {
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.add(velocity * dt * 60);
    angle += angularVelocity * dt;

    // Bounce off screen edges
    final screenSize = findGame()!.size;
    if (position.x - radius <= 0 || position.x + radius >= screenSize.x) {
      velocity.x *= -0.8;
      _addCollisionParticles();
    }
    if (position.y - radius <= 0 || position.y + radius >= screenSize.y) {
      velocity.y *= -0.8;
      _addCollisionParticles();
    }
  }

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    if (other is Gear) {
      final collisionNormal = (other.position - position).normalized();
      final relativeVelocity = other.velocity - velocity;
      final velocityAlongNormal = relativeVelocity.dot(collisionNormal);

      // Only resolve if objects are moving towards each other
      if (velocityAlongNormal > 0) return;

      // Collision response
      final restitution = 0.8;
      final impulseScalar = -(1 + restitution) * velocityAlongNormal;

      velocity.sub(collisionNormal * impulseScalar);
      other.velocity.add(collisionNormal * impulseScalar);

      // Exchange angular velocities
      final tempAngular = angularVelocity;
      angularVelocity = other.angularVelocity;
      other.angularVelocity = tempAngular;

      _addCollisionParticles();
    }
  }

  void _addCollisionParticles() {
    final particleComponent = ParticleSystemComponent(
      particle: Particle.generate(
        count: 10,
        lifespan: 0.5,
        generator: (i) => AcceleratedParticle(
          acceleration: Vector2(0, 98.0),
          speed: Vector2.random() * 100,
          position: position.clone(),
          child: CircleParticle(
            radius: 2,
            paint: Paint()
              ..color = AppTheme.accentColor.withOpacity(0.6),
          ),
        ),
      ),
    );
    findGame()!.add(particleComponent);
  }
}

class BrainGearsGame extends FlameGame with HasCollisionDetection {
  late List<Gear> gears;
  final int numberOfGears;

  BrainGearsGame({this.numberOfGears = 5});

  @override
  Future<void> onLoad() async {
    gears = [];
    final random = math.Random();

    for (int i = 0; i < numberOfGears; i++) {
      final gear = Gear(
        position: Vector2(
          random.nextDouble() * size.x,
          random.nextDouble() * size.y,
        ),
        gearSize: 30 + random.nextDouble() * 20,
        velocity: Vector2(
          -50 + random.nextDouble() * 100,
          -50 + random.nextDouble() * 100,
        ),
        angularVelocity: -2 + random.nextDouble() * 4,
      );
      add(gear);
      gears.add(gear);
    }

    // Add connecting lines component
    add(
      CustomConnectingLinesComponent(gears: gears),
    );
  }
}

class CustomConnectingLinesComponent extends Component with HasGameRef {
  final List<Gear> gears;
  final Paint linePaint;

  CustomConnectingLinesComponent({required this.gears})
      : linePaint = Paint()
    ..color = AppTheme.primaryColor.withOpacity(0.2)
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  @override
  void render(Canvas canvas) {
    for (int i = 0; i < gears.length; i++) {
      for (int j = i + 1; j < gears.length; j++) {
        final distance = gears[i].position.distanceTo(gears[j].position);
        if (distance < 150) {
          final opacity = (1 - distance / 150) * 0.5;
          linePaint.color = AppTheme.primaryColor.withOpacity(opacity);
          canvas.drawLine(
            gears[i].position.toOffset(),
            gears[j].position.toOffset(),
            linePaint,
          );
        }
      }
    }
  }
}
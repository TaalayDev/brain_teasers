import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _gearController;
  late final Animation<double> _gearRotation;

  @override
  void initState() {
    super.initState();
    _gearController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _gearRotation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_gearController);

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _gearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        children: [
          // Animated particles background
          const ParticlesBackground(),

          // Main content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated gear system
                  SizedBox(
                    width: size.width * 0.4,
                    height: size.width * 0.4,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background glow
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),

                        // Main gear
                        AnimatedBuilder(
                          animation: _gearRotation,
                          builder: (context, child) => Transform.rotate(
                            angle: _gearRotation.value,
                            child: _buildGear(
                              size: size.width * 0.25,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),

                        // Outer gears
                        ...List.generate(3, (index) {
                          final angle = (index * 2 * math.pi / 3);
                          return AnimatedBuilder(
                            animation: _gearRotation,
                            builder: (context, child) => Transform(
                              transform: Matrix4.identity()
                                ..translate(
                                  size.width * 0.15 * math.cos(angle),
                                  size.width * 0.15 * math.sin(angle),
                                )
                                ..rotateZ(-_gearRotation.value),
                              child: _buildGear(
                                size: size.width * 0.1,
                                color: AppTheme.secondaryColor,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  )
                      .animate()
                      .scale(
                        duration: AppTheme.mediumAnimation,
                        curve: Curves.easeOut,
                      )
                      .fadeIn(),

                  const SizedBox(height: 48),

                  // App name
                  Text(
                    'BrainTeasers',
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  )
                      .animate()
                      .fadeIn(
                        delay: const Duration(milliseconds: 300),
                        duration: AppTheme.mediumAnimation,
                      )
                      .slideY(
                        begin: 0.3,
                        duration: AppTheme.mediumAnimation,
                        curve: Curves.easeOut,
                      ),

                  const SizedBox(height: 16),

                  // Tagline
                  Text(
                    'Train Your Brain, One Puzzle at a Time',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.color
                          ?.withOpacity(0.7),
                    ),
                  )
                      .animate()
                      .fadeIn(
                        delay: const Duration(milliseconds: 600),
                        duration: AppTheme.mediumAnimation,
                      )
                      .slideY(
                        begin: 0.3,
                        duration: AppTheme.mediumAnimation,
                        curve: Curves.easeOut,
                      ),

                  const SizedBox(height: 48),

                  // Loading indicator
                  const LoadingIndicator().animate().fadeIn(
                        delay: const Duration(milliseconds: 900),
                        duration: AppTheme.mediumAnimation,
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGear({required double size, required Color color}) {
    return CustomPaint(
      size: Size(size, size),
      painter: GearPainter(color: color),
    );
  }
}

class GearPainter extends CustomPainter {
  final Color color;

  GearPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const teethCount = 12;
    final teethDepth = radius * 0.2;
    final innerRadius = radius * 0.6;

    final path = Path();

    // Draw teeth
    for (var i = 0; i < teethCount; i++) {
      final angle = 2 * math.pi * i / teethCount;
      final nextAngle = 2 * math.pi * (i + 0.5) / teethCount;

      if (i == 0) {
        path.moveTo(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        );
      }

      path.lineTo(
        center.dx +
            (radius + teethDepth) * math.cos(angle + math.pi / teethCount),
        center.dy +
            (radius + teethDepth) * math.sin(angle + math.pi / teethCount),
      );

      path.lineTo(
        center.dx + radius * math.cos(nextAngle),
        center.dy + radius * math.sin(nextAngle),
      );
    }

    path.close();
    canvas.drawPath(path, paint);

    // Draw inner circle
    canvas.drawCircle(center, innerRadius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ParticlesBackground extends StatelessWidget {
  const ParticlesBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: List.generate(20, (index) {
            final random = math.Random();
            final size = random.nextDouble() * 8 + 4;

            return Positioned(
              left: random.nextDouble() * constraints.maxWidth,
              top: random.nextDouble() * constraints.maxHeight,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withOpacity(0.2),
                ),
              )
                  .animate(
                    onPlay: (controller) => controller.repeat(),
                  )
                  .shimmer(
                    delay: Duration(milliseconds: random.nextInt(1000)),
                    duration: const Duration(seconds: 2),
                  )
                  .fadeIn(
                    delay: Duration(milliseconds: random.nextInt(1000)),
                    duration: const Duration(milliseconds: 500),
                  ),
            );
          }),
        );
      },
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const CircularProgressIndicator(
        strokeWidth: 3,
      ),
    );
  }
}

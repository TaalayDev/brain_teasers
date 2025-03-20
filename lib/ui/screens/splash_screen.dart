import 'dart:math' as math;
import 'dart:ui';
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
  late final AnimationController _animController;
  late final Animation<double> _gearRotation;
  final List<NeuronConnection> _neuronConnections = [];
  final List<BrainNeuron> _neurons = [];
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _gearRotation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_animController);

    // Generate neurons and connections after first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateNeurons();
    });

    _initializeApp();
  }

  void _generateNeurons() {
    final size = MediaQuery.of(context).size;
    final random = math.Random();
    const neuronCount = 12;

    // Create neurons
    for (int i = 0; i < neuronCount; i++) {
      final x = size.width * (0.1 + 0.8 * random.nextDouble());
      final y = size.height * (0.1 + 0.8 * random.nextDouble());
      final neuronSize = 4.0 + random.nextDouble() * 6.0;
      final pulseDuration = 1500 + random.nextInt(1500);

      setState(() {
        _neurons.add(BrainNeuron(
          position: Offset(x, y),
          size: neuronSize,
          pulseDuration: pulseDuration,
        ));
      });
    }

    // Create connections between neurons
    for (int i = 0; i < neuronCount; i++) {
      for (int j = i + 1; j < neuronCount; j++) {
        // Only connect some neurons
        if (random.nextDouble() < 0.3) {
          setState(() {
            _neuronConnections.add(NeuronConnection(
              start: _neurons[i].position,
              end: _neurons[j].position,
              thickness: 1.0 + random.nextDouble(),
              speed: 500 + random.nextInt(1000),
            ));
          });
        }
      }
    }
  }

  Future<void> _initializeApp() async {
    // Use a longer delay for better animation viewing
    await Future.delayed(const Duration(seconds: 4));
    if (mounted && !_isNavigating) {
      setState(() {
        _isNavigating = true;
      });

      // Fade out all animations before navigating
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        context.go('/home');
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        children: [
          // Neural network background
          CustomPaint(
            size: Size(size.width, size.height),
            painter: NeuralNetworkPainter(
              neurons: _neurons,
              connections: _neuronConnections,
              opacity: _isNavigating ? 0.0 : 1.0,
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: _isNavigating ? 0.0 : 1.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo and gear animation
                    SizedBox(
                      width: size.width * 0.5,
                      height: size.width * 0.5,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Brain-themed loading indicator
                          const BrainLoadingIndicator().animate().fadeIn(
                                delay: const Duration(milliseconds: 1200),
                                duration: AppTheme.mediumAnimation,
                              ),

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
                          ).animate().fadeIn(
                                duration: const Duration(milliseconds: 1200),
                                curve: Curves.easeOut,
                              ),
                        ],
                      ),
                    )
                        .animate()
                        .scale(
                          duration: AppTheme.mediumAnimation,
                          curve: Curves.easeOut,
                        )
                        .fadeIn(),

                    const SizedBox(height: 40),

                    // App name with letter animation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: "BrainTeasers".split('').map((letter) {
                        return Text(
                          letter,
                          style: GoogleFonts.poppins(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                            height: 1.2,
                          ),
                        )
                            .animate()
                            .fadeIn(
                              delay: Duration(
                                  milliseconds: 300 +
                                      "BrainTeasers".indexOf(letter) * 50),
                              duration: const Duration(milliseconds: 400),
                            )
                            .slideY(
                              begin: 0.5,
                              end: 0,
                              delay: Duration(
                                  milliseconds: 300 +
                                      "BrainTeasers".indexOf(letter) * 50),
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutQuad,
                            );
                      }).toList(),
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
                          delay: const Duration(milliseconds: 1000),
                          duration: AppTheme.mediumAnimation,
                        )
                        .slideY(
                          begin: 0.3,
                          end: 0,
                          duration: AppTheme.mediumAnimation,
                          curve: Curves.easeOut,
                        ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGear(
      {required double size, required Color color, required int teethCount}) {
    return CustomPaint(
      size: Size(size, size),
      painter: GearPainter(
        color: color,
        teethCount: teethCount,
      ),
    );
  }
}

class GearPainter extends CustomPainter {
  final Color color;
  final int teethCount;

  GearPainter({required this.color, required this.teethCount});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final teethDepth = radius * 0.2;
    final innerRadius = radius * 0.6;

    final path = Path();

    // Draw teeth with rounded edges
    for (var i = 0; i < teethCount; i++) {
      final angle = 2 * math.pi * i / teethCount;
      final nextAngle = 2 * math.pi * (i + 0.5) / teethCount;
      final toothCenter = angle + math.pi / teethCount;

      if (i == 0) {
        path.moveTo(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        );
      }

      // Create curved teeth
      path.quadraticBezierTo(
        center.dx +
            (radius + teethDepth * 0.8) *
                math.cos(toothCenter - math.pi / (teethCount * 4)),
        center.dy +
            (radius + teethDepth * 0.8) *
                math.sin(toothCenter - math.pi / (teethCount * 4)),
        center.dx + (radius + teethDepth) * math.cos(toothCenter),
        center.dy + (radius + teethDepth) * math.sin(toothCenter),
      );

      path.quadraticBezierTo(
        center.dx +
            (radius + teethDepth * 0.8) *
                math.cos(toothCenter + math.pi / (teethCount * 4)),
        center.dy +
            (radius + teethDepth * 0.8) *
                math.sin(toothCenter + math.pi / (teethCount * 4)),
        center.dx + radius * math.cos(nextAngle),
        center.dy + radius * math.sin(nextAngle),
      );
    }

    path.close();
    canvas.drawPath(path, paint);

    // Draw inner circle with gradient
    final gradient = RadialGradient(
      colors: [
        color.withOpacity(0.9),
        color.withOpacity(0.7),
      ],
      stops: const [0.6, 1.0],
      center: const Alignment(-0.2, -0.2),
    ).createShader(Rect.fromCircle(center: center, radius: innerRadius));

    canvas.drawCircle(center, innerRadius, Paint()..shader = gradient);

    // Draw center hole
    canvas.drawCircle(
      center,
      innerRadius * 0.3,
      Paint()..color = color.withOpacity(0.6),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BrainLoadingIndicator extends StatelessWidget {
  const BrainLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular background
          Container(
            width: 60,
            height: 60,
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
          ),

          // Pulsing circles
          ...List.generate(3, (index) {
            return Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.4),
                  width: 3,
                ),
              ),
            )
                .animate(
                  onPlay: (controller) => controller.repeat(),
                )
                .scaleXY(
                  begin: 0.2,
                  end: 1.0,
                  duration: Duration(milliseconds: 1500 + (index * 400)),
                  curve: Curves.easeOut,
                )
                .fadeOut(
                  duration: Duration(milliseconds: 1500 + (index * 400)),
                  curve: Curves.easeOut,
                );
          }),

          // Brain icon
          Icon(
            Icons.psychology,
            size: 32,
            color: AppTheme.primaryColor,
          )
              .animate(
                onPlay: (controller) => controller.repeat(),
              )
              .scaleXY(
                begin: 0.9,
                end: 1.1,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
              )
              .then()
              .scaleXY(
                begin: 1.1,
                end: 0.9,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
              ),

          // Rotating spinner
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.accentColor.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BrainNeuron {
  final Offset position;
  final double size;
  final int pulseDuration;

  BrainNeuron({
    required this.position,
    required this.size,
    required this.pulseDuration,
  });
}

class NeuronConnection {
  final Offset start;
  final Offset end;
  final double thickness;
  final int speed; // Animation speed in milliseconds

  NeuronConnection({
    required this.start,
    required this.end,
    required this.thickness,
    required this.speed,
  });
}

class NeuralNetworkPainter extends CustomPainter {
  final List<BrainNeuron> neurons;
  final List<NeuronConnection> connections;
  final double opacity;

  NeuralNetworkPainter({
    required this.neurons,
    required this.connections,
    this.opacity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Draw connections
    for (final connection in connections) {
      final connectionPaint = Paint()
        ..color = AppTheme.primaryColor.withOpacity(0.15 * opacity)
        ..strokeWidth = connection.thickness
        ..strokeCap = StrokeCap.round;

      // Calculate animation progress (0.0 to 1.0)
      final animationProgress = ((now % connection.speed) / connection.speed);

      // Draw the connection line
      canvas.drawLine(connection.start, connection.end, connectionPaint);

      // Draw moving particle along the connection
      final particlePaint = Paint()
        ..color = AppTheme.accentColor.withOpacity(0.7 * opacity)
        ..strokeWidth = connection.thickness * 3
        ..strokeCap = StrokeCap.round;

      final particlePosition = Offset(
        connection.start.dx +
            (connection.end.dx - connection.start.dx) * animationProgress,
        connection.start.dy +
            (connection.end.dy - connection.start.dy) * animationProgress,
      );

      canvas.drawPoints(PointMode.points, [particlePosition], particlePaint);
    }

    // Draw neurons
    for (final neuron in neurons) {
      // Calculate animation progress (0.0 to 1.0)
      final animationProgress =
          (now % neuron.pulseDuration) / neuron.pulseDuration;
      final pulseSize = neuron.size *
          (0.8 + (0.4 * math.sin(animationProgress * 2 * math.pi)));

      // Draw neuron
      final neuronPaint = Paint()
        ..color = AppTheme.primaryColor.withOpacity(0.5 * opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(neuron.position, pulseSize, neuronPaint);

      // Draw glow
      final glowPaint = Paint()
        ..color = AppTheme.primaryColor.withOpacity(0.2 * opacity)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(neuron.position, pulseSize * 1.2, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant NeuralNetworkPainter oldDelegate) => true;
}

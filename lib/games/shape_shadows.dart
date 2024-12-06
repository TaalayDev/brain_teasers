import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../theme/app_theme.dart';

class ShapeShadowsGame extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final Function(int score) onScoreUpdate;
  final VoidCallback onComplete;

  const ShapeShadowsGame({
    super.key,
    required this.gameData,
    required this.onScoreUpdate,
    required this.onComplete,
  });

  @override
  State<ShapeShadowsGame> createState() => _ShapeShadowsGameState();
}

class _ShapeShadowsGameState extends State<ShapeShadowsGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  late int _currentLevel;
  late List<Map<String, dynamic>> _levels;
  late double _currentAngle;
  late int _score;
  late bool _showFeedback;
  late bool _isCorrect;
  late String _selectedShadow;
  late bool _isShowingHint;
  late int _hintsRemaining;
  late bool _isRotating;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _initializeGame();
  }

  void _initializeGame() {
    _currentLevel = 0;
    _levels = List<Map<String, dynamic>>.from(widget.gameData['levels']);
    _currentAngle = 0;
    _score = 0;
    _showFeedback = false;
    _isCorrect = false;
    _selectedShadow = '';
    _isShowingHint = false;
    _hintsRemaining = 3;
    _isRotating = false;
  }

  void _rotateObject(double angle) {
    if (_isRotating) return;
    setState(() {
      _isRotating = true;
      _isShowingHint = false;
    });

    _rotationController.reset();
    _rotationController.forward().then((_) {
      setState(() {
        _currentAngle = (_currentAngle + angle) % 360;
        _isRotating = false;
      });
    });
  }

  void _useHint() {
    if (_hintsRemaining <= 0) return;

    setState(() {
      _hintsRemaining--;
      _isShowingHint = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isShowingHint = false;
        });
      }
    });
  }

  void _checkShadow(String shadow) {
    if (_showFeedback || _isRotating) return;

    final correctAngle = _levels[_currentLevel]['correctAngle'].toDouble();
    final isCorrectShadow = shadow ==
        _levels[_currentLevel]['shadows'][(_currentAngle / 90).round() %
            _levels[_currentLevel]['shadows'].length];

    setState(() {
      _showFeedback = true;
      _isCorrect = isCorrectShadow && (_currentAngle - correctAngle).abs() < 15;
      _selectedShadow = shadow;
    });

    if (_isCorrect) {
      final baseScore = 100;
      final hintBonus = _hintsRemaining * 50;
      final angleBonus =
          (15 - (_currentAngle - correctAngle).abs()).round() * 10;
      _score += baseScore + hintBonus + angleBonus;
      widget.onScoreUpdate(_score);

      _showSuccessParticles();

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showFeedback = false;
            if (_currentLevel < _levels.length - 1) {
              _currentLevel++;
              _currentAngle = 0;
              _selectedShadow = '';
              _isShowingHint = false;
            } else {
              widget.onComplete();
            }
          });
        }
      });
    } else {
      _showFailureEffect();
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _showFeedback = false;
            _selectedShadow = '';
          });
        }
      });
    }
  }

  void _showSuccessParticles() {
    // Implementation of particle effects
  }

  void _showFailureEffect() {
    // Implementation of failure feedback
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Stack(
            children: [
              _buildMainGame(),
              if (_showFeedback) _buildFeedbackOverlay(),
            ],
          ),
        ),
        _buildControls(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Level ${_currentLevel + 1}/${_levels.length}',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _levels[_currentLevel]['object'],
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          Row(
            children: [
              ...List.generate(
                  _hintsRemaining,
                  (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.lightbulb,
                          color: AppTheme.accentColor,
                          size: 24,
                        ),
                      )),
              ...List.generate(
                  3 - _hintsRemaining,
                  (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.lightbulb_outline,
                          color: AppTheme.accentColor.withOpacity(0.3),
                          size: 24,
                        ),
                      )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainGame() {
    return Column(
      children: [
        _build3DObject(),
        const SizedBox(height: 32),
        _buildShadowOptions(),
      ],
    );
  }

  Widget _build3DObject() {
    return Container(
      height: 200,
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AnimatedRotation(
        turns: _currentAngle / 360,
        duration: const Duration(milliseconds: 500),
        child: CustomPaint(
          painter: ObjectPainter(
            shape: _levels[_currentLevel]['object'],
            showHint: _isShowingHint,
          ),
        ),
      ),
    );
  }

  Widget _buildShadowOptions() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: _levels[_currentLevel]['shadows'].map<Widget>((shadow) {
        final isSelected = _selectedShadow == shadow;
        return GestureDetector(
          onTap: () => _checkShadow(shadow),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? _isCorrect
                        ? AppTheme.correctAnswerColor
                        : AppTheme.wrongAnswerColor
                    : Colors.grey.withOpacity(0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CustomPaint(
              painter: ShadowPainter(
                shape: _levels[_currentLevel]['object'],
                shadowType: shadow,
              ),
            ),
          ),
        ).animate(
          effects: [
            if (isSelected && _showFeedback)
              const ShakeEffect(
                duration: Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () => _rotateObject(-90),
            icon: const Icon(Icons.rotate_left),
            color: AppTheme.primaryColor,
            iconSize: 32,
          ),
          IconButton(
            onPressed: _hintsRemaining > 0 ? _useHint : null,
            icon: Icon(
              _hintsRemaining > 0 ? Icons.lightbulb : Icons.lightbulb_outline,
            ),
            color: _hintsRemaining > 0
                ? AppTheme.accentColor
                : AppTheme.accentColor.withOpacity(0.3),
            iconSize: 32,
          ),
          IconButton(
            onPressed: () => _rotateObject(90),
            icon: const Icon(Icons.rotate_right),
            color: AppTheme.primaryColor,
            iconSize: 32,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isCorrect ? Icons.check_circle : Icons.error,
                color: _isCorrect
                    ? AppTheme.correctAnswerColor
                    : AppTheme.wrongAnswerColor,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                _isCorrect ? 'Perfect Match!' : 'Try Again',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isCorrect) ...[
                const SizedBox(height: 8),
                Text(
                  '+$_score points',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: AppTheme.correctAnswerColor,
                  ),
                ),
              ],
            ],
          ),
        ).animate().scale(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            ),
      ),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }
}

class Shape3DPainter extends CustomPainter {
  final String shape;
  final double angle;

  Shape3DPainter({
    required this.shape,
    required this.angle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 3;

    switch (shape) {
      case 'cube':
        _drawCube(canvas, center, radius, paint);
        break;
      case 'pyramid':
        _drawPyramid(canvas, center, radius, paint);
        break;
      case 'cylinder':
        _drawCylinder(canvas, center, radius, paint);
        break;
    }
  }

  void _drawCube(Canvas canvas, Offset center, double radius, Paint paint) {
    // Front face
    final path = Path()
      ..moveTo(center.dx - radius, center.dy - radius)
      ..lineTo(center.dx + radius, center.dy - radius)
      ..lineTo(center.dx + radius, center.dy + radius)
      ..lineTo(center.dx - radius, center.dy + radius)
      ..close();

    // Back face
    final backPath = Path()
      ..moveTo(center.dx - radius + 20, center.dy - radius - 20)
      ..lineTo(center.dx + radius + 20, center.dy - radius - 20)
      ..lineTo(center.dx + radius + 20, center.dy + radius - 20)
      ..lineTo(center.dx - radius + 20, center.dy + radius - 20)
      ..close();

    // Connecting lines
    final connectPath = Path()
      ..moveTo(center.dx - radius, center.dy - radius)
      ..lineTo(center.dx - radius + 20, center.dy - radius - 20)
      ..moveTo(center.dx + radius, center.dy - radius)
      ..lineTo(center.dx + radius + 20, center.dy - radius - 20)
      ..moveTo(center.dx + radius, center.dy + radius)
      ..lineTo(center.dx + radius + 20, center.dy + radius - 20)
      ..moveTo(center.dx - radius, center.dy + radius)
      ..lineTo(center.dx - radius + 20, center.dy + radius - 20);

    canvas.drawPath(path, paint);
    canvas.drawPath(backPath, paint);
    canvas.drawPath(connectPath, paint);
  }

  void _drawPyramid(Canvas canvas, Offset center, double radius, Paint paint) {
    // Base
    final basePath = Path()
      ..moveTo(center.dx - radius, center.dy + radius)
      ..lineTo(center.dx + radius, center.dy + radius)
      ..lineTo(center.dx + radius - 20, center.dy + radius - 20)
      ..lineTo(center.dx - radius - 20, center.dy + radius - 20)
      ..close();

    // Sides
    final sidesPath = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx - radius, center.dy + radius)
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius, center.dy + radius)
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx, center.dy + radius);

    canvas.drawPath(basePath, paint);
    canvas.drawPath(sidesPath, paint);
  }

  void _drawCylinder(Canvas canvas, Offset center, double radius, Paint paint) {
    // Top ellipse
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - radius),
        width: radius * 2,
        height: radius,
      ),
      paint,
    );

    // Bottom ellipse
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius),
        width: radius * 2,
        height: radius,
      ),
      paint,
    );

    // Sides
    canvas.drawLine(
      Offset(center.dx - radius, center.dy - radius / 2),
      Offset(center.dx - radius, center.dy + radius / 2),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + radius, center.dy - radius / 2),
      Offset(center.dx + radius, center.dy + radius / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(Shape3DPainter oldDelegate) {
    return oldDelegate.shape != shape || oldDelegate.angle != angle;
  }
}

class ObjectPainter extends CustomPainter {
  final String shape;
  final bool showHint;

  ObjectPainter({
    required this.shape,
    required this.showHint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw shape
    switch (shape) {
      case 'cube':
        _drawCube(canvas, center, size.width * 0.4, paint);
        break;
      case 'pyramid':
        _drawPyramid(canvas, center, size.width * 0.4, paint);
        break;
      case 'cylinder':
        _drawCylinder(canvas, center, size.width * 0.4, paint);
        break;
    }

    // Draw hint overlay
    if (showHint) {
      _drawHintOverlay(canvas, size);
    }
  }

  void _drawCube(Canvas canvas, Offset center, double size, Paint paint) {
    // Front face
    final frontPath = Path()
      ..moveTo(center.dx - size, center.dy - size)
      ..lineTo(center.dx + size, center.dy - size)
      ..lineTo(center.dx + size, center.dy + size)
      ..lineTo(center.dx - size, center.dy + size)
      ..close();

    // Back face (offset and smaller)
    final backPath = Path()
      ..moveTo(center.dx - size * 0.7, center.dy - size * 1.3)
      ..lineTo(center.dx + size * 1.3, center.dy - size * 1.3)
      ..lineTo(center.dx + size * 1.3, center.dy - size * 0.3)
      ..lineTo(center.dx - size * 0.7, center.dy - size * 0.3)
      ..close();

    // Connecting lines
    final connectPath = Path()
      ..moveTo(center.dx - size, center.dy - size)
      ..lineTo(center.dx - size * 0.7, center.dy - size * 1.3)
      ..moveTo(center.dx + size, center.dy - size)
      ..lineTo(center.dx + size * 1.3, center.dy - size * 1.3)
      ..moveTo(center.dx + size, center.dy + size)
      ..lineTo(center.dx + size * 1.3, center.dy - size * 0.3)
      ..moveTo(center.dx - size, center.dy + size)
      ..lineTo(center.dx - size * 0.7, center.dy - size * 0.3);

    // Draw with depth effect
    final depthPaint = Paint()
      ..color = AppTheme.primaryColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    canvas.drawPath(backPath, depthPaint);
    canvas.drawPath(frontPath, depthPaint);

    canvas.drawPath(frontPath, paint);
    canvas.drawPath(backPath, paint);
    canvas.drawPath(connectPath, paint);
  }

  void _drawPyramid(Canvas canvas, Offset center, double size, Paint paint) {
    final apex = Offset(center.dx, center.dy - size);
    final basePoints = [
      Offset(center.dx - size, center.dy + size),
      Offset(center.dx + size, center.dy + size),
      Offset(center.dx + size * 0.5, center.dy + size * 0.5),
      Offset(center.dx - size * 0.5, center.dy + size * 0.5),
    ];

    // Draw base
    final basePath = Path()
      ..moveTo(basePoints[0].dx, basePoints[0].dy)
      ..lineTo(basePoints[1].dx, basePoints[1].dy)
      ..lineTo(basePoints[2].dx, basePoints[2].dy)
      ..lineTo(basePoints[3].dx, basePoints[3].dy)
      ..close();

    // Draw edges
    final edgesPath = Path();
    for (final point in basePoints) {
      edgesPath.moveTo(apex.dx, apex.dy);
      edgesPath.lineTo(point.dx, point.dy);
    }

    // Draw with depth effect
    final depthPaint = Paint()
      ..color = AppTheme.primaryColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    canvas.drawPath(basePath, depthPaint);
    canvas.drawPath(basePath, paint);
    canvas.drawPath(edgesPath, paint);
  }

  void _drawCylinder(Canvas canvas, Offset center, double size, Paint paint) {
    // Top ellipse
    final topRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy - size),
      width: size * 2,
      height: size,
    );

    // Bottom ellipse
    final bottomRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + size),
      width: size * 2,
      height: size,
    );

    // Side lines
    final sidePath = Path()
      ..moveTo(center.dx - size, center.dy - size * 0.5)
      ..lineTo(center.dx - size, center.dy + size * 0.5)
      ..moveTo(center.dx + size, center.dy - size * 0.5)
      ..lineTo(center.dx + size, center.dy + size * 0.5);

    // Draw with depth effect
    final depthPaint = Paint()
      ..color = AppTheme.primaryColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    canvas.drawOval(topRect, depthPaint);
    canvas.drawOval(bottomRect, depthPaint);

    canvas.drawOval(topRect, paint);
    canvas.drawOval(bottomRect, paint);
    canvas.drawPath(sidePath, paint);
  }

  void _drawHintOverlay(Canvas canvas, Size size) {
    // Draw semi-transparent directional indicators
    final paint = Paint()
      ..color = AppTheme.accentColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final arrowSize = size.width * 0.2;

    // Draw direction arrow
    final arrowPath = Path()
      ..moveTo(center.dx + arrowSize, center.dy)
      ..lineTo(center.dx + arrowSize * 0.5, center.dy - arrowSize * 0.3)
      ..lineTo(center.dx + arrowSize * 0.5, center.dy + arrowSize * 0.3)
      ..close();

    canvas.drawPath(arrowPath, paint);
  }

  @override
  bool shouldRepaint(ObjectPainter oldDelegate) {
    return oldDelegate.shape != shape || oldDelegate.showHint != showHint;
  }
}

class ShadowPainter extends CustomPainter {
  final String shape;
  final String shadowType;

  ShadowPainter({
    required this.shape,
    required this.shadowType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    switch (shape) {
      case 'cube':
        _drawCubeShadow(canvas, center, size.width * 0.4, paint);
        break;
      case 'pyramid':
        _drawPyramidShadow(canvas, center, size.width * 0.4, paint);
        break;
      case 'cylinder':
        _drawCylinderShadow(canvas, center, size.width * 0.4, paint);
        break;
    }
  }

  void _drawCubeShadow(Canvas canvas, Offset center, double size, Paint paint) {
    Path path;
    switch (shadowType) {
      case 'front':
        path = Path()
          ..addRect(Rect.fromCenter(
            center: center,
            width: size * 2,
            height: size * 2,
          ));
        break;
      case 'side':
        path = Path()
          ..addRect(Rect.fromCenter(
            center: center,
            width: size,
            height: size * 2,
          ));
        break;
      case 'top':
        path = Path()
          ..addRect(Rect.fromCenter(
            center: center,
            width: size * 2,
            height: size * 2,
          ));
        break;
      default:
        return;
    }
    canvas.drawPath(path, paint);
  }

  void _drawPyramidShadow(
      Canvas canvas, Offset center, double size, Paint paint) {
    Path path;
    switch (shadowType) {
      case 'front':
        path = Path()
          ..moveTo(center.dx, center.dy - size)
          ..lineTo(center.dx - size, center.dy + size)
          ..lineTo(center.dx + size, center.dy + size)
          ..close();
        break;
      case 'side':
        path = Path()
          ..moveTo(center.dx, center.dy - size)
          ..lineTo(center.dx - size * 0.5, center.dy + size)
          ..lineTo(center.dx + size * 0.5, center.dy + size)
          ..close();
        break;
      case 'top':
        path = Path()
          ..addRect(Rect.fromCenter(
            center: center,
            width: size * 2,
            height: size * 2,
          ));
        break;
      default:
        return;
    }
    canvas.drawPath(path, paint);
  }

  void _drawCylinderShadow(
      Canvas canvas, Offset center, double size, Paint paint) {
    switch (shadowType) {
      case 'front':
        canvas.drawRect(
          Rect.fromCenter(
            center: center,
            width: size * 2,
            height: size * 2,
          ),
          paint,
        );
        break;
      case 'side':
        canvas.drawRect(
          Rect.fromCenter(
            center: center,
            width: size,
            height: size * 2,
          ),
          paint,
        );
        break;
      case 'top':
        canvas.drawOval(
          Rect.fromCenter(
            center: center,
            width: size * 2,
            height: size,
          ),
          paint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(ShadowPainter oldDelegate) {
    return oldDelegate.shape != shape || oldDelegate.shadowType != shadowType;
  }
}

class Shape3DRotationController extends ValueNotifier<double> {
  Shape3DRotationController() : super(0);

  void rotate(double angle) {
    value = angle;
  }
}

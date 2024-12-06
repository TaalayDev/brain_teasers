import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../theme/app_theme.dart';

class BridgeBuilderGame extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final Function(int score) onScoreUpdate;
  final VoidCallback onComplete;

  const BridgeBuilderGame({
    super.key,
    required this.gameData,
    required this.onScoreUpdate,
    required this.onComplete,
  });

  @override
  State<BridgeBuilderGame> createState() => _BridgeBuilderGameState();
}

class _BridgeBuilderGameState extends State<BridgeBuilderGame>
    with TickerProviderStateMixin {
  late AnimationController _ballController;
  late Animation<Offset> _ballAnimation;
  late List<Beam> _beams;
  late List<Anchor> _anchors;
  late Offset _ballPosition;
  late Offset _goalPosition;
  bool _isSimulating = false;
  bool _hasWon = false;
  int _remainingBeams = 3;
  int _score = 0;
  Beam? _selectedBeam;
  Anchor? _startAnchor;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _ballController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  void _initializeGame() {
    // Initialize anchors at fixed points
    _anchors = [
      Anchor(position: const Offset(50, 200)),
      Anchor(position: const Offset(150, 300)),
      Anchor(position: const Offset(250, 250)),
      Anchor(position: const Offset(350, 350)),
    ];

    _beams = [];
    _ballPosition = const Offset(50, 50);
    _goalPosition = const Offset(350, 400);
  }

  void _onPanStart(DragStartDetails details) {
    if (_isSimulating || _remainingBeams <= 0) return;

    final anchor = _findNearestAnchor(details.localPosition);
    if (anchor != null) {
      setState(() {
        _startAnchor = anchor;
        _selectedBeam = Beam(
          start: anchor.position,
          end: anchor.position,
        );
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_selectedBeam == null || _startAnchor == null) return;

    setState(() {
      _selectedBeam = Beam(
        start: _startAnchor!.position,
        end: details.localPosition,
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_selectedBeam == null || _startAnchor == null) return;

    final endAnchor = _findNearestAnchor(_selectedBeam!.end);
    if (endAnchor != null && endAnchor != _startAnchor) {
      setState(() {
        _beams.add(Beam(
          start: _startAnchor!.position,
          end: endAnchor.position,
        ));
        _remainingBeams--;
      });
    }
    setState(() {
      _selectedBeam = null;
      _startAnchor = null;
    });
  }

  Anchor? _findNearestAnchor(Offset position) {
    const anchorRadius = 20.0;
    return _anchors.firstWhereOrNull(
      (anchor) => (anchor.position - position).distance < anchorRadius,
    );
  }

  void _startSimulation() {
    if (_isSimulating) return;

    setState(() => _isSimulating = true);

    _calculateBallPath();

    _ballController.forward().then((_) {
      setState(() {
        if (_hasWon) {
          _score = 1000 - (_beams.length * 100);
          widget.onScoreUpdate(_score);
          widget.onComplete();
        }
      });
    });
  }

  void _calculateBallPath() {
    final path = _calculatePhysicsPath();
    _ballAnimation = TweenSequence<Offset>(
      path
          .map((point) => TweenSequenceItem(
                weight: 1,
                tween: Tween(
                  begin: point.start,
                  end: point.end,
                ),
              ))
          .toList(),
    ).animate(
      CurvedAnimation(
        parent: _ballController,
        curve: Curves.easeIn,
      ),
    );

    // Check if path reaches goal
    final lastPoint = path.last.end;
    _hasWon = (lastPoint - _goalPosition).distance < 30;
  }

  List<PathSegment> _calculatePhysicsPath() {
    final path = <PathSegment>[];
    var currentPos = _ballPosition;
    var velocity = const Offset(2, 0); // Initial rightward momentum
    const gravity = Offset(0, 0.5); // Downward acceleration
    const steps = 100;
    const dt = 1 / steps;

    for (int i = 0; i < steps; i++) {
      // Update position and velocity
      final nextPos = currentPos + velocity * dt;
      velocity += gravity;

      // Check collision with beams
      for (final beam in _beams) {
        if (_intersectsBeam(currentPos, nextPos, beam)) {
          // Reflect velocity off beam
          final beamAngle = math.atan2(
            beam.end.dy - beam.start.dy,
            beam.end.dx - beam.start.dx,
          );
          final normalAngle = beamAngle + math.pi / 2;
          final normal = Offset(
            math.cos(normalAngle),
            math.sin(normalAngle),
          );

          // Reflect velocity around normal vector
          final dot = velocity.dx * normal.dx + velocity.dy * normal.dy;
          velocity = velocity - normal * (2 * dot);
          velocity = velocity * 0.8; // Add some energy loss
        }
      }

      path.add(PathSegment(currentPos, nextPos));
      currentPos = nextPos;

      // Stop if ball goes off screen or hits goal
      if (!_isInBounds(currentPos) ||
          (currentPos - _goalPosition).distance < 30) {
        break;
      }
    }

    return path;
  }

  bool _intersectsBeam(Offset lineStart, Offset lineEnd, Beam beam) {
    // Line segment intersection check
    final denominator =
        (lineEnd.dx - lineStart.dx) * (beam.end.dy - beam.start.dy) -
            (lineEnd.dy - lineStart.dy) * (beam.end.dx - beam.start.dx);

    if (denominator == 0) return false;

    final ua = ((beam.end.dx - beam.start.dx) * (lineStart.dy - beam.start.dy) -
            (beam.end.dy - beam.start.dy) * (lineStart.dx - beam.start.dx)) /
        denominator;
    final ub = ((lineEnd.dx - lineStart.dx) * (lineStart.dy - beam.start.dy) -
            (lineEnd.dy - lineStart.dy) * (lineStart.dx - beam.start.dx)) /
        denominator;

    return ua >= 0 && ua <= 1 && ub >= 0 && ub <= 1;
  }

  bool _isInBounds(Offset position) {
    return position.dx >= 0 &&
        position.dx <= 400 &&
        position.dy >= 0 &&
        position.dy <= 600;
  }

  @override
  void dispose() {
    _ballController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _buildGameBoard(),
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
                'Bridge Builder',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Remaining beams: $_remainingBeams',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: AppTheme.accentColor),
                const SizedBox(width: 8),
                Text(
                  _score.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameBoard() {
    return Container(
      margin: const EdgeInsets.all(16),
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
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CustomPaint(
            painter: BridgeGamePainter(
              beams: _beams,
              anchors: _anchors,
              selectedBeam: _selectedBeam,
              ballPosition:
                  _isSimulating ? _ballAnimation.value : _ballPosition,
              goalPosition: _goalPosition,
            ),
            size: const Size(400, 600),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed:
                !_isSimulating && _beams.isNotEmpty ? _startSimulation : null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: _isSimulating
                ? null
                : () {
                    setState(() {
                      _initializeGame();
                      _ballController.reset();
                      _isSimulating = false;
                      _hasWon = false;
                      _remainingBeams = 3;
                    });
                  },
            icon: const Icon(Icons.refresh),
            label: const Text('Reset'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class BridgeGamePainter extends CustomPainter {
  final List<Beam> beams;
  final List<Anchor> anchors;
  final Beam? selectedBeam;
  final Offset ballPosition;
  final Offset goalPosition;

  BridgeGamePainter({
    required this.beams,
    required this.anchors,
    required this.selectedBeam,
    required this.ballPosition,
    required this.goalPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw beams
    final beamPaint = Paint()
      ..color = AppTheme.primaryColor
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    for (final beam in beams) {
      canvas.drawLine(beam.start, beam.end, beamPaint);
    }

    // Draw selected beam
    if (selectedBeam != null) {
      final selectedPaint = Paint()
        ..color = AppTheme.primaryColor.withOpacity(0.5)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(selectedBeam!.start, selectedBeam!.end, selectedPaint);
    }

    // Draw anchors
    final anchorPaint = Paint()
      ..color = AppTheme.secondaryColor
      ..style = PaintingStyle.fill;

    for (final anchor in anchors) {
      canvas.drawCircle(anchor.position, 8, anchorPaint);
    }

    // Draw ball
    final ballPaint = Paint()..color = AppTheme.accentColor;
    canvas.drawCircle(ballPosition, 10, ballPaint);

    // Draw goal
    final goalPaint = Paint()..color = AppTheme.correctAnswerColor;
    canvas.drawCircle(goalPosition, 15, goalPaint);
  }

  @override
  bool shouldRepaint(BridgeGamePainter oldDelegate) {
    return true;
  }
}

class Beam {
  final Offset start;
  final Offset end;

  Beam({required this.start, required this.end});
}

class Anchor {
  final Offset position;

  Anchor({required this.position});
}

class PathSegment {
  final Offset start;
  final Offset end;

  PathSegment(this.start, this.end);
}

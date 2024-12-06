import 'package:brain_teasers/components/header_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../theme/app_theme.dart';

extension on Offset {
  double distanceBetween(Offset offset) {
    return (this - offset).distance;
  }
}

class ChainReactionGame extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final Function(int score) onScoreUpdate;
  final VoidCallback onComplete;

  const ChainReactionGame({
    Key? key,
    required this.gameData,
    required this.onScoreUpdate,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<ChainReactionGame> createState() => _ChainReactionGameState();
}

class _ChainReactionGameState extends State<ChainReactionGame>
    with TickerProviderStateMixin {
  final List<DominoData> _dominoes = [];
  final GlobalKey _boardKey = GlobalKey();
  bool _isSimulating = false;
  bool _canAddDominoes = true;
  int _score = 0;
  late AnimationController _simulationController;

  // Goal position (bottom right)
  late Offset _goalPosition = Offset.zero;
  final double _goalRadius = 30.0;
  bool _isGoalPositionSet = false;

  @override
  void initState() {
    super.initState();
    _simulationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(_updateSimulation);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGoalPosition();
    });
  }

  @override
  void dispose() {
    _simulationController.dispose();
    super.dispose();
  }

  void _initializeGoalPosition() {
    if (!mounted) return;

    final RenderBox? box =
        _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      setState(() {
        _goalPosition = Offset(
          box.size.width * 0.8,
          box.size.height * 0.8,
        );
        _isGoalPositionSet = true;
      });
    }
  }

  void _addDomino(Offset position) {
    if (!_canAddDominoes || _dominoes.length >= 5) return;

    setState(() {
      _dominoes.add(DominoData(
        position: position,
        rotation: 0,
        isFalling: false,
      ));
    });
  }

  void _startSimulation() {
    if (_dominoes.isEmpty) return;

    setState(() {
      _isSimulating = true;
      _canAddDominoes = false;
      // Start the first domino falling
      _dominoes[0].isFalling = true;
    });

    _simulationController.forward(from: 0);
  }

  void _resetGame() {
    setState(() {
      _dominoes.clear();
      _isSimulating = false;
      _canAddDominoes = true;
      _simulationController.reset();
    });
  }

  void _updateSimulation() {
    if (!_isSimulating) return;

    setState(() {
      for (int i = 0; i < _dominoes.length; i++) {
        if (_dominoes[i].isFalling) {
          // Update rotation for falling dominoes
          _dominoes[i].rotation += 0.1;

          // Check collision with next domino
          if (i < _dominoes.length - 1 && _dominoes[i].rotation > math.pi / 4) {
            _dominoes[i + 1].isFalling = true;
          }

          // Check if reached goal
          if (_dominoes[i].position.distanceBetween(_goalPosition) <
                  _goalRadius &&
              !_dominoes[i].hasReachedGoal) {
            _dominoes[i].hasReachedGoal = true;
            _handleGoalReached();
          }
        }
      }
    });

    // Check if simulation is complete
    if (_dominoes.every((d) => d.rotation >= math.pi / 2)) {
      _simulationController.stop();
    }
  }

  void _handleGoalReached() {
    _score += 1000;
    widget.onScoreUpdate(_score);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildGameBoard(),
          ),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return HeaderContainer(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Chain Reaction',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
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
      key: _boardKey,
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
        onTapUp: (details) {
          if (_canAddDominoes) {
            _addDomino(details.localPosition);
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Grid background
              CustomPaint(
                painter: GridPainter(),
                size: Size.infinite,
              ),
              // Goal - only show when position is set
              if (_isGoalPositionSet)
                Positioned(
                  left: _goalPosition.dx - _goalRadius,
                  top: _goalPosition.dy - _goalRadius,
                  child: Container(
                    width: _goalRadius * 2,
                    height: _goalRadius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.correctAnswerColor.withOpacity(0.3),
                    ),
                    child: Center(
                      child: Container(
                        width: _goalRadius,
                        height: _goalRadius,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.correctAnswerColor,
                        ),
                      ),
                    ),
                  ),
                ),
              // Dominoes
              ..._dominoes.map((domino) => Positioned(
                    left: domino.position.dx - 5,
                    top: domino.position.dy - 20,
                    child: Transform.rotate(
                      angle: domino.rotation,
                      child: Container(
                        width: 10,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ).animate().scale(
                            duration: const Duration(milliseconds: 200),
                          ),
                    ),
                  )),
            ],
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
            onPressed: _isSimulating ? null : _startSimulation,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _resetGame,
            icon: const Icon(Icons.refresh),
            label: const Text('Reset'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DominoData {
  Offset position;
  double rotation;
  bool isFalling;
  bool hasReachedGoal;

  DominoData({
    required this.position,
    required this.rotation,
    required this.isFalling,
    this.hasReachedGoal = false,
  });
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    const spacing = 20.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

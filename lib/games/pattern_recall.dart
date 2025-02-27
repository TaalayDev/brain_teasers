import 'dart:async';
import 'dart:math';
import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/game_container.dart';
import '../components/particle_system.dart';
import '../theme/app_theme.dart';
import 'game_controller.dart';

class PatternRecallGame extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final GameController gameController;

  const PatternRecallGame({
    super.key,
    required this.gameData,
    required this.gameController,
  });

  @override
  State<PatternRecallGame> createState() => _PatternRecallGameState();
}

class _PatternRecallGameState extends State<PatternRecallGame>
    with TickerProviderStateMixin {
  late int gridSize;
  late int sequenceLength;
  late List<int> pattern;
  late List<int> playerPattern;
  late bool isShowingPattern;
  late bool isPlayerTurn;
  late bool isInteractionEnabled;
  late int currentStep;
  int score = 0;
  Timer? patternTimer;
  late AnimationController _celebrationController;
  late AnimationController _tileController;

  int combo = 0;
  int highestCombo = 0;
  int reanimateTile = -1;

  List<GlobalKey> tileKeys = [];
  List<Widget> activeParticles = [];

  // Level configurations
  final List<Map<String, dynamic>> levelConfigs = [
    {'speed': 1000, 'gridSize': 3, 'sequenceLength': 3},
    {'speed': 800, 'gridSize': 3, 'sequenceLength': 4},
    {'speed': 700, 'gridSize': 4, 'sequenceLength': 4},
    {'speed': 600, 'gridSize': 4, 'sequenceLength': 5},
    {'speed': 500, 'gridSize': 4, 'sequenceLength': 6},
    {'speed': 450, 'gridSize': 5, 'sequenceLength': 6},
    {'speed': 400, 'gridSize': 5, 'sequenceLength': 7},
    {'speed': 350, 'gridSize': 5, 'sequenceLength': 8},
    {'speed': 300, 'gridSize': 6, 'sequenceLength': 8},
    {'speed': 250, 'gridSize': 6, 'sequenceLength': 9},
  ];

  final List<Color> tileColors = [
    const Color(0xFF4CAF50),
    const Color(0xFF2196F3),
    const Color(0xFFFFC107),
    const Color(0xFFE91E63),
    const Color(0xFF9C27B0),
    const Color(0xFFFF5722),
    const Color(0xFF00BCD4),
    const Color(0xFF795548),
    const Color(0xFF607D8B),
  ];

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _tileController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initializeGame();
  }

  void _initializeGame() {
    score = 0;
    combo = 0;
    highestCombo = 0;

    // Initialize game with controller values
    widget.gameController.setValues(
      timeRemaining: 30,
      maxLevels: levelConfigs.length,
      lives: 3,
      currentLevel: widget.gameData['level'] ?? 0,
      score: 0,
      streak: 0,
      highestStreak: 0,
    );

    _applyLevelConfig();
    _generatePattern();

    activeParticles = [];
  }

  void _applyLevelConfig() {
    final level = widget.gameController.currentLevel;
    final config = levelConfigs[min(level, levelConfigs.length - 1)];
    gridSize = config['gridSize'];
    sequenceLength = config['sequenceLength'];
    pattern = [];
    playerPattern = [];
    isShowingPattern = false;
    isPlayerTurn = false;
    isInteractionEnabled = true;
    currentStep = 0;

    tileKeys = List.generate(
      gridSize * gridSize,
      (_) => GlobalKey(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.gameController.startGame(
        timeLimit: 30,
        level: level,
        maxLevels: levelConfigs.length,
      );
    });
  }

  void _generatePattern() {
    final random = Random();
    pattern = List.generate(
      sequenceLength,
      (_) => random.nextInt(gridSize * gridSize),
    );

    // Clear player's pattern
    playerPattern = [];

    // Start showing the pattern to the player
    _showPattern();
  }

  void _showPattern() {
    setState(() {
      isShowingPattern = true;
      isPlayerTurn = false;
      isInteractionEnabled =
          false; // Disable interaction during pattern display
      currentStep = 0;
    });

    final level = widget.gameController.currentLevel;
    final config = levelConfigs[min(level, levelConfigs.length - 1)];
    final speed = config['speed'];

    // Cancel any existing timer
    patternTimer?.cancel();

    // Start a new timer to show each step of the pattern
    patternTimer = Timer.periodic(Duration(milliseconds: speed), (timer) async {
      if (currentStep >= pattern.length) {
        timer.cancel();
        setState(() {
          isShowingPattern = false;
          isPlayerTurn = true;
          currentStep = 0;
          playerPattern = [];
          isInteractionEnabled =
              true; // Re-enable interaction when pattern is done
        });
        return;
      }

      setState(() {
        isShowingPattern = false;
      });

      await Future.delayed(const Duration(milliseconds: 200));

      if (mounted) {
        // Check if still mounted before updating state
        setState(() {
          isShowingPattern = true;
          currentStep++;
        });
        HapticFeedback.lightImpact();
      }
    });
  }

  void _onTileTap(int index) {
    if (!isPlayerTurn ||
        widget.gameController.isPaused ||
        !isInteractionEnabled) return;

    // Ensure currentStep matches playerPattern length
    if (currentStep != playerPattern.length) {
      setState(() {
        currentStep = playerPattern.length;
      });
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      if (playerPattern.contains(index)) {
        reanimateTile = index;
      } else {
        reanimateTile = -1;
      }

      playerPattern.add(index);
      widget.gameController.incrementMoves();

      if (playerPattern.last != pattern[currentStep]) {
        _handleIncorrectMove();
      } else {
        _showTileParticles(index);
        // Check if this is the last item in the pattern
        if (currentStep == pattern.length - 1) {
          _handleLevelComplete();
        } else {
          currentStep++;
          combo++;
          if (combo > highestCombo) {
            highestCombo = combo;
            widget.gameController.setValues(highestStreak: highestCombo);
          }
          widget.gameController.updateStreak(true);
        }
      }
    });
  }

  void _handleIncorrectMove() {
    HapticFeedback.heavyImpact();
    widget.gameController.loseLive();
    combo = 0;
    widget.gameController.updateStreak(false);

    // Immediately disable interaction
    setState(() {
      isInteractionEnabled = false;
    });

    if (widget.gameController.lives <= 0) {
      _handleGameOver();
    } else {
      _showFeedback(false);
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            playerPattern = [];
            currentStep = 0;
            isInteractionEnabled = true; // Re-enable interaction after reset
          });
        }
      });
    }
  }

  void _handleLevelComplete() {
    // Immediately disable interaction
    setState(() {
      isInteractionEnabled = false;
    });

    _celebrationController.forward(from: 0);

    // Calculate score for this level
    final levelBonus = (widget.gameController.currentLevel + 1) * 100;
    final comboBonus = combo * 20;
    final timeBonus = widget.gameController.timeRemaining * 10;
    final movesPenalty = widget.gameController.moves * 5;

    final levelScore = levelBonus + comboBonus + timeBonus - movesPenalty;
    score += levelScore > 0 ? levelScore : 10;

    widget.gameController.updateScore(score);
    _showFeedback(true);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        if (widget.gameController.nextLevel()) {
          // Load next level
          _applyLevelConfig();
          _generatePattern();
        } else {
          // Game completed
          widget.gameController.completeGame();
        }
      }
    });
  }

  void _handleGameOver() {
    widget.gameController.gameOver();
  }

  void _showFeedback(bool success) {
    Flushbar(
      messageText: Row(
        children: [
          Icon(
            success ? Icons.check : Icons.close,
            color: success ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            success ? 'Correct pattern!' : 'Incorrect pattern!',
            style: GoogleFonts.poppins(
              color: success ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 1500),
      flushbarStyle: FlushbarStyle.FLOATING,
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      backgroundGradient: LinearGradient(
        colors: [
          Colors.white,
          success ? Colors.green.shade100 : Colors.red.shade100,
        ],
      ),
    ).show(context);
  }

  void _showTileParticles(int index) {
    final RenderBox? renderBox =
        tileKeys[index].currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(
      Offset(renderBox.size.width / 2, renderBox.size.height / 2),
    );

    // Add particle effect to show tile was correctly selected
    setState(() {
      activeParticles.add(
        Positioned(
          left: position.dx - 20,
          top: position.dy - 20,
          child: ParticleEffect(
            numberOfParticles: 10,
            particleColor: tileColors[index % tileColors.length],
            onComplete: () {
              setState(() {
                activeParticles.removeWhere((element) =>
                    element.key ==
                    ValueKey('particle-${position.dx}-${position.dy}'));
              });
            },
            maxRadius: 30,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    patternTimer?.cancel();
    _celebrationController.dispose();
    _tileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameContainer(
      child: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildGrid()),
              _buildCards(),
              _buildControls(),
            ],
          ),
          ...activeParticles,
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard(
                icon: Icons.stars,
                label: 'Score',
                value: score.toString(),
                color: AppTheme.accentColor,
              ),
              _buildStatCard(
                icon: Icons.trending_up,
                label: 'Level',
                value: '${widget.gameController.currentLevel + 1}',
                color: AppTheme.primaryColor,
              ),
              _buildStatCard(
                icon: Icons.bolt,
                label: 'Combo',
                value: '${widget.gameController.streak} / $highestCombo',
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLives(),
              _buildTimer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLives() {
    return Row(
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            index < widget.gameController.lives
                ? Icons.favorite
                : Icons.favorite_border,
            color: AppTheme.wrongAnswerColor,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildTimer() {
    return AnimatedBuilder(
      animation: widget.gameController,
      builder: (context, child) {
        final color =
            widget.gameController.timeRemaining < 10 ? Colors.red : Colors.blue;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.timer, color: color),
              const SizedBox(width: 8),
              Text(
                widget.gameController.timeRemaining.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrid() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final gridWidth = constraints.maxWidth;
            final tileSize = (gridWidth - (gridSize - 1) * 8) / gridSize;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridSize,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: gridSize * gridSize,
              itemBuilder: (context, index) => _buildTile(index, tileSize),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTile(int index, double size) {
    final bool isHighlighted = isShowingPattern &&
        currentStep > 0 &&
        pattern[currentStep - 1] == index;
    // Only consider it in player pattern if the selection was correct
    final bool isInPlayerPattern =
        playerPattern.where((item) => item == index).isNotEmpty &&
            playerPattern.indexOf(index) < pattern.length &&
            pattern[playerPattern.indexOf(index)] == index;
    final color = tileColors[index % tileColors.length];

    return GestureDetector(
      key: tileKeys[index],
      onTap: () => _onTileTap(index),
      child: TileWidget(
        isHighlighted: isHighlighted,
        isInPlayerPattern: isInPlayerPattern,
        isReanimated: reanimateTile == index,
        color: color,
      ),
    );
  }

  Widget _buildCards() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < sequenceLength; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.circle,
                color: playerPattern.length > i
                    ? (playerPattern[i] == pattern[i]
                        ? Colors.green
                        : Colors.red)
                    : Colors.grey,
                size: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: isPlayerTurn && !widget.gameController.isPaused
                ? _showPattern
                : null,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: Text(
              'Show Pattern',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: color,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TileWidget extends HookWidget {
  const TileWidget({
    super.key,
    required this.isHighlighted,
    required this.isInPlayerPattern,
    required this.isReanimated,
    required this.color,
  });

  final bool isHighlighted;
  final bool isInPlayerPattern;
  final bool isReanimated;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isInPlayerPatternState = useState(isInPlayerPattern);

    useEffect(() {
      if (isReanimated) {
        isInPlayerPatternState.value = !isInPlayerPattern;
        Future.delayed(const Duration(milliseconds: 200), () {
          isInPlayerPatternState.value = isInPlayerPattern;
        });
      }
      return null;
    }, [isReanimated]);

    useEffect(() {
      isInPlayerPatternState.value = isInPlayerPattern;
      return null;
    }, [isInPlayerPattern]);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isHighlighted || isInPlayerPatternState.value
            ? color
            : color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (isHighlighted || isInPlayerPatternState.value)
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(
              isHighlighted || isInPlayerPatternState.value ? 0.5 : 0.0,
            ),
            width: 2,
          ),
        ),
      ),
    );
  }
}

class ParticleEffect extends StatefulWidget {
  final int numberOfParticles;
  final Color particleColor;
  final VoidCallback onComplete;
  final double maxRadius;

  const ParticleEffect({
    super.key,
    required this.numberOfParticles,
    required this.particleColor,
    required this.onComplete,
    this.maxRadius = 20,
  });

  @override
  State<ParticleEffect> createState() => _ParticleEffectState();
}

class _ParticleEffectState extends State<ParticleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    particles = List.generate(
      widget.numberOfParticles,
      (index) => Particle(
        Random().nextDouble() * 2 * pi,
        widget.particleColor,
        Random().nextDouble() * widget.maxRadius,
        Random().nextDouble() * 0.5 + 0.5,
      ),
    );

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.maxRadius * 2, widget.maxRadius * 2),
          painter: ParticlePainter(
            particles: particles,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class Particle {
  final double angle;
  final Color color;
  final double maxRadius;
  final double speed;

  Particle(this.angle, this.color, this.maxRadius, this.speed);
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final particle in particles) {
      final radius = progress * particle.maxRadius;
      final offset = Offset(
        center.dx + cos(particle.angle) * radius * particle.speed,
        center.dy + sin(particle.angle) * radius * particle.speed,
      );

      canvas.drawCircle(
        offset,
        3 * (1 - progress),
        Paint()
          ..color = particle.color.withOpacity(1 - progress)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

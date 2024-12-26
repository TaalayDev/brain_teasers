import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late int currentStep;
  late int score;
  late int level;
  late int lives;
  late Timer? patternTimer;
  late AnimationController _celebrationController;
  late int timeRemaining;
  Timer? _gameTimer;
  int combo = 0;
  int highestCombo = 0;

  List<GlobalKey> tileKeys = [];
  List<Widget> activeParticles = [];

  // Level configurations
  final List<Map<String, dynamic>> levelConfigs = [
    {'speed': 1000, 'gridSize': 3, 'sequenceLength': 3}, // Level 1
    {'speed': 800, 'gridSize': 3, 'sequenceLength': 4}, // Level 2
    {'speed': 700, 'gridSize': 4, 'sequenceLength': 4}, // Level 3
    {'speed': 600, 'gridSize': 4, 'sequenceLength': 5}, // Level 4
    {'speed': 500, 'gridSize': 4, 'sequenceLength': 6}, // Level 5
    {'speed': 450, 'gridSize': 5, 'sequenceLength': 6}, // Level 6
    {'speed': 400, 'gridSize': 5, 'sequenceLength': 7}, // Level 7
    {'speed': 350, 'gridSize': 5, 'sequenceLength': 8}, // Level 8
    {'speed': 300, 'gridSize': 6, 'sequenceLength': 8}, // Level 9
    {'speed': 250, 'gridSize': 6, 'sequenceLength': 9}, // Level 10
  ];

  final List<Color> tileColors = [
    const Color(0xFF4CAF50), // Green
    const Color(0xFF2196F3), // Blue
    const Color(0xFFFFC107), // Yellow
    const Color(0xFFE91E63), // Pink
    const Color(0xFF9C27B0), // Purple
    const Color(0xFFFF5722), // Orange
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFF795548), // Brown
    const Color(0xFF607D8B), // Blue Grey
  ];

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _initializeGame();
  }

  void _initializeGame() {
    level = 1;
    score = 0;
    lives = 3;
    combo = 0;
    highestCombo = 0;
    _applyLevelConfig();
    _generatePattern();

    tileKeys = List.generate(
      gridSize * gridSize,
      (_) => GlobalKey(),
    );
    activeParticles = [];
  }

  void _applyLevelConfig() {
    final config = levelConfigs[min(level - 1, levelConfigs.length - 1)];
    gridSize = config['gridSize'];
    sequenceLength = config['sequenceLength'];
    pattern = [];
    playerPattern = [];
    isShowingPattern = false;
    isPlayerTurn = false;
    currentStep = 0;
    timeRemaining = 30; // Reset timer for each level
  }

  void _startGameTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (timeRemaining > 0) {
          timeRemaining--;
        } else {
          _handleIncorrectMove();
          timeRemaining = 30;
        }
      });
    });
  }

  void _generatePattern() {
    final random = Random();
    pattern = List.generate(
      sequenceLength,
      (_) => random.nextInt(gridSize * gridSize),
    );
    _showPattern();
  }

  void _showPattern() {
    setState(() {
      isShowingPattern = true;
      isPlayerTurn = false;
      currentStep = 0;
    });

    final config = levelConfigs[min(level - 1, levelConfigs.length - 1)];
    final speed = config['speed'];

    patternTimer = Timer.periodic(Duration(milliseconds: speed), (timer) {
      if (currentStep >= pattern.length) {
        timer.cancel();
        setState(() {
          isShowingPattern = false;
          isPlayerTurn = true;
          currentStep = 0;
          playerPattern = [];
        });
        _startGameTimer();
        return;
      }

      setState(() {
        currentStep++;
      });
      HapticFeedback.lightImpact();
    });
  }

  void _onTileTap(int index) {
    if (!isPlayerTurn) return;

    HapticFeedback.mediumImpact();
    setState(() {
      playerPattern.add(index);

      if (playerPattern.last != pattern[currentStep]) {
        _handleIncorrectMove();
      } else {
        _showTileParticles(index);
        if (currentStep == pattern.length - 1) {
          _handleLevelComplete();
        } else {
          currentStep++;
          combo++;
          if (combo > highestCombo) {
            highestCombo = combo;
          }
        }
      }
    });
  }

  void _handleIncorrectMove() {
    HapticFeedback.heavyImpact();
    lives--;
    combo = 0;
    if (lives <= 0) {
      _handleGameOver();
    } else {
      _showFeedback(false);
      Future.delayed(const Duration(milliseconds: 1000), () {
        setState(() {
          playerPattern = [];
          currentStep = 0;
          timeRemaining = 30;
        });
      });
    }
  }

  void _handleLevelComplete() {
    _celebrationController.forward(from: 0);
    final levelBonus = level * 100;
    final comboBonus = combo * 20;
    final timeBonus = timeRemaining * 10;

    score += levelBonus + comboBonus + timeBonus;
    widget.gameController.updateScore(score);

    level++;
    _showFeedback(true);

    Future.delayed(const Duration(milliseconds: 1500), () {
      _applyLevelConfig();
      _generatePattern();
    });
  }

  void _handleGameOver() {
    _gameTimer?.cancel();
    widget.gameController.completeGame();
  }

  void _showFeedback(bool success) {
    final message = success
        ? 'Level $level Complete!\n+${level * 100} points\n+${combo * 20} combo bonus\n+${timeRemaining * 10} time bonus'
        : 'Wrong pattern! Try again';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        backgroundColor:
            success ? AppTheme.correctAnswerColor : AppTheme.wrongAnswerColor,
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  void _showTileParticles(int index) {
    final RenderBox? renderBox =
        tileKeys[index].currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(
      Offset(renderBox.size.width / 2, renderBox.size.height / 2),
    );

    setState(() {
      activeParticles.add(
        Positioned(
          left: position.dx - 100, // Center the particle system
          top: position.dy - 100, // Center the particle system
          child: ParticleSystem(
            position: const Offset(100, 100), // Center of the particle system
            color: tileColors[index % tileColors.length],
          ),
        ),
      );
    });

    // Remove particles after animation
    Future.delayed(const Duration(milliseconds: 600), () {
      setState(() {
        activeParticles.removeLast();
      });
    });
  }

  @override
  void dispose() {
    patternTimer?.cancel();
    _gameTimer?.cancel();
    _celebrationController.dispose();
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
                value: level.toString(),
                color: AppTheme.primaryColor,
              ),
              _buildStatCard(
                icon: Icons.bolt,
                label: 'Combo',
                value: '$combo / $highestCombo',
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
            index < lives ? Icons.favorite : Icons.favorite_border,
            color: AppTheme.wrongAnswerColor,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildTimer() {
    final color = timeRemaining < 10 ? Colors.red : Colors.blue;
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
            timeRemaining.toString(),
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
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
    final bool isInPlayerPattern = playerPattern.contains(index);
    final color = tileColors[index % tileColors.length];

    return GestureDetector(
      key: tileKeys[index],
      onTap: () => _onTileTap(index),
      child: Container(
        decoration: BoxDecoration(
          color: isHighlighted || isInPlayerPattern
              ? color
              : color.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (isHighlighted || isInPlayerPattern)
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: AnimatedScale(
          scale: isHighlighted || isInPlayerPattern ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(
                  isHighlighted || isInPlayerPattern ? 0.5 : 0.0,
                ),
                width: 2,
              ),
            ),
          ),
        ),
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
            onPressed: isShowingPattern || isPlayerTurn ? null : _showPattern,
            icon: const Icon(Icons.refresh),
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

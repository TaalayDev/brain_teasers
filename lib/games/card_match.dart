import 'dart:async';
import 'dart:math' as math;
import 'dart:math';
import 'package:brain_teasers/utils/card_match_level.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/game_container.dart';
import '../theme/app_theme.dart';
import 'game_controller.dart';

class CardMatchGame extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final GameController gameController;

  const CardMatchGame({
    super.key,
    required this.gameData,
    required this.gameController,
  });

  @override
  State<CardMatchGame> createState() => _CardMatchGameState();
}

class _CardMatchGameState extends State<CardMatchGame>
    with TickerProviderStateMixin {
  CardData? firstCard;
  CardData? secondCard;
  int score = 0;
  int moves = 0;
  bool isProcessing = false;
  late int gridRows;
  late int gridCols;
  int get timeElapsed => widget.gameController.timeRemaining;
  late ConfettiController _confettiController;
  bool showHint = false;
  int hintsRemaining = 3;

  int get _level => widget.gameController.currentLevel;
  CardMatchLevel get level => CardMatchLevelSystem.levels[_level];
  List<CardData> cards = [];

  @override
  void initState() {
    super.initState();
    _initializeGame();

    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 500),
    );
  }

  void _initializeGame() {
    _initializeLevel();
  }

  void _initializeLevel() {
    gridRows = level.gridRows;
    gridCols = level.gridColumns;
    cards = CardMatchLevelSystem.generateCards(level, this);

    hintsRemaining = level.hintsAllowed;
    firstCard = null;
    secondCard = null;
    isProcessing = false;
    showHint = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.gameController.startGame(
        level: _level,
        maxLevels: CardMatchLevelSystem.levels.length,
        timeLimit: level.timeLimit,
      );
    });
  }

  void _showHintBriefly() {
    if (hintsRemaining <= 0) return;

    setState(() {
      showHint = true;
      hintsRemaining--;
    });

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        showHint = false;
      });
    });
  }

  void _onMatchFound() {
    score += 100;

    // Bonus points for quick matches
    if (timeElapsed < 5) {
      score += 50;
    }

    widget.gameController.updateScore(score);
  }

  void _updateCard(int index, CardData card) {
    cards[index] = card;
  }

  void _onCardTap(CardData card) {
    if (isProcessing || card.isMatched || card.isFlipped) return;

    card.animation.forward();

    final index = card.currentIndex;

    setState(() {
      _updateCard(index, card.copyWith(isFlipped: true));

      if (firstCard == null) {
        firstCard = card;
        // Haptic feedback for first card
        HapticFeedback.lightImpact();
      } else if (secondCard == null) {
        secondCard = card;
        isProcessing = true;
        moves++;

        // Haptic feedback for second card
        HapticFeedback.mediumImpact();

        Future.delayed(const Duration(milliseconds: 1000), () {
          setState(() {
            if (firstCard!.value == secondCard!.value) {
              _updateCard(
                firstCard!.currentIndex,
                firstCard!.copyWith(isMatched: true),
              );
              _updateCard(
                secondCard!.currentIndex,
                secondCard!.copyWith(isMatched: true),
              );

              // Start fade out animation for matched cards
              firstCard!.fadeAnimation.forward();
              secondCard!.fadeAnimation.forward();

              _onMatchFound();

              if (cards.every((card) => card.isMatched)) {
                _confettiController.play();

                // Haptic feedback for game completion
                HapticFeedback.mediumImpact();

                if (_level == CardMatchLevelSystem.levels.length - 1) {
                  widget.gameController.completeGame();
                } else {
                  widget.gameController.nextLevel();
                  _initializeLevel();
                }
              }
            } else {
              firstCard!.animation.reverse();
              secondCard!.animation.reverse();

              _updateCard(
                firstCard!.currentIndex,
                firstCard!.copyWith(isFlipped: false),
              );
              _updateCard(
                secondCard!.currentIndex,
                secondCard!.copyWith(isFlipped: false),
              );

              score = math.max(0, score - 10);
              widget.gameController.updateScore(score);

              // Haptic feedback for mismatch
              HapticFeedback.heavyImpact();
            }

            firstCard = null;
            secondCard = null;
            isProcessing = false;
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameContainer(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildGrid(),
                ConfettiOverlay(controller: _confettiController),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
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
              _buildTimeDisplay(),
              _buildStatCard(
                icon: Icons.touch_app,
                label: 'Moves',
                value: moves.toString(),
                color: AppTheme.primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildHintButton(),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay() {
    return AnimatedBuilder(
      animation: widget.gameController,
      builder: (context, child) {
        final minutes = (timeElapsed ~/ 60).toString().padLeft(2, '0');
        final seconds = (timeElapsed % 60).toString().padLeft(2, '0');

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                '$minutes:$seconds',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHintButton() {
    return TextButton.icon(
      onPressed: hintsRemaining > 0 ? _showHintBriefly : null,
      icon: const Icon(Icons.lightbulb_outline),
      label: Text('Hint ($hintsRemaining remaining)'),
      style: TextButton.styleFrom(
        foregroundColor: Colors.amber,
        backgroundColor: Colors.amber.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      constraints: const BoxConstraints(maxWidth: 800),
      alignment: Alignment.center,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth =
              (constraints.maxWidth - (gridCols - 1) * 8) / gridCols;
          final cardHeight =
              (constraints.maxHeight - (gridRows - 1) * 8) / gridRows;
          final size = math.min(cardWidth, cardHeight);

          return GridView.builder(
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridCols,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              return MemoryCard(
                card: cards[index],
                size: size,
                onTap: () => _onCardTap(cards[index]),
                showHint: showHint && !cards[index].isMatched,
              );
            },
          );
        },
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

  @override
  void dispose() {
    _confettiController.dispose();
    for (var card in cards) {
      card.animation.dispose();
      card.fadeAnimation.dispose();
    }
    super.dispose();
  }
}

class MemoryCard extends StatelessWidget {
  final CardData card;
  final double size;
  final VoidCallback onTap;
  final bool showHint;

  const MemoryCard({
    super.key,
    required this.card,
    required this.size,
    required this.onTap,
    this.showHint = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: card.fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: 1 - card.fadeAnimation.value,
          child: Transform.scale(
            scale: 1 - (card.fadeAnimation.value * 0.5),
            child: GestureDetector(
              onTap: onTap,
              child: AnimatedBuilder(
                animation: card.animation,
                builder: (context, child) {
                  var angle = card.animation.value * math.pi;

                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.002)
                      ..rotateY(angle),
                    alignment: Alignment.center,
                    child: angle < math.pi / 2
                        ? _buildCardBack()
                        : Transform(
                            transform: Matrix4.identity()..rotateY(math.pi),
                            alignment: Alignment.center,
                            child: _buildCardFront(),
                          ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardFront() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          card.value,
          style: GoogleFonts.poppins(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      decoration: BoxDecoration(
        color: showHint ? AppTheme.accentColor : AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (showHint ? AppTheme.accentColor : AppTheme.secondaryColor)
                .withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.question_mark_rounded,
              size: size * 0.4,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          _buildPattern(),
          if (showHint)
            Center(
              child: Text(
                card.value,
                style: TextStyle(
                  fontSize: size * 0.3,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPattern() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CustomPaint(
        size: Size(size, size),
        painter: CardPatternPainter(),
      ),
    );
  }
}

class ConfettiOverlay extends StatelessWidget {
  final ConfettiController controller;

  const ConfettiOverlay({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ConfettiWidget(
        confettiController: controller,
        blastDirectionality: BlastDirectionality.explosive,
        shouldLoop: false,
        colors: const [
          Colors.green,
          Colors.blue,
          Colors.pink,
          Colors.orange,
          Colors.purple
        ],
        createParticlePath: drawStar,
      ),
    );
  }

  Path drawStar(Size size) {
    final path = Path();
    final halfWidth = size.width / 2;
    final halfHeight = size.height / 2;
    final radius = math.min(halfWidth, halfHeight);

    path.moveTo(halfWidth, 0);
    for (var i = 1; i <= 5; i++) {
      final x = math.cos(2 * math.pi * i / 5) * radius + halfWidth;
      final y = math.sin(2 * math.pi * i / 5) * radius + halfHeight;
      path.lineTo(x, y);
    }

    path.close();
    return path;
  }
}

final Random random = Random();

class ConfettiPainter extends CustomPainter {
  final double progress;
  final List<Particle> particles;

  ConfettiPainter({required this.progress})
      : particles = List.generate(
          20,
          (index) {
            return Particle(
              x: random.nextDouble(),
              y: random.nextDouble(),
              color: Colors.primaries[random.nextInt(Colors.primaries.length)]
                  .withOpacity(0.6),
              size: random.nextDouble() * 3 + 2,
              speed: random.nextDouble() * 0.3 + 0.1,
              angle: random.nextDouble() * math.pi / 2 + math.pi / 4,
            );
          },
        );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      paint.color = particle.color;

      final x = particle.x * size.width;
      final y =
          particle.y * size.height + (progress * particle.speed * size.height);

      // Create a gentle arc motion
      final dx = math.sin(progress * 2 * math.pi) * 20;

      canvas.drawCircle(
        Offset(x + dx, y),
        particle.size * (1 - progress), // Particles get smaller as they fall
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}

class Particle {
  final double x;
  final double y;
  final Color color;
  final double size;
  final double speed;
  final double angle;

  Particle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.speed,
    required this.angle,
  });
}

class CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pattern = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < size.width; i += 20) {
      for (var j = 0; j < size.height; j += 20) {
        canvas.drawCircle(
          Offset(i.toDouble(), j.toDouble()),
          2,
          pattern,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

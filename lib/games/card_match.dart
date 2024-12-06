import 'dart:async';
import 'dart:math' as math;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/game_container.dart';
import '../components/header_container.dart';
import '../theme/app_theme.dart';

class CardMatchGame extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final Function(int score) onScoreUpdate;
  final VoidCallback onComplete;

  const CardMatchGame({
    super.key,
    required this.gameData,
    required this.onScoreUpdate,
    required this.onComplete,
  });

  @override
  State<CardMatchGame> createState() => _CardMatchGameState();
}

class _CardMatchGameState extends State<CardMatchGame>
    with TickerProviderStateMixin {
  late List<CardData> cards;
  CardData? firstCard;
  CardData? secondCard;
  int score = 0;
  int moves = 0;
  bool isProcessing = false;
  late int gridRows;
  late int gridCols;
  int timeElapsed = 0;
  late Timer gameTimer;
  late AnimationController _confettiController;
  bool showHint = false;
  int hintsRemaining = 3;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _startTimer();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  void _startTimer() {
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        timeElapsed++;
      });
    });
  }

  void _initializeGame() {
    gridRows = widget.gameData['gridSize']['rows'];
    gridCols = widget.gameData['gridSize']['columns'];
    cards = _createCards();
  }

  List<CardData> _createCards() {
    final List<String> values = _generateCardValues();
    return values
        .asMap()
        .entries
        .map((entry) => CardData(
              id: entry.key,
              value: entry.value,
              animation: AnimationController(
                vsync: this,
                duration: const Duration(milliseconds: 400),
              ),
              fadeAnimation: AnimationController(
                vsync: this,
                duration: const Duration(milliseconds: 400),
              ),
            ))
        .toList();
  }

  List<String> _generateCardValues() {
    final theme = widget.gameData['theme'];
    final int pairsNeeded = (gridRows * gridCols) ~/ 2;
    List<String> values = [];

    switch (theme) {
      case 'animals':
        values = ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯'];
        break;
      case 'fruits':
        values = ['🍎', '🍌', '🍇', '🍊', '🍓', '🍐', '🍒', '🥝', '🍍', '🥭'];
        break;
      case 'shapes':
        values = ['⭐', '⚡', '❤️', '💠', '🔶', '🔺', '⭕', '🔷', '💫', '🌟'];
        break;
      default:
        values = List.generate(10, (index) => String.fromCharCode(65 + index));
    }

    values = values.take(pairsNeeded).toList();
    values = [...values, ...values];
    values.shuffle();

    return values;
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
    _confettiController.forward(from: 0);
    score += 100;

    // Bonus points for quick matches
    if (timeElapsed < 5) {
      score += 50;
    }

    widget.onScoreUpdate(score);
  }

  void _onCardTap(CardData card) {
    if (isProcessing || card.isMatched || card.isFlipped) return;

    card.animation.forward();

    setState(() {
      card.isFlipped = true;

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
              firstCard!.isMatched = true;
              secondCard!.isMatched = true;

              // Start fade out animation for matched cards
              firstCard!.fadeAnimation.forward();
              secondCard!.fadeAnimation.forward();

              _onMatchFound();

              if (cards.every((card) => card.isMatched)) {
                gameTimer.cancel();
                widget.onComplete();
              }
            } else {
              firstCard!.animation.reverse();
              secondCard!.animation.reverse();
              firstCard!.isFlipped = false;
              secondCard!.isFlipped = false;
              score = math.max(0, score - 10);
              widget.onScoreUpdate(score);

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
                if (_confettiController.status == AnimationStatus.forward)
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
    gameTimer.cancel();
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
  final AnimationController controller;

  const ConfettiOverlay({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: ConfettiPainter(
            progress: controller.value,
          ),
        );
      },
    );
  }
}

final Random random = Random();

class ConfettiPainter extends CustomPainter {
  final double progress;
  final List<Particle> particles;

  ConfettiPainter({required this.progress})
      : particles = List.generate(20, (index) {
          return Particle(
            x: random.nextDouble(),
            y: random.nextDouble(),
            color: Colors.primaries[random.nextInt(Colors.primaries.length)]
                .withOpacity(0.6),
            size: random.nextDouble() * 3 + 2,
            speed: random.nextDouble() * 0.3 + 0.1,
            angle: random.nextDouble() * math.pi / 2 + math.pi / 4,
          );
        });

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

class CardData {
  final int id;
  final String value;
  bool isMatched;
  bool isFlipped;
  final AnimationController animation;
  final AnimationController fadeAnimation;

  CardData({
    required this.id,
    required this.value,
    required this.animation,
    required this.fadeAnimation,
    this.isMatched = false,
    this.isFlipped = false,
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

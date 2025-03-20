import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../ui/components/game_container.dart';
import '../ui/components/header_container.dart';
import '../ui/theme/app_theme.dart';
import 'controller/game_controller.dart';

class SymbolSequenceGame extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final GameController gameController;

  const SymbolSequenceGame({
    super.key,
    required this.gameData,
    required this.gameController,
  });

  @override
  State<SymbolSequenceGame> createState() => _SymbolSequenceGameState();
}

class _SymbolSequenceGameState extends State<SymbolSequenceGame>
    with SingleTickerProviderStateMixin {
  late List<List<dynamic>> sequences;
  late List<String> hints;
  late List<String?> selectedAnswers;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  int currentSequence = 0;
  int streak = 0;
  bool showHint = false;
  bool isAnimating = false;
  double rotationAngle = 0.0;
  int hintsRemaining = 3;
  bool showTutorial = true;

  @override
  void initState() {
    super.initState();
    sequences = List<List<dynamic>>.from(widget.gameData['sequences']);
    hints = List<String>.from(widget.gameData['hints']);
    selectedAnswers = List.filled(sequences.length, null);

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Initialize game controller
    widget.gameController.startGame(
      timeLimit: 300, // 5 minutes
      maxLevels: sequences.length,
    );

    // Show tutorial on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorialDialog();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void checkAnswer(String answer) {
    if (isAnimating) return;
    setState(() {
      isAnimating = true;
      selectedAnswers[currentSequence] = answer;

      final correctAnswer = findCorrectAnswer(sequences[currentSequence]);
      if (answer == correctAnswer) {
        handleCorrectAnswer();
      } else {
        handleIncorrectAnswer();
      }
    });
  }

  void handleCorrectAnswer() {
    streak++;
    const baseScore = 100;
    final streakBonus = streak * 20;
    final timeBonus = widget.gameController.timeRemaining * 2;
    final totalPoints = baseScore + streakBonus + timeBonus;

    _controller.forward().then((_) => _controller.reverse());
    widget.gameController
        .updateScore(widget.gameController.score + totalPoints);

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        isAnimating = false;
        if (currentSequence < sequences.length - 1) {
          currentSequence++;
          widget.gameController.nextLevel();
        } else {
          widget.gameController.completeGame();
        }
      });
    });
  }

  void handleIncorrectAnswer() {
    streak = 0;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        selectedAnswers[currentSequence] = null;
        isAnimating = false;
      });
    });
  }

  String findCorrectAnswer(List<dynamic> sequence) {
    final missingIndex = sequence.indexOf(null);
    // Look for patterns in the sequence

    // Try pattern by position (next element in sequence)
    if (missingIndex > 0) {
      return sequence[missingIndex - 1].toString();
    }

    // If that doesn't work, return the first non-null element as fallback
    for (var item in sequence) {
      if (item != null) return item.toString();
    }

    return "□"; // Default fallback
  }

  List<String> generateOptions() {
    final sequence = sequences[currentSequence];
    final correctAnswer = findCorrectAnswer(sequence);
    final options = <String>{correctAnswer};

    final symbols = ['□', '△', '○', '◇', '☆', '⬡', '⬢'];
    while (options.length < 4) {
      options.add(symbols[Random().nextInt(symbols.length)]);
    }

    return options.toList()..shuffle();
  }

  void _useHint() {
    if (hintsRemaining <= 0) return;

    setState(() {
      hintsRemaining--;
      showHint = true;
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          showHint = false;
        });
      }
    });
  }

  void _rotateSymbols() {
    setState(() {
      rotationAngle = (rotationAngle + 90) % 360;
    });
  }

  void _showTutorialDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'How to Play Symbol Sequence',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Find the missing symbol in each sequence',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 8),
            Text(
              '2. Look for patterns in the symbols',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 8),
            Text(
              '3. Select the correct symbol to complete the pattern',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 8),
            Text(
              '4. Use hints when you get stuck',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 8),
            Text(
              '5. You can rotate symbols if needed',
              style: GoogleFonts.poppins(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                showTutorial = false;
              });
            },
            child: Text(
              'Got it!',
              style: GoogleFonts.poppins(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameContainer(
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const Spacer(),
            _buildSequence(),
            if (showHint) _buildHint(),
            const SizedBox(height: 32),
            _buildOptions(),
            const Spacer(),
            _buildProgress(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildScoreCard(),
              const SizedBox(width: 12),
              _buildTimeDisplay(),
            ],
          ),
          const SizedBox(height: 12),
          _buildControlButtons(),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _rotateSymbols,
          icon: const Icon(Icons.rotate_right),
          tooltip: 'Rotate symbols',
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: hintsRemaining > 0 ? _useHint : null,
          icon: Icon(
            hintsRemaining > 0 ? Icons.lightbulb : Icons.lightbulb_outline,
            color: hintsRemaining > 0 ? AppTheme.accentColor : Colors.grey,
          ),
          tooltip: 'Use hint ($hintsRemaining remaining)',
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.accentColor.withOpacity(0.1),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: () => _showTutorialDialog(),
          icon: const Icon(Icons.help_outline),
          tooltip: 'How to play',
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.secondaryColor.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCard() {
    return AnimatedBuilder(
      animation: widget.gameController,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.star, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                widget.gameController.score.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeDisplay() {
    return AnimatedBuilder(
      animation: widget.gameController,
      builder: (context, _) {
        final minutes = (widget.gameController.timeRemaining ~/ 60)
            .toString()
            .padLeft(2, '0');
        final seconds = (widget.gameController.timeRemaining % 60)
            .toString()
            .padLeft(2, '0');

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  fontSize: 16,
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

  Widget _buildSequence() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Complete the sequence',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: sequences[currentSequence].map((symbol) {
              final isSelected =
                  symbol == null && selectedAnswers[currentSequence] != null;
              final isCorrect = isSelected &&
                  selectedAnswers[currentSequence] ==
                      findCorrectAnswer(sequences[currentSequence]);

              return Container(
                width: 60,
                height: 60,
                child: Transform.rotate(
                  angle: rotationAngle * pi / 180,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isCorrect
                              ? Colors.green.withOpacity(0.3)
                              : Colors.red.withOpacity(0.3))
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? (isCorrect ? Colors.green : Colors.red)
                            : Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        symbol?.toString() ??
                            (isSelected
                                ? selectedAnswers[currentSequence]!
                                : '?'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ).animate().scale(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHint() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hints[currentSequence],
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    if (isAnimating) return const SizedBox.shrink();

    return Column(
      children: [
        Text(
          'Select the missing symbol',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: generateOptions().map((option) {
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => checkAnswer(option),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.8),
                        AppTheme.primaryColor.withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: rotationAngle * pi / 180,
                      child: Text(
                        option,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ).animate().scale(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${currentSequence + 1}/${sequences.length}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (currentSequence + 1) / sequences.length,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.primaryColor,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

// Add these utility classes at the end of the file
class ParticleSystem extends StatelessWidget {
  final bool isPlaying;
  final Color color;

  const ParticleSystem({
    super.key,
    required this.isPlaying,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (!isPlaying) return const SizedBox.shrink();

    return IgnorePointer(
      child: Stack(
        children: List.generate(
          20,
          (index) => Particle(
            color: color,
            index: index,
          ),
        ),
      ),
    );
  }
}

class Particle extends StatelessWidget {
  final Color color;
  final int index;

  const Particle({
    super.key,
    required this.color,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final random = Random();
    final size = 8.0 + random.nextDouble() * 4.0;
    final angle = random.nextDouble() * 2 * pi;
    final distance = 50.0 + random.nextDouble() * 100.0;
    final dx = cos(angle) * distance;
    final dy = sin(angle) * distance;

    return Positioned(
      left: MediaQuery.of(context).size.width / 2,
      top: MediaQuery.of(context).size.height / 2,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      )
          .animate(
            onPlay: (controller) => controller.repeat(),
          )
          .move(
            duration: Duration(milliseconds: 500 + random.nextInt(500)),
            begin: const Offset(0, 0),
            end: Offset(dx, dy),
          )
          .fade(
            duration: const Duration(milliseconds: 500),
            end: 0,
          ),
    );
  }
}

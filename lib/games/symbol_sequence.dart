import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../components/game_container.dart';
import 'game_controller.dart';

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
  int score = 0;
  int streak = 0;
  bool showHint = false;
  bool isAnimating = false;
  double rotationAngle = 0.0;

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
    score += baseScore + streakBonus;

    _controller.forward().then((_) => _controller.reverse());
    widget.gameController.updateScore(score);

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        isAnimating = false;
        if (currentSequence < sequences.length - 1) {
          currentSequence++;
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
    return sequence[(missingIndex - 1 + sequence.length) % sequence.length];
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
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    score.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.rotate_right, color: Colors.white),
                onPressed: () => setState(() => rotationAngle += 90),
              ),
              IconButton(
                icon: Icon(
                  showHint ? Icons.lightbulb : Icons.lightbulb_outline,
                  color: showHint ? Colors.amber : Colors.white,
                ),
                onPressed: () => setState(() => showHint = !showHint),
              ),
            ],
          ),
        ],
      ),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: sequences[currentSequence].map((symbol) {
          final isSelected =
              symbol == null && selectedAnswers[currentSequence] != null;
          final isCorrect = isSelected &&
              selectedAnswers[currentSequence] ==
                  findCorrectAnswer(sequences[currentSequence]);

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
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
                        (isSelected ? selectedAnswers[currentSequence]! : '?'),
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

    return Wrap(
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
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
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
                Colors.purple.shade400,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

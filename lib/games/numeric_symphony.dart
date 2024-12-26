import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../theme/app_theme.dart';
import 'game_controller.dart';

class NumericSymphonyGame extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final GameController gameController;

  const NumericSymphonyGame({
    super.key,
    required this.gameData,
    required this.gameController,
  });

  @override
  State<NumericSymphonyGame> createState() => _NumericSymphonyGameState();
}

class _NumericSymphonyGameState extends State<NumericSymphonyGame> {
  late List<List<dynamic>> sequences;
  late List<String> hints;
  late List<int> selectedAnswers;
  late List<bool> sequenceCompleted;
  int currentSequence = 0;
  int score = 0;
  int streak = 0;
  int attempts = 0;
  bool showHint = false;
  bool isAnimating = false;

  @override
  void initState() {
    super.initState();
    sequences = List<List<dynamic>>.from(widget.gameData['sequences']);
    hints = List<String>.from(widget.gameData['hints']);
    selectedAnswers = List.filled(sequences.length, -1);
    sequenceCompleted = List.filled(sequences.length, false);
  }

  void checkAnswer(int answer) {
    if (isAnimating) return;

    setState(() {
      attempts++;
      selectedAnswers[currentSequence] = answer;
      isAnimating = true;

      final correctAnswer = calculateCorrectAnswer(sequences[currentSequence]);
      if (answer == correctAnswer) {
        handleCorrectAnswer();
      } else {
        handleIncorrectAnswer();
      }
    });
  }

  void handleCorrectAnswer() {
    sequenceCompleted[currentSequence] = true;
    streak++;

    // Calculate score bonus based on streak and attempts
    const baseScore = 100;
    final streakBonus = streak * 20;
    final attemptsDeduction = (attempts - 1) * 10;
    final sequenceScore =
        math.max(0, baseScore + streakBonus - attemptsDeduction);

    score += sequenceScore;
    widget.gameController.updateScore(score);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        isAnimating = false;
        attempts = 0;
        if (currentSequence < sequences.length - 1) {
          currentSequence++;
        } else {
          widget.gameController.nextLevel();
        }
      });
    });
  }

  void handleIncorrectAnswer() {
    streak = 0;
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        selectedAnswers[currentSequence] = -1;
        isAnimating = false;
      });
    });
  }

  int calculateCorrectAnswer(List<dynamic> sequence) {
    final numbers = sequence.whereType<int>().toList();
    final missingIndex = sequence.indexOf(null);

    // Check for common patterns
    if (isArithmetic(numbers)) {
      final difference = numbers[1] - numbers[0];
      return numbers[0] + difference * missingIndex;
    } else if (isGeometric(numbers)) {
      final ratio = numbers[1] / numbers[0];
      return (numbers[0] * math.pow(ratio, missingIndex)).round();
    } else if (isSquareSequence(numbers)) {
      return (missingIndex + 1) * (missingIndex + 1);
    }

    // Default to arithmetic if no pattern is found
    final difference = numbers[1] - numbers[0];
    return numbers[0] + difference * missingIndex;
  }

  bool isArithmetic(List<int> numbers) {
    if (numbers.length < 3) return false;
    final difference = numbers[1] - numbers[0];
    for (int i = 2; i < numbers.length; i++) {
      if (numbers[i] - numbers[i - 1] != difference) return false;
    }
    return true;
  }

  bool isGeometric(List<int> numbers) {
    if (numbers.length < 3) return false;
    final ratio = numbers[1] / numbers[0];
    for (int i = 2; i < numbers.length; i++) {
      if ((numbers[i] / numbers[i - 1] - ratio).abs() > 0.0001) return false;
    }
    return true;
  }

  bool isSquareSequence(List<int> numbers) {
    if (numbers.length < 3) return false;
    for (int i = 0; i < numbers.length; i++) {
      if (numbers[i] != (i + 1) * (i + 1)) return false;
    }
    return true;
  }

  List<int> generateOptions() {
    final sequence = sequences[currentSequence];
    final correctAnswer = calculateCorrectAnswer(sequence);
    final options = <int>{correctAnswer};

    // Generate plausible wrong answers
    while (options.length < 4) {
      final variation = math.Random().nextInt(5) + 1;
      final sign = math.Random().nextBool() ? 1 : -1;
      options.add(correctAnswer + (variation * sign));
    }

    return options.toList()..shuffle();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        const Spacer(),
        _buildSequenceDisplay(),
        const SizedBox(height: 32),
        _buildOptions(),
        const Spacer(),
        _buildProgress(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.stars_rounded,
                color: AppTheme.accentColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Score: $score',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: AppTheme.accentColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Streak: $streak',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              showHint ? Icons.lightbulb : Icons.lightbulb_outline,
              color: AppTheme.accentColor,
            ),
            onPressed: () => setState(() => showHint = !showHint),
          ),
        ],
      ),
    );
  }

  Widget _buildSequenceDisplay() {
    final sequence = sequences[currentSequence];

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(sequence.length, (index) {
                return _buildNumberBox(sequence[index], index);
              }),
            ),
          ),
        ),
        if (showHint) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.accentColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb,
                  color: AppTheme.accentColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hints[currentSequence],
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNumberBox(dynamic value, int index) {
    final isSelected = value == null && selectedAnswers[currentSequence] != -1;
    final selectedValue = selectedAnswers[currentSequence];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            if (value == null)
              if (isSelected)
                selectedValue ==
                        calculateCorrectAnswer(sequences[currentSequence])
                    ? AppTheme.correctAnswerColor
                    : AppTheme.wrongAnswerColor
              else
                AppTheme.primaryColor
            else
              AppTheme.primaryColor.withOpacity(0.8),
            if (value == null)
              if (isSelected)
                selectedValue ==
                        calculateCorrectAnswer(sequences[currentSequence])
                    ? AppTheme.correctAnswerColor.withOpacity(0.8)
                    : AppTheme.wrongAnswerColor.withOpacity(0.8)
              else
                AppTheme.primaryColor.withOpacity(0.6)
            else
              AppTheme.primaryColor.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (value == null ? AppTheme.primaryColor : Colors.black)
                .withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          value?.toString() ?? (isSelected ? selectedValue.toString() : '?'),
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    ).animate(
      effects: [
        if (value == null && isSelected)
          const ShakeEffect(
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          ),
      ],
    );
  }

  Widget _buildOptions() {
    if (isAnimating) return const SizedBox.shrink();

    final options = generateOptions();

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: options.map((option) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => checkAnswer(option),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 100,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.8),
                    AppTheme.primaryColor.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                option.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
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
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${sequenceCompleted.where((e) => e).length}/${sequences.length}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value:
                  sequenceCompleted.where((e) => e).length / sequences.length,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(
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

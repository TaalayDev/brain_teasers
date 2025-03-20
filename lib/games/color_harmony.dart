import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../ui/components/game_container.dart';
import '../ui/components/color_wheel.dart';
import '../ui/theme/app_theme.dart';
import 'controller/game_controller.dart';

enum ColorRule {
  complementary,
  triadic,
  monochromatic,
}

class ColorPattern {
  final List<Color> colors;
  final ColorRule rule;
  final int missingIndex;

  ColorPattern({
    required this.colors,
    required this.rule,
    required this.missingIndex,
  });
}

class ColorHarmonyGame extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final GameController gameController;

  const ColorHarmonyGame({
    super.key,
    required this.gameData,
    required this.gameController,
  });

  @override
  State<ColorHarmonyGame> createState() => _ColorHarmonyGameState();
}

class _ColorHarmonyGameState extends State<ColorHarmonyGame> {
  late List<ColorPattern> patterns;
  late List<String> hints;
  late int timeLimit;
  int currentPattern = 0;
  int streak = 0;
  int attempts = 0;
  bool showHint = false;
  bool isAnimating = false;
  Color? selectedColor;
  late List<bool> patternCompleted;
  late ColorWheel colorWheel;
  int hintsRemaining = 3;
  bool showTutorial = true;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    colorWheel = const ColorWheel();

    // Start game with controller
    widget.gameController.startGame(
      timeLimit: timeLimit,
      maxLevels: patterns.length,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorialDialog();
    });
  }

  void _initializeGame() {
    patterns = _parsePatterns(widget.gameData['patterns']);
    hints = List<String>.from(widget.gameData['hints']);
    timeLimit = widget.gameData['timeLimit'] ?? 120;
    patternCompleted = List.filled(patterns.length, false);
  }

  List<ColorPattern> _parsePatterns(List<dynamic> patternsData) {
    return patternsData.map((pattern) {
      final colors = (pattern['colors'] as List).map((color) {
        if (color == null) return null;
        return Color(int.parse(color.substring(1), radix: 16) + 0xFF000000);
      }).toList();

      return ColorPattern(
        colors: colors.where((c) => c != null).cast<Color>().toList(),
        rule: ColorRule.values.firstWhere(
          (r) => r.toString().split('.').last == pattern['rule'],
        ),
        missingIndex: colors.indexOf(null),
      );
    }).toList();
  }

  void checkAnswer(Color color) {
    if (isAnimating) return;

    setState(() {
      attempts++;
      selectedColor = color;
      isAnimating = true;

      final isCorrect = _isCorrectColor(color);
      if (isCorrect) {
        handleCorrectAnswer();
      } else {
        handleIncorrectAnswer();
      }
    });
  }

  bool _isCorrectColor(Color color) {
    final pattern = patterns[currentPattern];
    switch (pattern.rule) {
      case ColorRule.complementary:
        return _isComplementary(pattern.colors[0], color);
      case ColorRule.triadic:
        return _isTriadic(pattern.colors[0], pattern.colors[1], color);
      case ColorRule.monochromatic:
        return _isMonochromatic(pattern.colors[0], color);
    }
  }

  bool _isComplementary(Color base, Color test) {
    final HSVColor baseHsv = HSVColor.fromColor(base);
    final HSVColor testHsv = HSVColor.fromColor(test);

    // Complementary colors are approximately 180 degrees apart on the color wheel
    final hueDifference = (baseHsv.hue - testHsv.hue).abs();
    return (hueDifference - 180).abs() < 15; // Allow some tolerance
  }

  bool _isTriadic(Color first, Color second, Color test) {
    final HSVColor firstHsv = HSVColor.fromColor(first);
    final HSVColor secondHsv = HSVColor.fromColor(second);
    final HSVColor testHsv = HSVColor.fromColor(test);

    // Triadic colors are approximately 120 degrees apart
    final hue1Diff = (firstHsv.hue - testHsv.hue).abs();
    final hue2Diff = (secondHsv.hue - testHsv.hue).abs();
    return (hue1Diff - 120).abs() < 15 || (hue2Diff - 120).abs() < 15;
  }

  bool _isMonochromatic(Color base, Color test) {
    final HSVColor baseHsv = HSVColor.fromColor(base);
    final HSVColor testHsv = HSVColor.fromColor(test);

    // Same hue, different saturation or value
    return (baseHsv.hue - testHsv.hue).abs() < 15 &&
        baseHsv.saturation != testHsv.saturation;
  }

  void handleCorrectAnswer() {
    patternCompleted[currentPattern] = true;
    streak++;

    final baseScore = 100;
    final streakBonus = streak * 20;
    final attemptsDeduction = (attempts - 1) * 10;
    final timeBonus = (widget.gameController.timeRemaining / 2).round();

    final patternScore =
        math.max(0, baseScore + streakBonus + timeBonus - attemptsDeduction);
    widget.gameController
        .updateScore(widget.gameController.score + patternScore);

    _showFeedback(true, patternScore);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        isAnimating = false;
        attempts = 0;
        selectedColor = null;
        if (currentPattern < patterns.length - 1) {
          currentPattern++;
          widget.gameController.nextLevel();
        } else {
          widget.gameController.completeGame();
        }
      });
    });
  }

  void handleIncorrectAnswer() {
    streak = 0;
    _showFeedback(false, 0);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        isAnimating = false;
        selectedColor = null;
      });
    });
  }

  void _showTutorialDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'How to Play Color Harmony',
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
              '1. Identify the color harmony pattern shown (complementary, triadic, or monochromatic)',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 8),
            Text(
              '2. Select a color from the color wheel that would complete the pattern',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 8),
            Text(
              '3. Use hints if you get stuck',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 8),
            Text(
              '4. The more patterns you complete correctly, the higher your score!',
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

  void _showFeedback(bool isCorrect, int points) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              isCorrect ? 'Correct! +$points points' : 'Try again!',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor:
            isCorrect ? AppTheme.correctAnswerColor : AppTheme.wrongAnswerColor,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return GameContainer(
      child: Column(
        children: [
          _buildHeader(),
          const Spacer(),
          _buildPatternDisplay(),
          const SizedBox(height: 32),
          _buildColorWheel(),
          const Spacer(),
          _buildProgress(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildScoreDisplay(),
              _buildTimeDisplay(),
            ],
          ),
          _buildControlButtons(),
        ],
      ),
    );
  }

  Widget _buildScoreDisplay() {
    return AnimatedBuilder(
      animation: widget.gameController,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.stars_rounded,
                color: AppTheme.accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Score: ${widget.gameController.score}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentColor,
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

  Widget _buildControlButtons() {
    return Row(
      children: [
        TextButton.icon(
          onPressed: hintsRemaining > 0 ? _useHint : null,
          label: Text('Hint ($hintsRemaining)'),
          icon: const Icon(Icons.lightbulb),
        )
      ],
    );
  }

  Widget _buildPatternDisplay() {
    final pattern = patterns[currentPattern];

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
            child: Column(
              children: [
                Text(
                  _getRuleDescription(pattern.rule),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...pattern.colors.map((color) => _buildColorBox(color)),
                    _buildColorBox(selectedColor),
                  ],
                ),
              ],
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
                    hints[currentPattern],
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

  Widget _buildColorBox(Color? color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: color ?? Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (color ?? Colors.grey[300]!).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    ).animate(
      effects: [
        if (color != null && color == selectedColor)
          const ShakeEffect(
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          ),
      ],
    );
  }

  Widget _buildColorWheel() {
    return Column(
      children: [
        Text(
          'Select a color to complete the pattern',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ColorWheel(
            onColorSelected: (color) => checkAnswer(color),
          ),
        ),
      ],
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
                  color: Colors.white,
                ),
              ),
              Text(
                '${patternCompleted.where((e) => e).length}/${patterns.length}',
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
              value: patternCompleted.where((e) => e).length / patterns.length,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.4),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  String _getRuleDescription(ColorRule rule) {
    switch (rule) {
      case ColorRule.complementary:
        return 'Find the Complementary Color';
      case ColorRule.triadic:
        return 'Complete the Triadic Harmony';
      case ColorRule.monochromatic:
        return 'Match the Monochromatic Shade';
    }
  }
}

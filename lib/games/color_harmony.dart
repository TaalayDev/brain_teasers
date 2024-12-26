import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../components/game_container.dart';
import '../components/color_wheel.dart';
import '../theme/app_theme.dart';
import 'game_controller.dart';

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
  int score = 0;
  int streak = 0;
  int attempts = 0;
  bool showHint = false;
  bool isAnimating = false;
  Color? selectedColor;
  late List<bool> patternCompleted;
  late ColorWheel colorWheel;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    colorWheel = const ColorWheel();
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
    final timeBonus = (timeLimit / 2).round();

    final patternScore =
        math.max(0, baseScore + streakBonus + timeBonus - attemptsDeduction);
    score += patternScore;
    widget.gameController.updateScore(score);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        isAnimating = false;
        attempts = 0;
        selectedColor = null;
        if (currentPattern < patterns.length - 1) {
          currentPattern++;
        } else {
          widget.gameController.completeGame();
        }
      });
    });
  }

  void handleIncorrectAnswer() {
    streak = 0;
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        isAnimating = false;
        selectedColor = null;
      });
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
                  color: Theme.of(context).colorScheme.onPrimary,
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
        if (color != null)
          const ShakeEffect(
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          ),
      ],
    );
  }

  Widget _buildColorWheel() {
    return SizedBox(
      height: 200,
      child: ColorWheel(
        onColorSelected: (color) => checkAnswer(color),
      ),
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
                  color: Theme.of(context).colorScheme.onPrimary,
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

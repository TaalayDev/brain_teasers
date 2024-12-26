import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../utils/pattern_generator.dart';
import '../components/game_container.dart';
import '../theme/app_theme.dart';
import 'game_controller.dart';

class PatternSequenceGame extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final GameController gameController;

  const PatternSequenceGame({
    super.key,
    required this.gameData,
    required this.gameController,
  });

  @override
  State<PatternSequenceGame> createState() => _PatternSequenceGameState();
}

class _PatternSequenceGameState extends State<PatternSequenceGame> {
  late List<List<dynamic>> _sequences;
  late List<int> _selectedAnswers;
  late List<bool> _sequenceCompleted;
  bool _showFeedback = false;
  bool _isCorrect = false;
  int _currentScore = 0;
  int _currentSequence = 0;
  int _streak = 0;
  bool _isAnimating = false;
  int _currentLevel = 0;
  List<LevelData> levels = [];
  LevelData get currentLevel => levels[_currentLevel];

  final List<Color> _backgroundGradients = [
    const Color(0xFF6448FE),
    const Color(0xFF5FC3E4),
    const Color(0xFFE55D87),
    const Color(0xFF5FC3E4),
  ];

  @override
  void initState() {
    super.initState();
    _currentLevel = widget.gameData['level'] ?? 0;
    levels = PatternGenerator.generateLevels(
      startLevel: _currentLevel + 1,
    );
    _initializeGame();
  }

  void _initializeGame() {
    _sequences = currentLevel.sequences;
    _selectedAnswers = List.filled(_sequences.length, -1);
    _sequenceCompleted = List.filled(_sequences.length, false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.gameController.startGame(
        timeLimit: currentLevel.timeLimit,
        maxLevels: levels.length,
        level: _currentLevel,
      );
    });
  }

  // Game logic methods remain the same...
  void _checkAnswer(int selectedValue) {
    if (_isAnimating) return;

    final currentSequence = _sequences[_currentSequence];
    final missingIndex = currentSequence.indexOf(null);
    final correctAnswer = _calculateCorrectAnswer(currentSequence);

    setState(() {
      _selectedAnswers[_currentSequence] = selectedValue;
      _showFeedback = true;
      _isCorrect = selectedValue == correctAnswer;
      _isAnimating = true;

      if (_isCorrect) {
        _sequenceCompleted[_currentSequence] = true;
        _streak++;
        _currentScore += (100 * math.pow(1.1, _streak)).round();
        widget.gameController.updateScore(_currentScore);

        final newSequence = List.from(currentSequence);
        newSequence[missingIndex] = correctAnswer;
        _sequences[_currentSequence] = newSequence;
      } else {
        _streak = 0;
      }
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showFeedback = false;
          _isAnimating = false;
          if (_isCorrect) {
            if (_currentSequence < _sequences.length - 1) {
              _currentSequence++;
            } else if (_currentLevel < levels.length - 1) {
              _currentLevel++;
              _initializeGame();
              widget.gameController.nextLevel();
            } else {
              widget.gameController.completeGame();
            }
          }
        });
      }
    });
  }

  bool _isLevelComplete() {
    return _currentSequence >= _sequences.length - 1;
  }

  int _calculateCorrectAnswer(List<dynamic> sequence) {
    final numbers = sequence.whereType<int>().toList();
    if (numbers.length < 2) return 0;

    // Find the pattern type
    bool isArithmetic = true;
    bool isGeometric = true;
    final firstDiff = numbers[1] - numbers[0];
    final firstRatio = numbers[1] / numbers[0];

    for (int i = 1; i < numbers.length - 1; i++) {
      if (numbers[i + 1] - numbers[i] != firstDiff) {
        isArithmetic = false;
      }
      if (numbers[i + 1] / numbers[i] != firstRatio) {
        isGeometric = false;
      }
    }

    final missingIndex = sequence.indexOf(null);
    if (isArithmetic) {
      return numbers[0] + firstDiff * missingIndex;
    } else if (isGeometric) {
      return (numbers[0] * math.pow(firstRatio, missingIndex)).round();
    }

    // Fallback to linear progression
    return numbers[0] + firstDiff * missingIndex;
  }

  List<int> _generateOptions(List<dynamic> sequence) {
    final correctAnswer = _calculateCorrectAnswer(sequence);
    final options = <int>{correctAnswer};

    // Generate wrong options that look plausible
    while (options.length < 4) {
      final variation = math.Random().nextInt(5) + 1;
      final isAdd = math.Random().nextBool();
      final wrongOption =
          isAdd ? correctAnswer + variation : correctAnswer - variation;
      if (wrongOption > 0) {
        options.add(wrongOption);
      }
    }

    return options.toList()..shuffle();
  }

  @override
  Widget build(BuildContext context) {
    return GameContainer(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPatternGrid(),
                    const SizedBox(height: 32),
                    _buildOptions(),
                  ],
                ),
              ),
            ),
          ),
          _buildProgress(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildStatCard(
                icon: Feather.award,
                label: 'Score',
                value: _currentScore.toString(),
                color: AppTheme.accentColor,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                icon: Feather.bar_chart_2,
                label: 'Level',
                value: (_currentLevel + 1).toString(),
                color: AppTheme.accentColor,
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.rotate_right, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.white,
                ),
                onPressed: () {},
              ),
            ],
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
    )
        .animate(
          onPlay: (controller) => controller.repeat(),
        )
        .shimmer(
          duration: const Duration(seconds: 2),
          color: Colors.white24,
        );
  }

  Widget _buildPatternGrid() {
    final currentSequence = _sequences[_currentSequence];

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).cardColor,
              Theme.of(context).cardColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                currentSequence.length,
                (index) => _buildEnhancedNumberBox(
                  currentSequence[index],
                  index,
                ),
              ),
            ),
            if (_showFeedback) ...[
              const SizedBox(height: 24),
              _buildFeedbackMessage(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedNumberBox(dynamic value, int index) {
    final isSelected =
        value == null && _selectedAnswers[_currentSequence] != -1;
    final selectedValue = _selectedAnswers[_currentSequence];
    final isTarget = value == null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  if (isTarget)
                    if (_showFeedback)
                      _isCorrect
                          ? AppTheme.correctAnswerColor.withOpacity(0.8)
                          : AppTheme.wrongAnswerColor.withOpacity(0.8)
                    else
                      AppTheme.primaryColor.withOpacity(0.8)
                  else
                    AppTheme.primaryColor.withOpacity(0.2),
                  if (isTarget)
                    if (_showFeedback)
                      _isCorrect
                          ? AppTheme.correctAnswerColor.withOpacity(0.6)
                          : AppTheme.wrongAnswerColor.withOpacity(0.6)
                    else
                      AppTheme.primaryColor.withOpacity(0.6)
                  else
                    AppTheme.primaryColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isTarget ? AppTheme.primaryColor : Colors.black)
                      .withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                value?.toString() ??
                    (isSelected ? selectedValue.toString() : '?'),
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isTarget ? Colors.white : AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          // if (!isTarget) ...[
          //   const SizedBox(height: 8),
          //   Container(
          //     width: 4,
          //     height: 4,
          //     decoration: BoxDecoration(
          //       color: AppTheme.primaryColor.withOpacity(0.3),
          //       shape: BoxShape.circle,
          //     ),
          //   ),
          // ],
        ],
      ),
    ).animate(
      effects: [
        if (isTarget && _showFeedback)
          const ShakeEffect(
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          ),
        if (!isTarget)
          ScaleEffect(
            duration: const Duration(milliseconds: 400),
            delay: Duration(milliseconds: index * 100),
            curve: Curves.easeOut,
          ),
      ],
    );
  }

  Widget _buildFeedbackMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: _isCorrect
            ? AppTheme.correctAnswerColor.withOpacity(0.1)
            : AppTheme.wrongAnswerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isCorrect
              ? AppTheme.correctAnswerColor.withOpacity(0.3)
              : AppTheme.wrongAnswerColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isCorrect ? Icons.check_circle : Icons.error,
            color: _isCorrect
                ? AppTheme.correctAnswerColor
                : AppTheme.wrongAnswerColor,
          ),
          const SizedBox(width: 8),
          Text(
            _isCorrect
                ? 'Correct! +${_currentScore - (_currentScore ~/ 1.1)}'
                : 'Try Again!',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _isCorrect
                  ? AppTheme.correctAnswerColor
                  : AppTheme.wrongAnswerColor,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildOptions() {
    if (_showFeedback) return const SizedBox.shrink();

    final options = _generateOptions(_sequences[_currentSequence]);

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: options.map((option) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _checkAnswer(option),
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
                child: Text(
                  option.toString(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
                'Level',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_currentLevel + 1} / ${levels.length}',
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
              value: _currentSequence / _sequences.length,
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
    final random = math.Random();
    final size = 8.0 + random.nextDouble() * 4.0;
    final angle = random.nextDouble() * 2 * math.pi;
    final distance = 50.0 + random.nextDouble() * 100.0;
    final dx = math.cos(angle) * distance;
    final dy = math.sin(angle) * distance;

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

class Levels {
  static const List<LevelData> list = [
    LevelData(
      sequences: [
        [1, 3, 5, 7, 9, null],
        [2, 4, 8, 16, 32, null],
        [3, 6, 12, 24, 48, null],
        [5, 10, 20, 40, 80, null],
        [1, 4, 9, 16, 25, null],
      ],
      hints: [
        'Add 2 to the previous number',
        'Double the previous number',
        'Multiply the previous number by 2',
        'Double the previous number',
        'Square the previous number',
      ],
      timeLimit: 60,
    ),
    LevelData(
      sequences: [
        [1, 1, 2, 3, 5, 8, null],
        [1, 2, 3, 5, 8, 13, null],
        [2, 4, 8, 16, 32, 64, null],
        [1, 3, 6, 10, 15, 21, null],
        [1, 2, 4, 8, 16, 32, null],
      ],
      hints: [
        'Add the previous two numbers',
        'Add the previous two numbers',
        'Double the previous number',
        'Add the previous number',
        'Double the previous number',
      ],
      timeLimit: 60,
    ),
    LevelData(
      sequences: [
        [1, 2, 4, 8, 16, 32, null],
        [1, 3, 9, 27, 81, 243, null],
        [2, 4, 8, 16, 32, 64, null],
        [1, 4, 16, 64, 256, 1024, null],
        [1, 5, 25, 125, 625, 3125, null],
      ],
      hints: [
        'Double the previous number',
        'Triple the previous number',
        'Double the previous number',
        'Square the previous number',
        'Multiply the previous number by 5',
      ],
      timeLimit: 60,
    ),
  ];
}

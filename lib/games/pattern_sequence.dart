import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../components/game_container.dart';
import '../theme/app_theme.dart';

class PatternSequenceGame extends StatefulWidget {
  final List<List<dynamic>> sequences;
  final Function(int score) onScoreUpdate;
  final VoidCallback onComplete;

  const PatternSequenceGame({
    super.key,
    required this.sequences,
    required this.onScoreUpdate,
    required this.onComplete,
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

  final List<Color> _backgroundGradients = [
    const Color(0xFF6448FE),
    const Color(0xFF5FC3E4),
    const Color(0xFFE55D87),
    const Color(0xFF5FC3E4),
  ];

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    _sequences = List.from(widget.sequences);
    _selectedAnswers = List.filled(_sequences.length, -1);
    _sequenceCompleted = List.filled(_sequences.length, false);
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
        widget.onScoreUpdate(_currentScore);

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
            } else {
              widget.onComplete();
            }
          }
        });
      }
    });
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
          Divider(height: 0, color: Colors.grey.withOpacity(0.3)),
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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 10),
            spreadRadius: -10,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pattern ${_currentSequence + 1}/${_sequences.length}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Find the missing number',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.7),
                ),
              ),
            ],
          ),
          _buildScoreDisplay(),
        ],
      ),
    );
  }

  Widget _buildScoreDisplay() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.stars_rounded,
            color: AppTheme.accentColor,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            _currentScore.toString(),
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
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
                borderRadius: BorderRadius.circular(16),
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
                  fontSize: 24,
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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: AppTheme.accentColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Streak: $_streak',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_sequenceCompleted.where((e) => e).length}/${_sequences.length} Completed',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Stack(
              children: [
                // Background track
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                // Progress indicator
                AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 300),
                  alignment: Alignment.centerLeft,
                  widthFactor: _sequenceCompleted.where((e) => e).length /
                      _sequences.length,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.accentColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                // Progress markers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    _sequences.length,
                    (index) => Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _sequenceCompleted[index]
                            ? AppTheme.accentColor
                            : Colors.transparent,
                        border: Border.all(
                          color: _sequenceCompleted[index]
                              ? AppTheme.accentColor
                              : AppTheme.primaryColor.withOpacity(0.3),
                          width: 2,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ).animate(
                      effects: [
                        if (_sequenceCompleted[index])
                          const ScaleEffect(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.elasticOut,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_streak > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_streak}x',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Combo!',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.7),
                    ),
                  ),
                ],
              ).animate().fadeIn().slideY(
                    begin: 0.5,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  ),
            ],
          ],
        ),
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

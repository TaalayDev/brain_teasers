import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../ui/components/game_container.dart';
import '../ui/theme/app_theme.dart';
import 'controller/game_controller.dart';

class EquationBuilderGame extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final GameController gameController;

  const EquationBuilderGame({
    super.key,
    required this.gameData,
    required this.gameController,
  });

  @override
  State<EquationBuilderGame> createState() => _EquationBuilderGameState();
}

class _EquationBuilderGameState extends State<EquationBuilderGame> {
  late List<int> availableNumbers;
  late int targetNumber;
  late List<EquationElement> equation;
  late List<int> unusedNumbers;
  bool isComplete = false;
  int moves = 0;
  String? errorMessage;
  int hintsRemaining = 3;
  bool isShowingHint = false;

  final operators = ['+', '-', '*', '/'];

  @override
  void initState() {
    super.initState();
    availableNumbers = List<int>.from(widget.gameData['numbers']);
    targetNumber = widget.gameData['target'];
    equation = [];
    unusedNumbers = List<int>.from(availableNumbers);

    // Start the game with the controller
    widget.gameController.startGame(
      timeLimit: 180, // 3 minutes
      maxLevels: 1,
    );
  }

  void _addNumber(int number) {
    if (!unusedNumbers.contains(number)) return;

    setState(() {
      equation.add(EquationElement(
        type: ElementType.number,
        value: number.toString(),
      ));
      unusedNumbers.remove(number);
      _validateEquation();
      moves++;
      widget.gameController.incrementMoves();
    });
  }

  void _addOperator(String operator) {
    if (equation.isEmpty) return;
    if (equation.last.type == ElementType.operator) return;

    setState(() {
      equation.add(EquationElement(
        type: ElementType.operator,
        value: operator,
      ));
      _validateEquation();
      moves++;
      widget.gameController.incrementMoves();
    });
  }

  void _removeLastElement() {
    if (equation.isEmpty) return;

    setState(() {
      final lastElement = equation.removeLast();
      if (lastElement.type == ElementType.number) {
        unusedNumbers.add(int.parse(lastElement.value));
      }
      errorMessage = null;
      _validateEquation();
    });
  }

  void _useHint() {
    if (hintsRemaining <= 0) return;

    setState(() {
      hintsRemaining--;
      isShowingHint = true;

      // Show a simple hint like what operator might work next
      if (equation.isEmpty) {
        errorMessage = "Hint: Start with a number";
      } else if (equation.last.type == ElementType.number) {
        errorMessage = "Hint: Try adding an operator next";
      } else {
        errorMessage = "Hint: Add a number after an operator";
      }
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          isShowingHint = false;
          errorMessage = null;
        });
      }
    });
  }

  void _validateEquation() {
    if (equation.isEmpty) return;

    // Check if equation ends with a number
    if (equation.last.type == ElementType.operator) {
      setState(() => errorMessage = 'Equation cannot end with an operator');
      return;
    }

    // Check for consecutive operators
    for (int i = 0; i < equation.length - 1; i++) {
      if (equation[i].type == ElementType.operator &&
          equation[i + 1].type == ElementType.operator) {
        setState(() => errorMessage = 'Cannot have consecutive operators');
        return;
      }
    }

    final result = _evaluateEquation();
    if (result != null) {
      setState(() {
        if (result == targetNumber) {
          isComplete = true;
          int score = _calculateScore();
          widget.gameController.updateScore(score);
          widget.gameController.completeGame();
          errorMessage = null;
        } else {
          errorMessage = 'Current result: $result (Target: $targetNumber)';
        }
      });
    }
  }

  double? _evaluateEquation() {
    if (equation.isEmpty) return null;

    try {
      // First handle multiplication and division
      List<EquationElement> tempEquation = List.from(equation);
      for (int i = 1; i < tempEquation.length - 1; i += 2) {
        if (tempEquation[i].value == '*' || tempEquation[i].value == '/') {
          final num1 = double.parse(tempEquation[i - 1].value);
          final num2 = double.parse(tempEquation[i + 1].value);
          double result;
          if (tempEquation[i].value == '*') {
            result = num1 * num2;
          } else {
            if (num2 == 0) throw Exception('Division by zero');
            result = num1 / num2;
          }
          tempEquation[i - 1] = EquationElement(
            type: ElementType.number,
            value: result.toString(),
          );
          tempEquation.removeAt(i);
          tempEquation.removeAt(i);
          i -= 2;
        }
      }

      // Then handle addition and subtraction
      double result = double.parse(tempEquation[0].value);
      for (int i = 1; i < tempEquation.length - 1; i += 2) {
        final num2 = double.parse(tempEquation[i + 1].value);
        if (tempEquation[i].value == '+') {
          result += num2;
        } else if (tempEquation[i].value == '-') {
          result -= num2;
        }
      }

      return result;
    } catch (e) {
      setState(() => errorMessage = 'Invalid equation');
      return null;
    }
  }

  int _calculateScore() {
    const baseScore = 1000;
    final movesPenalty = moves * 10;
    final timeBonus = widget.gameController.timeRemaining * 5;
    return math.max(0, baseScore - movesPenalty + timeBonus);
  }

  @override
  Widget build(BuildContext context) {
    return GameContainer(
      child: Column(
        children: [
          _buildHeader(),
          _buildEquationDisplay(),
          const Spacer(),
          _buildNumberPad(),
          _buildOperatorPad(),
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
            children: [
              _buildStatCard(
                icon: Icons.stars,
                label: 'Score',
                value: widget.gameController.score.toString(),
                color: AppTheme.accentColor,
              ),
              const SizedBox(width: 16),
              _buildTimeDisplay(),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Target: $targetNumber',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay() {
    return AnimatedBuilder(
      animation: widget.gameController,
      builder: (context, child) {
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

  Widget _buildProgressBar() {
    // Calculate how close the player is to completing the equation
    double progress = 0.0;
    if (equation.isNotEmpty) {
      final result = _evaluateEquation();
      if (result != null) {
        // Calculate relative progress toward target
        final difference = (targetNumber - result).abs();
        progress = math.max(0, 1 - (difference / targetNumber));
        // Cap at 0.9 unless exact match
        if (result != targetNumber && progress > 0.9) progress = 0.9;
        if (result == targetNumber) progress = 1.0;
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        valueColor: AlwaysStoppedAnimation<Color>(
          progress == 1.0 ? AppTheme.correctAnswerColor : AppTheme.primaryColor,
        ),
        minHeight: 6,
      ),
    );
  }

  Widget _buildEquationDisplay() {
    return Container(
      margin: const EdgeInsets.all(16),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 100),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              ...equation.map((element) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: element.type == ElementType.number
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : AppTheme.secondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      element.value,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: element.type == ElementType.number
                            ? AppTheme.primaryColor
                            : AppTheme.secondaryColor,
                      ),
                    ),
                  )),
              if (equation.isNotEmpty)
                IconButton(
                  onPressed: _removeLastElement,
                  icon: const Icon(Icons.backspace_outlined),
                  color: AppTheme.wrongAnswerColor,
                ),
            ],
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isShowingHint
                    ? AppTheme.accentColor
                    : AppTheme.wrongAnswerColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNumberPad() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: availableNumbers.map((number) {
          final isAvailable = unusedNumbers.contains(number);
          return InkWell(
            onTap: isAvailable ? () => _addNumber(number) : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isAvailable
                    ? AppTheme.primaryColor
                    : AppTheme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  if (isAvailable)
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Center(
                child: Text(
                  number.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isAvailable
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ).animate().scale(
                duration: const Duration(milliseconds: 200),
              );
        }).toList(),
      ),
    );
  }

  Widget _buildOperatorPad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ...operators.map((operator) {
            return InkWell(
              onTap: () => _addOperator(operator),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondaryColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    operator,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ).animate().scale(duration: 200.ms);
          }).toList(),
          InkWell(
            onTap: hintsRemaining > 0 ? _useHint : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: hintsRemaining > 0
                    ? AppTheme.accentColor.withOpacity(0.8)
                    : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  if (hintsRemaining > 0)
                    BoxShadow(
                      color: AppTheme.accentColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                  Text(
                    hintsRemaining.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().scale(duration: 200.ms),
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

enum ElementType { number, operator }

class EquationElement {
  final ElementType type;
  final String value;

  EquationElement({
    required this.type,
    required this.value,
  });
}

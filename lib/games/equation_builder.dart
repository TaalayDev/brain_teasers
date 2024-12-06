import 'package:brain_teasers/components/game_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import '../components/header_container.dart';
import '../theme/app_theme.dart';

class EquationBuilderGame extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final Function(int score) onScoreUpdate;
  final VoidCallback onComplete;

  const EquationBuilderGame({
    super.key,
    required this.gameData,
    required this.onScoreUpdate,
    required this.onComplete,
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
  int score = 0;
  int moves = 0;
  String? errorMessage;

  final operators = ['+', '-', '*', '/'];

  @override
  void initState() {
    super.initState();
    availableNumbers = List<int>.from(widget.gameData['numbers']);
    targetNumber = widget.gameData['target'];
    equation = [];
    unusedNumbers = List<int>.from(availableNumbers);
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
          score = _calculateScore();
          widget.onScoreUpdate(score);
          widget.onComplete();
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
    return math.max(0, baseScore - movesPenalty);
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
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Equation Builder',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  Text(
                    'Target: $targetNumber',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: AppTheme.accentColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      score.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEquationDisplay() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 120,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
                color: AppTheme.wrongAnswerColor,
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
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: operators.map((operator) {
          return InkWell(
            onTap: () => _addOperator(operator),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  operator,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ).animate().scale(duration: 200.ms);
        }).toList(),
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

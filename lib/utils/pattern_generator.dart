import 'dart:math' as math;

class PatternGenerator {
  static final _random = math.Random();

  /// Generates a complete set of game levels with increasing difficulty
  static List<LevelData> generateLevels({
    int startLevel = 1,
    int numberOfLevels = 10,
    int sequencesPerLevel = 3,
  }) {
    List<LevelData> levels = [];

    for (int level = startLevel; level <= numberOfLevels; level++) {
      levels.add(_generateLevel(
        level: level,
        sequenceCount: sequencesPerLevel,
      ));
    }

    return levels;
  }

  /// Generates a single level with appropriate difficulty
  static LevelData _generateLevel({
    required int level,
    required int sequenceCount,
  }) {
    final sequences = <List<dynamic>>[];
    final hints = <String>[];

    // Adjust difficulty parameters based on level
    final complexity = math.min((level / 2).ceil(), 5);
    final maxNumber = 10 * level;
    final sequenceLength = math.min(5 + (level ~/ 3), 8);
    final timeLimit =
        math.max(240 - (level * 15), 60); // Decrease time as level increases

    for (int i = 0; i < sequenceCount; i++) {
      final patternType = _selectPatternType(complexity);
      final sequence = _generateSequence(
        patternType: patternType,
        maxNumber: maxNumber,
        length: sequenceLength,
      );
      sequences.add(sequence.numbers);
      hints.add(sequence.hint);
    }

    return LevelData(
      sequences: sequences,
      hints: hints,
      timeLimit: timeLimit,
    );
  }

  /// Selects an appropriate pattern type based on level complexity
  static PatternType _selectPatternType(int complexity) {
    final availablePatterns = <PatternType>[];

    // Add patterns based on complexity
    if (complexity >= 1) {
      availablePatterns.addAll([
        PatternType.additive,
        PatternType.subtractive,
      ]);
    }
    if (complexity >= 2) {
      availablePatterns.addAll([
        PatternType.multiplicative,
        PatternType.geometric,
      ]);
    }
    if (complexity >= 3) {
      availablePatterns.addAll([
        PatternType.fibonacci,
        PatternType.square,
      ]);
    }
    if (complexity >= 4) {
      availablePatterns.addAll([
        PatternType.compound,
        PatternType.alternating,
      ]);
    }
    if (complexity >= 5) {
      availablePatterns.addAll([
        PatternType.polynomial,
        PatternType.exponential,
      ]);
    }

    return availablePatterns[_random.nextInt(availablePatterns.length)];
  }

  /// Generates a sequence based on the selected pattern type
  static SequenceData _generateSequence({
    required PatternType patternType,
    required int maxNumber,
    required int length,
  }) {
    switch (patternType) {
      case PatternType.additive:
        return _generateAdditive(maxNumber, length);
      case PatternType.subtractive:
        return _generateSubtractive(maxNumber, length);
      case PatternType.multiplicative:
        return _generateMultiplicative(maxNumber, length);
      case PatternType.geometric:
        return _generateGeometric(maxNumber, length);
      case PatternType.fibonacci:
        return _generateFibonacci(maxNumber, length);
      case PatternType.square:
        return _generateSquare(maxNumber, length);
      case PatternType.compound:
        return _generateCompound(maxNumber, length);
      case PatternType.alternating:
        return _generateAlternating(maxNumber, length);
      case PatternType.polynomial:
        return _generatePolynomial(maxNumber, length);
      case PatternType.exponential:
        return _generateExponential(maxNumber, length);
    }
  }

  // Pattern generation methods
  static SequenceData _generateAdditive(int maxNumber, int length) {
    final difference = _random.nextInt(math.max(1, maxNumber ~/ length)) + 1;
    final start = _random.nextInt(maxNumber ~/ 2);
    final numbers = <dynamic>[];

    for (int i = 0; i < length; i++) {
      if (i == length - 2) {
        numbers.add(null);
      } else {
        numbers.add(start + (difference * i));
      }
    }

    return SequenceData(
      numbers: numbers,
      hint: 'Add $difference to each number',
      rule: (n) => start + (difference * n),
    );
  }

  static SequenceData _generateSubtractive(int maxNumber, int length) {
    final difference = _random.nextInt(math.max(1, maxNumber ~/ length)) + 1;
    final start = maxNumber - (difference * (length - 1));
    final numbers = <dynamic>[];

    for (int i = 0; i < length; i++) {
      if (i == length - 2) {
        numbers.add(null);
      } else {
        numbers.add(start - (difference * i));
      }
    }

    return SequenceData(
      numbers: numbers,
      hint: 'Subtract $difference from each number',
      rule: (n) => start - (difference * n),
    );
  }

  static SequenceData _generateMultiplicative(int maxNumber, int length) {
    final multiplier = _random.nextInt(3) + 2;
    final start = _random.nextInt(
            math.max(1, maxNumber ~/ math.pow(multiplier, length - 1))) +
        1;
    final numbers = <dynamic>[];

    for (int i = 0; i < length; i++) {
      if (i == length - 2) {
        numbers.add(null);
      } else {
        numbers.add(start * math.pow(multiplier, i).toInt());
      }
    }

    return SequenceData(
      numbers: numbers,
      hint: 'Multiply each number by $multiplier',
      rule: (n) => start * math.pow(multiplier, n).toInt(),
    );
  }

  static SequenceData _generateGeometric(int maxNumber, int length) {
    final ratio = _random.nextInt(2) + 2;
    final start =
        _random.nextInt(math.max(1, maxNumber ~/ math.pow(ratio, length - 1))) +
            1;
    final numbers = <dynamic>[];

    for (int i = 0; i < length; i++) {
      if (i == length - 2) {
        numbers.add(null);
      } else {
        numbers.add(start * math.pow(ratio, i).toInt());
      }
    }

    return SequenceData(
      numbers: numbers,
      hint: 'Each number is multiplied by $ratio',
      rule: (n) => start * math.pow(ratio, n).toInt(),
    );
  }

  static SequenceData _generateFibonacci(int maxNumber, int length) {
    List<int> fib = [1, 1];
    while (fib.length < length && fib.last < maxNumber) {
      fib.add(fib[fib.length - 1] + fib[fib.length - 2]);
    }

    final numbers = <dynamic>[];
    for (int i = 0; i < length; i++) {
      if (i == length - 2) {
        numbers.add(null);
      } else {
        numbers.add(fib[i]);
      }
    }

    return SequenceData(
      numbers: numbers,
      hint: 'Add the previous two numbers',
      rule: (n) => fib[n],
    );
  }

  static SequenceData _generateSquare(int maxNumber, int length) {
    final start =
        _random.nextInt(math.max(1, math.sqrt(maxNumber ~/ length).toInt())) +
            1;
    final numbers = <dynamic>[];

    for (int i = 0; i < length; i++) {
      if (i == length - 2) {
        numbers.add(null);
      } else {
        numbers.add(math.pow(start + i, 2).toInt());
      }
    }

    return SequenceData(
      numbers: numbers,
      hint: 'Square each position number',
      rule: (n) => math.pow(start + n, 2).toInt(),
    );
  }

  static SequenceData _generateCompound(int maxNumber, int length) {
    final additive = _random.nextInt(3) + 1;
    final multiplicative = _random.nextInt(2) + 2;
    final start =
        _random.nextInt(math.max(1, maxNumber ~/ (length * multiplicative))) +
            1;
    final numbers = <dynamic>[];

    for (int i = 0; i < length; i++) {
      if (i == length - 2) {
        numbers.add(null);
      } else {
        numbers
            .add(start * math.pow(multiplicative, i).toInt() + (additive * i));
      }
    }

    return SequenceData(
      numbers: numbers,
      hint: 'Multiply by $multiplicative and add $additive',
      rule: (n) => start * math.pow(multiplicative, n).toInt() + (additive * n),
    );
  }

  static SequenceData _generateAlternating(int maxNumber, int length) {
    final sequence1 = _random.nextInt(5) + 1;
    final sequence2 = _random.nextInt(5) + 1;
    final start = _random.nextInt(maxNumber ~/ 2) + 1;
    final numbers = <dynamic>[];

    for (int i = 0; i < length; i++) {
      if (i == length - 2) {
        numbers.add(null);
      } else {
        numbers.add(start + (i.isEven ? sequence1 * i : sequence2 * i));
      }
    }

    return SequenceData(
      numbers: numbers,
      hint: 'Alternate between adding $sequence1 and $sequence2',
      rule: (n) => start + (n.isEven ? sequence1 * n : sequence2 * n),
    );
  }

  static SequenceData _generatePolynomial(int maxNumber, int length) {
    final a = _random.nextInt(2) + 1;
    final b = _random.nextInt(3) + 1;
    final numbers = <dynamic>[];

    for (int i = 0; i < length; i++) {
      if (i == length - 2) {
        numbers.add(null);
      } else {
        numbers.add(a * i * i + b * i);
      }
    }

    return SequenceData(
      numbers: numbers,
      hint: 'Think about quadratic growth',
      rule: (n) => a * n * n + b * n,
    );
  }

  static SequenceData _generateExponential(int maxNumber, int length) {
    final base = _random.nextInt(2) + 2;
    final numbers = <dynamic>[];

    for (int i = 0; i < length; i++) {
      if (i == length - 2) {
        numbers.add(null);
      } else {
        numbers.add(math.pow(base, i).toInt());
      }
    }

    return SequenceData(
      numbers: numbers,
      hint: 'Powers of $base',
      rule: (n) => math.pow(base, n).toInt(),
    );
  }
}

enum PatternType {
  additive,
  subtractive,
  multiplicative,
  geometric,
  fibonacci,
  square,
  compound,
  alternating,
  polynomial,
  exponential,
}

class SequenceData {
  final List<dynamic> numbers;
  final String hint;
  final int Function(int) rule;

  const SequenceData({
    required this.numbers,
    required this.hint,
    required this.rule,
  });
}

class LevelData {
  final List<List<dynamic>> sequences;
  final List<String> hints;
  final int timeLimit;

  const LevelData({
    required this.sequences,
    required this.hints,
    required this.timeLimit,
  });
}

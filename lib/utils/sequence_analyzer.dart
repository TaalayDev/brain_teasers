import 'dart:math' as math;

class SequenceAnalyzer {
  /// Identifies the type of sequence and calculates the next number
  static int predictNext(List<int> sequence) {
    if (sequence.isEmpty) return 0;
    if (sequence.length == 1) return sequence[0];

    // Check for common sequence patterns
    if (isArithmetic(sequence)) {
      return continueArithmetic(sequence);
    } else if (isGeometric(sequence)) {
      return continueGeometric(sequence);
    } else if (isFibonacci(sequence)) {
      return continueFibonacci(sequence);
    } else if (isSquareNumbers(sequence)) {
      return continueSquareNumbers(sequence);
    } else if (isPowerSequence(sequence)) {
      return continuePowerSequence(sequence);
    } else if (isTriangularNumbers(sequence)) {
      return continueTriangularNumbers(sequence);
    }

    // Default to arithmetic progression if no pattern is found
    return continueArithmetic(sequence);
  }

  /// Arithmetic sequence (constant difference)
  static bool isArithmetic(List<int> sequence) {
    if (sequence.length < 3) return false;
    final difference = sequence[1] - sequence[0];
    for (int i = 2; i < sequence.length; i++) {
      if (sequence[i] - sequence[i - 1] != difference) return false;
    }
    return true;
  }

  static int continueArithmetic(List<int> sequence) {
    final difference = sequence[1] - sequence[0];
    return sequence.last + difference;
  }

  /// Geometric sequence (constant ratio)
  static bool isGeometric(List<int> sequence) {
    if (sequence.length < 3) return false;
    if (sequence.contains(0)) return false;
    final ratio = sequence[1] / sequence[0];
    for (int i = 2; i < sequence.length; i++) {
      if ((sequence[i] / sequence[i - 1] - ratio).abs() > 0.0001) return false;
    }
    return true;
  }

  static int continueGeometric(List<int> sequence) {
    final ratio = sequence[1] / sequence[0];
    return (sequence.last * ratio).round();
  }

  /// Fibonacci sequence
  static bool isFibonacci(List<int> sequence) {
    if (sequence.length < 3) return false;
    for (int i = 2; i < sequence.length; i++) {
      if (sequence[i] != sequence[i - 1] + sequence[i - 2]) return false;
    }
    return true;
  }

  static int continueFibonacci(List<int> sequence) {
    return sequence[sequence.length - 1] + sequence[sequence.length - 2];
  }

  /// Square numbers (1, 4, 9, 16, 25, ...)
  static bool isSquareNumbers(List<int> sequence) {
    if (sequence.length < 2) return false;
    for (int i = 0; i < sequence.length; i++) {
      if (sequence[i] != (i + 1) * (i + 1)) return false;
    }
    return true;
  }

  static int continueSquareNumbers(List<int> sequence) {
    final n = math.sqrt(sequence.last).round() + 1;
    return n * n;
  }

  /// Power sequence (2^n, 3^n, etc.)
  static bool isPowerSequence(List<int> sequence) {
    if (sequence.length < 3) return false;
    final base = math.pow(sequence[1] / sequence[0], 1 / 1).round();
    for (int i = 0; i < sequence.length; i++) {
      if (sequence[i] != math.pow(base, i + 1)) return false;
    }
    return true;
  }

  static int continuePowerSequence(List<int> sequence) {
    final base = math.pow(sequence[1] / sequence[0], 1 / 1).round();
    final exponent = math.log(sequence.last) / math.log(base) + 1;
    return math.pow(base, exponent).round();
  }

  /// Triangular numbers (1, 3, 6, 10, 15, ...)
  static bool isTriangularNumbers(List<int> sequence) {
    if (sequence.length < 2) return false;
    for (int i = 0; i < sequence.length; i++) {
      final triangularNumber = ((i + 1) * (i + 2)) ~/ 2;
      if (sequence[i] != triangularNumber) return false;
    }
    return true;
  }

  static int continueTriangularNumbers(List<int> sequence) {
    final n = sequence.length + 1;
    return (n * (n + 1)) ~/ 2;
  }

  /// Get a description of the sequence pattern
  static String getPatternDescription(List<int> sequence) {
    if (isArithmetic(sequence)) {
      final difference = sequence[1] - sequence[0];
      return 'Add $difference to each number';
    } else if (isGeometric(sequence)) {
      final ratio = sequence[1] ~/ sequence[0];
      return 'Multiply each number by $ratio';
    } else if (isFibonacci(sequence)) {
      return 'Add the previous two numbers';
    } else if (isSquareNumbers(sequence)) {
      return 'Square numbers: 1², 2², 3², ...';
    } else if (isPowerSequence(sequence)) {
      final base = math.pow(sequence[1] / sequence[0], 1 / 1).round();
      return 'Powers of $base';
    } else if (isTriangularNumbers(sequence)) {
      return 'Triangular numbers';
    }
    return 'Look for a pattern in the numbers';
  }
}

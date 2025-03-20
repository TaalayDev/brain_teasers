import 'package:flutter/material.dart';
import 'dart:math' as math;

// Level configuration and game mechanics for CardMatchGame
class CardMatchLevel {
  final int gridRows;
  final int gridColumns;
  final String theme;
  final int timeLimit;
  final int hintsAllowed;
  final double matchTimeBonus;
  final bool rotatingCards;
  final bool movingCards;
  final double cardMoveSpeed;
  final bool timedReveal;
  final int revealDuration;
  final List<String> specialEffects;

  const CardMatchLevel({
    required this.gridRows,
    required this.gridColumns,
    required this.theme,
    required this.timeLimit,
    this.hintsAllowed = 3,
    this.matchTimeBonus = 5,
    this.rotatingCards = false,
    this.movingCards = false,
    this.cardMoveSpeed = 0.0,
    this.timedReveal = false,
    this.revealDuration = 1000,
    this.specialEffects = const [],
  });

  int get totalCards => gridRows * gridColumns;
  int get numberOfPairs => totalCards ~/ 2;
}

class CardMatchLevelSystem {
  static const List<CardMatchLevel> levels = [
    CardMatchLevel(
      gridRows: 4,
      gridColumns: 4,
      theme: 'animals',
      timeLimit: 120,
      hintsAllowed: 3,
      matchTimeBonus: 5,
      specialEffects: ['sparkle', 'pulse'],
    ),
    CardMatchLevel(
      gridRows: 4,
      gridColumns: 4,
      theme: 'fruits',
      timeLimit: 100,
      hintsAllowed: 2,
      matchTimeBonus: 4,
      rotatingCards: true,
      specialEffects: ['sparkle', 'pulse', 'rotate'],
    ),
    CardMatchLevel(
      gridRows: 6,
      gridColumns: 6,
      theme: 'shapes',
      timeLimit: 120,
      hintsAllowed: 2,
      matchTimeBonus: 4,
      movingCards: true,
      cardMoveSpeed: 0.5,
      specialEffects: ['sparkle', 'pulse', 'move'],
    ),
    CardMatchLevel(
      gridRows: 6,
      gridColumns: 6,
      theme: 'mixed',
      timeLimit: 150,
      hintsAllowed: 2,
      matchTimeBonus: 3,
      timedReveal: true,
      revealDuration: 800,
      specialEffects: ['sparkle', 'pulse', 'fade'],
    ),
    CardMatchLevel(
      gridRows: 8,
      gridColumns: 8,
      theme: 'mixed',
      timeLimit: 180,
      hintsAllowed: 1,
      matchTimeBonus: 3,
      rotatingCards: true,
      movingCards: true,
      cardMoveSpeed: 0.8,
      timedReveal: true,
      revealDuration: 600,
      specialEffects: ['sparkle', 'pulse', 'rotate', 'move', 'fade'],
    ),
  ];

  static Map<String, List<String>> themeElements = {
    'animals': [
      '🐶',
      '🐱',
      '🐭',
      '🐹',
      '🐰',
      '🦊',
      '🐻',
      '🐼',
      '🐨',
      '🐯',
      '🦁',
      '🐮',
      '🐷',
      '🐸',
      '🐒'
    ],
    'fruits': [
      '🍎',
      '🍌',
      '🍇',
      '🍊',
      '🍓',
      '🍐',
      '🍒',
      '🥝',
      '🍍',
      '🥭',
      '🍉',
      '🍑',
      '🍈',
      '🍋',
      '🥑'
    ],
    'shapes': [
      '⭐',
      '⚡',
      '❤️',
      '💠',
      '🔶',
      '🔺',
      '⭕',
      '🔷',
      '💫',
      '🌟',
      '🔆',
      '💮',
      '🔱',
      '✴️',
      '🔰'
    ],
    'mixed': [
      '🎨',
      '🎭',
      '🎪',
      '🎢',
      '🎡',
      '🎠',
      '🎮',
      '🎲',
      '🎯',
      '🎳',
      '🎸',
      '🎺',
      '🎻',
      '🎹',
      '🎵',
      '🎬',
      '🎤',
      '🎧',
      '🪩',
      '🎰',
      '🧩',
      '🎱',
      '🎣',
      '🎷',
      '🥁',
      '🎺',
      '🎸',
      '🪗',
      '🪘',
      '🪙',
      '🚀',
      '🗿',
    ],
  };

  static List<String> getThemeElements(String theme, int count) {
    if (!themeElements.containsKey(theme)) {
      throw ArgumentError('Theme $theme not found');
    }

    final elements = List<String>.from(themeElements[theme]!);

    elements.shuffle();
    return elements.take(count).toList();
  }

  static List<CardData> generateCards(
    CardMatchLevel level,
    TickerProvider vsync,
  ) {
    final elements = getThemeElements(level.theme, level.numberOfPairs);
    final cards = <CardData>[];

    for (var element in elements) {
      for (var i = 0; i < 2; i++) {
        cards.add(CardData(
          id: cards.length,
          value: element,
          currentIndex: cards.length,
          isMatched: false,
          isFlipped: false,
          animation: AnimationController(
            vsync: vsync,
            duration: const Duration(milliseconds: 400),
          ),
          fadeAnimation: AnimationController(
            vsync: vsync,
            duration: const Duration(milliseconds: 400),
          ),
          initialPosition: _calculateInitialPosition(cards.length, level),
        ));
      }
    }

    // Shuffle cards
    cards.shuffle();

    // Update positions after shuffle
    for (var i = 0; i < cards.length; i++) {
      cards[i] = cards[i].copyWith(currentIndex: i);
    }

    return cards;
  }

  static Vector2 _calculateInitialPosition(int index, CardMatchLevel level) {
    final row = index ~/ level.gridColumns;
    final col = index % level.gridColumns;
    return Vector2(col.toDouble(), row.toDouble());
  }

  static double calculateCardScore(CardMatchLevel level, int timeRemaining) {
    const baseScore = 100.0;
    final timeBonus = timeRemaining * 2.0;
    final difficultyMultiplier = (level.gridRows * level.gridColumns) / 16.0;

    return (baseScore + timeBonus) * difficultyMultiplier;
  }

  static Duration calculateRevealDuration(
    CardMatchLevel level,
    int currentStreak,
  ) {
    final baseDuration = level.revealDuration;
    final streakBonus = math.min(currentStreak * 50, 200); // Max 200ms bonus
    return Duration(milliseconds: math.max(baseDuration - streakBonus, 300));
  }

  static Vector2 calculateMovementOffset(
    CardMatchLevel level,
    int index,
    double time,
  ) {
    if (!level.movingCards) return Vector2.zero();

    final amplitude = 20.0 * level.cardMoveSpeed;
    final frequency = 2 * math.pi * level.cardMoveSpeed;

    return Vector2(
      amplitude * math.sin(frequency * time + index),
      amplitude * math.cos(frequency * time + index),
    );
  }
}

class Vector2 {
  final double x;
  final double y;

  const Vector2(this.x, this.y);

  Vector2 operator +(Vector2 other) => Vector2(x + other.x, y + other.y);
  Vector2 operator *(double scalar) => Vector2(x * scalar, y * scalar);

  static Vector2 zero() => const Vector2(0, 0);
}

class CardData {
  final int id;
  final String value;
  final int currentIndex;
  final bool isMatched;
  final bool isFlipped;
  final AnimationController animation;
  final AnimationController fadeAnimation;
  final Vector2 initialPosition;

  const CardData({
    required this.id,
    required this.value,
    required this.currentIndex,
    required this.isMatched,
    required this.isFlipped,
    required this.animation,
    required this.fadeAnimation,
    required this.initialPosition,
  });

  CardData copyWith({
    int? id,
    String? value,
    int? currentIndex,
    bool? isMatched,
    bool? isFlipped,
    AnimationController? animation,
    AnimationController? fadeAnimation,
    Vector2? initialPosition,
  }) {
    return CardData(
      id: id ?? this.id,
      value: value ?? this.value,
      currentIndex: currentIndex ?? this.currentIndex,
      isMatched: isMatched ?? this.isMatched,
      isFlipped: isFlipped ?? this.isFlipped,
      animation: animation ?? this.animation,
      fadeAnimation: fadeAnimation ?? this.fadeAnimation,
      initialPosition: initialPosition ?? this.initialPosition,
    );
  }
}

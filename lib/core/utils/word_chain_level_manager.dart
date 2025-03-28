import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WordChainLevelManager {
  // Singleton pattern
  static final WordChainLevelManager _instance =
      WordChainLevelManager._internal();
  factory WordChainLevelManager() => _instance;
  WordChainLevelManager._internal();

  // List of word chain levels
  final List<Map<String, dynamic>> _levels = wordChainLevels;

  // Get level data
  Map<String, dynamic> getLevel(int levelNumber) {
    return _levels.firstWhere(
      (level) => level['level'] == levelNumber,
      orElse: () => _levels[0],
    );
  }

  // Get all levels
  List<Map<String, dynamic>> getAllLevels() {
    return List.from(_levels);
  }

  // Get maximum level number
  int get maxLevel => _levels.length;

  // Get player's highest unlocked level
  Future<int> getHighestUnlockedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('highestUnlockedLevel') ?? 1;
  }

  // Unlock next level
  Future<void> unlockNextLevel(int currentLevel) async {
    if (currentLevel >= maxLevel) return;

    final prefs = await SharedPreferences.getInstance();
    final highestUnlocked = prefs.getInt('highestUnlockedLevel') ?? 1;

    if (currentLevel + 1 > highestUnlocked) {
      await prefs.setInt('highestUnlockedLevel', currentLevel + 1);
    }
  }

  // Save level score
  Future<void> saveLevelScore(int levelNumber, int score, int moves) async {
    final prefs = await SharedPreferences.getInstance();

    // Save highest score for this level
    final currentHighScore =
        prefs.getInt('level_${levelNumber}_highscore') ?? 0;
    if (score > currentHighScore) {
      await prefs.setInt('level_${levelNumber}_highscore', score);
    }

    // Save best (lowest) moves for this level
    final currentBestMoves =
        prefs.getInt('level_${levelNumber}_bestmoves') ?? 999;
    if (moves < currentBestMoves) {
      await prefs.setInt('level_${levelNumber}_bestmoves', moves);
    }

    // Save completion status
    await prefs.setBool('level_${levelNumber}_completed', true);
  }

  // Check if level is completed
  Future<bool> isLevelCompleted(int levelNumber) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('level_${levelNumber}_completed') ?? false;
  }

  // Get level high score
  Future<int> getLevelHighScore(int levelNumber) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('level_${levelNumber}_highscore') ?? 0;
  }

  // Get level best moves
  Future<int> getLevelBestMoves(int levelNumber) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('level_${levelNumber}_bestmoves') ?? 0;
  }

  // Reset all progress (for testing)
  Future<void> resetAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
        (key) => key.startsWith('level_') || key == 'highestUnlockedLevel');

    for (final key in keys) {
      await prefs.remove(key);
    }

    // Reset to level 1
    await prefs.setInt('highestUnlockedLevel', 1);
  }
}

final List<Map<String, dynamic>> wordChainLevels = [
  // Level 1 - Easy introduction
  {
    'level': 1,
    'start': 'COLD',
    'end': 'WARM',
    'maxMoves': 6,
    'difficulty': 'Easy',
    'hint': 'Try changing the C first',
  },

  // Level 2 - Simple transformation
  {
    'level': 2,
    'start': 'SHIP',
    'end': 'BOAT',
    'maxMoves': 7,
    'difficulty': 'Easy',
    'hint': 'Consider words like SLIP, SHOP',
  },

  // Level 3 - Opposites theme
  {
    'level': 3,
    'start': 'DARK',
    'end': 'LIGHT',
    'maxMoves': 8,
    'difficulty': 'Medium',
    'hint': 'Try LARK as an intermediate step',
  },

  // Level 4 - Emotional transition
  {
    'level': 4,
    'start': 'LOVE',
    'end': 'HATE',
    'maxMoves': 6,
    'difficulty': 'Medium',
    'hint': 'HAVE is a useful stepping stone',
  },

  // Level 5 - Music reference
  {
    'level': 5,
    'start': 'ROCK',
    'end': 'ROLL',
    'maxMoves': 5,
    'difficulty': 'Easy',
    'hint': 'Only a few steps needed!',
  },

  // Level 6 - Work/play contrast
  {
    'level': 6,
    'start': 'PLAY',
    'end': 'WORK',
    'maxMoves': 7,
    'difficulty': 'Medium',
    'hint': 'Consider PLANK as a step',
  },

  // Level 7 - Food items
  {
    'level': 7,
    'start': 'RICE',
    'end': 'BEAN',
    'maxMoves': 8,
    'difficulty': 'Hard',
    'hint': 'Try words ending with -EAN',
  },

  // Level 8 - Elements theme
  {
    'level': 8,
    'start': 'FIRE',
    'end': 'WOOD',
    'maxMoves': 7,
    'difficulty': 'Hard',
    'hint': 'WIRE is a good first step',
  },

  // Level 9 - Action opposites
  {
    'level': 9,
    'start': 'LOST',
    'end': 'FIND',
    'maxMoves': 7,
    'difficulty': 'Medium',
    'hint': 'LINT might help',
  },

  // Level 10 - Body parts
  {
    'level': 10,
    'start': 'FOOT',
    'end': 'HAND',
    'maxMoves': 7,
    'difficulty': 'Medium',
    'hint': 'HEAD is a useful step',
  },

  // Level 11 - Flowers
  {
    'level': 11,
    'start': 'ROSE',
    'end': 'LILY',
    'maxMoves': 8,
    'difficulty': 'Hard',
    'hint': 'Try RILE as an intermediate word',
  },

  // Level 12 - Big cats
  {
    'level': 12,
    'start': 'LION',
    'end': 'TIGER',
    'maxMoves': 9,
    'difficulty': 'Very Hard',
    'hint': 'This requires changing word length - think creatively!',
  },

  // Level 13 - Directions
  {
    'level': 13,
    'start': 'EAST',
    'end': 'WEST',
    'maxMoves': 6,
    'difficulty': 'Medium',
    'hint': 'Try WAST as a stepping stone',
  },

  // Level 14 - Nature relationship
  {
    'level': 14,
    'start': 'TREE',
    'end': 'LEAF',
    'maxMoves': 7,
    'difficulty': 'Medium',
    'hint': 'REEF might be useful',
  },

  // Level 15 - Book related
  {
    'level': 15,
    'start': 'BOOK',
    'end': 'PAGE',
    'maxMoves': 7,
    'difficulty': 'Hard',
    'hint': 'PACE is a helpful step',
  },

  // Level 16 - Celestial objects
  {
    'level': 16,
    'start': 'MOON',
    'end': 'STAR',
    'maxMoves': 8,
    'difficulty': 'Hard',
    'hint': 'MOAN might be a good first step',
  },

  // Level 17 - Animal types
  {
    'level': 17,
    'start': 'FISH',
    'end': 'BIRD',
    'maxMoves': 7,
    'difficulty': 'Hard',
    'hint': 'FIRD is not a word; try another approach',
  },

  // Level 18 - Beverages
  {
    'level': 18,
    'start': 'BEER',
    'end': 'WINE',
    'maxMoves': 6,
    'difficulty': 'Medium',
    'hint': 'BIER is an archaic word worth trying',
  },

  // Level 19 - Numbers
  {
    'level': 19,
    'start': 'FIVE',
    'end': 'NINE',
    'maxMoves': 5,
    'difficulty': 'Easy',
    'hint': 'FINE is very close to the answer',
  },

  // Level 20 - Moral opposites (challenging finale)
  {
    'level': 20,
    'start': 'GOOD',
    'end': 'EVIL',
    'maxMoves': 8,
    'difficulty': 'Very Hard',
    'hint': 'This might require more creative thinking',
  },
];

// Function to get a level by number
Map<String, dynamic> getLevelByNumber(int levelNumber) {
  return wordChainLevels.firstWhere(
    (level) => level['level'] == levelNumber,
    orElse: () => wordChainLevels[0], // Return first level if not found
  );
}

// Function to get all levels
List<Map<String, dynamic>> getAllLevels() {
  return wordChainLevels;
}

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'database.dart';

extension AppDatabaseSeedX on AppDatabase {
  Future<void> seedDatabase() async {
    await transaction(() async {
      // Seed Categories
      final categoryIds = await _seedCategories();

      // Seed Puzzles for each category
      await _seedPuzzles(categoryIds);

      // Seed Achievements
      await _seedAchievements();

      // Seed Settings
      await _seedSettings();
    });
  }

  Future<Map<String, int>> _seedCategories() async {
    final Map<String, int> categoryIds = {};

    final categories = [
      PuzzleCategoriesCompanion.insert(
        name: 'Logic Puzzles',
        description: 'Challenge your logical thinking with these brain teasers',
        iconName: 'logic',
        sortOrder: 1,
      ),
      PuzzleCategoriesCompanion.insert(
        name: 'Memory Games',
        description: 'Improve your memory with pattern recognition',
        iconName: 'memory',
        sortOrder: 2,
      ),
      // PuzzleCategoriesCompanion.insert(
      //   name: 'Physics Puzzles',
      //   description: 'Solve physics-based challenges and experiments',
      //   iconName: 'science',
      //   sortOrder: 3,
      // ),
      PuzzleCategoriesCompanion.insert(
        name: 'Word Games',
        description: 'Test your vocabulary and word skills',
        iconName: 'text_fields',
        sortOrder: 4,
      ),
      PuzzleCategoriesCompanion.insert(
        name: 'Math Challenges',
        description: 'Mathematical puzzles and number games',
        iconName: 'calculate',
        sortOrder: 5,
      ),
      PuzzleCategoriesCompanion.insert(
        name: 'Sequence Masters',
        description:
            'Master the art of pattern recognition and sequence completion',
        iconName: 'pattern_sequence',
        sortOrder: 6,
      ),
      PuzzleCategoriesCompanion.insert(
        name: 'Visual Puzzles',
        description:
            'Challenge your visual perception and spatial reasoning skills',
        iconName: 'visual',
        sortOrder: 7,
      ),
      PuzzleCategoriesCompanion.insert(
        name: 'Attention Training',
        description: 'Sharpen your focus and improve concentration',
        iconName: 'visibility',
        sortOrder: 8,
      ),
    ];

    for (final category in categories) {
      final id = await into(puzzleCategories).insert(category);
      categoryIds[category.name.value] = id;
    }

    return categoryIds;
  }

  Future<void> _seedPuzzles(Map<String, int> categoryIds) async {
    // Logic Puzzles
    await _seedLogicPuzzles(categoryIds['Logic Puzzles']!);

    // Memory Games
    await _seedMemoryGames(categoryIds['Memory Games']!);

    // Physics Puzzles
    // await _seedPhysicsPuzzles(categoryIds['Physics Puzzles']!);

    // Word Games
    await _seedWordGames(categoryIds['Word Games']!);

    // Math Challenges
    await _seedMathChallenges(categoryIds['Math Challenges']!);

    // Sequence Masters
    await _seedSequenceCategory(categoryIds['Sequence Masters']!);

    // Visual Puzzles
    await _seedVisualPuzzles(categoryIds['Visual Puzzles']!);

    await _seedAttentionGames(categoryIds['Attention Training']!);
  }

  Future<void> _seedLogicPuzzles(int categoryId) async {
    final puzzlesList = [
      PuzzlesCompanion.insert(
        categoryId: categoryId,
        name: 'Pattern Sequence',
        description: 'Complete the sequence by finding the pattern',
        difficulty: 'easy',
        orderInCategory: 1,
        gameData: jsonEncode({
          'type': 'pattern_sequence',
          'sequences': [
            [1, 2, 3, null, 5],
            [2, 4, 6, null, 10],
          ],
        }),
        isLocked: const Value(false),
        requiredScore: const Value(0),
      ),
      PuzzlesCompanion.insert(
        categoryId: categoryId,
        name: 'Circuit Path',
        description:
            'Guide the energy from start to end by rotating circuit pieces. Connect them to create a continuous path.',
        difficulty: 'medium',
        orderInCategory: 4,
        gameData: jsonEncode({
          "type": "circuit_path",
          "gridSize": 6,
          "timeLimit": 180,
        }),
        isLocked: const Value(true),
        requiredScore: const Value(100),
      ),
    ];

    for (final puzzle in puzzlesList) {
      await into(puzzles).insert(puzzle);
    }
  }

  Future<void> _seedMemoryGames(int categoryId) async {
    final puzzlesList = [
      PuzzlesCompanion.insert(
        categoryId: categoryId,
        name: 'Card Match',
        description: 'Find matching pairs of cards',
        difficulty: 'easy',
        orderInCategory: 1,
        gameData: jsonEncode({
          'type': 'card_match',
          'gridSize': {'rows': 4, 'columns': 4},
          'theme': 'animals',
        }),
        isLocked: const Value(false),
        requiredScore: const Value(0),
      ),
      PuzzlesCompanion.insert(
        categoryId: categoryId,
        name: 'Pattern Recall',
        description: 'Remember and reproduce the pattern',
        difficulty: 'medium',
        orderInCategory: 2,
        gameData: jsonEncode({
          'type': 'pattern_recall',
          'gridSize': 5,
          'sequenceLength': 5,
        }),
        isLocked: const Value(true),
        requiredScore: const Value(150),
      ),
    ];

    for (final puzzle in puzzlesList) {
      await into(puzzles).insert(puzzle);
    }
  }

  Future<void> _seedPhysicsPuzzles(int categoryId) async {
    final puzzlesList = [
      PuzzlesCompanion.insert(
        categoryId: categoryId,
        name: 'Gravity Maze',
        description: 'Guide the ball to the goal using physics',
        difficulty: 'medium',
        orderInCategory: 1,
        gameData: jsonEncode({
          'type': 'balance_ball',
          'gravity': 9.81,
          'friction': 0.3,
        }),
        isLocked: const Value(false),
        requiredScore: const Value(0),
      ),
      PuzzlesCompanion.insert(
        categoryId: categoryId,
        name: 'Gravity Flow',
        description: 'Control the flow of water to fill all containers',
        difficulty: 'hard',
        orderInCategory: 2,
        gameData: jsonEncode({
          'type': 'gravity_flow',
        }),
        isLocked: const Value(true),
        requiredScore: const Value(200),
      ),
      PuzzlesCompanion.insert(
        categoryId: categoryId,
        name: 'Pendulum Balance',
        description:
            'Control a swinging pendulum and guide it to the target angle.',
        difficulty: 'medium',
        orderInCategory: 3,
        gameData: jsonEncode({
          'type': 'pendulum_puzzle',
          'targetAngle': 45,
          'timeLimit': 60,
        }),
        isLocked: const Value(true),
        requiredScore: const Value(150),
      ),
    ];

    for (final puzzle in puzzlesList) {
      await into(puzzles).insert(puzzle);
    }
  }

  Future<void> _seedWordGames(int categoryId) async {
    final puzzlesList = [
      PuzzlesCompanion.insert(
        categoryId: categoryId,
        name: 'Word Search',
        description: 'Find hidden words in the grid',
        difficulty: 'easy',
        orderInCategory: 1,
        gameData: jsonEncode({
          'type': 'word_search',
          'gridSize': 8,
          'words': ['PUZZLE', 'BRAIN', 'GAME'],
        }),
        isLocked: const Value(false),
        requiredScore: const Value(0),
      ),
      PuzzlesCompanion.insert(
        categoryId: categoryId,
        name: 'Word Chain',
        description: 'Connect words by changing one letter',
        difficulty: 'medium',
        orderInCategory: 2,
        gameData: jsonEncode({
          'type': 'word_chain',
          'start': 'COLD',
          'end': 'WARM',
        }),
        isLocked: const Value(true),
        requiredScore: const Value(120),
      ),
    ];

    for (final puzzle in puzzlesList) {
      await into(puzzles).insert(puzzle);
    }
  }

  Future<void> _seedMathChallenges(int categoryId) async {
    final puzzlesList = [
      PuzzlesCompanion.insert(
        categoryId: categoryId,
        name: 'Number Grid',
        description: 'Fill in the grid with correct numbers',
        difficulty: 'medium',
        orderInCategory: 1,
        gameData: jsonEncode({
          'type': 'number_grid',
          'gridSize': 3,
          'target': 15,
        }),
        isLocked: const Value(false),
        requiredScore: const Value(0),
      ),
      PuzzlesCompanion.insert(
        categoryId: categoryId,
        name: 'Equation Builder',
        description: 'Create equations to reach the target',
        difficulty: 'hard',
        orderInCategory: 2,
        gameData: jsonEncode({
          'type': 'equation_builder',
          'numbers': [2, 3, 5, 7],
          'target': 24,
        }),
        isLocked: const Value(true),
        requiredScore: const Value(180),
      ),
    ];

    for (final puzzle in puzzlesList) {
      await into(puzzles).insert(puzzle);
    }
  }

  Future<void> _seedSequenceCategory(int categoryId) async {
    final puzzlesList = [
      PuzzlesCompanion.insert(
        categoryId: categoryId,
        name: 'Numeric Symphony',
        description:
            'Identify and complete patterns in number sequences with varying rules and progressions',
        difficulty: 'medium',
        orderInCategory: 1,
        gameData: jsonEncode({
          'type': 'pattern_sequence',
          'sequences': [
            [2, 4, 8, null, 32], // Geometric (×2)
            [1, 4, 9, 16, null], // Square numbers
            [3, 7, 15, 31, null], // Double previous + 1
            [13, 10, 7, null, 1], // Arithmetic (-3)
          ],
          'hints': [
            'Look for multiplication patterns',
            'Think about perfect squares',
            'Each number has a relationship to the previous one',
            'Check if numbers are increasing or decreasing by the same amount'
          ]
        }),
        isLocked: const Value(false),
        requiredScore: const Value(0),
      ),
      PuzzlesCompanion.insert(
        categoryId: categoryId,
        name: 'Symbol Sequence',
        description:
            'Find the pattern in sequences of symbols and select the next logical element',
        difficulty: 'medium',
        orderInCategory: 2,
        gameData: jsonEncode({
          'type': 'symbol_sequence',
          'sequences': [
            ['□', '△', '○', null, '△'], // Shape pattern
            ['🌑', '🌓', '🌕', null, '🌑'], // Moon phases
            ['⚀', '⚁', '⚂', null, '⚄'], // Dice faces
            ['←', '↑', '→', null, '←'], // Directions
          ],
          'hints': [
            'Notice how shapes alternate',
            'Think about cyclic patterns',
            'Look for increasing values',
            'Consider rotational patterns'
          ],
          'style': 'symbols',
          'allowRotation': true,
          'hasAnimation': true
        }),
        isLocked: const Value(true),
        requiredScore: const Value(100),
      ),
    ];

    for (final puzzle in puzzlesList) {
      await into(puzzles).insert(puzzle);
    }
  }

  Future<void> _seedVisualPuzzles(int categoryId) async {
    final puzzlesList = [
      PuzzlesCompanion.insert(
        categoryId: categoryId,
        name: 'Color Harmony',
        description:
            'Match and complete color patterns following specific rules and gradients',
        difficulty: 'easy',
        orderInCategory: 1,
        gameData: jsonEncode({
          'type': 'color_harmony',
          'patterns': [
            {
              'colors': [
                '#FF5733',
                '#FFB833',
                null,
                '#33FF57'
              ], // Complementary
              'rule': 'complementary'
            },
            {
              'colors': ['#3366FF', '#6633FF', null, '#FF3366'], // Triadic
              'rule': 'triadic'
            },
            {
              'colors': [
                '#FF0000',
                '#FF3333',
                null,
                '#FF9999'
              ], // Monochromatic
              'rule': 'monochromatic'
            }
          ],
          'timeLimit': 120,
          'hints': [
            'Look for color relationships on the color wheel',
            'Notice how colors transition from one to another',
            'Some patterns follow specific color theory rules'
          ]
        }),
        isLocked: const Value(false),
        requiredScore: const Value(0),
      ),
      PuzzlesCompanion.insert(
        categoryId: categoryId,
        name: 'Pattern Mirror',
        description:
            'Complete symmetrical patterns by replicating missing sections',
        difficulty: 'hard',
        orderInCategory: 3,
        gameData: jsonEncode({
          'type': 'pattern_mirror',
          'patterns': [
            {
              'grid': [
                [1, 0, 1, null, null],
                [0, 1, 0, null, null],
                [1, 1, 1, null, null]
              ],
              'symmetryType': 'vertical'
            },
            {
              'grid': [
                [1, 0, 1],
                [0, 1, 0],
                [null, null, null]
              ],
              'symmetryType': 'horizontal'
            },
            {
              'grid': [
                [1, 0, null],
                [0, 1, null],
                [null, null, 1]
              ],
              'symmetryType': 'diagonal'
            }
          ],
          'timeLimit': 240,
          'hints': [
            'Look for reflection patterns across the axis',
            'Each cell corresponds to its mirror position',
            'Consider both shape and color in complex patterns'
          ]
        }),
        isLocked: const Value(true),
        requiredScore: const Value(300),
      ),
      PuzzlesCompanion.insert(
        categoryId: categoryId,
        name: 'Pic Slider',
        description:
            'Recreate the original image by sliding and rearranging the pieces',
        difficulty: 'expert',
        orderInCategory: 4,
        gameData: jsonEncode({
          'type': 'pic_slider',
          'levels': [
            {
              'image': 'assets/images/puzzle_images/landscape.jpg',
              'gridSize': 3,
              'shuffleCount': 10,
            },
            {
              'image': 'assets/images/puzzle_images/animals.jpg',
              'gridSize': 4,
              'shuffleCount': 15
            },
            {
              'image': 'assets/images/puzzle_images/abstract.jpg',
              'gridSize': 5,
              'shuffleCount': 20
            },
            {
              'image': 'assets/images/puzzle_images/flowers.jpg',
              'gridSize': 6,
              'shuffleCount': 25
            }
          ],
          'hints': [
            'Start by moving the corner pieces',
            'Work on the edges to align the borders',
            'Focus on one row or column at a time'
          ]
        }),
        isLocked: const Value(true),
        requiredScore: const Value(400),
      ),
    ];

    for (final puzzle in puzzlesList) {
      await into(puzzles).insert(puzzle);
    }
  }

  Future<void> _seedAttentionGames(int categoryId) async {
    final puzzlesList = [
      PuzzlesCompanion.insert(
        categoryId: categoryId,
        name: 'Spot the Difference',
        description: 'Find subtle differences between two similar images',
        difficulty: 'easy',
        orderInCategory: 1,
        gameData: jsonEncode({
          'type': 'spot_difference',
          'timeLimit': 180,
          'levels': [
            {
              'gridSize': {'width': 4, 'height': 4},
              'differences': 3,
              'elements': ['circle', 'square', 'triangle', 'star']
            },
            {
              'gridSize': {'width': 5, 'height': 5},
              'differences': 4,
              'elements': ['circle', 'square', 'triangle', 'star', 'hexagon']
            },
            {
              'gridSize': {'width': 6, 'height': 6},
              'differences': 5,
              'elements': [
                'circle',
                'square',
                'triangle',
                'star',
                'hexagon',
                'diamond'
              ]
            }
          ]
        }),
        isLocked: const Value(false),
        requiredScore: const Value(0),
      ),
      PuzzlesCompanion.insert(
        categoryId: categoryId,
        name: 'Change Blindness',
        description: 'Detect changes in alternating patterns',
        difficulty: 'medium',
        orderInCategory: 2,
        gameData: jsonEncode({
          'type': 'change_blindness',
          'timeLimit': 120,
          'levels': [
            {'gridSize': 4, 'changes': 1, 'flashDuration': 500},
            {'gridSize': 5, 'changes': 2, 'flashDuration': 400},
            {'gridSize': 6, 'changes': 3, 'flashDuration': 300}
          ]
        }),
        isLocked: const Value(true),
        requiredScore: const Value(100),
      ),
      PuzzlesCompanion.insert(
        categoryId: categoryId,
        name: 'Visual Search',
        description: 'Find specific targets among distractors',
        difficulty: 'hard',
        orderInCategory: 3,
        gameData: jsonEncode({
          'type': 'visual_search',
          'timeLimit': 60,
          'levels': [
            {
              'gridSize': {'width': 6, 'height': 6},
              'targetCount': 3,
              'distractorTypes': 2
            },
            {
              'gridSize': {'width': 8, 'height': 8},
              'targetCount': 4,
              'distractorTypes': 3
            },
            {
              'gridSize': {'width': 10, 'height': 10},
              'targetCount': 5,
              'distractorTypes': 4
            },
            {
              'gridSize': {'width': 12, 'height': 12},
              'targetCount': 6,
              'distractorTypes': 5
            },
            {
              'gridSize': {'width': 14, 'height': 14},
              'targetCount': 7,
              'distractorTypes': 6
            },
            {
              'gridSize': {'width': 16, 'height': 16},
              'targetCount': 8,
              'distractorTypes': 7
            },
            {
              'gridSize': {'width': 18, 'height': 18},
              'targetCount': 9,
              'distractorTypes': 8
            },
            {
              'gridSize': {'width': 20, 'height': 20},
              'targetCount': 10,
              'distractorTypes': 9
            },
            {
              'gridSize': {'width': 22, 'height': 22},
              'targetCount': 11,
              'distractorTypes': 10
            },
            {
              'gridSize': {'width': 24, 'height': 24},
              'targetCount': 12,
              'distractorTypes': 11
            }
          ]
        }),
        isLocked: const Value(true),
        requiredScore: const Value(200),
      ),
      PuzzlesCompanion.insert(
        categoryId: categoryId,
        name: 'Multiple Object Tracking',
        description: 'Track multiple moving targets simultaneously',
        difficulty: 'expert',
        orderInCategory: 4,
        gameData: jsonEncode({
          'type': 'object_tracking',
          'timeLimit': 90,
          'levels': [
            {'targets': 2, 'distractors': 4, 'speed': 100, 'duration': 5},
            {'targets': 3, 'distractors': 5, 'speed': 150, 'duration': 7},
            {'targets': 4, 'distractors': 6, 'speed': 200, 'duration': 10}
          ]
        }),
        isLocked: const Value(true),
        requiredScore: const Value(300),
      )
    ];

    for (final puzzle in puzzlesList) {
      await into(puzzles).insert(puzzle);
    }
  }

  Future<void> _seedAchievements() async {
    final achievementsList = [
      AchievementsCompanion.insert(
        name: 'First Steps',
        description: 'Complete your first puzzle',
        iconName: 'stars',
        type: 'completion',
        requirement: 1,
      ),
      AchievementsCompanion.insert(
        name: 'Quick Thinker',
        description: 'Solve a puzzle in under 1 minute',
        iconName: 'timer',
        type: 'time',
        requirement: 60,
      ),
      AchievementsCompanion.insert(
        name: 'Perfect Score',
        description: 'Get maximum points in any puzzle',
        iconName: 'grade',
        type: 'score',
        requirement: 1000,
      ),
      AchievementsCompanion.insert(
        name: 'Category Master',
        description: 'Complete all puzzles in a category',
        iconName: 'workspace_premium',
        type: 'category',
        requirement: 1,
      ),
    ];

    for (final achievement in achievementsList) {
      await into(achievements).insert(achievement);
    }
  }

  Future<void> _seedSettings() async {
    final settingsList = [
      SettingsCompanion.insert(
        key: 'sound_enabled',
        value: 'true',
      ),
      SettingsCompanion.insert(
        key: 'music_enabled',
        value: 'true',
      ),
      SettingsCompanion.insert(
        key: 'vibration_enabled',
        value: 'true',
      ),
      SettingsCompanion.insert(
        key: 'difficulty',
        value: 'normal',
      ),
      SettingsCompanion.insert(
        key: 'theme_mode',
        value: 'system',
      ),
    ];

    for (final setting in settingsList) {
      await into(settings).insert(setting);
    }
  }
}

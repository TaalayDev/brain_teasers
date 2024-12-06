import 'package:brain_teasers/components/game_container.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flame/game.dart' show FlameGame, GameWidget;
import 'dart:convert';

import '../games/balance_ball_flame.dart';
import '../games/card_match.dart' show CardMatchGame;
import '../games/chain_reaction.dart';
import '../games/change_blindness.dart';
import '../games/equation_builder.dart';
import '../games/flow_connection.dart';
import '../games/gravity_flow.dart';
import '../games/pendulum_puzzle.dart';
import '../games/pic_slide.dart';
import '../games/logic_gates.dart';
import '../games/multiple_object_tracking.dart';
import '../games/number_grid.dart';
import '../games/numeric_symphony.dart';
import '../games/pattern_mirror.dart';
import '../games/pattern_recall.dart';
import '../games/pattern_sequence.dart';
import '../games/shape_shadows_flame.dart';
import '../games/spot_the_difference.dart';
import '../games/symbol_sequence.dart';
import '../games/visual_search.dart';
import '../games/word_chain.dart';
import '../games/word_search.dart';
import '../providers/common.dart';
import '../theme/app_theme.dart';
import '../db/database.dart';
import 'package:brain_teasers/games/bridge_builder.dart';
import 'package:brain_teasers/games/circuit_flow.dart';
import 'package:brain_teasers/games/circuit_path.dart';
import 'package:brain_teasers/games/color_harmony.dart';

// Providers
final puzzleProvider = FutureProvider.family<Puzzle, String>((ref, id) async {
  final database = ref.watch(databaseProvider);
  return database.getPuzzleById(int.parse(id));
});

final puzzleProgressProvider =
    FutureProvider.family<UserProgressData?, String>((ref, id) async {
  final database = ref.watch(databaseProvider);
  return database.getProgressForPuzzle(int.parse(id));
});

class PuzzleScreen extends ConsumerStatefulWidget {
  final String puzzleId;

  const PuzzleScreen({
    super.key,
    required this.puzzleId,
  });

  @override
  ConsumerState<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends ConsumerState<PuzzleScreen> {
  late final ValueNotifier<int> _score;
  late final ValueNotifier<int> _timeSpent;
  late final ValueNotifier<bool> _isPaused;
  late final ValueNotifier<bool> _isComplete;

  @override
  void initState() {
    super.initState();
    _score = ValueNotifier(0);
    _timeSpent = ValueNotifier(0);
    _isPaused = ValueNotifier(false);
    _isComplete = ValueNotifier(false);
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!_isPaused.value && !_isComplete.value && mounted) {
        _timeSpent.value++;
        _startTimer();
      }
    });
  }

  @override
  void dispose() {
    _score.dispose();
    _timeSpent.dispose();
    _isPaused.dispose();
    _isComplete.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Consumer(
          builder: (context, ref, child) {
            final puzzleAsync = ref.watch(puzzleProvider(widget.puzzleId));
            final progressAsync =
                ref.watch(puzzleProgressProvider(widget.puzzleId));

            return puzzleAsync.when(
              data: (puzzle) => _buildPuzzleContent(
                context,
                puzzle,
                progressAsync,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(context, error),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPuzzleContent(
    BuildContext context,
    Puzzle puzzle,
    AsyncValue<UserProgressData?> progressAsync,
  ) {
    return Stack(
      children: [
        // Main puzzle area
        Column(
          children: [
            _buildTopBar(context, puzzle),
            Expanded(
              child: _buildPuzzleGame(context, puzzle),
            ),
          ],
        ),

        // Pause overlay
        ValueListenableBuilder<bool>(
          valueListenable: _isPaused,
          builder: (context, isPaused, child) {
            if (!isPaused) return const SizedBox.shrink();
            return _buildPauseOverlay(context);
          },
        ),

        // Completion overlay
        ValueListenableBuilder<bool>(
          valueListenable: _isComplete,
          builder: (context, isComplete, child) {
            if (!isComplete) return const SizedBox.shrink();
            return _buildCompletionOverlay(context);
          },
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, Puzzle puzzle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: -10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  puzzle.name,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Difficulty: ${puzzle.difficulty}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.difficultyColors[puzzle.difficulty],
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => _isPaused.value = true,
            icon: const Icon(Icons.pause),
            label: const Text('Pause'),
            style: TextButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.help_outline),
            style: TextButton.styleFrom(
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzleGame(BuildContext context, Puzzle puzzle) {
    final gameData = jsonDecode(puzzle.gameData);

    switch (gameData['type']) {
      case 'pattern_sequence':
        return _buildPatternSequence(context, gameData);
      case 'logic_gates':
        return _buildLogicGates(context, gameData);
      case 'card_match':
        return _buildCardMatch(context, gameData);
      case 'pattern_recall':
        return _buildPatternRecall(context, gameData);
      case 'balance_ball':
        return _buildBalanceBall(context, gameData);
      case 'word_search':
        return _buildWordSearch(context, gameData);
      case 'number_grid':
        return _buildNumberGrid(context, gameData);
      case 'gravity_flow':
        return GameWidget(
          backgroundBuilder: (context) => const GameContainer(),
          game: GravityFlowGame(
            gameData: gameData,
            onScoreUpdate: (score) {
              _score.value = score;
            },
            onComplete: () {
              _isComplete.value = true;

              final database = ref.read(databaseProvider);
              database.updateProgress(
                UserProgressCompanion.insert(
                  puzzleId: int.parse(widget.puzzleId),
                  score: Value(_score.value),
                  timeSpentSeconds: Value(_timeSpent.value),
                  isCompleted: const Value(true),
                  lastPlayedAt: Value(DateTime.now()),
                ),
              );
            },
          ),
        );
      case 'pendulum_puzzle':
        return GameWidget(
          backgroundBuilder: (context) => const GameContainer(),
          game: PendulumPuzzleGame(
            gameData: gameData,
            onScoreUpdate: (score) {
              _score.value = score;
            },
            onComplete: () {
              _isComplete.value = true;
              final database = ref.read(databaseProvider);
              database.updateProgress(
                UserProgressCompanion.insert(
                  puzzleId: int.parse(widget.puzzleId),
                  score: Value(_score.value),
                  timeSpentSeconds: Value(_timeSpent.value),
                  isCompleted: const Value(true),
                  lastPlayedAt: Value(DateTime.now()),
                ),
              );
            },
          ),
        );
      case 'word_chain':
        return WordChainGame(
          gameData: {
            'start': gameData['start'],
            'end': gameData['end'],
          },
          onScoreUpdate: (score) {
            _score.value = score;
          },
          onComplete: () {
            _isComplete.value = true;

            final database = ref.read(databaseProvider);
            database.updateProgress(
              UserProgressCompanion.insert(
                puzzleId: int.parse(widget.puzzleId),
                score: Value(_score.value),
                timeSpentSeconds: Value(_timeSpent.value),
                isCompleted: const Value(true),
                lastPlayedAt: Value(DateTime.now()),
                hintsUsed: const Value(0),
              ),
            );
          },
        );
      case 'equation_builder':
        return EquationBuilderGame(
          gameData: {
            'numbers': gameData['numbers'],
            'target': gameData['target'],
          },
          onScoreUpdate: (score) {
            _score.value = score;
          },
          onComplete: () {
            _isComplete.value = true;

            final database = ref.read(databaseProvider);
            database.updateProgress(
              UserProgressCompanion.insert(
                puzzleId: int.parse(widget.puzzleId),
                score: Value(_score.value),
                timeSpentSeconds: Value(_timeSpent.value),
                isCompleted: const Value(true),
                lastPlayedAt: Value(DateTime.now()),
                hintsUsed: const Value(0),
              ),
            );
          },
        );
      case 'circuit_flow':
        return CircuitFlowGame(
          gameData: gameData,
          onScoreUpdate: (score) {
            _score.value = score;
          },
          onComplete: () {
            _isComplete.value = true;

            final database = ref.read(databaseProvider);
            database.updateProgress(
              UserProgressCompanion.insert(
                puzzleId: int.parse(widget.puzzleId),
                score: Value(_score.value),
                timeSpentSeconds: Value(_timeSpent.value),
                isCompleted: const Value(true),
                lastPlayedAt: Value(DateTime.now()),
                hintsUsed: const Value(0),
              ),
            );
          },
        );
      case 'numeric_symphony':
        return NumericSymphonyGame(
          gameData: gameData,
          onScoreUpdate: (score) {
            _score.value = score;
          },
          onComplete: () {
            _isComplete.value = true;
            final database = ref.read(databaseProvider);
            database.updateProgress(
              UserProgressCompanion.insert(
                puzzleId: int.parse(widget.puzzleId),
                score: Value(_score.value),
                timeSpentSeconds: Value(_timeSpent.value),
                isCompleted: const Value(true),
                lastPlayedAt: Value(DateTime.now()),
                hintsUsed: const Value(0),
              ),
            );
          },
        );
      case 'symbol_sequence':
        return SymbolSequenceGame(
          gameData: gameData,
          onScoreUpdate: (score) {
            _score.value = score;
          },
          onComplete: () {
            _isComplete.value = true;

            final database = ref.read(databaseProvider);
            database.updateProgress(
              UserProgressCompanion.insert(
                puzzleId: int.parse(widget.puzzleId),
                score: Value(_score.value),
                timeSpentSeconds: Value(_timeSpent.value),
                isCompleted: const Value(true),
                lastPlayedAt: Value(DateTime.now()),
                hintsUsed: const Value(1),
              ),
            );
          },
        );
      case 'color_harmony':
        return ColorHarmonyGame(
          gameData: gameData,
          onScoreUpdate: (score) {},
          onComplete: () {},
        );
      case 'shape_shadows':
        return GameWidget(
            game: FlameGame(
          world: ShapeShadowsGame(
            gameData: gameData,
            onScoreUpdate: (score) {
              _score.value = score;
            },
            onComplete: () {
              _isComplete.value = true;
              // Save progress
              final database = ref.read(databaseProvider);
              database.updateProgress(
                UserProgressCompanion.insert(
                  puzzleId: int.parse(widget.puzzleId),
                  score: Value(_score.value),
                  timeSpentSeconds: Value(_timeSpent.value),
                  isCompleted: const Value(true),
                  lastPlayedAt: Value(DateTime.now()),
                  hintsUsed: const Value(0),
                ),
              );
            },
          ),
        ));
      case 'pattern_mirror':
        return PatternMirrorGame(
          gameData: gameData,
          onScoreUpdate: (score) {
            _score.value = score;
          },
          onComplete: () {
            _isComplete.value = true;
            final database = ref.read(databaseProvider);
            database.updateProgress(
              UserProgressCompanion.insert(
                puzzleId: int.parse(widget.puzzleId),
                score: Value(_score.value),
                timeSpentSeconds: Value(_timeSpent.value),
                isCompleted: const Value(true),
                lastPlayedAt: Value(DateTime.now()),
                hintsUsed: const Value(0),
              ),
            );
          },
        );
      case 'spot_difference':
        return SpotDifferenceGame(
          gameData: gameData,
          onScoreUpdate: (score) {
            _score.value = score;
          },
          onComplete: () {
            _isComplete.value = true;
            final database = ref.read(databaseProvider);
            database.updateProgress(
              UserProgressCompanion.insert(
                puzzleId: int.parse(widget.puzzleId),
                score: Value(_score.value),
                timeSpentSeconds: Value(_timeSpent.value),
                isCompleted: const Value(true),
                lastPlayedAt: Value(DateTime.now()),
                hintsUsed: const Value(0),
              ),
            );
          },
        );
      case 'change_blindness':
        return ChangeBlindnessGame(
          gameData: gameData,
          onScoreUpdate: (score) {
            _score.value = score;
          },
          onComplete: () {
            _isComplete.value = true;
            final database = ref.read(databaseProvider);
            database.updateProgress(
              UserProgressCompanion.insert(
                puzzleId: int.parse(widget.puzzleId),
                score: Value(_score.value),
                timeSpentSeconds: Value(_timeSpent.value),
                isCompleted: const Value(true),
                lastPlayedAt: Value(DateTime.now()),
                hintsUsed: const Value(0),
              ),
            );
          },
        );
      case 'visual_search':
        return VisualSearchGame(
          gameData: gameData,
          onScoreUpdate: (score) {
            _score.value = score;
          },
          onComplete: () {
            _isComplete.value = true;
            final database = ref.read(databaseProvider);
            database.updateProgress(
              UserProgressCompanion.insert(
                puzzleId: int.parse(widget.puzzleId),
                score: Value(_score.value),
                timeSpentSeconds: Value(_timeSpent.value),
                isCompleted: const Value(true),
                lastPlayedAt: Value(DateTime.now()),
                hintsUsed: const Value(0),
              ),
            );
          },
        );
      case 'object_tracking':
        return GameWidget(
          backgroundBuilder: (context) => const GameContainer(),
          game: MultipleObjectTrackingGame(
            gameData: gameData,
            onScoreUpdate: (score) {
              _score.value = score;
            },
            onComplete: () {
              _isComplete.value = true;
              final database = ref.read(databaseProvider);
              database.updateProgress(
                UserProgressCompanion.insert(
                  puzzleId: int.parse(widget.puzzleId),
                  score: Value(_score.value),
                  timeSpentSeconds: Value(_timeSpent.value),
                  isCompleted: const Value(true),
                  lastPlayedAt: Value(DateTime.now()),
                  hintsUsed: const Value(0),
                ),
              );
            },
          ),
        );
      case 'circuit_path':
        return FlowConnectGame(
          gameData: gameData,
          onScoreUpdate: (score) {
            _score.value = score;
          },
          onComplete: () {
            _isComplete.value = true;
            final database = ref.read(databaseProvider);
            database.updateProgress(
              UserProgressCompanion.insert(
                puzzleId: int.parse(widget.puzzleId),
                score: Value(_score.value),
                timeSpentSeconds: Value(_timeSpent.value),
                isCompleted: const Value(true),
                lastPlayedAt: Value(DateTime.now()),
                hintsUsed: const Value(0),
              ),
            );
          },
        );
      case 'pic_slide':
        return PicSlideGame(
          gameData: gameData,
          image: Image.asset('assets/images/cat.jpg'),
          onScoreUpdate: (score) {
            _score.value = score;
          },
          onComplete: () {
            _isComplete.value = true;
            final database = ref.read(databaseProvider);
            database.updateProgress(
              UserProgressCompanion.insert(
                puzzleId: int.parse(widget.puzzleId),
                score: Value(_score.value),
                timeSpentSeconds: Value(_timeSpent.value),
                isCompleted: const Value(true),
                lastPlayedAt: Value(DateTime.now()),
                hintsUsed: const Value(0),
              ),
            );
          },
        );
      default:
        return Center(
          child: Text(
            'Unsupported puzzle type: ${gameData['type']}',
            style: GoogleFonts.poppins(fontSize: 16),
          ),
        );
    }
  }

  Widget _buildPauseOverlay(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
            width: 250,
            height: 240,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Paused',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _isPaused.value = false,
                  child: const Text('Resume'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Quit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionOverlay(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.stars,
                  size: 64,
                  color: AppTheme.accentColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Puzzle Complete!',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<int>(
                  valueListenable: _score,
                  builder: (context, score, child) => Text(
                    'Score: $score',
                    style: GoogleFonts.poppins(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Reset and replay
                        _score.value = 0;
                        _timeSpent.value = 0;
                        _isComplete.value = false;
                        _startTimer();
                      },
                      child: const Text('Play Again'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Exit'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.wrongAnswerColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading puzzle',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: GoogleFonts.poppins(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  // Puzzle type specific builders
  Widget _buildPatternSequence(
    BuildContext context,
    Map<String, dynamic> gameData,
  ) {
    // Implementation for pattern sequence puzzle
    return PatternSequenceGame(
      sequences: List<List<dynamic>>.from(gameData['sequences']),
      onScoreUpdate: (score) {
        _score.value = score;
      },
      onComplete: () {
        _isComplete.value = true;
        // Save progress to database
        final database = ref.read(databaseProvider);
        database.updateProgress(
          UserProgressCompanion.insert(
            puzzleId: int.parse(widget.puzzleId),
            score: Value(_score.value),
            timeSpentSeconds: Value(_timeSpent.value),
            isCompleted: const Value(true),
            lastPlayedAt: Value(DateTime.now()),
          ),
        );
      },
    );
  }

  Widget _buildLogicGates(BuildContext context, Map<String, dynamic> gameData) {
    return GameWidget(
      game: GravityFlowGame(
        gameData: {
          'gravity': 91.81, // Adjust gravity strength
        },
        onScoreUpdate: (score) {
          _score.value = score;
        },
        onComplete: () {
          _isComplete.value = true;
        },
      ),
    );
  }

  Widget _buildCardMatch(BuildContext context, Map<String, dynamic> gameData) {
    return CardMatchGame(
      gameData: gameData,
      onScoreUpdate: (score) {
        _score.value = score;
      },
      onComplete: () {
        _isComplete.value = true;
        // Save progress to database
        final database = ref.read(databaseProvider);
        database.updateProgress(
          UserProgressCompanion.insert(
            puzzleId: int.parse(widget.puzzleId),
            score: Value(_score.value),
            timeSpentSeconds: Value(_timeSpent.value),
            isCompleted: const Value(true),
            lastPlayedAt: Value(DateTime.now()),
          ),
        );
      },
    );
  }

  Widget _buildPatternRecall(
    BuildContext context,
    Map<String, dynamic> gameData,
  ) {
    return PatternRecallGame(
      gameData: gameData,
      onScoreUpdate: (score) {
        _score.value = score;
      },
      onComplete: () {
        _isComplete.value = true;
        // Save progress to database
        final database = ref.read(databaseProvider);
        database.updateProgress(
          UserProgressCompanion.insert(
            puzzleId: int.parse(widget.puzzleId),
            score: Value(_score.value),
            timeSpentSeconds: Value(_timeSpent.value),
            isCompleted: const Value(true),
            lastPlayedAt: Value(DateTime.now()),
          ),
        );
      },
    );
  }

  Widget _buildBalanceBall(
    BuildContext context,
    Map<String, dynamic> gameData,
  ) {
    // return BalanceBallGame(
    //   gameData: gameData,
    //   onScoreUpdate: (score) {
    //     _score.value = score;
    //   },
    //   onComplete: () {
    //     _isComplete.value = true;
    //     // Save progress to database
    //     final database = ref.read(databaseProvider);
    //     database.updateProgress(
    //       UserProgressCompanion.insert(
    //         puzzleId: int.parse(widget.puzzleId),
    //         score: Value(_score.value),
    //         timeSpentSeconds: Value(_timeSpent.value),
    //         isCompleted: const Value(true),
    //         lastPlayedAt: Value(DateTime.now()),
    //       ),
    //     );
    //   },
    // );
    return GameWidget(
      backgroundBuilder: (context) => const GameContainer(),
      game: BalanceBallGame(
        gameData: gameData,
        onScoreUpdate: (score) {
          //_score.value = score;
        },
        onComplete: () {
          _isComplete.value = true;
          // Save progress to database
          final database = ref.read(databaseProvider);
          database.updateProgress(
            UserProgressCompanion.insert(
              puzzleId: int.parse(widget.puzzleId),
              score: Value(_score.value),
              timeSpentSeconds: Value(_timeSpent.value),
              isCompleted: const Value(true),
              lastPlayedAt: Value(DateTime.now()),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWordSearch(BuildContext context, Map<String, dynamic> gameData) {
    return WordSearchGame(
      gameData: {
        'gridSize': gameData['gridSize'],
        'words': gameData['words'],
      },
      onScoreUpdate: (score) {
        _score.value = score;
      },
      onComplete: () {
        _isComplete.value = true;
        final database = ref.read(databaseProvider);
        database.updateProgress(
          UserProgressCompanion.insert(
            puzzleId: int.parse(widget.puzzleId),
            score: Value(_score.value),
            timeSpentSeconds: Value(_timeSpent.value),
            isCompleted: const Value(true),
            lastPlayedAt: Value(DateTime.now()),
          ),
        );
      },
    );
  }

  Widget _buildNumberGrid(BuildContext context, Map<String, dynamic> gameData) {
    return NumberGridGame(
      gameData: {
        'gridSize': gameData['gridSize'],
        'target': gameData['target'],
      },
      onScoreUpdate: (score) {
        _score.value = score;
      },
      onComplete: () {
        _isComplete.value = true;
        // Save progress...
      },
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

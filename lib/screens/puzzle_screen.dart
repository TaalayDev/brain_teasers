import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flame/game.dart' show FlameGame, GameWidget;
import 'dart:convert';

import '../games/game_controller.dart';
import '../games/balance_ball_flame.dart';
import '../games/card_match.dart' show CardMatchGame;
import '../games/change_blindness.dart';
import '../games/equation_builder.dart';
import '../games/flow_connection.dart';
import '../games/gravity_flow.dart';
import '../games/pendulum_puzzle.dart';
import '../games/pic_slide.dart';
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
import '../components/game_container.dart';
import '../games/circuit_flow.dart';
import '../games/color_harmony.dart';

typedef PuzzleRec = ({
  Puzzle puzzle,
  UserProgressData? progress,
});

// Providers
final puzzleProvider =
    FutureProvider.family<PuzzleRec, String>((ref, id) async {
  final database = ref.read(databaseProvider);
  final puzzle = await database.getPuzzleById(int.parse(id));
  final progress = await ref.read(puzzleProgressProvider(id).future);

  return (
    puzzle: puzzle,
    progress: progress,
  );
});

final puzzleProgressProvider =
    FutureProvider.family<UserProgressData?, String>((ref, id) {
  final database = ref.read(databaseProvider);
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
  late GameController _gameController;

  @override
  void initState() {
    super.initState();
  }

  void _updateProgress() {
    final isCompete = _gameController.isComplete;
    final timeSpent = _gameController.timeSpent;
    final score = _gameController.score;
    final level = _gameController.currentLevel;

    final database = ref.read(databaseProvider);
    database.updateProgress(
      UserProgressCompanion.insert(
        puzzleId: int.parse(widget.puzzleId),
        score: Value(score),
        timeSpentSeconds: Value(timeSpent),
        isCompleted: Value(isCompete),
        level: Value(level),
        lastPlayedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _gameController = ref.watch(gameControllerProvider(
      GameControllerParams(
        onScoreUpdate: (score) {
          _updateProgress();
        },
        onComplete: () {
          _updateProgress();
        },
        onLevelComplete: (level) {
          _updateProgress();
        },
        onStateChange: (state) {},
      ),
    ));
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Consumer(
          builder: (context, ref, child) {
            final puzzleAsync = ref.watch(puzzleProvider(widget.puzzleId));

            return puzzleAsync.when(
              data: (rec) => _buildPuzzleContent(
                context,
                rec.puzzle,
                rec.progress,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(
                context,
                error,
                stack,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPuzzleContent(
    BuildContext context,
    Puzzle puzzle,
    UserProgressData? progress,
  ) {
    return Stack(
      children: [
        // Main puzzle area
        Column(
          children: [
            _buildTopBar(context, puzzle),
            Expanded(
              child: _buildPuzzleGame(context, puzzle, progress),
            ),
          ],
        ),

        // Pause overlay
        if (!_gameController.isPaused)
          const SizedBox.shrink()
        else
          _buildPauseOverlay(context),

        // Completion overlay
        if (!_gameController.isComplete)
          const SizedBox.shrink()
        else
          _buildCompletionOverlay(context),
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
            onPressed: _gameController.pauseGame,
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

  Widget _buildPuzzleGame(
    BuildContext context,
    Puzzle puzzle,
    UserProgressData? progress,
  ) {
    final gameData = jsonDecode(puzzle.gameData);
    gameData['level'] = progress?.level;

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
            gameController: _gameController,
          ),
        );
      case 'pendulum_puzzle':
        return GameWidget(
          backgroundBuilder: (context) => const GameContainer(),
          game: PendulumPuzzleGame(
            gameData: gameData,
            gameController: _gameController,
          ),
        );
      case 'word_chain':
        return WordChainGame(
          gameData: {
            'start': gameData['start'],
            'end': gameData['end'],
          },
          gameController: _gameController,
        );
      case 'equation_builder':
        return EquationBuilderGame(
          gameData: {
            'numbers': gameData['numbers'],
            'target': gameData['target'],
          },
          gameController: _gameController,
        );
      case 'circuit_flow':
        return CircuitFlowGame(
          gameData: gameData,
          gameController: _gameController,
        );
      case 'numeric_symphony':
        return NumericSymphonyGame(
          gameData: gameData,
          gameController: _gameController,
        );
      case 'symbol_sequence':
        return SymbolSequenceGame(
          gameData: gameData,
          gameController: _gameController,
        );
      case 'color_harmony':
        return ColorHarmonyGame(
          gameData: gameData,
          gameController: _gameController,
        );
      case 'shape_shadows':
        return GameWidget(
          game: FlameGame(
            world: ShapeShadowsGame(
              gameData: gameData,
              gameController: _gameController,
            ),
          ),
        );
      case 'pattern_mirror':
        return PatternMirrorGame(
          gameData: gameData,
          gameController: _gameController,
        );
      case 'spot_difference':
        return SpotDifferenceGame(
          gameData: gameData,
          gameController: _gameController,
        );
      case 'change_blindness':
        return ChangeBlindnessGame(
          gameData: gameData,
          gameController: _gameController,
        );
      case 'visual_search':
        return VisualSearchGame(
          gameData: gameData,
          gameController: _gameController,
        );
      case 'object_tracking':
        return GameWidget(
          backgroundBuilder: (context) => const GameContainer(),
          game: MultipleObjectTrackingGame(
            gameData: gameData,
            gameController: _gameController,
          ),
        );
      case 'flow_connect':
        return FlowConnectGame(
          gameData: gameData,
          gameController: _gameController,
        );
      case 'pic_slider':
        return PicSlideGame(
          gameData: gameData,
          image: Image.asset('assets/images/cat.jpg'),
          gameController: _gameController,
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
                  onPressed: () {
                    _gameController.resumeGame();
                  },
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
                Text(
                  'Score: ${_gameController.score}',
                  style: GoogleFonts.poppins(fontSize: 18),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Reset and replay
                        _gameController.restartGame();
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

  Widget _buildErrorState(
    BuildContext context,
    Object error,
    StackTrace stack,
  ) {
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
          const SizedBox(height: 8),
          Text(
            stack.toString(),
            style: GoogleFonts.poppins(fontSize: 12),
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
    return PatternSequenceGame(
      gameData: gameData,
      gameController: _gameController,
    );
  }

  Widget _buildLogicGates(BuildContext context, Map<String, dynamic> gameData) {
    return GameWidget(
      game: GravityFlowGame(
        gameData: {
          'gravity': 91.81,
        },
        gameController: _gameController,
      ),
    );
  }

  Widget _buildCardMatch(BuildContext context, Map<String, dynamic> gameData) {
    return CardMatchGame(
      gameData: gameData,
      gameController: _gameController,
    );
  }

  Widget _buildPatternRecall(
    BuildContext context,
    Map<String, dynamic> gameData,
  ) {
    return PatternRecallGame(
      gameData: gameData,
      gameController: _gameController,
    );
  }

  Widget _buildBalanceBall(
    BuildContext context,
    Map<String, dynamic> gameData,
  ) {
    return GameWidget(
      backgroundBuilder: (context) => const GameContainer(),
      game: BalanceBallGame(
        gameData: gameData,
        gameController: _gameController,
      ),
    );
  }

  Widget _buildWordSearch(BuildContext context, Map<String, dynamic> gameData) {
    return WordSearchGame(
      gameData: {
        'gridSize': gameData['gridSize'],
        'words': gameData['words'],
      },
      gameController: _gameController,
    );
  }

  Widget _buildNumberGrid(BuildContext context, Map<String, dynamic> gameData) {
    return NumberGridGame(
      gameData: {
        'gridSize': gameData['gridSize'],
        'target': gameData['target'],
      },
      gameController: _gameController,
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

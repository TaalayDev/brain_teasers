import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../ui/components/game_container.dart';
import '../ui/theme/app_theme.dart';
import 'controller/game_controller.dart';

class PatternMirrorGame extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final GameController gameController;

  const PatternMirrorGame({
    super.key,
    required this.gameData,
    required this.gameController,
  });

  @override
  State<PatternMirrorGame> createState() => _PatternMirrorGameState();
}

class _PatternMirrorGameState extends State<PatternMirrorGame> {
  late List<List<List<int>>> _patterns;
  late List<String> _symmetryTypes;
  late int _currentLevel;
  late List<List<int>> _currentPattern;
  late List<List<int>> _playerPattern;
  late bool _showFeedback;
  late bool _isCorrect;
  late bool _isTimerRunning;
  late int _hintsRemaining;
  late bool _isShowingHint;
  bool _showTutorial = true;

  @override
  void initState() {
    super.initState();
    _initializeGame();

    // Start game with controller
    widget.gameController.startGame(
      timeLimit: widget.gameData['timeLimit'] ?? 240,
      maxLevels: _patterns.length,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorialDialog();
    });
  }

  void _initializeGame() {
    _patterns =
        (widget.gameData['patterns'] as List).map<List<List<int>>>((pattern) {
      return (pattern['grid'] as List).map<List<int>>((row) {
        return List<int>.from(row.map((e) => e ?? -1));
      }).toList();
    }).toList();

    _symmetryTypes =
        (widget.gameData['patterns'] as List).map<String>((pattern) {
      return pattern['symmetryType'] as String;
    }).toList();

    _currentLevel = 0;
    _currentPattern = List.from(_patterns[_currentLevel]);
    _playerPattern = List.from(_patterns[_currentLevel]);
    _showFeedback = false;
    _isCorrect = false;
    _isTimerRunning = true;
    _hintsRemaining = 3;
    _isShowingHint = false;
  }

  void _useHint() {
    if (_hintsRemaining <= 0) return;

    setState(() {
      _hintsRemaining--;
      _isShowingHint = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isShowingHint = false;
        });
      }
    });
  }

  void _onTileTap(int row, int col) {
    if (_showFeedback || !_isEditableTile(row, col)) return;

    setState(() {
      _playerPattern[row][col] = _playerPattern[row][col] == 0 ? 1 : 0;
    });
  }

  bool _isEditableTile(int row, int col) {
    final symmetryType = _symmetryTypes[_currentLevel];
    final gridSize = _currentPattern.length;

    switch (symmetryType) {
      case 'vertical':
        return col >= gridSize ~/ 2;
      case 'horizontal':
        return row >= gridSize ~/ 2;
      case 'diagonal':
        return row > col;
      default:
        return false;
    }
  }

  void _checkPattern() {
    if (_showFeedback) return;

    final symmetryType = _symmetryTypes[_currentLevel];
    final gridSize = _currentPattern.length;
    bool isCorrect = true;

    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        if (_isEditableTile(i, j)) {
          int mirrorValue = _getMirrorValue(i, j, symmetryType, gridSize);
          if (_playerPattern[i][j] != mirrorValue) {
            isCorrect = false;
            break;
          }
        }
      }
      if (!isCorrect) break;
    }

    setState(() {
      _showFeedback = true;
      _isCorrect = isCorrect;
    });

    if (isCorrect) {
      _handleSuccess();
    } else {
      _showFailureEffect();
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _showFeedback = false;
          });
        }
      });
    }
  }

  void _handleSuccess() {
    final timeBonus = widget.gameController.timeRemaining * 5;
    final levelBonus = (_currentLevel + 1) * 100;
    final score = 1000 + timeBonus + levelBonus;

    widget.gameController.updateScore(widget.gameController.score + score);
    _showSuccessMessage(score);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showFeedback = false;
          if (_currentLevel < _patterns.length - 1) {
            _currentLevel++;
            _currentPattern = List.from(_patterns[_currentLevel]);
            _playerPattern = List.from(_patterns[_currentLevel]);
            widget.gameController.nextLevel();
          } else {
            _isTimerRunning = false;
            widget.gameController.completeGame();
          }
        });
      }
    });
  }

  void _showSuccessMessage(int points) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Pattern Complete! +$points points',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.correctAnswerColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showFailureEffect() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Not quite right. Try again!',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.wrongAnswerColor,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  int _getMirrorValue(int row, int col, String symmetryType, int gridSize) {
    switch (symmetryType) {
      case 'vertical':
        return _playerPattern[row][gridSize - 1 - col];
      case 'horizontal':
        return _playerPattern[gridSize - 1 - row][col];
      case 'diagonal':
        return _playerPattern[col][row];
      default:
        return 0;
    }
  }

  void _showTutorialDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'How to Play Pattern Mirror',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Each puzzle has a symmetry type: vertical, horizontal, or diagonal',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 8),
            Text(
              '2. You can only edit tiles on one side of the pattern',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 8),
            Text(
              '3. Tap editable tiles to flip them (black or white)',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 8),
            Text(
              '4. Create a symmetrical pattern matching the symmetry type',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 8),
            Text(
              '5. Press "Check Pattern" when you think it\'s correct',
              style: GoogleFonts.poppins(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _showTutorial = false;
              });
            },
            child: Text(
              'Got it!',
              style: GoogleFonts.poppins(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameContainer(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildGrid(),
          ),
          _buildControls(),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLevelInfo(),
              Row(
                children: [
                  _buildScoreDisplay(),
                  const SizedBox(width: 12),
                  _buildTimeDisplay(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildLevelInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    'Level ${_currentLevel + 1}/${_patterns.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Symmetry: ${_symmetryTypes[_currentLevel]}',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreDisplay() {
    return AnimatedBuilder(
      animation: widget.gameController,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.stars, color: AppTheme.accentColor, size: 16),
              const SizedBox(width: 4),
              Text(
                widget.gameController.score.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeDisplay() {
    return AnimatedBuilder(
      animation: widget.gameController,
      builder: (context, _) {
        final minutes = (widget.gameController.timeRemaining ~/ 60)
            .toString()
            .padLeft(2, '0');
        final seconds = (widget.gameController.timeRemaining % 60)
            .toString()
            .padLeft(2, '0');

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                '$minutes:$seconds',
                style: GoogleFonts.poppins(
                  fontSize: 14,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: (_currentLevel + 1) / _patterns.length,
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        minHeight: 6,
      ),
    );
  }

  Widget _buildGrid() {
    final gridSize = _currentPattern.length;

    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _getSymmetryInstructions(),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridSize,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                    ),
                    itemCount: gridSize * gridSize,
                    itemBuilder: (context, index) {
                      final row = index ~/ gridSize;
                      final col = index % gridSize;
                      return _buildTile(row, col);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isShowingHint) _buildHintOverlay(),
      ],
    );
  }

  String _getSymmetryInstructions() {
    switch (_symmetryTypes[_currentLevel]) {
      case 'vertical':
        return 'Create a pattern with vertical symmetry\nEdit tiles on the right side';
      case 'horizontal':
        return 'Create a pattern with horizontal symmetry\nEdit tiles on the bottom half';
      case 'diagonal':
        return 'Create a pattern with diagonal symmetry\nEdit tiles below the diagonal';
      default:
        return 'Create a symmetrical pattern';
    }
  }

  Widget _buildTile(int row, int col) {
    final isEditable = _isEditableTile(row, col);
    final isActive = _playerPattern[row][col] == 1;

    return GestureDetector(
      onTap: () => _onTileTap(row, col),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isEditable
                ? AppTheme.accentColor
                : Colors.grey.withOpacity(0.2),
            width: isEditable ? 2 : 1,
          ),
        ),
        child: isEditable
            ? Center(
                child: Icon(
                  Icons.edit,
                  size: 16,
                  color: isActive
                      ? Colors.white.withOpacity(0.5)
                      : Colors.black.withOpacity(0.2),
                ),
              )
            : null,
      ),
    ).animate(
      effects: [
        if (_showFeedback && isEditable)
          ShakeEffect(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          ),
      ],
    );
  }

  Widget _buildHintOverlay() {
    final symmetryType = _symmetryTypes[_currentLevel];
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lightbulb, color: Colors.amber, size: 48),
            const SizedBox(height: 16),
            Text(
              _getHintText(symmetryType),
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ).animate().fadeIn().scale(),
    );
  }

  String _getHintText(String symmetryType) {
    switch (symmetryType) {
      case 'vertical':
        return 'With vertical symmetry, imagine folding the grid down the middle.\n\nWhat you draw on the right should mirror on the left, like looking in a mirror.';
      case 'horizontal':
        return 'With horizontal symmetry, imagine folding the grid across the middle.\n\nWhat you draw on the bottom should mirror on the top, like a reflection in water.';
      case 'diagonal':
        return 'With diagonal symmetry, imagine folding the grid across the diagonal.\n\nEach tile should mirror across to the opposite side of the diagonal line.';
      default:
        return 'Look for the symmetry pattern and try to complete it.';
    }
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
              child: TextButton.icon(
            onPressed: _hintsRemaining > 0 ? _useHint : null,
            icon: const Icon(Icons.lightbulb_outline),
            label: Text('Hint (${_hintsRemaining})'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.amber,
              backgroundColor: Colors.amber.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _showFeedback ? null : _checkPattern,
              icon: const Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
              ),
              label: Text(
                'Check Pattern',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                foregroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

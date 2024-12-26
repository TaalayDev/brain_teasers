import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/game_container.dart';
import '../theme/app_theme.dart';
import 'game_controller.dart';

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
  late int _score;
  late bool _showFeedback;
  late bool _isCorrect;
  late int _remainingTime;
  late bool _isTimerRunning;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _startTimer();
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
    _score = 0;
    _showFeedback = false;
    _isCorrect = false;
    _remainingTime = widget.gameData['timeLimit'] ?? 240;
    _isTimerRunning = true;
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _isTimerRunning) {
        setState(() {
          _remainingTime--;
          if (_remainingTime <= 0) {
            _handleTimeUp();
          } else {
            _startTimer();
          }
        });
      }
    });
  }

  void _handleTimeUp() {
    _isTimerRunning = false;
    widget.gameController.completeGame();
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
      _score += (100 * (_remainingTime / widget.gameData['timeLimit'])).round();
      widget.gameController.updateScore(_score);

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showFeedback = false;
            if (_currentLevel < _patterns.length - 1) {
              _currentLevel++;
              _currentPattern = List.from(_patterns[_currentLevel]);
              _playerPattern = List.from(_patterns[_currentLevel]);
            } else {
              _isTimerRunning = false;
              widget.gameController.completeGame();
            }
          });
        }
      });
    } else {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _showFeedback = false;
          });
        }
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return GameContainer(
      child: Column(
        children: [
          _buildHeader(),
          const Spacer(),
          _buildGrid(),
          const Spacer(),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Level ${_currentLevel + 1}/${_patterns.length}',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              Text(
                'Symmetry: ${_symmetryTypes[_currentLevel]}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.timer, color: AppTheme.accentColor),
              const SizedBox(width: 8),
              Text(
                _formatTime(_remainingTime),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _remainingTime < 30
                      ? AppTheme.wrongAnswerColor
                      : Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    final gridSize = _currentPattern.length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridSize,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            reverse: true,
            itemCount: gridSize * gridSize,
            itemBuilder: (context, index) {
              final row = index ~/ gridSize;
              final col = index % gridSize;
              return _buildTile(row, col);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTile(int row, int col) {
    final isEditable = _isEditableTile(row, col);
    final isActive = _playerPattern[row][col] == 1;

    return GestureDetector(
      onTap: () => _onTileTap(row, col),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: isEditable
            ? Icon(
                Icons.edit,
                size: 16,
                color: isActive
                    ? Colors.white
                    : AppTheme.primaryColor.withOpacity(0.3),
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

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: _showFeedback ? null : _checkPattern,
            icon: const Icon(Icons.check_circle),
            label: Text(
              'Check Pattern',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

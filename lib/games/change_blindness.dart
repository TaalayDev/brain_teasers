import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:async';

import '../theme/app_theme.dart';

class ChangeBlindnessGame extends StatefulWidget {
  final Map<String, dynamic> gameData;
  final Function(int score) onScoreUpdate;
  final VoidCallback onComplete;

  const ChangeBlindnessGame({
    super.key,
    required this.gameData,
    required this.onScoreUpdate,
    required this.onComplete,
  });

  @override
  State<ChangeBlindnessGame> createState() => _ChangeBlindnessGameState();
}

class _ChangeBlindnessGameState extends State<ChangeBlindnessGame> {
  late List<Map<String, dynamic>> _levels;
  late int _currentLevel;
  late List<List<IconData>> _baseGrid;
  late List<List<IconData>> _changedGrid;
  late Set<Point> _changedPositions;
  late Set<Point> _foundChanges;
  late bool _showingBaseGrid;
  Timer? _flashTimer;
  late int _score;
  late int _remainingTime;
  late bool _isTimerRunning;

  final List<IconData> _icons = [
    Icons.star,
    Icons.favorite,
    Icons.circle,
    Icons.square,
    MaterialCommunityIcons.vector_triangle,
    Icons.diamond,
  ];

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _startTimer();
  }

  void _initializeGame() {
    _levels = List<Map<String, dynamic>>.from(widget.gameData['levels']);
    _currentLevel = 0;
    _score = 0;
    _showingBaseGrid = true;
    _foundChanges = {};
    _loadLevel();
  }

  void _loadLevel() {
    final level = _levels[_currentLevel];
    final gridSize = level['gridSize'];
    final changes = level['changes'];
    final flashDuration = level['flashDuration'];

    // Generate base grid
    _baseGrid = List.generate(
      gridSize,
      (_) => List.generate(
        gridSize,
        (_) => _icons[math.Random().nextInt(_icons.length)],
      ),
    );

    // Copy base grid and make changes
    _changedGrid = List.generate(
      gridSize,
      (y) => List.from(_baseGrid[y]),
    );

    // Generate random changes
    _changedPositions = {};
    while (_changedPositions.length < changes) {
      final x = math.Random().nextInt(gridSize);
      final y = math.Random().nextInt(gridSize);
      final point = Point(x, y);
      if (!_changedPositions.contains(point)) {
        _changedPositions.add(point);
        IconData newIcon;
        do {
          newIcon = _icons[math.Random().nextInt(_icons.length)];
        } while (newIcon == _changedGrid[y][x]);
        _changedGrid[y][x] = newIcon;
      }
    }

    _remainingTime = widget.gameData['timeLimit'];
    _isTimerRunning = true;
    _startFlashing(flashDuration);
  }

  void _startFlashing(int duration) {
    _flashTimer?.cancel();
    _flashTimer = Timer.periodic(Duration(milliseconds: duration), (timer) {
      if (mounted && _isTimerRunning) {
        setState(() {
          _showingBaseGrid = !_showingBaseGrid;
        });
      }
    });
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
    _flashTimer?.cancel();
    widget.onComplete();
  }

  void _onTileTap(int x, int y) {
    if (!_isTimerRunning) return;
    final point = Point(x, y);

    setState(() {
      if (_changedPositions.contains(point) && !_foundChanges.contains(point)) {
        _foundChanges.add(point);
        _score += 100;
        widget.onScoreUpdate(_score);

        if (_foundChanges.length == _changedPositions.length) {
          _handleLevelComplete();
        }
      } else if (!_changedPositions.contains(point)) {
        _score = math.max(0, _score - 20);
        widget.onScoreUpdate(_score);
        _showIncorrectFeedback();
      }
    });
  }

  void _handleLevelComplete() {
    _flashTimer?.cancel();
    _isTimerRunning = false;

    if (_currentLevel < _levels.length - 1) {
      _showLevelCompleteFeedback();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _currentLevel++;
            _foundChanges.clear();
            _loadLevel();
          });
        }
      });
    } else {
      widget.onComplete();
    }
  }

  void _showIncorrectFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Try Again! -20 points',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.wrongAnswerColor,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showLevelCompleteFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Level Complete! +100 points',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.correctAnswerColor,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        const Spacer(),
        _buildGrid(),
        const Spacer(),
        _buildInstructions(),
      ],
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
                'Level ${_currentLevel + 1}/${_levels.length}',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Find ${_changedPositions.length - _foundChanges.length} changes',
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
                  color: _remainingTime < 30 ? AppTheme.wrongAnswerColor : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    final gridSize = _levels[_currentLevel]['gridSize'];
    final currentGrid = _showingBaseGrid ? _baseGrid : _changedGrid;

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
            itemCount: gridSize * gridSize,
            itemBuilder: (context, index) {
              final x = (index % gridSize).toInt();
              final y = index ~/ gridSize;
              return _buildTile(x, y, currentGrid[y][x]);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTile(int x, int y, IconData icon) {
    final point = Point(x, y);
    final isFound = _foundChanges.contains(point);

    return GestureDetector(
      onTap: () => _onTileTap(x, y),
      child: Container(
        decoration: BoxDecoration(
          color: isFound
              ? AppTheme.correctAnswerColor.withOpacity(0.2)
              : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isFound
                ? AppTheme.correctAnswerColor
                : AppTheme.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: isFound ? AppTheme.correctAnswerColor : AppTheme.primaryColor,
          size: 24,
        ),
      ),
    ).animate(
      effects: [
        if (isFound)
          const ShakeEffect(
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        'Tap tiles that change when image flashes',
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: Colors.grey[600],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class Point {
  final int x;
  final int y;

  Point(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GameControllerParams extends Equatable {
  final int timeLimit;
  final int maxLevels;
  final Function(int score)? onScoreUpdate;
  final VoidCallback? onComplete;
  final Function(int level)? onLevelComplete;
  final Function(GameState state)? onStateChange;

  const GameControllerParams({
    this.timeLimit = 60,
    this.maxLevels = 1,
    this.onScoreUpdate,
    this.onComplete,
    this.onLevelComplete,
    this.onStateChange,
  });

  @override
  List<Object?> get props => [
        timeLimit,
        maxLevels,
        onScoreUpdate,
        onComplete,
        onLevelComplete,
        onStateChange
      ];
}

final gameControllerProvider = ChangeNotifierProvider.autoDispose
    .family<GameController, GameControllerParams>((ref, params) {
  return GameController(
    timeLimit: params.timeLimit,
    maxLevels: params.maxLevels,
    onScoreUpdate: params.onScoreUpdate,
    onComplete: params.onComplete,
    onLevelComplete: params.onLevelComplete,
    onStateChange: params.onStateChange,
  );
});

enum GameState {
  initial,
  playing,
  paused,
  complete,
  gameOver,
}

class GameController extends ChangeNotifier {
  // Core game state
  GameState _state = GameState.initial;
  int _score = 0;
  int _timeRemaining = 0;
  bool _isTimerRunning = false;
  int _currentLevel = 0;
  int _maxLevels = 1;
  int _timeSpent = 0;
  Timer? _gameTimer;

  // Optional game states with defaults
  int _lives = 3;
  int _moves = 0;
  int _streak = 0;
  int _highestStreak = 0;
  bool _showHint = false;

  // Getters
  GameState get state => _state;
  int get score => _score;
  int get timeRemaining => _timeRemaining;
  int get currentLevel => _currentLevel;
  int get maxLevels => _maxLevels;
  int get lives => _lives;
  int get moves => _moves;
  int get streak => _streak;
  int get highestStreak => _highestStreak;
  bool get showHint => _showHint;
  bool get isPlaying => _state == GameState.playing;
  bool get isComplete => _state == GameState.complete;
  bool get isGameOver => _state == GameState.gameOver;
  bool get isPaused => _state == GameState.paused;
  int get timeSpent => _timeSpent;

  // Callback functions
  final Function(int score)? onScoreUpdate;
  final VoidCallback? onComplete;
  final Function(int level)? onLevelComplete;
  final Function(GameState state)? onStateChange;

  GameController({
    required int timeLimit,
    int maxLevels = 1,
    this.onScoreUpdate,
    this.onComplete,
    this.onLevelComplete,
    this.onStateChange,
  }) {
    _timeRemaining = timeLimit;
    _maxLevels = maxLevels;
  }

  // Game control methods
  void startGame({
    int? timeLimit,
    int? maxLevels,
    int? lives,
    int? level,
  }) {
    _state = GameState.playing;
    _isTimerRunning = true;
    _timeRemaining = timeLimit ?? _timeRemaining;
    _maxLevels = maxLevels ?? _maxLevels;
    _lives = lives ?? _lives;
    _currentLevel = level ?? _currentLevel;

    _startTimer();
    notifyListeners();
    onStateChange?.call(_state);
  }

  void pauseGame() {
    _state = GameState.paused;
    _isTimerRunning = false;
    _gameTimer?.cancel();
    notifyListeners();
    onStateChange?.call(_state);
  }

  void resumeGame() {
    _state = GameState.playing;
    _isTimerRunning = true;
    _startTimer();
    notifyListeners();
    onStateChange?.call(_state);
  }

  void completeGame() {
    _state = GameState.complete;
    _isTimerRunning = false;
    _gameTimer?.cancel();
    onComplete?.call();
    notifyListeners();
    onStateChange?.call(_state);
  }

  void gameOver() {
    _state = GameState.gameOver;
    _isTimerRunning = false;
    _gameTimer?.cancel();
    notifyListeners();
    onStateChange?.call(_state);
  }

  void restartGame() {
    _state = GameState.initial;
    _score = 0;
    _moves = 0;
    _streak = 0;
    _currentLevel = 0;
    _isTimerRunning = false;
    _gameTimer?.cancel();
    notifyListeners();
    onStateChange?.call(_state);
  }

  // Score and progress methods
  void updateScore(int points) {
    _score += points;
    onScoreUpdate?.call(_score);
    notifyListeners();
  }

  void incrementMoves() {
    _moves++;
    notifyListeners();
  }

  void updateStreak(bool success) {
    if (success) {
      _streak++;
      if (_streak > _highestStreak) {
        _highestStreak = _streak;
      }
    } else {
      _streak = 0;
    }
    notifyListeners();
  }

  void loseLive() {
    if (_lives > 0) {
      _lives--;
      if (_lives <= 0) {
        gameOver();
      }
    }
    notifyListeners();
  }

  void nextLevel() {
    if (_currentLevel < _maxLevels - 1) {
      _currentLevel++;
      onLevelComplete?.call(_currentLevel);
      notifyListeners();
    } else {
      completeGame();
    }
  }

  void toggleHint() {
    _showHint = !_showHint;
    notifyListeners();
  }

  // Timer management
  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isTimerRunning) {
        if (_timeRemaining > 0) {
          _timeSpent++;
          _timeRemaining--;
          notifyListeners();
        } else {
          gameOver();
        }
      }
    });
  }

  // Format time for display
  String formatTime() {
    final minutes = _timeRemaining ~/ 60;
    final seconds = _timeRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }
}

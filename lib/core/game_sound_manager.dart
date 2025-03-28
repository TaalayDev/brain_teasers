import '../providers/sound_controller.dart';
import '../games/controller/game_controller.dart';

/// Utility class to connect a GameController with the SoundController
class GameSoundManager {
  final GameController gameController;
  final SoundController soundController;
  GameState? _previousState;

  GameSoundManager({
    required this.gameController,
    required this.soundController,
  }) {
    _initListeners();
  }

  void _initListeners() {
    // Subscribe to game state changes
    gameController.addListener(_handleGameStateChanges);
    _previousState = gameController.state;
  }

  void _handleGameStateChanges() {
    final currentState = gameController.state;

    // Only process if state actually changed
    if (_previousState == currentState) return;

    switch (currentState) {
      case GameState.initial:
        break;

      case GameState.playing:
        if (_previousState == GameState.initial) {
          // Game just started
          soundController.playEffect(SoundType.click);
          _startGameMusic();
        } else if (_previousState == GameState.paused) {
          // Game resumed from pause
          soundController.playEffect(SoundType.click);
          soundController.resumeBgm();
        }
        break;

      case GameState.paused:
        soundController.playEffect(SoundType.click);
        soundController.pauseBgm();
        break;

      case GameState.complete:
        soundController.playEffect(SoundType.success);
        soundController.fadeBgm(duration: const Duration(milliseconds: 2000));
        break;

      case GameState.gameOver:
        soundController.playEffect(SoundType.failure);
        soundController.fadeBgm(duration: const Duration(milliseconds: 1500));
        break;
    }

    _previousState = currentState;
  }

  void _startGameMusic() {
    soundController.playBgm();
  }

  // Method to handle successful actions like correct match, puzzle solved, etc.
  void playSuccessSound() {
    soundController.playEffect(SoundType.success);
  }

  // Method to handle failure actions like wrong match, mistake, etc.
  void playFailureSound() {
    soundController.playEffect(SoundType.failure);
  }

  // Method to play appropriate sound when a level is completed
  void playLevelComplete() {
    soundController.playEffect(SoundType.levelComplete);
  }

  // Method to play sound when cards/items match
  void playMatchSound() {
    soundController.playEffect(SoundType.match);
  }

  // Method to play sound when cards are flipped
  void playCardFlipSound() {
    soundController.playEffect(SoundType.cardFlip);
  }

  // Method to handle achievement unlocked
  void playAchievementSound() {
    soundController.playEffect(SoundType.achievement);
  }

  // Method to handle UI interactions
  void playClickSound() {
    soundController.playEffect(SoundType.click);
  }

  // Dispose resources
  void dispose() {
    gameController.removeListener(_handleGameStateChanges);
  }
}

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import '../providers/common.dart';
import '../db/database.dart';

/// Enum for different sound categories
enum SoundType {
  bgm,
  success,
  failure,
  click,
  match,
  levelComplete,
  gameComplete,
  countdown,
  hint,
  cardFlip,
  unlock,
  achievement,
  bonus,
}

/// Provider for the sound controller
final soundControllerProvider = Provider<SoundController>((ref) {
  final database = ref.watch(databaseProvider);
  return SoundController(database: database);
});

/// Controller to manage all sound and music in the app
class SoundController {
  final AppDatabase database;

  // Audio players
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final Map<String, AudioPlayer> _effectPlayers = {};

  // Current state
  bool _isSoundEnabled = true;
  bool _isMusicEnabled = true;
  bool _isVibrationEnabled = true;
  double _soundVolume = 1.0;
  double _musicVolume = 0.7;
  String? _currentBgm;

  // Maximum concurrent effect players
  static const int _maxEffectPlayers = 5;

  SoundController({required this.database}) {
    _init();
  }

  /// Initialize the controller
  Future<void> _init() async {
    await _loadSettings();

    // Initialize bgm player
    await _bgmPlayer.setVolume(_musicVolume);
    await _bgmPlayer.setLoopMode(LoopMode.all);
  }

  /// Load settings from database
  Future<void> _loadSettings() async {
    try {
      final soundEnabled = await database.getSetting('sound_enabled');
      final musicEnabled = await database.getSetting('music_enabled');
      final vibrationEnabled = await database.getSetting('vibration_enabled');

      _isSoundEnabled = soundEnabled == 'true';
      _isMusicEnabled = musicEnabled == 'true';
      _isVibrationEnabled = vibrationEnabled == 'true';
    } catch (e) {
      // Default values already set
      debugPrint("Error loading sound settings: $e");
    }
  }

  /// Get appropriate sound file path
  String _getSoundFile(SoundType type, {String? variant}) {
    switch (type) {
      case SoundType.bgm:
        if (variant != null) {
          return 'assets/audio/bgm/$variant.mp3';
        }
        return 'assets/audio/bgm/main_theme.mp3';

      case SoundType.success:
        return 'assets/audio/sfx/success.mp3';

      case SoundType.failure:
        return 'assets/audio/sfx/failure.mp3';

      case SoundType.click:
        return 'assets/audio/sfx/click.mp3';

      case SoundType.match:
        return 'assets/audio/sfx/match.mp3';

      case SoundType.levelComplete:
        return 'assets/audio/sfx/level_complete.mp3';

      case SoundType.gameComplete:
        return 'assets/audio/sfx/game_complete.mp3';

      case SoundType.countdown:
        return 'assets/audio/sfx/countdown.mp3';

      case SoundType.hint:
        return 'assets/audio/sfx/hint.mp3';

      case SoundType.cardFlip:
        return 'assets/audio/sfx/card_flip.mp3';

      case SoundType.unlock:
        return 'assets/audio/sfx/unlock.mp3';

      case SoundType.achievement:
        return 'assets/audio/sfx/achievement.mp3';

      case SoundType.bonus:
        return 'assets/audio/sfx/bonus.mp3';
    }
  }

  /// Play a background music track
  Future<void> playBgm(String variant) async {
    if (!_isMusicEnabled || _currentBgm == variant) return;

    String soundFile = _getSoundFile(SoundType.bgm, variant: variant);

    try {
      // Stop current BGM if playing
      await stopBgm();

      // Play new BGM
      await _bgmPlayer.setAsset(soundFile);
      await _bgmPlayer.setVolume(_musicVolume);
      await _bgmPlayer.play();
      _currentBgm = variant;
    } catch (e) {
      debugPrint("Error playing BGM: $e");
    }
  }

  /// Stop the background music
  Future<void> stopBgm() async {
    if (_bgmPlayer.playing) {
      await _bgmPlayer.stop();
      _currentBgm = null;
    }
  }

  /// Pause the background music
  Future<void> pauseBgm() async {
    if (_bgmPlayer.playing) {
      await _bgmPlayer.pause();
    }
  }

  /// Resume the background music
  Future<void> resumeBgm() async {
    if (_isMusicEnabled && _currentBgm != null && !_bgmPlayer.playing) {
      await _bgmPlayer.play();
    }
  }

  /// Fade out the background music
  Future<void> fadeBgm(
      {Duration duration = const Duration(milliseconds: 1000)}) async {
    if (_bgmPlayer.playing) {
      final timer = Timer.periodic(
        Duration(milliseconds: (duration.inMilliseconds / 10).round()),
        (timer) async {
          double newVolume = _bgmPlayer.volume - (_musicVolume / 10);
          if (newVolume <= 0) {
            timer.cancel();
            await _bgmPlayer.setVolume(0);
            await _bgmPlayer.stop();
            await _bgmPlayer.setVolume(_musicVolume);
            _currentBgm = null;
          } else {
            await _bgmPlayer.setVolume(newVolume);
          }
        },
      );
    }
  }

  /// Play a sound effect
  Future<void> playEffect(SoundType type) async {
    if (!_isSoundEnabled) return;

    final soundFile = _getSoundFile(type);

    try {
      // Manage audio player pool
      final playerId = type.toString();

      // Reuse existing player or create a new one
      if (!_effectPlayers.containsKey(playerId)) {
        // Limit the number of concurrent players
        if (_effectPlayers.length >= _maxEffectPlayers) {
          // Find a player that's not currently active and remove it
          final inactivePlayers = _effectPlayers.entries
              .where((entry) => !entry.value.playing)
              .map((entry) => entry.key)
              .toList();

          if (inactivePlayers.isNotEmpty) {
            final playerToRemove = inactivePlayers.first;
            await _effectPlayers[playerToRemove]?.dispose();
            _effectPlayers.remove(playerToRemove);
          } else {
            // If all players are active, just return
            return;
          }
        }

        _effectPlayers[playerId] = AudioPlayer();
      }

      final player = _effectPlayers[playerId]!;

      // Stop if already playing
      if (player.playing) {
        await player.stop();
      }

      await player.setAsset(soundFile);
      await player.setVolume(_soundVolume);
      await player.play();
    } catch (e) {
      debugPrint("Error playing sound effect: $e");
    }
  }

  /// Trigger a device vibration
  Future<void> vibrate(
      {Duration duration = const Duration(milliseconds: 300)}) async {
    if (!_isVibrationEnabled) return;

    try {
      await HapticFeedback.vibrate();
    } catch (e) {
      debugPrint("Error triggering vibration: $e");
    }
  }

  /// Play success feedback (sound + vibration)
  Future<void> playSuccess() async {
    await playEffect(SoundType.success);
    await vibrate(duration: const Duration(milliseconds: 100));
  }

  /// Play failure feedback (sound + vibration)
  Future<void> playFailure() async {
    await playEffect(SoundType.failure);
    await vibrate(duration: const Duration(milliseconds: 400));
  }

  /// Enable or disable sound
  Future<void> setSoundEnabled(bool enabled) async {
    _isSoundEnabled = enabled;
    await database.setSetting('sound_enabled', enabled.toString());
  }

  /// Enable or disable music
  Future<void> setMusicEnabled(bool enabled) async {
    _isMusicEnabled = enabled;
    await database.setSetting('music_enabled', enabled.toString());

    if (enabled) {
      if (_currentBgm != null) {
        await resumeBgm();
      }
    } else {
      await pauseBgm();
    }
  }

  /// Enable or disable vibration
  Future<void> setVibrationEnabled(bool enabled) async {
    _isVibrationEnabled = enabled;
    await database.setSetting('vibration_enabled', enabled.toString());
  }

  /// Set sound volume
  void setSoundVolume(double volume) {
    _soundVolume = volume.clamp(0.0, 1.0);
  }

  /// Set music volume
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await _bgmPlayer.setVolume(_musicVolume);
  }

  /// Get sound enabled state
  bool get isSoundEnabled => _isSoundEnabled;

  /// Get music enabled state
  bool get isMusicEnabled => _isMusicEnabled;

  /// Get vibration enabled state
  bool get isVibrationEnabled => _isVibrationEnabled;

  /// Get sound volume
  double get soundVolume => _soundVolume;

  /// Get music volume
  double get musicVolume => _musicVolume;

  /// Get current background music
  String? get currentBgm => _currentBgm;

  /// Dispose all audio players
  Future<void> dispose() async {
    await stopBgm();
    await _bgmPlayer.dispose();

    for (final player in _effectPlayers.values) {
      await player.dispose();
    }
    _effectPlayers.clear();
  }
}

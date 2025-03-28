import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// A singleton service to handle analytics tracking throughout the app.
/// Uses Firebase Analytics to collect event data and user properties.
class Analytics {
  // Private constructor
  Analytics._();

  // Singleton instance
  static final Analytics _instance = Analytics._();

  // Factory constructor to return the singleton instance
  factory Analytics() => _instance;

  // Firebase Analytics instance
  final _analytics = FirebaseAnalytics.instance;

  // Whether analytics are enabled
  bool _enabled = true;

  /// Enable or disable analytics collection
  void setEnabled(bool enabled) {
    _enabled = enabled;
    _analytics.setAnalyticsCollectionEnabled(enabled);
    debugPrint('Analytics collection ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Log a screen view event
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_enabled) return;

    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? 'Flutter',
      );
      debugPrint('Logged screen view: $screenName');
    } catch (e) {
      debugPrint('Failed to log screen view: $e');
    }
  }

  /// Log when a user starts a puzzle
  Future<void> logPuzzleStart({
    required int puzzleId,
    required String puzzleName,
    required String difficulty,
    required String category,
  }) async {
    if (!_enabled) return;

    try {
      await _analytics.logEvent(
        name: 'puzzle_start',
        parameters: {
          'puzzle_id': puzzleId,
          'puzzle_name': puzzleName,
          'difficulty': difficulty,
          'category': category,
        },
      );
      debugPrint('Logged puzzle start: $puzzleName');
    } catch (e) {
      debugPrint('Failed to log puzzle start: $e');
    }
  }

  /// Log when a user completes a puzzle
  Future<void> logPuzzleComplete({
    required int puzzleId,
    required String puzzleName,
    required String difficulty,
    required String category,
    required int score,
    required int timeSpent,
    required int hintsUsed,
  }) async {
    if (!_enabled) return;

    try {
      await _analytics.logEvent(
        name: 'puzzle_complete',
        parameters: {
          'puzzle_id': puzzleId,
          'puzzle_name': puzzleName,
          'difficulty': difficulty,
          'category': category,
          'score': score,
          'time_spent': timeSpent,
          'hints_used': hintsUsed,
        },
      );
      debugPrint('Logged puzzle complete: $puzzleName with score $score');
    } catch (e) {
      debugPrint('Failed to log puzzle complete: $e');
    }
  }

  /// Log when a user fails a puzzle
  Future<void> logPuzzleFail({
    required int puzzleId,
    required String puzzleName,
    required String difficulty,
    required String category,
    required int timeSpent,
  }) async {
    if (!_enabled) return;

    try {
      await _analytics.logEvent(
        name: 'puzzle_fail',
        parameters: {
          'puzzle_id': puzzleId,
          'puzzle_name': puzzleName,
          'difficulty': difficulty,
          'category': category,
          'time_spent': timeSpent,
        },
      );
      debugPrint('Logged puzzle fail: $puzzleName');
    } catch (e) {
      debugPrint('Failed to log puzzle fail: $e');
    }
  }

  /// Log when a user unlocks an achievement
  Future<void> logAchievementUnlocked({
    required int achievementId,
    required String achievementName,
  }) async {
    if (!_enabled) return;

    try {
      await _analytics.logEvent(
        name: 'achievement_unlocked',
        parameters: {
          'achievement_id': achievementId,
          'achievement_name': achievementName,
        },
      );
      debugPrint('Logged achievement unlock: $achievementName');
    } catch (e) {
      debugPrint('Failed to log achievement unlock: $e');
    }
  }

  /// Log when a user changes a setting
  Future<void> logSettingChange({
    required String settingName,
    required String settingValue,
  }) async {
    if (!_enabled) return;

    try {
      await _analytics.logEvent(
        name: 'setting_change',
        parameters: {
          'setting_name': settingName,
          'setting_value': settingValue,
        },
      );
      debugPrint('Logged setting change: $settingName to $settingValue');
    } catch (e) {
      debugPrint('Failed to log setting change: $e');
    }
  }

  /// Log a custom event
  Future<void> logEvent({
    required String name,
    Map<String, String>? parameters,
  }) async {
    if (!_enabled) return;

    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
      debugPrint('Logged custom event: $name');
    } catch (e) {
      debugPrint('Failed to log custom event: $e');
    }
  }

  /// Set a user property
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    if (!_enabled) return;

    try {
      await _analytics.setUserProperty(
        name: name,
        value: value,
      );
      debugPrint('Set user property: $name to $value');
    } catch (e) {
      debugPrint('Failed to set user property: $e');
    }
  }

  /// Set user ID
  Future<void> setUserId(String? id) async {
    if (!_enabled) return;

    try {
      await _analytics.setUserId(id: id);
      debugPrint('Set user ID: $id');
    } catch (e) {
      debugPrint('Failed to set user ID: $e');
    }
  }
}

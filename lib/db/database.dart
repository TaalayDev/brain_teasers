import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

import 'seeder.dart';

// Tables
part 'database.g.dart';

// Puzzle Categories table
class PuzzleCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get iconName => text()();
  IntColumn get sortOrder => integer()();
}

// Puzzles table
class Puzzles extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(PuzzleCategories, #id)();
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get difficulty => text()(); // 'easy', 'medium', 'hard', 'expert'
  IntColumn get orderInCategory => integer()();
  TextColumn get gameData => text()(); // JSON string containing puzzle data
  BoolColumn get isLocked => boolean().withDefault(const Constant(true))();
  IntColumn get requiredScore => integer().withDefault(const Constant(0))();
}

// User Progress table
class UserProgress extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get puzzleId => integer().references(Puzzles, #id)();
  IntColumn get stars => integer().withDefault(const Constant(0))();
  IntColumn get score => integer().withDefault(const Constant(0))();
  IntColumn get hintsUsed => integer().withDefault(const Constant(0))();
  IntColumn get timeSpentSeconds => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
}

// Achievements table
class Achievements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get iconName => text()();
  TextColumn get type => text()(); // 'puzzle_completion', 'score', 'time', etc.
  IntColumn get requirement => integer()();
  TextColumn get reward => text().nullable()(); // JSON string for reward data
}

// User Achievements table
class UserAchievements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get achievementId => integer().references(Achievements, #id)();
  DateTimeColumn get unlockedAt => dateTime()();
  BoolColumn get isCollected => boolean().withDefault(const Constant(false))();
}

// Settings table
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    PuzzleCategories,
    Puzzles,
    UserProgress,
    Achievements,
    UserAchievements,
    Settings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'brain_teasers_15.db',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
        onResult: (result) {
          if (result.missingFeatures.isNotEmpty) {
            debugPrint(
              'Using ${result.chosenImplementation} due to unsupported '
              'browser features: ${result.missingFeatures}',
            );
          }
        },
      ),
    );
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await seedDatabase();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Add migration logic here when needed
        },
      );

  Future<void> _insertInitialData() async {
    // Insert default categories
    await batch((batch) {
      batch.insertAll(puzzleCategories, [
        PuzzleCategoriesCompanion.insert(
          name: 'Logic',
          description: 'Test your logical thinking',
          iconName: 'brain',
          sortOrder: 1,
        ),
        PuzzleCategoriesCompanion.insert(
          name: 'Physics',
          description: 'Physics-based puzzles',
          iconName: 'science',
          sortOrder: 2,
        ),
        PuzzleCategoriesCompanion.insert(
          name: 'Memory',
          description: 'Train your memory',
          iconName: 'memory',
          sortOrder: 3,
        ),
      ]);
    });

    // Insert default achievements
    await batch((batch) {
      batch.insertAll(achievements, [
        AchievementsCompanion.insert(
          name: 'Beginner',
          description: 'Complete your first puzzle',
          iconName: 'star_beginner',
          type: 'puzzle_completion',
          requirement: 1,
        ),
        AchievementsCompanion.insert(
          name: 'Expert',
          description: 'Complete 50 puzzles',
          iconName: 'star_expert',
          type: 'puzzle_completion',
          requirement: 50,
        ),
      ]);
    });

    // Insert default settings
    await batch((batch) {
      batch.insertAll(settings, [
        SettingsCompanion.insert(
          key: 'sound_enabled',
          value: 'true',
        ),
        SettingsCompanion.insert(
          key: 'music_enabled',
          value: 'true',
        ),
        SettingsCompanion.insert(
          key: 'notifications_enabled',
          value: 'true',
        ),
        SettingsCompanion.insert(
          key: 'theme_mode',
          value: 'system',
        ),
      ]);
    });
  }

  // Puzzle-related queries
  Future<List<PuzzleCategory>> getAllCategories() =>
      select(puzzleCategories).get();

  Stream<List<Puzzle>> watchPuzzles() => select(puzzles).watch();

  Future<List<Puzzle>> getPuzzlesByCategory(int categoryId) =>
      (select(puzzles)..where((p) => p.categoryId.equals(categoryId))).get();

  Stream<List<Puzzle>> watchPuzzlesByCategory(int categoryId) =>
      (select(puzzles)..where((p) => p.categoryId.equals(categoryId))).watch();

  Future<Puzzle> getPuzzleById(int id) =>
      (select(puzzles)..where((p) => p.id.equals(id))).getSingle();

  // Progress-related queries
  Future<UserProgressData> getProgressForPuzzle(int puzzleId) =>
      (select(userProgress)..where((p) => p.puzzleId.equals(puzzleId)))
          .getSingle();

  Future<int> updateProgress(UserProgressCompanion progress) =>
      into(userProgress).insert(
        progress,
        mode: InsertMode.insertOrReplace,
      );

  // Achievement-related queries
  Stream<List<Achievement>> watchUnlockedAchievements() {
    final query = select(achievements).join([
      innerJoin(
        userAchievements,
        userAchievements.achievementId.equalsExp(achievements.id),
      ),
    ]);
    return query
        .watch()
        .map((rows) => rows.map((row) => row.readTable(achievements)).toList());
  }

  Future<void> unlockAchievement(int achievementId) =>
      into(userAchievements).insert(
        UserAchievementsCompanion.insert(
          achievementId: achievementId,
          unlockedAt: DateTime.now(),
        ),
      );

  // Settings-related queries
  Future<String?> getSetting(String key) async {
    final result = await (select(settings)..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return result?.value;
  }

  Future<void> setSetting(String key, String value) => into(settings).insert(
        SettingsCompanion.insert(key: key, value: value),
        mode: InsertMode.insertOrReplace,
      );

  // Statistics queries
  Future<Map<String, dynamic>> getUserStatistics() async {
    final totalPuzzles = await (select(userProgress)
          ..where((p) => p.isCompleted.equals(true)))
        .get();

    final totalTime = totalPuzzles.fold<int>(
        0, (sum, progress) => sum + progress.timeSpentSeconds);

    final totalScore =
        totalPuzzles.fold<int>(0, (sum, progress) => sum + progress.score);

    return {
      'completedPuzzles': totalPuzzles.length,
      'totalTimeSpent': totalTime,
      'totalScore': totalScore,
      'averageTime':
          totalPuzzles.isEmpty ? 0 : (totalTime / totalPuzzles.length).round(),
    };
  }
}

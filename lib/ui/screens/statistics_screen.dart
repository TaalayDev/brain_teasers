import 'package:drift/drift.dart' show innerJoin, OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../providers/common.dart';
import '../theme/app_theme.dart';
import '../../db/database.dart';

// Provider for overall user statistics
final statisticsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.getUserStatistics();
});

// Provider for category statistics
final categoryStatsProvider = FutureProvider<List<CategoryStats>>((ref) async {
  final database = ref.watch(databaseProvider);

  // Get all categories
  final categories = await database.getAllCategories();

  final stats = <CategoryStats>[];

  for (final category in categories) {
    // Get all puzzles in the category
    final puzzles = await database.getPuzzlesByCategory(category.id);

    // Count completed puzzles
    int completed = 0;
    for (final puzzle in puzzles) {
      final progress = await database.getProgressForPuzzle(puzzle.id);
      if (progress != null && progress.isCompleted) {
        completed++;
      }
    }

    stats.add(CategoryStats(
      category: category,
      completed: completed,
      total: puzzles.length,
    ));
  }

  return stats;
});

// Provider for daily activity stats (last 7 days)
final dailyActivityProvider = FutureProvider<List<DailyActivity>>((ref) async {
  final database = ref.watch(databaseProvider);

  // Get all user progress entries
  final progressTable = database.userProgress;
  final query = database.select(progressTable)
    ..where((tbl) => tbl.lastPlayedAt.isNotNull())
    ..orderBy([(t) => OrderingTerm.desc(t.lastPlayedAt)]);

  final allProgress = await query.get();

  // Calculate daily stats for the last 7 days
  final now = DateTime.now();
  final stats = <DailyActivity>[];

  for (int i = 6; i >= 0; i--) {
    final day = DateTime(now.year, now.month, now.day - i);
    final nextDay = DateTime(now.year, now.month, now.day - i + 1);

    // Count puzzles played on this day
    final dayEntries = allProgress.where((progress) {
      final played = progress.lastPlayedAt;
      return played != null && played.isAfter(day) && played.isBefore(nextDay);
    });

    final scoreSum =
        dayEntries.fold<int>(0, (sum, progress) => sum + progress.score);
    final count = dayEntries.length;

    stats.add(DailyActivity(
      date: day,
      puzzlesPlayed: count,
      totalScore: scoreSum,
    ));
  }

  return stats;
});

// Provider for recent achievements
final recentAchievementsProvider =
    StreamProvider<List<AchievementWithDate>>((ref) async* {
  final database = ref.watch(databaseProvider);

  final query = database.select(database.achievements).join([
    innerJoin(
      database.userAchievements,
      database.userAchievements.achievementId
          .equalsExp(database.achievements.id),
    ),
  ])
    ..orderBy([
      OrderingTerm.desc(database.userAchievements.unlockedAt),
    ])
    ..limit(5); // Only get the 5 most recent achievements

  await for (final rows in query.watch()) {
    final results = <AchievementWithDate>[];

    for (final row in rows) {
      final achievement = row.readTable(database.achievements);
      final userAchievement = row.readTable(database.userAchievements);

      results.add(AchievementWithDate(
        achievement: achievement,
        unlockedAt: userAchievement.unlockedAt,
      ));
    }

    yield results;
  }
});

class CategoryStats {
  final PuzzleCategory category;
  final int completed;
  final int total;

  const CategoryStats({
    required this.category,
    required this.completed,
    required this.total,
  });

  double get completionRate => total > 0 ? completed / total : 0;
}

class DailyActivity {
  final DateTime date;
  final int puzzlesPlayed;
  final int totalScore;

  const DailyActivity({
    required this.date,
    required this.puzzlesPlayed,
    required this.totalScore,
  });

  String get dayLabel => DateFormat('E').format(date);
  String get fullDateLabel => DateFormat('MMM d').format(date);
}

class AchievementWithDate {
  final Achievement achievement;
  final DateTime unlockedAt;

  const AchievementWithDate({
    required this.achievement,
    required this.unlockedAt,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(unlockedAt);

    if (difference.inDays > 30) {
      return DateFormat('MMM d').format(unlockedAt);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          _buildOverallStats(context),
          _buildCategoryProgress(context),
          _buildDailyProgress(context),
          _buildAchievementStats(context),
          // Add extra space at the bottom
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Statistics',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.secondaryColor,
                    AppTheme.secondaryColor.withOpacity(0.8),
                  ],
                ),
              ),
              child: CustomPaint(
                painter: StatsPatternPainter(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              right: -30,
              bottom: -20,
              child: Icon(
                Feather.bar_chart_2,
                size: 200,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStats(BuildContext context) {
    return SliverToBoxAdapter(
      child: Consumer(
        builder: (context, ref, _) {
          final statsAsync = ref.watch(statisticsProvider);

          return statsAsync.when(
            data: (stats) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Progress',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Puzzles Solved',
                          stats['completedPuzzles'].toString(),
                          Icons.extension,
                          AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Total Score',
                          _formatScore(stats['totalScore']),
                          Icons.stars,
                          AppTheme.accentColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Time Played',
                          _formatTime(stats['totalTimeSpent']),
                          Icons.timer,
                          AppTheme.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ).animate().fadeIn(duration: AppTheme.mediumAnimation),
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) =>
                _buildErrorWidget(context, 'Failed to load statistics', error),
          );
        },
      ),
    );
  }

  Widget _buildCategoryProgress(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final categoryStatsAsync = ref.watch(categoryStatsProvider);

        return SliverToBoxAdapter(
          child: categoryStatsAsync.when(
            data: (categoryStats) => Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category Progress',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (categoryStats.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'No categories found',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: AppTheme.neutralGray,
                              ),
                            ),
                          ),
                        )
                      else
                        ...categoryStats.map((stat) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildProgressBar(
                                context,
                                stat.category.name,
                                stat.completed,
                                stat.total,
                                _getIconData(stat.category.iconName),
                              ),
                            )),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: AppTheme.mediumAnimation),
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => _buildErrorWidget(
                context, 'Failed to load category statistics', error),
          ),
        );
      },
    );
  }

  Widget _buildDailyProgress(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final dailyActivityAsync = ref.watch(dailyActivityProvider);

        return SliverToBoxAdapter(
          child: dailyActivityAsync.when(
            data: (activityStats) => Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Activity',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 160,
                        child: _buildActivityChart(context, activityStats),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Last 7 Days',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.neutralGray,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: AppTheme.mediumAnimation),
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => _buildErrorWidget(
                context, 'Failed to load activity data', error),
          ),
        );
      },
    );
  }

  Widget _buildActivityChart(
      BuildContext context, List<DailyActivity> activityStats) {
    // Find the max count to normalize bar heights
    final maxCount = activityStats.fold<int>(1,
        (max, stats) => stats.puzzlesPlayed > max ? stats.puzzlesPlayed : max);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: activityStats.map((stats) {
        // Calculate height percentage, with a minimum height for empty bars
        final heightPercent =
            stats.puzzlesPlayed > 0 ? stats.puzzlesPlayed / maxCount : 0.05;

        // Select color based on today or not
        final isToday = stats.date.day == DateTime.now().day &&
            stats.date.month == DateTime.now().month;
        final barColor = isToday
            ? AppTheme.accentColor
            : AppTheme.secondaryColor.withOpacity(0.7);

        return Tooltip(
          message:
              '${stats.fullDateLabel}: ${stats.puzzlesPlayed} puzzle${stats.puzzlesPlayed == 1 ? '' : 's'} played',
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 30,
                height: 100 * heightPercent,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
                alignment: Alignment.center,
                child: stats.puzzlesPlayed > 0
                    ? Text(
                        stats.puzzlesPlayed.toString(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                stats.dayLabel,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday ? AppTheme.accentColor : null,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAchievementStats(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final achievementsAsync = ref.watch(recentAchievementsProvider);

        return SliverToBoxAdapter(
          child: achievementsAsync.when(
            data: (achievements) => Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Achievements',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (achievements.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.emoji_events_outlined,
                                  size: 48,
                                  color: AppTheme.neutralGray.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No achievements unlocked yet',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppTheme.neutralGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: achievements.length,
                          separatorBuilder: (context, index) => const Divider(),
                          padding: const EdgeInsets.only(top: 8),
                          itemBuilder: (context, index) =>
                              _buildAchievementItem(
                                  context, achievements[index]),
                        ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: AppTheme.mediumAnimation),
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => _buildErrorWidget(
                context, 'Failed to load achievements', error),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    String category,
    int completed,
    int total,
    IconData? icon,
  ) {
    final progress = total > 0 ? completed / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: AppTheme.primaryColor.withOpacity(0.8),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                category,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              '$completed/$total',
              style: GoogleFonts.poppins(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            // Background
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Progress
            AnimatedContainer(
              duration: AppTheme.mediumAnimation,
              height: 8,
              width: progress * MediaQuery.of(context).size.width * 0.7,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAchievementItem(
      BuildContext context, AchievementWithDate achievement) {
    // Map the iconName to an IconData
    IconData iconData = _getIconData(achievement.achievement.iconName);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          iconData,
          color: AppTheme.accentColor,
        ),
      ),
      title: Text(
        achievement.achievement.name,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        achievement.achievement.description,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color:
              Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
        ),
      ),
      trailing: Text(
        achievement.timeAgo,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color:
              Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    // Map the iconName string to actual IconData
    switch (iconName) {
      case 'stars':
        return Icons.stars;
      case 'timer':
        return Icons.timer;
      case 'grade':
        return Icons.grade;
      case 'workspace_premium':
        return Icons.workspace_premium;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  Widget _buildErrorWidget(BuildContext context, String message, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.wrongAnswerColor,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: GoogleFonts.poppins(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  String _formatScore(int score) {
    if (score >= 1000000) {
      return '${(score / 1000000).toStringAsFixed(1)}M';
    } else if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}K';
    }
    return score.toString();
  }
}

class StatsPatternPainter extends CustomPainter {
  final Color color;

  StatsPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final spacing = size.width / 20;

    for (var i = 0; i < size.width; i += spacing.toInt()) {
      for (var j = 0; j < size.height; j += spacing.toInt()) {
        final path = Path();
        path.moveTo(i.toDouble(), j.toDouble());
        path.lineTo(i + spacing / 2, j + spacing / 2);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

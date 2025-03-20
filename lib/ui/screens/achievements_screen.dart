import 'package:drift/drift.dart' show leftOuterJoin;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../providers/common.dart';
import '../theme/app_theme.dart';
import '../../db/database.dart';

// Updated providers to get all achievements
final allAchievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final database = ref.watch(databaseProvider);
  return database.select(database.achievements).get();
});

// Provider for unlocked achievements with user data
final unlockedAchievementsProvider =
    StreamProvider<List<AchievementWithProgress>>((ref) async* {
  final database = ref.watch(databaseProvider);

  final query = database.select(database.achievements).join([
    leftOuterJoin(
      database.userAchievements,
      database.userAchievements.achievementId
          .equalsExp(database.achievements.id),
    ),
  ]);

  await for (final rows in query.watch()) {
    final results = <AchievementWithProgress>[];

    for (final row in rows) {
      final achievement = row.readTable(database.achievements);
      final userAchievement = row.readTableOrNull(database.userAchievements);

      results.add(AchievementWithProgress(
        achievement: achievement,
        unlockedAt: userAchievement?.unlockedAt,
        isCollected: userAchievement?.isCollected ?? false,
      ));
    }

    yield results;
  }
});

// Model to hold achievement with unlock status
class AchievementWithProgress {
  final Achievement achievement;
  final DateTime? unlockedAt;
  final bool isCollected;

  const AchievementWithProgress({
    required this.achievement,
    this.unlockedAt,
    this.isCollected = false,
  });

  bool get isUnlocked => unlockedAt != null;
}

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          _buildAchievementStats(context, ref),
          _buildAchievementList(context, ref),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Achievements',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.accentColor,
                    AppTheme.primaryColor,
                  ],
                ),
              ),
            ),
            CustomPaint(
              painter: AchievementPatternPainter(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            Positioned(
              right: -50,
              bottom: -50,
              child: Icon(
                Icons.emoji_events,
                size: 200,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementStats(BuildContext context, WidgetRef ref) {
    final unlockedAchievementsAsync = ref.watch(unlockedAchievementsProvider);
    final allAchievementsAsync = ref.watch(allAchievementsProvider);

    return SliverToBoxAdapter(
      child: unlockedAchievementsAsync.when(
        data: (unlockedAchievements) {
          return allAchievementsAsync.when(
            data: (allAchievements) {
              final totalAchievements = allAchievements.length;
              final unlockedCount =
                  unlockedAchievements.where((a) => a.isUnlocked).length;
              final progress = totalAchievements > 0
                  ? unlockedCount / totalAchievements
                  : 0.0;

              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppTheme.neutralGray.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.accentColor,
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          context,
                          'Total',
                          totalAchievements.toString(),
                          Icons.stars_rounded,
                        ),
                        _buildStatItem(
                          context,
                          'Unlocked',
                          unlockedCount.toString(),
                          Icons.lock_open_rounded,
                        ),
                        _buildStatItem(
                          context,
                          'Locked',
                          (totalAchievements - unlockedCount).toString(),
                          Icons.lock_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: AppTheme.mediumAnimation);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
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
            color:
                Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementList(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(unlockedAchievementsProvider);

    return achievementsAsync.when(
      data: (achievements) {
        if (achievements.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    size: 64,
                    color: AppTheme.neutralGray.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No achievements yet',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neutralGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Keep playing to unlock achievements!',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.neutralGray,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Sort achievements: unlocked first, then by unlock date (newest first)
        final sortedAchievements =
            List<AchievementWithProgress>.from(achievements)
              ..sort((a, b) {
                if (a.isUnlocked && !b.isUnlocked) return -1;
                if (!a.isUnlocked && b.isUnlocked) return 1;

                // If both unlocked, sort by date (newest first)
                if (a.isUnlocked && b.isUnlocked) {
                  return b.unlockedAt!.compareTo(a.unlockedAt!);
                }

                // If both locked, sort by name
                return a.achievement.name.compareTo(b.achievement.name);
              });

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final achievement = sortedAchievements[index];
              return _AchievementCard(
                achievement: achievement,
                index: index,
              ).animate().fadeIn(
                    duration: AppTheme.quickAnimation,
                    delay: Duration(milliseconds: 50 * index),
                  );
            },
            childCount: sortedAchievements.length,
          ),
        );
      },
      loading: () => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => SliverFillRemaining(
        child: Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final AchievementWithProgress achievement;
  final int index;

  const _AchievementCard({
    required this.achievement,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildAchievementIcon(
                  isUnlocked, achievement.achievement.iconName),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.achievement.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      achievement.achievement.description,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.7),
                      ),
                    ),
                    if (isUnlocked) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Unlocked on ${_formatDate(achievement.unlockedAt!)}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementIcon(bool isUnlocked, String iconName) {
    // Map the iconName to an IconData if possible, or use a default
    IconData iconData = _getIconData(iconName);

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isUnlocked
              ? [AppTheme.accentColor, AppTheme.primaryColor]
              : [Colors.grey.shade400, Colors.grey.shade600],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isUnlocked ? AppTheme.accentColor : Colors.grey)
                .withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        iconData,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  IconData _getIconData(String iconName) {
    // Map the iconName string to actual IconData
    switch (iconName) {
      case 'stars':
        return Icons.stars;
      case 'star_beginner':
      case 'star_expert':
        return Icons.star;
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

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }
}

class AchievementPatternPainter extends CustomPainter {
  final Color color;

  AchievementPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 20.0;
    const radius = 3.0;

    for (var i = 0.0; i < size.width + spacing; i += spacing) {
      for (var j = 0.0; j < size.height + spacing; j += spacing) {
        if ((i + j) % (2 * spacing) == 0) {
          canvas.drawCircle(Offset(i.toDouble(), j.toDouble()), radius, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/screen_size.dart';
import '../utils/extensions.dart';
import '../providers/common.dart';
import '../theme/app_theme.dart';
import '../db/database.dart';

final userStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.getUserStatistics();
});

final selectedCategoryProvider = StateProvider<int?>((ref) => null);

final categoriesProvider = FutureProvider<List<PuzzleCategory>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.getAllCategories();
});

final puzzlesByCategoryProvider =
    StreamProvider.family<List<Puzzle>, int?>((ref, categoryId) {
  final database = ref.watch(databaseProvider);
  if (categoryId == null) {
    return database.watchPuzzles();
  }

  return database.watchPuzzlesByCategory(categoryId);
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Enhanced App Bar
          SliverAppBar(
            expandedHeight: 240,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            actions: [
              IconButton(
                icon: const Icon(Feather.award),
                onPressed: () => context.push('/achievements'),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                ),
              ),
              IconButton(
                icon: const Icon(Feather.bar_chart_2),
                onPressed: () => context.push('/statistics'),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                ),
              ),
              IconButton(
                icon: const Icon(Feather.settings),
                onPressed: () => context.push('/settings'),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.secondaryColor,
                        ],
                      ),
                    ),
                  ),
                  // Pattern overlay
                  CustomPaint(
                    painter: BrainPatternPainter(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back!',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ready to challenge your mind?',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // User Stats
          SliverToBoxAdapter(
            child: Consumer(
              builder: (context, ref, child) {
                final statsAsync = ref.watch(userStatsProvider);
                return statsAsync.when(
                  data: (stats) => _buildEnhancedStats(stats, context),
                  loading: () => const ShimmerLoadingStats(),
                  error: (error, stack) => _buildErrorWidget(context, error),
                );
              },
            ),
          ),

          // Daily Challenge
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _buildDailyChallenge(context),
            ),
          ),

          // Categories Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Text(
                'Games Catalog',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),

          _buildCategoryTabs(context, ref),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: Consumer(
              builder: (context, ref, child) {
                final categoryId = ref.watch(selectedCategoryProvider);
                final puzzles = ref.watch(puzzlesByCategoryProvider(
                  categoryId,
                ));

                return puzzles.when(
                  data: (puzzles) => _buildEnhancedPuzzlesGrid(
                    puzzles,
                    context,
                    ref,
                  ),
                  loading: () => const SliverToBoxAdapter(
                    child: ShimmerLoadingCategories(),
                  ),
                  error: (error, stack) => SliverToBoxAdapter(
                    child: _buildErrorWidget(context, error),
                  ),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildEnhancedStats(Map<String, dynamic> stats, BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildEnhancedStatItem(
            context,
            'Puzzles Solved',
            '${stats['completedPuzzles']}',
            Icons.extension,
            AppTheme.primaryColor,
          ),
          _buildDivider(),
          _buildEnhancedStatItem(
            context,
            'Total Score',
            '${stats['totalScore']}',
            Icons.stars_rounded,
            AppTheme.accentColor,
          ),
          _buildDivider(),
          _buildEnhancedStatItem(
            context,
            'Time Played',
            '${(stats['totalTimeSpent'] / 3600).toStringAsFixed(1)}h',
            Icons.timer,
            AppTheme.secondaryColor,
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppTheme.mediumAnimation);
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.withOpacity(0.2),
    );
  }

  Widget _buildEnhancedStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyChallenge(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentColor,
            AppTheme.accentColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/puzzle/daily'),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.flash_on_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Challenge',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'New puzzle available! Solve it now',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().slideX(
          begin: 0.2,
          duration: AppTheme.mediumAnimation,
          curve: Curves.easeOut,
        );
  }

  Widget _buildCategoryTabs(
    BuildContext context,
    WidgetRef ref,
  ) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return SliverPersistentHeader(
      pinned: true,
      delegate: _CategoryTabsDelegate(
        categoriesAsync: categoriesAsync,
        selectedCategory: selectedCategory,
        onCategorySelected: (categoryId) {
          ref.read(selectedCategoryProvider.notifier).state = categoryId;
        },
      ),
    );
  }

  Widget _buildEnhancedPuzzlesGrid(
    List<Puzzle> puzzles,
    BuildContext context,
    WidgetRef ref,
  ) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.sizeOf(context).adaptiveValue(
          2,
          {
            ScreenSize.xs: 2,
            ScreenSize.sm: 2,
            ScreenSize.md: 3,
            ScreenSize.lg: 4,
            ScreenSize.xl: 5,
          },
        ),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final puzzle = puzzles[index];
          return _buildEnhancedPuzzleCard(puzzle, context, index, ref);
        },
        childCount: puzzles.length,
      ),
    );
  }

  PuzzleCategory? _getCategoryById(
    int id,
    AsyncValue<List<PuzzleCategory>> categories,
  ) {
    return categories.valueOrNull?.firstWhere((c) => c.id == id);
  }

  Widget _buildEnhancedPuzzleCard(
    Puzzle puzzle,
    BuildContext context,
    int index,
    WidgetRef ref,
  ) {
    final colors = [
      [AppTheme.primaryColor, AppTheme.secondaryColor],
      [AppTheme.secondaryColor, AppTheme.accentColor],
      [AppTheme.accentColor, AppTheme.primaryColor],
      [AppTheme.secondaryColor, AppTheme.primaryColor],
      [AppTheme.accentColor, AppTheme.secondaryColor],
      [AppTheme.primaryColor, AppTheme.accentColor],
    ];
    final colorPair = colors[index % colors.length];

    final category = _getCategoryById(
      puzzle.categoryId,
      ref.watch(categoriesProvider),
    );
    final icon = category?.icon ?? Feather.help_circle;

    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () => context.push('/puzzle/${puzzle.id}'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorPair[0],
                colorPair[1],
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              // Background pattern
              CustomPaint(
                painter: CategoryPatternPainter(
                  color: Colors.white.withOpacity(0.1),
                ),
                size: const Size.square(double.infinity),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Best: 1000',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        const Spacer(),
                        if (puzzle.isLocked)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                    Divider(
                      color: Colors.white.withOpacity(0.5),
                    ),
                    Text(
                      puzzle.name,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        puzzle.description,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Opacity(
                  opacity: 0.5,
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn(
          duration: AppTheme.mediumAnimation,
        )
        .slideY(
          begin: 0.2,
          duration: AppTheme.mediumAnimation,
          curve: Curves.easeOut,
        );
  }
}

// Custom Painters for background patterns
class BrainPatternPainter extends CustomPainter {
  final Color color;

  BrainPatternPainter({required this.color});

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

class CategoryPatternPainter extends CustomPainter {
  final Color color;

  CategoryPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final spacing = size.width / 8;

    for (var i = 0; i < size.width; i += spacing.toInt()) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        paint,
      );
    }

    for (var i = 0; i < size.height; i += spacing.toInt()) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(0, i.toDouble()),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Shimmer loading states
class ShimmerLoadingStats extends StatelessWidget {
  const ShimmerLoadingStats({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          3,
          (index) => Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              )
                  .animate(
                    onPlay: (controller) => controller.repeat(),
                  )
                  .shimmer(
                    duration: AppTheme.slowAnimation,
                    color: Colors.white54,
                  ),
              const SizedBox(height: 8),
              Container(
                width: 60,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(6),
                ),
              )
                  .animate(
                    onPlay: (controller) => controller.repeat(),
                  )
                  .shimmer(
                    duration: AppTheme.slowAnimation,
                    color: Colors.white54,
                  ),
              const SizedBox(height: 4),
              Container(
                width: 40,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              )
                  .animate(
                    onPlay: (controller) => controller.repeat(),
                  )
                  .shimmer(
                    duration: AppTheme.slowAnimation,
                    color: Colors.white54,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShimmerLoadingCategories extends StatelessWidget {
  const ShimmerLoadingCategories({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(20),
          ),
        )
            .animate(
              onPlay: (controller) => controller.repeat(),
            )
            .shimmer(
              duration: AppTheme.slowAnimation,
              color: Colors.white54,
            );
      },
    );
  }
}

Widget _buildErrorWidget(BuildContext context, Object error) {
  return Container(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.wrongAnswerColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppTheme.wrongAnswerColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Oops! Something went wrong',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          error.toString(),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color:
                Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {
            // Trigger a reload of the providers
          },
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try Again'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    ),
  ).animate().fadeIn(duration: AppTheme.mediumAnimation);
}

class _CategoryTabsDelegate extends SliverPersistentHeaderDelegate {
  final AsyncValue<List<PuzzleCategory>> categoriesAsync;
  final int? selectedCategory;
  final Function(int?) onCategorySelected;

  _CategoryTabsDelegate({
    required this.categoriesAsync,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: categoriesAsync.when(
        data: (categories) => ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length + 1,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: selectedCategory == null,
                  showCheckmark: false,
                  label: const Text('All'),
                  onSelected: (_) => onCategorySelected(null),
                  backgroundColor: Colors.transparent,
                  selectedColor: AppTheme.primaryColor,
                  labelStyle: GoogleFonts.poppins(
                    color: selectedCategory == null ? Colors.white : null,
                  ),
                  side: BorderSide(
                    color: selectedCategory == null
                        ? Colors.transparent
                        : AppTheme.primaryColor,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              );
            }

            final category = categories[index - 1];
            final isSelected = category.id == selectedCategory;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                showCheckmark: false,
                label: Text(category.name),
                onSelected: (_) => onCategorySelected(category.id),
                avatar: Icon(
                  category.icon,
                  size: 18,
                  color: isSelected ? Colors.white : AppTheme.primaryColor,
                ),
                backgroundColor: Colors.transparent,
                selectedColor: AppTheme.primaryColor,
                labelStyle: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : null,
                ),
                side: BorderSide(
                  color:
                      isSelected ? Colors.transparent : AppTheme.primaryColor,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading categories: $error'),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 64;

  @override
  double get minExtent => 64;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}

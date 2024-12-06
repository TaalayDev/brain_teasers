import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../utils/extensions.dart';
import '../providers/common.dart';
import '../theme/app_theme.dart';
import '../db/database.dart';

// Providers
final selectedCategoryProvider = StateProvider<int?>((ref) => null);

final categoriesProvider = FutureProvider<List<PuzzleCategory>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.getAllCategories();
});

final puzzlesByCategoryProvider =
    FutureProvider.family<List<Puzzle>, int?>((ref, categoryId) {
  final database = ref.watch(databaseProvider);
  if (categoryId == null) {
    return database.getPuzzlesByCategory(1); // Default category
  }
  return database.getPuzzlesByCategory(categoryId);
});

class PuzzleCatalogScreen extends HookConsumerWidget {
  final String? categoryId;

  const PuzzleCatalogScreen({super.key, this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (categoryId != null) {
          ref.read(selectedCategoryProvider.notifier).state =
              int.parse(categoryId!);
        }
      });
    }, [categoryId]);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          _buildCategoryTabs(context, ref),
          _buildPuzzleGrid(context, ref),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Puzzle Catalog',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: CustomPaint(
            painter: CatalogPatternPainter(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(BuildContext context, WidgetRef ref) {
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

  Widget _buildPuzzleGrid(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final puzzlesAsync = ref.watch(puzzlesByCategoryProvider(selectedCategory));

    return puzzlesAsync.when(
      data: (puzzles) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        sliver: SliverMasonryGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 4,
          itemBuilder: (context, index) {
            return _PuzzleCard(
              puzzle: puzzles[index],
              index: index,
            ).animate().fadeIn(
                  duration: AppTheme.quickAnimation,
                  delay: Duration(milliseconds: 50 * index),
                );
          },
          childCount: puzzles.length,
        ),
      ),
      loading: () => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => SliverFillRemaining(
        child: _buildErrorWidget(context, error),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: AppTheme.wrongAnswerColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: GoogleFonts.poppins(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Refresh the providers
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class _CategoryTabsDelegate extends SliverPersistentHeaderDelegate {
  final AsyncValue<List<PuzzleCategory>> categoriesAsync;
  final int? selectedCategory;
  final Function(int) onCategorySelected;

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
          itemCount: categories.length,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemBuilder: (context, index) {
            final category = categories[index];
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

class _PuzzleCard extends StatelessWidget {
  final Puzzle puzzle;
  final int index;

  const _PuzzleCard({
    required this.puzzle,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => context.push('/puzzle/${puzzle.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getDifficultyColor(puzzle.difficulty),
                _getDifficultyColor(puzzle.difficulty).withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      puzzle.difficulty.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    _getPuzzleIcon(puzzle),
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                puzzle.name,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                puzzle.description,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white70,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
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
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    return AppTheme.difficultyColors[difficulty] ?? AppTheme.primaryColor;
  }

  IconData _getPuzzleIcon(Puzzle puzzle) {
    // Add puzzle type specific icons
    return Icons.extension;
  }
}

class CatalogPatternPainter extends CustomPainter {
  final Color color;

  CatalogPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final spacing = size.width / 20;

    for (var i = 0; i < size.width; i += spacing.toInt()) {
      for (var j = 0; j < size.height; j += spacing.toInt()) {
        canvas.drawCircle(
          Offset(i.toDouble(), j.toDouble()),
          2,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

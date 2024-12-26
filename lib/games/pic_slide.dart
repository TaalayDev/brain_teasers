import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

import '../components/game_container.dart';
import '../theme/app_theme.dart';
import 'game_controller.dart';

class PicSlideGame extends StatefulWidget {
  final Image image;
  final Map<String, dynamic> gameData;
  final GameController gameController;

  const PicSlideGame({
    super.key,
    required this.gameData,
    required this.image,
    required this.gameController,
  });

  @override
  State<PicSlideGame> createState() => _PicSlideGameState();
}

class _PicSlideGameState extends State<PicSlideGame> {
  late List<PuzzleTile> tiles;
  late int gridSize;
  late int emptyIndex;
  int moves = 0;
  int score = 1000;
  bool isComplete = false;
  bool isImageLoaded = false;

  @override
  void initState() {
    super.initState();
    gridSize = widget.gameData['gridSize'] ?? 3;
    _loadImage();
  }

  Future<void> _loadImage() async {
    // Convert Image widget to ui.Image
    final completer = Completer<ui.Image>();
    widget.image.image.resolve(const ImageConfiguration()).addListener(
          ImageStreamListener((info, _) => completer.complete(info.image)),
        );

    final image = await completer.future;

    // crop image into slices
    final tileWidth = image.width ~/ gridSize;
    final tileHeight = image.height ~/ gridSize;

    List<ui.Image> images = List.generate(
      gridSize * gridSize,
      (index) {
        final row = index ~/ gridSize;
        final col = index % gridSize;
        final srcRect = Rect.fromLTWH(
          col * tileWidth.toDouble(),
          row * tileHeight.toDouble(),
          tileWidth.toDouble(),
          tileHeight.toDouble(),
        );

        final pictureRecorder = ui.PictureRecorder();
        final canvas = Canvas(pictureRecorder);
        canvas.drawImageRect(
          image,
          srcRect,
          Rect.fromLTWH(0, 0, tileWidth.toDouble(), tileHeight.toDouble()),
          Paint(),
        );
        final picture = pictureRecorder.endRecording();
        final img = picture.toImageSync(tileWidth, tileHeight);
        return img;
      },
    );

    setState(() {
      isImageLoaded = true;
    });
    _initializePuzzle(images);
  }

  void _initializePuzzle(List<ui.Image> images) {
    // Create ordered tiles
    tiles = List.generate(
      gridSize * gridSize - 1,
      (index) => PuzzleTile(
        id: index,
        currentIndex: index,
        imageSlice: _createImageSlice(images[index]),
      ),
    );

    // Add empty tile at the end
    emptyIndex = gridSize * gridSize - 1;

    // Shuffle tiles
    _shufflePuzzle();
  }

  Widget _createImageSlice(ui.Image image) {
    return CustomPaint(
      painter: ImageSlicePainter(
        image: image,
        srcRect: Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        ),
      ),
    );
  }

  void _shufflePuzzle() {
    final random = math.Random();
    for (int i = 0; i < 1000; i++) {
      final movableTiles = _getMovableTiles();
      if (movableTiles.isEmpty) continue;

      final tileToMove = movableTiles[random.nextInt(movableTiles.length)];
      _moveTile(tileToMove.currentIndex, incrementMoves: false);
    }

    // Reset moves counter after shuffling
    moves = 0;
    score = 1000;
  }

  List<PuzzleTile> _getMovableTiles() {
    final movableTiles = <PuzzleTile>[];

    // Check adjacent tiles (up, down, left, right)
    final row = emptyIndex ~/ gridSize;
    final col = emptyIndex % gridSize;

    // Check up
    if (row > 0) {
      final index = (row - 1) * gridSize + col;
      movableTiles.add(tiles.firstWhere((tile) => tile.currentIndex == index));
    }

    // Check down
    if (row < gridSize - 1) {
      final index = (row + 1) * gridSize + col;
      movableTiles.add(tiles.firstWhere((tile) => tile.currentIndex == index));
    }

    // Check left
    if (col > 0) {
      final index = row * gridSize + (col - 1);
      movableTiles.add(tiles.firstWhere((tile) => tile.currentIndex == index));
    }

    // Check right
    if (col < gridSize - 1) {
      final index = row * gridSize + (col + 1);
      movableTiles.add(tiles.firstWhere((tile) => tile.currentIndex == index));
    }

    return movableTiles;
  }

  void _moveTile(int index, {bool incrementMoves = true}) {
    // Swap positions
    final tile = tiles.firstWhere((tile) => tile.currentIndex == index);
    setState(() {
      tile.currentIndex = emptyIndex;
      emptyIndex = index;

      if (incrementMoves) {
        moves++;
        score = math.max(0, 1000 - moves * 10);
        widget.gameController.updateScore(score);
      }
    });

    // Check if puzzle is complete
    _checkCompletion();
  }

  void _checkCompletion() {
    final isComplete = tiles.every((tile) => tile.id == tile.currentIndex);
    if (isComplete && !this.isComplete) {
      setState(() {
        this.isComplete = true;
      });
      widget.gameController.completeGame();
    }
  }

  bool _canMoveTile(int index) {
    final row = index ~/ gridSize;
    final col = index % gridSize;
    final emptyRow = emptyIndex ~/ gridSize;
    final emptyCol = emptyIndex % gridSize;

    return (row == emptyRow && (col == emptyCol - 1 || col == emptyCol + 1)) ||
        (col == emptyCol && (row == emptyRow - 1 || row == emptyRow + 1));
  }

  @override
  Widget build(BuildContext context) {
    if (!isImageLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return GameContainer(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: Center(child: _buildPuzzleGrid())),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatCard(
            icon: Icons.touch_app,
            label: 'Moves',
            value: moves.toString(),
            color: AppTheme.primaryColor,
          ),
          _buildStatCard(
            icon: Icons.stars,
            label: 'Score',
            value: score.toString(),
            color: AppTheme.accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: color,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzleGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size =
            math.min(constraints.maxWidth, constraints.maxHeight) * 0.9;
        final tileSize = size / gridSize;

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          margin: const EdgeInsets.all(8),
          child: AspectRatio(
            aspectRatio: 1,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridSize,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 1,
              ),
              padding: const EdgeInsets.all(8),
              itemCount: gridSize * gridSize,
              itemBuilder: (context, index) {
                if (index == emptyIndex) {
                  return const SizedBox();
                }

                final tile =
                    tiles.firstWhere((tile) => tile.currentIndex == index);
                return _buildTile(tile, tileSize);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTile(PuzzleTile tile, double size) {
    final canMove = _canMoveTile(tile.currentIndex);

    return GestureDetector(
      onTap: canMove ? () => _moveTile(tile.currentIndex) : null,
      child: Container(
        decoration: BoxDecoration(
          color: canMove
              ? AppTheme.primaryColor
              : AppTheme.primaryColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Positioned.fill(child: tile.imageSlice),
              Center(
                child: Text(
                  (tile.id + 1).toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().scale(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: _shufflePuzzle,
            icon: const Icon(Icons.shuffle),
            label: Text(
              'Shuffle',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PuzzleTile {
  final int id;
  int currentIndex;
  final Widget imageSlice;

  PuzzleTile({
    required this.id,
    required this.currentIndex,
    required this.imageSlice,
  });
}

class ImageSlicePainter extends CustomPainter {
  final ui.Image image;
  final Rect srcRect;

  ImageSlicePainter({
    required this.image,
    required this.srcRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    paintImage(
      canvas: canvas,
      rect: Rect.fromLTWH(0, 0, size.width, size.height),
      image: image,
      fit: BoxFit.cover,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

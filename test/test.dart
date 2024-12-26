class LevelPoint {
  final int x;
  final int y;
  final int colorIndex;

  const LevelPoint(this.x, this.y, this.colorIndex);

  String toString() {
    return 'LevelPoint($x, $y, $colorIndex)';
  }
}

List<List<LevelPoint>> convertGridToConnectedPoints(List<List<int>> grid) {
  final List<List<LevelPoint>> connectedPoints = [];
  final List<LevelPoint> allPoints = [];

  // First pass: collect all points
  for (int y = 0; y < grid.length; y++) {
    for (int x = 0; x < grid[y].length; x++) {
      if (grid[y][x] > 0) {
        allPoints.add(LevelPoint(x, y, grid[y][x] - 1));
      }
    }
  }

  // Track used points to avoid duplicates
  final usedPoints = <LevelPoint>{};

  // Second pass: find pairs of matching colors
  for (final point in allPoints) {
    if (usedPoints.contains(point)) continue;

    // Look for matching point with same color
    for (final otherPoint in allPoints) {
      if (point == otherPoint || usedPoints.contains(otherPoint)) continue;

      if (point.colorIndex == otherPoint.colorIndex) {
        connectedPoints.add([point, otherPoint]);
        usedPoints.add(point);
        usedPoints.add(otherPoint);
        break;
      }
    }
  }

  return connectedPoints;
}

void main() {
  final grid = [
    [0, 0, 0, 0, 0, 0, 0, 8, 0, 7],
    [0, 6, 2, 0, 0, 6, 0, 0, 0, 4],
    [0, 0, 0, 0, 0, 3, 4, 0, 7, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
    [0, 0, 0, 0, 3, 0, 0, 5, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 8, 0, 0],
    [0, 0, 0, 2, 0, 0, 5, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 1, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  ];

  final points = convertGridToConnectedPoints(grid);
  print(points);
}

// This file is auto-generated. Do not edit manually.
// Generated on Fri Mar 28 20:40:52 +06 2025

/// Assets constants for the application
class Assets {
  const Assets._();

  /// Assets from 'audio' directory
  static const audio = (
    bgm: (
      $values: ['assets/audio/bgm/main_theme.mp3'],
      mainTheme: 'assets/audio/bgm/main_theme.mp3',
    ),
    sfx: (),
  );

  /// Assets from 'data' directory
  static const data = (
    $values: ['assets/data/english_words.txt'],
    englishWords: 'assets/data/english_words.txt',
  );

  /// Assets from 'images' directory
  static const images = (
    $values: ['assets/images/cat.jpg', 'assets/images/flutter.png'],
    cat: 'assets/images/cat.jpg',
    flutter: 'assets/images/flutter.png',
  );

  /// Assets from 'vectors' directory
  static const vectors = ();
}

/*
 * Example usage:
 *
 * // Access specific asset
 * Image.asset(AppAssets.images.logo);
 * 
 * // Access all assets in a directory
 * for (final path in AppAssets.images.$values) {
 *   Image.asset(path);
 * }
 */

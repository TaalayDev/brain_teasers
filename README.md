# BrainTeasers

BrainTeasers is a comprehensive mobile puzzle game built with Flutter that challenges users with various brain training exercises and logic puzzles. The app features a diverse collection of interactive puzzles designed to develop logical thinking, attention, and memory skills.

## Features

### Multiple Puzzle Categories
- Logic Puzzles
- Memory Games
- Physics-based Challenges
- Word Games
- Math Problems
- Pattern Recognition
- Visual Puzzles
- Attention Training

### Game Types
- Card Matching
- Pattern Recall
- Balance Ball Physics
- Word Search
- Number Grid
- Circuit Path
- Chain Reaction
- Equation Builder
- Color Harmony
- Multiple Object Tracking
- Change Blindness
- And more...

### Core Features
- Offline gameplay
- Progress tracking
- Achievement system
- Performance statistics
- Daily challenges
- Difficulty progression
- Score tracking
- Local data storage

## Technical Stack

### Framework & Languages
- Flutter/Dart
- Flame Game Engine for physics-based puzzles
- SQLite (via Drift) for local data storage

### Key Dependencies
- `flame`: Game engine for 2D games
- `flame_forge2d`: Physics engine
- `drift`: SQLite database
- `go_router`: Navigation
- `hooks_riverpod`: State management
- `flutter_animate`: Animations
- `google_fonts`: Typography
- Additional UI libraries for enhanced visuals

### Architecture
- Clean Architecture principles
- BLoC pattern for state management
- SQLite for local data persistence
- Component-based game design

## Getting Started

### Prerequisites
- Flutter SDK
- Android Studio or VS Code
- Android SDK for Android deployment
- Xcode for iOS deployment

### Installation

1. Clone the repository:
```bash
git clone https://github.com/TaalayDev/brain_teasers.git
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate necessary files:
```bash
flutter pub run build_runner build
```

4. Run the application:
```bash
flutter run
```

### Project Structure

```
lib/
├── components/      # Reusable UI components
├── db/             # Database configurations and models
├── games/          # Individual game implementations
├── l10n/           # Localization files
├── providers/      # State management providers
├── router/         # Navigation configuration
├── screens/        # Main app screens
├── theme/          # App theming
└── utils/          # Helper functions and utilities
```

## Development

### Adding New Puzzles

1. Create a new game file in `lib/games/`
2. Implement the game logic using provided base classes
3. Add the game type to the database seeder
4. Update the puzzle screen to handle the new game type

## Database Schema

The app uses several tables to manage game data:
- PuzzleCategories: Stores puzzle categories
- Puzzles: Individual puzzle definitions
- UserProgress: Player progress tracking
- Achievements: Achievement definitions
- UserAchievements: Player achievements
- Settings: App configuration

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## Credits

- Flame Game Engine - https://flame-engine.org/
- Flutter Team - https://flutter.dev/
- Icons by Flutter Vector Icons

## Future Enhancements

- Online multiplayer support
- Cloud save functionality
- Additional puzzle categories
- Social features
- Leaderboards
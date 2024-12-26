import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flame/flame.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'db/database.dart';
import 'l10n/strings.dart';
import 'providers/common.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Flame
  await Flame.device.fullScreen();
  await Flame.device.setPortrait();

  final database = AppDatabase();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
      ],
      child: const BrainTeasersApp(),
    ),
  );
}

class BrainTeasersApp extends ConsumerWidget {
  const BrainTeasersApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'BrainTeasers',

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,

      // Localization setup
      localizationsDelegates: const [
        Strings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: Strings.supportedLocales,

      // Router configuration
      routerConfig: AppRouter.router,

      // Debug banner
      debugShowCheckedModeBanner: false,
    );
  }
}

class _ErrorHandler extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Oops! Something went wrong.',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please try again later.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

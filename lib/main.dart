import 'package:brain_teasers/firebase_options.dart';
import 'package:brain_teasers/providers/sound_controller.dart';
import 'package:device_preview_plus/device_preview_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flame/flame.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'db/database.dart';
import 'l10n/strings.dart';
import 'providers/common.dart';
import 'ui/theme/app_theme.dart';
import 'core/router/app_router.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Flame
  await Flame.device.fullScreen();
  await Flame.device.setPortrait();

  final database = AppDatabase();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
      ],
      child: const BrainTeasersApp(),
    ),
  );
}

class BrainTeasersApp extends HookConsumerWidget {
  const BrainTeasersApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      ref.read(soundControllerProvider.notifier).playBgm();
      // ref.read(soundControllerProvider).playBgm('main_theme');
      return null;
    }, const []);

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

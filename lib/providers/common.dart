import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../core/analytics_service.dart';
import '../db/database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Database must be initialized before accessing');
});

final analyticsProvider = Provider<Analytics>((ref) {
  return Analytics();
});

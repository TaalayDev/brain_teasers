// Database provider
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../db/database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Database must be initialized before accessing');
});
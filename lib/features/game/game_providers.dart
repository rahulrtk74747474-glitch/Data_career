import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/analyst_task.dart';
import '../../repositories/content_repository.dart';
import 'game_progress.dart';

final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => const ContentRepository(),
);

final tasksProvider = FutureProvider<List<AnalystTask>>((ref) {
  return ref.read(contentRepositoryProvider).loadPhaseOneTasks();
});

final gameProgressProvider =
    StateNotifierProvider<GameProgressNotifier, GameProgress>(
  (ref) => GameProgressNotifier(),
);

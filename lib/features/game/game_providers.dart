import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../../models/analyst_task.dart';
import '../../models/boss_case.dart';
import '../../models/boss_case_result.dart';
import '../../models/placement_question.dart';
import '../../models/skill_mastery.dart';
import '../../models/sql_table_schema.dart';
import '../../repositories/boss_case_result_repository.dart';
import '../../repositories/content_repository.dart';
import '../../repositories/mastery_repository.dart';
import '../../repositories/sql_workspace_repository.dart';
import '../../services/adaptive_review_service.dart';
import '../../services/sql_runner.dart';
import 'game_progress.dart';

final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => const ContentRepository(),
);

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final masteryRepositoryProvider = Provider<MasteryRepository>((ref) {
  return MasteryRepository(ref.watch(appDatabaseProvider));
});

final sqlRunnerProvider = Provider<SqlRunner>((ref) {
  return SqlRunner(ref.watch(appDatabaseProvider));
});

final sqlWorkspaceRepositoryProvider =
    Provider<SqlWorkspaceRepository>((ref) {
  return SqlWorkspaceRepository(ref.watch(appDatabaseProvider));
});

final bossCaseResultRepositoryProvider =
    Provider<BossCaseResultRepository>((ref) {
  return BossCaseResultRepository(ref.watch(appDatabaseProvider));
});

final tasksProvider = FutureProvider<List<AnalystTask>>((ref) {
  return ref.read(contentRepositoryProvider).loadCareerTasks();
});

final placementQuestionsProvider =
    FutureProvider<List<PlacementQuestion>>((ref) {
  return ref.read(contentRepositoryProvider).loadPlacementQuestions();
});

final bossCaseProvider = FutureProvider<BossCaseDefinition>((ref) {
  return ref.read(contentRepositoryProvider).loadBossCase();
});

final skillProfileProvider = FutureProvider<List<SkillMastery>>((ref) {
  return ref.read(masteryRepositoryProvider).loadSkills();
});

final placementCompletedProvider = FutureProvider<bool>((ref) {
  return ref.read(masteryRepositoryProvider).hasCompletedPlacement();
});

final sqlSchemasProvider = FutureProvider<List<SqlTableSchema>>((ref) {
  return ref.read(sqlWorkspaceRepositoryProvider).loadSchemas();
});

final bossCaseResultProvider =
    FutureProvider.family<BossCaseResult?, String>((ref, caseId) {
  return ref.read(bossCaseResultRepositoryProvider).load(caseId);
});

final reviewQueueProvider = FutureProvider<List<ReviewItem>>((ref) async {
  final skills = await ref.watch(skillProfileProvider.future);
  final tasks = await ref.watch(tasksProvider.future);
  return AdaptiveReviewService.buildQueue(
    skills: skills,
    tasks: tasks,
    now: DateTime.now().toUtc(),
  );
});

final adaptiveRecommendationsProvider =
    FutureProvider<List<AnalystTask>>((ref) async {
  final progress = ref.watch(gameProgressProvider);
  final skills = await ref.watch(skillProfileProvider.future);
  final tasks = await ref.watch(tasksProvider.future);
  return AdaptiveReviewService.recommendTasks(
    skills: skills,
    tasks: tasks,
    completedTaskIds: progress.completedTaskIds,
  );
});

final gameProgressProvider =
    StateNotifierProvider<GameProgressNotifier, GameProgress>(
  (ref) => GameProgressNotifier(),
);

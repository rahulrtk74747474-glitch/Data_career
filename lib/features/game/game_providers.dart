import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../../models/analyst_task.dart';
import '../../models/boss_case.dart';
import '../../models/boss_case_result.dart';
import '../../models/dashboard_challenge.dart';
import '../../models/daily_challenge.dart';
import '../../models/interview.dart';
import '../../models/interview_result.dart';
import '../../models/pandas_challenge.dart';
import '../../models/placement_question.dart';
import '../../models/portfolio_snapshot.dart';
import '../../models/skill_mastery.dart';
import '../../models/sql_table_schema.dart';
import '../../repositories/boss_case_result_repository.dart';
import '../../repositories/content_repository.dart';
import '../../repositories/evidence_repository.dart';
import '../../repositories/interview_result_repository.dart';
import '../../repositories/mastery_repository.dart';
import '../../repositories/portfolio_repository.dart';
import '../../repositories/sql_workspace_repository.dart';
import '../../repositories/task_performance_repository.dart';
import '../../services/adaptive_review_service.dart';
import '../../services/boss_case_selection_service.dart';
import '../../services/career_progression_service.dart';
import '../../services/career_task_service.dart';
import '../../services/daily_challenge_service.dart';
import '../../services/portfolio_export_service.dart';
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

final taskPerformanceRepositoryProvider =
    Provider<TaskPerformanceRepository>((ref) {
  return TaskPerformanceRepository(ref.watch(appDatabaseProvider));
});

final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  return PortfolioRepository(ref.watch(appDatabaseProvider));
});

final evidenceRepositoryProvider = Provider<EvidenceRepository>((ref) {
  return EvidenceRepository(ref.watch(appDatabaseProvider));
});

final portfolioExportServiceProvider =
    Provider<PortfolioExportService>((ref) {
  return PortfolioExportService(ref.watch(appDatabaseProvider));
});

final interviewResultRepositoryProvider =
    Provider<InterviewResultRepository>((ref) {
  return InterviewResultRepository(ref.watch(appDatabaseProvider));
});

final tasksProvider = FutureProvider<List<AnalystTask>>((ref) {
  return ref.read(contentRepositoryProvider).loadCareerTasks();
});

final careerTasksProvider = FutureProvider<List<AnalystTask>>((ref) async {
  final progress = ref.watch(gameProgressProvider);
  final tasks = await ref.watch(tasksProvider.future);
  return CareerTaskService.visibleTasks(
    progress: progress,
    tasks: tasks,
  );
});

final placementQuestionsProvider =
    FutureProvider<List<PlacementQuestion>>((ref) {
  return ref.read(contentRepositoryProvider).loadPlacementQuestions();
});

final bossCasesProvider = FutureProvider<List<BossCaseDefinition>>((ref) {
  return ref.read(contentRepositoryProvider).loadBossCases();
});

final bossCaseProvider = FutureProvider<BossCaseDefinition>((ref) async {
  final progress = ref.watch(gameProgressProvider);
  final cases = await ref.watch(bossCasesProvider.future);
  return BossCaseSelectionService.select(
    cases: cases,
    companyKey: progress.companyKey,
    careerLevel: progress.careerLevel,
  );
});

final pandasChallengesProvider =
    FutureProvider<List<PandasChallenge>>((ref) {
  return ref.read(contentRepositoryProvider).loadPandasChallenges();
});

final dashboardChallengesProvider =
    FutureProvider<List<DashboardChallenge>>((ref) {
  return ref.read(contentRepositoryProvider).loadDashboardChallenges();
});

final dailyChallengeDefinitionsProvider =
    FutureProvider<List<DailyChallengeDefinition>>((ref) {
  return ref.read(contentRepositoryProvider).loadDailyChallenges();
});

final dailyChallengeProvider =
    FutureProvider<DailyChallengeSelection?>((ref) async {
  final progress = ref.watch(gameProgressProvider);
  final definitions = await ref.watch(dailyChallengeDefinitionsProvider.future);
  final tasks = await ref.watch(tasksProvider.future);
  final definition = DailyChallengeService.selectDefinition(
    definitions: definitions,
    date: DateTime.now(),
    careerLevel: progress.careerLevel,
    companyKey: progress.companyKey,
  );
  if (definition == null) return null;

  final matches = tasks.where((task) => task.id == definition.taskId);
  if (matches.isEmpty) return null;

  return DailyChallengeSelection(
    definition: definition,
    task: matches.first,
    dateKey: DailyChallengeService.dateKey(DateTime.now()),
  );
});

final interviewRoundsProvider =
    FutureProvider<List<InterviewRoundDefinition>>((ref) {
  return ref.read(contentRepositoryProvider).loadInterviewRounds();
});

final interviewResultsProvider =
    FutureProvider<List<InterviewResult>>((ref) {
  return ref.read(interviewResultRepositoryProvider).loadAll();
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

final portfolioSnapshotProvider = FutureProvider<PortfolioSnapshot>((ref) {
  return ref.read(portfolioRepositoryProvider).load();
});

final promotionReviewProvider = FutureProvider<PromotionReview>((ref) async {
  final progress = ref.watch(gameProgressProvider);
  final skills = await ref.watch(skillProfileProvider.future);
  final boss = await ref.watch(bossCaseProvider.future);
  final bossResult =
      await ref.read(bossCaseResultRepositoryProvider).load(boss.id);
  final interviews = await ref.watch(interviewResultsProvider.future);
  final bestInterviewScore = interviews.isEmpty
      ? null
      : interviews
          .map((result) => result.bestScore)
          .reduce((a, b) => a > b ? a : b);

  return CareerProgressionService.evaluate(
    progress: progress,
    skills: skills,
    bossCaseScore: bossResult?.totalScore,
    bestInterviewScore: bestInterviewScore,
  );
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

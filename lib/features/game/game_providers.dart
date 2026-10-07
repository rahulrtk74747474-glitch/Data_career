import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/app_database.dart';
import '../../models/achievement_badge.dart';
import '../../models/analyst_task.dart';
import '../../models/analytics_challenge.dart';
import '../../models/boss_case.dart';
import '../../models/boss_case_result.dart';
import '../../models/capstone.dart';
import '../../models/capstone_result.dart';
import '../../models/dashboard_challenge.dart';
import '../../models/daily_challenge.dart';
import '../../models/interview.dart';
import '../../models/interview_result.dart';
import '../../models/job_readiness.dart';
import '../../models/narrative_content.dart';
import '../../models/pandas_challenge.dart';
import '../../models/placement_question.dart';
import '../../models/reminder_settings.dart';
import '../../models/portfolio_snapshot.dart';
import '../../models/skill_mastery.dart';
import '../../models/spreadsheet_challenge.dart';
import '../../models/sql_table_schema.dart';
import '../../repositories/achievement_repository.dart';
import '../../repositories/boss_case_result_repository.dart';
import '../../repositories/capstone_result_repository.dart';
import '../../repositories/content_repository.dart';
import '../../repositories/evidence_repository.dart';
import '../../repositories/interview_result_repository.dart';
import '../../repositories/mastery_repository.dart';
import '../../repositories/portfolio_repository.dart';
import '../../repositories/reminder_settings_repository.dart';
import '../../repositories/sql_workspace_repository.dart';
import '../../repositories/task_performance_repository.dart';
import '../../services/adaptive_review_service.dart';
import '../../services/achievement_service.dart';
import '../../services/backup_service.dart';
import '../../services/cloud_sync_service.dart';
import '../../services/boss_case_selection_service.dart';
import '../../services/career_progression_service.dart';
import '../../services/career_task_service.dart';
import '../../services/certificate_export_service.dart';
import '../../services/company_chapter_progression_service.dart';
import '../../services/content_pack_loader.dart';
import '../../services/daily_challenge_service.dart';
import '../../services/graduation_service.dart';
import '../../services/job_readiness_service.dart';
import '../../services/portfolio_delivery_service.dart';
import '../../services/portfolio_export_service.dart';
import '../../services/portfolio_pdf_export_service.dart';
import '../../services/release_diagnostics_service.dart';
import '../../services/reminder_scheduler.dart';
import '../../services/sql_runner.dart';
import '../../services/startup_service.dart';
import '../../services/weekly_case_service.dart';
import 'game_progress.dart';

final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => const ContentRepository(),
);

final pendingLaunchNotificationPayloadProvider =
    StateProvider<String?>((ref) => null);

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final contentPackLoaderProvider = Provider<ContentPackLoader>((ref) {
  return ContentPackLoader(ref.watch(appDatabaseProvider));
});

final startupServiceProvider = Provider<StartupService>((ref) {
  return OfflineStartupService(
    ref.watch(appDatabaseProvider),
    ref.watch(contentPackLoaderProvider),
  );
});

final startupInitializationProvider = FutureProvider<void>((ref) async {
  await ref.read(appDatabaseProvider).database;
  await ref.read(contentPackLoaderProvider).installBundledPacks();
});

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return AchievementRepository(ref.watch(appDatabaseProvider));
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(appDatabaseProvider));
});

final cloudRuntimeConfigProvider = Provider<CloudRuntimeConfig>((ref) {
  return CloudRuntimeConfig.fromEnvironment();
});

final cloudSyncServiceProvider = Provider<CloudSyncGateway>((ref) {
  final service = SupabaseCloudService(
    config: ref.watch(cloudRuntimeConfigProvider),
  );
  ref.onDispose(service.close);
  return service;
});

final weeklyCaseServiceProvider = Provider<WeeklyCaseService>((ref) {
  final service = WeeklyCaseService(
    config: ref.watch(cloudRuntimeConfigProvider),
  );
  ref.onDispose(service.close);
  return service;
});

final releaseDiagnosticsServiceProvider =
    Provider<ReleaseDiagnosticsService>((ref) {
  return ReleaseDiagnosticsService(
    ref.watch(backupServiceProvider),
    ref.watch(cloudRuntimeConfigProvider),
  );
});

final releaseDiagnosticsProvider =
    FutureProvider<ReleaseDiagnostics>((ref) {
  return ref.read(releaseDiagnosticsServiceProvider).load();
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

final capstoneResultRepositoryProvider =
    Provider<CapstoneResultRepository>((ref) {
  return CapstoneResultRepository(ref.watch(appDatabaseProvider));
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

final portfolioPdfExportServiceProvider =
    Provider<PortfolioPdfExportService>((ref) {
  return PortfolioPdfExportService(ref.watch(appDatabaseProvider));
});

final certificateExportServiceProvider =
    Provider<CertificateExportService>((ref) {
  return CertificateExportService(ref.watch(appDatabaseProvider));
});

final portfolioDeliveryServiceProvider =
    Provider<PortfolioDeliveryService>((ref) {
  return const PortfolioDeliveryService();
});

final interviewResultRepositoryProvider =
    Provider<InterviewResultRepository>((ref) {
  return InterviewResultRepository(ref.watch(appDatabaseProvider));
});

final reminderSettingsRepositoryProvider =
    Provider<ReminderSettingsRepository>((ref) {
  return const ReminderSettingsRepository();
});

final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  return LocalNotificationReminderScheduler();
});

final reminderSettingsProvider = FutureProvider<ReminderSettings>((ref) {
  return ref.read(reminderSettingsRepositoryProvider).load();
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

final insightScenariosProvider =
    FutureProvider<List<InsightScenario>>((ref) {
  return ref.read(contentRepositoryProvider).loadInsightScenarios();
});

final managerDialoguesProvider =
    FutureProvider<List<ManagerDialogue>>((ref) {
  return ref.read(contentRepositoryProvider).loadManagerDialogues();
});

final randomEventsProvider =
    FutureProvider<List<RandomEventDefinition>>((ref) {
  return ref.read(contentRepositoryProvider).loadRandomEvents();
});

final placementQuestionsProvider =
    FutureProvider<List<PlacementQuestion>>((ref) {
  return ref.read(contentRepositoryProvider).loadPlacementQuestions();
});

final bossCasesProvider = FutureProvider<List<BossCaseDefinition>>((ref) {
  return ref.read(contentRepositoryProvider).loadBossCases();
});

final finalCapstoneProvider = FutureProvider<CapstoneDefinition>((ref) {
  return ref.read(contentRepositoryProvider).loadCapstone();
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

final analyticsChallengesProvider =
    FutureProvider<List<AnalyticsChallenge>>((ref) {
  return ref.read(contentRepositoryProvider).loadAnalyticsChallenges();
});

final dashboardChallengesProvider =
    FutureProvider<List<DashboardChallenge>>((ref) {
  return ref.read(contentRepositoryProvider).loadDashboardChallenges();
});

final spreadsheetChallengesProvider =
    FutureProvider<List<SpreadsheetChallenge>>((ref) {
  return ref.read(contentRepositoryProvider).loadSpreadsheetChallenges();
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

final interviewGauntletProvider =
    FutureProvider<InterviewRoundDefinition>((ref) async {
  final rounds = await ref.watch(interviewRoundsProvider.future);
  return rounds.singleWhere(
    (round) => round.key == 'job_readiness_gauntlet',
  );
});

final availableInterviewRoundsProvider =
    FutureProvider<List<InterviewRoundDefinition>>((ref) async {
  final progress = ref.watch(gameProgressProvider);
  final rounds = await ref.watch(interviewRoundsProvider.future);
  return rounds
      .where(
        (round) =>
            round.companyKey == 'general' ||
            (round.companyKey == progress.companyKey &&
                round.minCompanyChapter <= progress.resolvedCompanyChapter),
      )
      .toList();
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

final capstoneResultProvider = FutureProvider<CapstoneResult?>((ref) async {
  final definition = await ref.watch(finalCapstoneProvider.future);
  return ref.read(capstoneResultRepositoryProvider).load(definition.id);
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
  final relevantInterviews = progress.companyKey == 'bank'
      ? interviews
          .where((result) => result.roundKey == 'bank_analytics')
          .toList()
      : interviews;
  final bestInterviewScore = relevantInterviews.isEmpty
      ? null
      : relevantInterviews
          .map((result) => result.bestScore)
          .reduce((a, b) => a > b ? a : b);

  return CareerProgressionService.evaluate(
    progress: progress,
    skills: skills,
    bossCaseScore: bossResult?.totalScore,
    bestInterviewScore: bestInterviewScore,
  );
});

final companyChapterReviewProvider =
    FutureProvider<CompanyChapterReview>((ref) async {
  final progress = ref.watch(gameProgressProvider);
  final skills = await ref.watch(skillProfileProvider.future);
  final tasks = await ref.watch(tasksProvider.future);
  final boss = await ref.watch(bossCaseProvider.future);
  final bossResult =
      await ref.read(bossCaseResultRepositoryProvider).load(boss.id);
  final interviews = await ref.watch(interviewResultsProvider.future);

  final currentCompanyTasks = tasks
      .where((task) => task.companyKey == progress.companyKey)
      .toList();
  final completedCurrentCompanyTickets = currentCompanyTasks
      .where((task) => progress.completedTaskIds.contains(task.id))
      .length;

  int? interviewScore;
  String? requiredRoundKey;
  switch (progress.companyKey) {
    case 'logistics':
      requiredRoundKey = 'logistics_analytics';
      break;
    case 'hospital':
      requiredRoundKey = 'hospital_analytics';
      break;
    case 'bank':
      requiredRoundKey = 'bank_analytics';
      break;
    case 'saas':
      final generalResults = interviews
          .where(
            (result) =>
                result.roundKey != 'bank_analytics' &&
                result.roundKey != 'hospital_analytics' &&
                result.roundKey != 'logistics_analytics',
          )
          .toList();
      if (generalResults.isNotEmpty) {
        interviewScore = generalResults
            .map((result) => result.bestScore)
            .reduce((a, b) => a > b ? a : b);
      }
      break;
  }

  if (requiredRoundKey != null) {
    final companyResults = interviews
        .where((result) => result.roundKey == requiredRoundKey)
        .toList();
    if (companyResults.isNotEmpty) {
      interviewScore = companyResults
          .map((result) => result.bestScore)
          .reduce((a, b) => a > b ? a : b);
    }
  }

  return CompanyChapterProgressionService.evaluate(
    progress: progress,
    completedCurrentCompanyTickets: completedCurrentCompanyTickets,
    skills: skills,
    bossCaseScore: bossResult?.totalScore,
    interviewScore: interviewScore,
  );
});

final jobReadinessProvider =
    FutureProvider<JobReadinessReport>((ref) async {
  final progress = ref.watch(gameProgressProvider);
  final skills = await ref.watch(skillProfileProvider.future);
  final portfolio = await ref.watch(portfolioSnapshotProvider.future);
  final interviews = await ref.watch(interviewResultsProvider.future);
  final capstone = await ref.watch(capstoneResultProvider.future);

  return JobReadinessService.calculate(
    progress: progress,
    skills: skills,
    bossCases: portfolio.bossCases,
    interviews: interviews,
    evidence: portfolio.attempts,
    capstone: capstone,
  );
});

final graduationEligibilityProvider =
    FutureProvider<GraduationEligibility>((ref) async {
  final progress = ref.watch(gameProgressProvider);
  final readiness = await ref.watch(jobReadinessProvider.future);
  final capstone = await ref.watch(capstoneResultProvider.future);
  final interviews = await ref.watch(interviewResultsProvider.future);
  InterviewResult? gauntlet;
  for (final result in interviews) {
    if (result.roundKey == 'job_readiness_gauntlet') {
      gauntlet = result;
      break;
    }
  }

  return GraduationService.evaluate(
    progress: progress,
    readiness: readiness,
    capstone: capstone,
    gauntlet: gauntlet,
  );
});

final achievementsProvider =
    FutureProvider<List<AchievementBadge>>((ref) async {
  final progress = ref.watch(gameProgressProvider);
  final skills = await ref.watch(skillProfileProvider.future);
  final portfolio = await ref.watch(portfolioSnapshotProvider.future);
  final interviews = await ref.watch(interviewResultsProvider.future);
  final graduation = await ref.watch(graduationEligibilityProvider.future);

  final badges = AchievementService.evaluate(
    progress: progress,
    skills: skills,
    portfolio: portfolio,
    interviews: interviews,
    graduated: graduation.eligible,
  );
  await ref.read(achievementRepositoryProvider).sync(badges);
  final persisted = await ref.read(achievementRepositoryProvider).loadUnlocked();

  return [
    for (final badge in badges)
      AchievementBadge(
        id: badge.id,
        title: badge.title,
        description: badge.description,
        unlocked: badge.unlocked || persisted.contains(badge.id),
      ),
  ];
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

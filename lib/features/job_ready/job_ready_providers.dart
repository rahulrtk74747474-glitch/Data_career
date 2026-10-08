import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/job_ready_v15.dart';
import '../../models/flagship_attempt.dart';
import '../../repositories/job_ready_repository.dart';
import '../../repositories/flagship_attempt_repository.dart';
import '../../services/flagship_project_export_service.dart';
import '../game/game_providers.dart';

final jobReadyRepositoryProvider = Provider<JobReadyRepository>(
  (ref) => const JobReadyRepository(),
);

final flagshipWorkdaysProvider = FutureProvider<List<FlagshipWorkday>>(
  (ref) => ref.read(jobReadyRepositoryProvider).loadWorkdays(),
);

final domainPlaybooksProvider = FutureProvider<List<DomainPlaybook>>(
  (ref) => ref.read(jobReadyRepositoryProvider).loadDomainPlaybooks(),
);

final leadershipCasesProvider = FutureProvider<List<LeadershipCase>>(
  (ref) => ref.read(jobReadyRepositoryProvider).loadLeadershipCases(),
);

final adaptiveCoachScenariosProvider =
    FutureProvider<List<AdaptiveCoachScenario>>(
  (ref) => ref.read(jobReadyRepositoryProvider).loadCoachScenarios(),
);

final flagshipAttemptRepositoryProvider =
    Provider<FlagshipAttemptRepository>(
  (ref) => const FlagshipAttemptRepository(),
);

final flagshipAttemptsProvider =
    FutureProvider<Map<String, FlagshipAttempt>>(
  (ref) => ref.read(flagshipAttemptRepositoryProvider).loadAll(),
);

final flagshipAttemptProvider =
    FutureProvider.family<FlagshipAttempt, String>(
  (ref, workdayId) =>
      ref.read(flagshipAttemptRepositoryProvider).load(workdayId),
);

final flagshipProjectExportServiceProvider =
    Provider<FlagshipProjectExportService>(
  (ref) => FlagshipProjectExportService(ref.watch(appDatabaseProvider)),
);

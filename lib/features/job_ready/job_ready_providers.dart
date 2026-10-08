import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/job_ready_v15.dart';
import '../../repositories/job_ready_repository.dart';

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

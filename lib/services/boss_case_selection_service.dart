import '../models/boss_case.dart';

class BossCaseSelectionService {
  const BossCaseSelectionService._();

  static BossCaseDefinition select({
    required List<BossCaseDefinition> cases,
    required String companyKey,
    required int careerLevel,
  }) {
    final eligible = cases
        .where(
          (item) =>
              item.companyKey == companyKey &&
              item.minCareerLevel <= careerLevel,
        )
        .toList()
      ..sort(
        (a, b) => b.minCareerLevel.compareTo(a.minCareerLevel),
      );

    if (eligible.isNotEmpty) return eligible.first;

    final fallback = cases
        .where((item) => item.minCareerLevel <= careerLevel)
        .toList()
      ..sort(
        (a, b) => b.minCareerLevel.compareTo(a.minCareerLevel),
      );

    if (fallback.isNotEmpty) return fallback.first;
    if (cases.isEmpty) {
      throw StateError('No Boss Cases are available.');
    }
    return cases.first;
  }
}

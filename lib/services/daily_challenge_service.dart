import '../models/daily_challenge.dart';

class DailyChallengeService {
  const DailyChallengeService._();

  static DailyChallengeDefinition? selectDefinition({
    required List<DailyChallengeDefinition> definitions,
    required DateTime date,
    required int careerLevel,
    required String companyKey,
  }) {
    final eligible = definitions
        .where(
          (definition) =>
              definition.companyKey == companyKey &&
              definition.minCareerLevel <= careerLevel,
        )
        .toList();

    if (eligible.isEmpty) return null;

    final day = DateTime.utc(date.year, date.month, date.day);
    final anchor = DateTime.utc(2026, 1, 1);
    final index = day.difference(anchor).inDays.abs() % eligible.length;
    return eligible[index];
  }

  static String dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

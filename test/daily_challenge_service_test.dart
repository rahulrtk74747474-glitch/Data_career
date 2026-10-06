import 'package:dataquest_analyst_career/models/daily_challenge.dart';
import 'package:dataquest_analyst_career/services/daily_challenge_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const definitions = [
    DailyChallengeDefinition(
      id: 'e1',
      taskId: 'task-e1',
      bonusXp: 30,
      companyKey: 'ecommerce',
      minCareerLevel: 0,
    ),
    DailyChallengeDefinition(
      id: 'e2',
      taskId: 'task-e2',
      bonusXp: 40,
      companyKey: 'ecommerce',
      minCareerLevel: 1,
    ),
    DailyChallengeDefinition(
      id: 's1',
      taskId: 'task-s1',
      bonusXp: 50,
      companyKey: 'saas',
      minCareerLevel: 2,
    ),
  ];

  test('same date and career context selects the same challenge', () {
    final first = DailyChallengeService.selectDefinition(
      definitions: definitions,
      date: DateTime(2026, 10, 6),
      careerLevel: 1,
      companyKey: 'ecommerce',
    );
    final second = DailyChallengeService.selectDefinition(
      definitions: definitions,
      date: DateTime(2026, 10, 6),
      careerLevel: 1,
      companyKey: 'ecommerce',
    );

    expect(first, isNotNull);
    expect(second!.id, first!.id);
  });

  test('selection respects company and minimum career level', () {
    final selected = DailyChallengeService.selectDefinition(
      definitions: definitions,
      date: DateTime(2026, 10, 6),
      careerLevel: 2,
      companyKey: 'saas',
    );

    expect(selected, isNotNull);
    expect(selected!.id, 's1');
  });

  test('date key is stable and zero padded', () {
    expect(
      DailyChallengeService.dateKey(DateTime(2026, 2, 3)),
      '2026-02-03',
    );
  });
}

import 'package:dataquest_analyst_career/features/game/game_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('learning reward IDs survive progress serialization', () {
    final progress = GameProgress.initial().copyWith(
      xp: 120,
      rewardedLearningIds: {
        'academy:foundation-sql-01',
        'pandas:pandas-filter-001',
      },
    );

    final restored = GameProgress.fromJson(progress.toJson());

    expect(restored.xp, 120);
    expect(
      restored.rewardedLearningIds,
      containsAll({
        'academy:foundation-sql-01',
        'pandas:pandas-filter-001',
      }),
    );
  });
}

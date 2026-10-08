import 'package:dataquest_analyst_career/models/flagship_attempt.dart';
import 'package:dataquest_analyst_career/repositories/flagship_attempt_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('workday drafts survive loading without finishing any stage', () async {
    const repository = FlagshipAttemptRepository();
    const draft = FlagshipAttempt(
      workdayId: 'flagship-ecommerce-revenue',
      selectedIssues: {'Duplicate event warning'},
      tool: 'SQL',
      analysisText: 'SELECT segment FROM sample',
      statisticsAnswer: 'A single period cannot prove growth.',
      chartAnswer: 'Show segments and refunds.',
      managerText: 'We should compare customer cohorts.',
      hintsUsed: 1,
    );
    await repository.save(draft);
    final restored = await repository.load(draft.workdayId);
    expect(restored.isComplete, isFalse);
    expect(restored.completedStages, isEmpty);
    expect(restored.selectedIssues, contains('Duplicate event warning'));
    expect(restored.tool, 'SQL');
    expect(restored.analysisText, contains('segment'));
    expect(restored.statisticsAnswer, contains('single period'));
    expect(restored.chartAnswer, contains('refunds'));
    expect(restored.managerText, contains('customer cohorts'));
    expect(restored.hintsUsed, 1);
  });

  test('parallel drafts for different workdays do not overwrite one another',
      () async {
    const repository = FlagshipAttemptRepository();
    await Future.wait([
      for (var i = 0; i < 12; i++)
        repository.save(FlagshipAttempt(
          workdayId: 'draft-$i',
          analysisText: 'query $i',
          hintsUsed: i % 4,
        )),
    ]);
    final all = await repository.loadAll();
    expect(all.length, 12);
    for (var i = 0; i < 12; i++) {
      expect(all['draft-$i']?.analysisText, 'query $i');
      expect(all['draft-$i']?.hintsUsed, i % 4);
    }
  });

  test('saving a draft does not remove completed scoring or evidence', () async {
    const repository = FlagshipAttemptRepository();
    const original = FlagshipAttempt(
      workdayId: 'flagship-ecommerce-revenue',
      selectedIssues: {'Duplicate order'},
      tool: 'SQL',
      analysisText: 'SELECT 1',
      completedStages: {'quality', 'tool'},
      issueScore: 100,
      toolScore: 100,
    );
    await repository.save(original);
    await repository.save(original.copyWith(
      analysisText: 'SELECT 2',
      managerText: 'An unfinished status update.',
    ));
    final restored = await repository.load(original.workdayId);
    expect(restored.completedStages, {'quality', 'tool'});
    expect(restored.issueScore, 100);
    expect(restored.toolScore, 100);
    expect(restored.analysisText, 'SELECT 2');
  });
}

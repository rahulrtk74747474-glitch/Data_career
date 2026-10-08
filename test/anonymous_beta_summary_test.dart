import 'package:dataquest_analyst_career/services/anonymous_beta_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('never export raw free text, dates or names by default', () {
    final raw = <String, dynamic>{
      'appOpens': 7,
      'workdayStarts': 3,
      'workdayCompletions': 1,
      'firstOpen': '2026-10-08T12:00:00Z',
      'activeDates': ['2026-10-08', '2026-10-09'],
      'name': 'Private User',
      'feedback': [
        {
          'freeText': 'my private email is learner@example.test',
          'submittedAt': '2026-10-08',
          'realism': 4,
          'usefulness': 5,
          'wouldPay': 'Maybe',
        },
      ],
    };
    expect(
      () => AnonymousBetaSummary.fromTelemetry(raw, consent: false),
      throwsStateError,
    );
    final summary = AnonymousBetaSummary.fromTelemetry(
      raw, consent: true, independentSqlPassed: true,
    );
    expect(summary['meanRealism'], 4);
    expect(summary['meanUsefulness'], 5);
    expect(summary['feedbackCount'], 1);
    expect(summary['independentSqlPassed'], isTrue);
    final serialized = summary.toString();
    expect(serialized, isNot(contains('learner@example.test')));
    expect(serialized, isNot(contains('2026-10-08')));
    expect(serialized, isNot(contains('Private User')));
    expect(serialized, isNot(contains('freeText')));
  });
}

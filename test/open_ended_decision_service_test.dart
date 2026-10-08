import 'package:dataquest_analyst_career/services/open_ended_decision_service.dart';
import 'package:dataquest_analyst_career/services/analyst_mistake_diagnostics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bank analyst must explain denominator versus absolute exposure', () {
    final good = OpenEndedDecisionService.grade(
      workdayId: 'flagship-bank-risk',
      stage: 'statistics',
      answer: 'The ratio fell partly because the denominator grew. Absolute exposure may still be higher, so compare both trends before declaring lower risk.',
    );
    final weak = OpenEndedDecisionService.grade(
      workdayId: 'flagship-bank-risk',
      stage: 'statistics',
      answer: 'denominator ratio exposure growth',
    );
    expect(good.passed, isTrue);
    expect(weak.passed, isFalse);
  });

  test('hospital chart requires a justified operational view', () {
    final good = OpenEndedDecisionService.grade(
      workdayId: 'flagship-hospital-capacity',
      stage: 'chart',
      answer: 'Show wait times per unit using median and P90 alongside daily staffing capacity.',
    );
    final bad = OpenEndedDecisionService.grade(
      workdayId: 'flagship-hospital-capacity',
      stage: 'chart',
      answer: 'Make a pretty pie chart.',
    );
    expect(good.passed, isTrue);
    expect(bad.passed, isFalse);
  });

  test('flagship model answers meet the open-ended rubric', () {
    const answers = <String, List<String>>{
      'flagship-bank-risk': [
        'The ratio improved partly because the denominator grew; evaluate both absolute exposure and the ratio before declaring lower risk.',
        'Exposure by risk band with both amount and share, plus delinquency trend.',
      ],
      'flagship-hospital-capacity': [
        "Simpson's paradox / composition effect: the aggregate can move differently from subgroup trends.",
        'Unit-level wait trends with median/P90 and a capacity-gap view by day.',
      ],
      'flagship-logistics-sla': [
        'Absolute cost increased, but normalized shipping efficiency improved; investigate weight and route mix before cutting spend.',
        'Route-level cost/kg and SLA bars plus a time trend for late-rate/P90 transit time.',
      ],
    };
    for (final entry in answers.entries) {
      expect(OpenEndedDecisionService.grade(
        workdayId: entry.key, stage: 'statistics', answer: entry.value[0],
      ).passed, isTrue, reason: entry.key);
      expect(OpenEndedDecisionService.grade(
        workdayId: entry.key, stage: 'chart', answer: entry.value[1],
      ).passed, isTrue, reason: entry.key);
    }
  });

  test('SQL feedback distinguishes possible join multiplier and wrong grain', () {
    final diagnostic = AnalystMistakeDiagnostics.sql(
      query: 'SELECT * FROM orders JOIN order_items ON orders.id = order_items.order_id',
      graderFeedback: 'Incorrect result.',
      actualRowCount: 18,
      expectedRowCount: 3,
    );
    expect(diagnostic, contains('many-to-many join'));
    expect(diagnostic, contains('Grain mismatch'));
  });

  test('manager feedback flags unqualified causal overclaim', () {
    expect(AnalystMistakeDiagnostics.managerOverclaim(
      'The enterprise segment definitely causes growth.',
    ), contains('Causal overclaim'));
    expect(AnalystMistakeDiagnostics.managerOverclaim(
      'The data does not prove that segment causes growth.',
    ), isNull);
  });
}

import 'package:dataquest_analyst_career/models/boss_case.dart';
import 'package:dataquest_analyst_career/services/boss_case_selection_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final cases = [
    _case('ecom', 'ecommerce', 0),
    _case('saas', 'saas', 2),
    _case('bank', 'bank', 4),
  ];

  test('selects ecommerce case for junior career', () {
    final selected = BossCaseSelectionService.select(
      cases: cases,
      companyKey: 'ecommerce',
      careerLevel: 1,
    );

    expect(selected.id, 'ecom');
  });

  test('selects SaaS case for Senior Analyst', () {
    final selected = BossCaseSelectionService.select(
      cases: cases,
      companyKey: 'saas',
      careerLevel: 3,
    );

    expect(selected.id, 'saas');
  });

  test('selects bank case for Lead Analyst', () {
    final selected = BossCaseSelectionService.select(
      cases: cases,
      companyKey: 'bank',
      careerLevel: 4,
    );

    expect(selected.id, 'bank');
  });
}

BossCaseDefinition _case(
  String id,
  String companyKey,
  int minCareerLevel,
) {
  return BossCaseDefinition(
    id: id,
    title: id,
    company: companyKey,
    context: '',
    datasetName: '',
    cleaningPrompt: '',
    cleaningOptions: const ['A'],
    cleaningExpectedSelections: const ['A'],
    sqlPrompt: '',
    sqlExpectedRows: const [],
    kpiPrompt: '',
    kpiExpected: 0,
    kpiTolerance: 0,
    chartPrompt: '',
    chartOptions: const ['A'],
    chartExpected: 'A',
    recommendationPrompt: '',
    recommendationOptions: const ['A'],
    recommendationExpected: 'A',
    rubric: const {
      'cleaning': 20,
      'sql': 30,
      'kpi': 20,
      'chart': 10,
      'recommendation': 20,
    },
    companyKey: companyKey,
    minCareerLevel: minCareerLevel,
  );
}

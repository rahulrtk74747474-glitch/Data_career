import 'package:dataquest_analyst_career/services/filter_context_dax_lab.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('filter context propagates through customer-sales relationship', () {
    expect(FilterContextDaxLab.evaluate('Total = SUM(Sales[amount])'), 4200);
    expect(FilterContextDaxLab.evaluate('SUM(Sales[amount])',
        slicerRegion: 'North'), 2300);
    expect(FilterContextDaxLab.evaluate('SUM(Sales[amount])',
        slicerRegion: 'South'), 1900);
  });

  test('CALCULATE replaces slicer and ALL removes customer filter', () {
    expect(
      FilterContextDaxLab.evaluate(
        'South = CALCULATE(SUM(Sales[amount]), Customers[region]="South")',
        slicerRegion: 'North',
      ), 1900,
    );
    const measure = 'All Sales = CALCULATE(SUM(Sales[amount]), ALL(Customers))';
    expect(FilterContextDaxLab.passesAllRegionIndependentTask(measure), isTrue);
    expect(FilterContextDaxLab.passesAllRegionIndependentTask(
      'Total = SUM(Sales[amount])',
    ), isFalse);
    expect(FilterContextDaxLab.passesAllRegionIndependentTask(
      'Total = 4200',
    ), isFalse);
  });

  test('unknown functions and invalid formulas fail safely', () {
    expect(() => FilterContextDaxLab.evaluate('=RELATEDTABLE(X)'),
        throwsFormatException);
    expect(() => FilterContextDaxLab.evaluate('Total = 4200'),
        throwsFormatException);
  });
}

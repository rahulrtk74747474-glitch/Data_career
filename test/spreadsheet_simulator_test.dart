import 'package:dataquest_analyst_career/models/spreadsheet_challenge.dart';
import 'package:dataquest_analyst_career/services/spreadsheet_simulator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formula grading normalizes spaces and dollar references', () {
    final result = SpreadsheetSimulator.run(
      _challenge(
        expectedCommand: 'FORMULA =B2*(1-C2)',
        rows: const [{'row': 2, 'gross': 1000, 'discount': 0.1}],
        expectedRows: const [],
      ),
      r'formula = $B2 * (1 - C2)',
    );
    expect(result.isCorrect, isTrue);
  });

  test('equivalent but differently written formula earns credit', () {
    final challenge = _challenge(
      rows: const [{'row': 2, 'gross': 1000, 'discount': 0.1}],
      expectedCommand: 'FORMULA =B2*(1-C2)',
      expectedRows: const [],
    );
    expect(SpreadsheetSimulator.run(challenge, '=B2-B2*C2').isCorrect, isTrue);
    expect(SpreadsheetSimulator.run(challenge, '=900').isCorrect, isFalse);
    expect(SpreadsheetSimulator.run(challenge, '=B2*(1+C2)').isCorrect, isFalse);
    expect(SpreadsheetSimulator.run(challenge, '=B2/0').isCorrect, isFalse);
  });

  test('margin formula is calculated on live and altered cells', () {
    final challenge = _challenge(
      rows: const [{'row': 2, 'revenue': 2000, 'cost': 1400}],
      expectedCommand: 'FORMULA =(B2-C2)/B2',
      expectedRows: const [],
    );
    expect(SpreadsheetSimulator.run(challenge, '=1-C2/B2').isCorrect, isTrue);
    expect(SpreadsheetSimulator.run(challenge, '=0.3').isCorrect, isFalse);
  });

  test('sort task requires requested row order and valid direction', () {
    final challenge = _challenge(
      rows: const [
        {'id': 'A', 'revenue': 100},
        {'id': 'B', 'revenue': 300},
        {'id': 'C', 'revenue': 200},
      ],
      expectedCommand: 'SORT revenue DESC',
      expectedRows: const [
        {'id': 'B', 'revenue': 300},
        {'id': 'C', 'revenue': 200},
        {'id': 'A', 'revenue': 100},
      ],
    );

    expect(
      SpreadsheetSimulator.run(challenge, 'SORT revenue DESC').isCorrect,
      isTrue,
    );
    expect(
      SpreadsheetSimulator.run(challenge, 'SORT revenue ASC').isCorrect,
      isFalse,
    );
    expect(
      SpreadsheetSimulator.run(challenge, 'SORT revenue SIDEWAYS').feedback,
      contains('ASC or DESC'),
    );
  });

  test('lookup and filter are case-insensitive but preserve source values', () {
    final lookup = SpreadsheetSimulator.executeRows(
      const [
        {'customer_id': 'C001', 'segment': 'Retail'},
        {'customer_id': 'C002', 'segment': 'SMB'},
      ],
      'LOOKUP CUSTOMER_ID c002 SEGMENT',
    );
    final filter = SpreadsheetSimulator.executeRows(
      const [
        {'id': 1, 'status': 'Completed'},
        {'id': 2, 'status': 'Refunded'},
      ],
      'FILTER STATUS = completed',
    );

    expect(lookup, const [
      {'customer_id': 'C002', 'segment': 'SMB'},
    ]);
    expect(filter, const [
      {'id': 1, 'status': 'Completed'},
    ]);
  });

  test('pivot sums and date normalization are deterministic', () {
    final pivot = SpreadsheetSimulator.run(
      _challenge(
        rows: const [
          {'region': 'North', 'revenue': 100},
          {'region': 'West', 'revenue': 80},
          {'region': 'North', 'revenue': 50},
        ],
        expectedCommand: 'PIVOT region SUM revenue',
        expectedRows: const [
          {'region': 'North', 'sum_revenue': 150},
          {'region': 'West', 'sum_revenue': 80},
        ],
      ),
      'PIVOT region SUM revenue',
    );

    final clean = SpreadsheetSimulator.run(
      _challenge(
        rows: const [
          {'id': 1, 'date': '2026/10/02'},
          {'id': 2, 'date': '03/10/2026'},
        ],
        expectedCommand: 'CLEAN DATE_ISO date',
        expectedRows: const [
          {'id': 1, 'date': '2026-10-02'},
          {'id': 2, 'date': '2026-10-03'},
        ],
      ),
      'CLEAN DATE_ISO date',
    );

    expect(pivot.isCorrect, isTrue);
    expect(clean.isCorrect, isTrue);
  });

  test('IQR cleaning removes statistical outliers and keeps normal rows', () {
    final cleaned = SpreadsheetSimulator.executeRows(
      const [
        {'id': 1, 'amount': 10},
        {'id': 2, 'amount': 11},
        {'id': 3, 'amount': 12},
        {'id': 4, 'amount': 12},
        {'id': 5, 'amount': 13},
        {'id': 6, 'amount': 1000},
      ],
      'CLEAN OUTLIERS_IQR amount',
    );

    expect(cleaned, hasLength(5));
    expect(cleaned.any((row) => row['amount'] == 1000), isFalse);
  });

  test('invalid columns fail with a specific workbook message', () {
    final result = SpreadsheetSimulator.run(
      _challenge(
        rows: const [
          {'id': 'A', 'revenue': 100},
        ],
        expectedCommand: 'SORT revenue DESC',
        expectedRows: const [
          {'id': 'A', 'revenue': 100},
        ],
      ),
      'SORT missing DESC',
    );

    expect(result.isCorrect, isFalse);
    expect(result.feedback, contains('Column "missing" does not exist'));
  });
}

SpreadsheetChallenge _challenge({
  String expectedCommand = '',
  List<Map<String, Object?>> rows = const [],
  List<Map<String, dynamic>> expectedRows = const [],
}) {
  return SpreadsheetChallenge(
    id: 'test',
    title: 'Test',
    skillKey: 'spreadsheets',
    difficulty: 'Beginner',
    companyKey: 'ecommerce',
    context: '',
    prompt: '',
    datasetName: 'test',
    rows: rows,
    expectedCommand: expectedCommand,
    expectedRows: expectedRows,
    hints: const ['a', 'b', 'c'],
    explanation: '',
    xp: 50,
  );
}

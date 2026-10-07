import 'package:dataquest_analyst_career/models/spreadsheet_challenge.dart';
import 'package:dataquest_analyst_career/services/spreadsheet_simulator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formula grading normalizes spaces and dollar references', () {
    final result = SpreadsheetSimulator.run(
      _challenge(
        expectedCommand: 'FORMULA =B2*(1-C2)',
        expectedRows: const [],
      ),
      r'formula = $B2 * (1 - C2)',
    );

    expect(result.isCorrect, isTrue);
  });

  test('sort task requires the requested row order', () {
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
  });

  test('pivot sums and cleaning date normalization are deterministic', () {
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

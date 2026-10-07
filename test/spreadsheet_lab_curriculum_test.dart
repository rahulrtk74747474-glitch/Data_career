import 'dart:convert';

import 'package:dataquest_analyst_career/models/spreadsheet_challenge.dart';
import 'package:dataquest_analyst_career/services/spreadsheet_simulator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('spreadsheet and cleaning pack contains the requested 15 tasks', () async {
    final items = await _loadChallenges();

    expect(items, hasLength(15));
    expect(items.where((item) => item.skillKey == 'spreadsheets'), hasLength(10));
    expect(items.where((item) => item.skillKey == 'cleaning'), hasLength(5));

    for (final item in items) {
      expect(item.hints, hasLength(3), reason: item.id);
      expect(item.expectedCommand.trim(), isNotEmpty, reason: item.id);
      expect(item.rows, isNotEmpty, reason: item.id);
      expect(item.context.trim(), isNotEmpty, reason: item.id);
      expect(item.explanation.trim(), isNotEmpty, reason: item.id);
    }
  });

  test('all 15 shipped workbook commands auto-grade successfully', () async {
    final items = await _loadChallenges();

    for (final item in items) {
      final result = SpreadsheetSimulator.run(item, item.expectedCommand);
      expect(
        result.isCorrect,
        isTrue,
        reason: '${item.id}: ${result.feedback}',
      );
    }
  });

  test('task mix covers every required spreadsheet and cleaning workflow',
      () async {
    final items = await _loadChallenges();
    final commands = items.map((item) => item.expectedCommand).join('\n');

    expect(commands, contains('FORMULA '));
    expect(commands, contains('LOOKUP '));
    expect(commands, contains('SORT '));
    expect(commands, contains('FILTER '));
    expect(commands, contains('PIVOT '));
    expect(commands, contains('CLEAN FILL '));
    expect(commands, contains('CLEAN DEDUPE '));
    expect(commands, contains('CLEAN TITLE '));
    expect(commands, contains('CLEAN NONNEGATIVE '));
    expect(commands, contains('CLEAN DATE_ISO '));
  });
}

Future<List<SpreadsheetChallenge>> _loadChallenges() async {
  final raw = await rootBundle.loadString(
    'assets/content/spreadsheet_cleaning_v1.json',
  );
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  final rows = decoded['challenges'] as List<dynamic>;
  return rows
      .map(
        (row) => SpreadsheetChallenge.fromJson(
          Map<String, dynamic>.from(row as Map),
        ),
      )
      .toList();
}

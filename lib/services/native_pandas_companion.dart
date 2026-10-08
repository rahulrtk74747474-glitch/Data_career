// ignore_for_file: prefer_interpolation_to_compose_strings
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pandas_challenge.dart';
import 'sql_result_grader.dart';

class NativePandasResult {
  const NativePandasResult({
    required this.executed, required this.correctOnSample,
    required this.feedback, required this.rows,
  });
  final bool executed;
  final bool correctOnSample;
  final String feedback;
  final List<Map<String, Object?>> rows;
}

/// Optional loopback-only local desktop companion for real Pandas.
/// No learner code or records are transmitted until explicit button click.
class NativePandasCompanion {
  const NativePandasCompanion._();

  static const endpoint =
      String.fromEnvironment('DATAQUEST_PYTHON_COMPANION_URL');

  static bool get available {
    final uri = Uri.tryParse(endpoint);
    return uri != null && uri.scheme == 'http' &&
        (uri.host == 'localhost' || uri.host == '127.0.0.1') &&
        uri.path == '/run' &&
        uri.userInfo.isEmpty && uri.query.isEmpty;
  }

  static Future<NativePandasResult> run(
      PandasChallenge task, String code) async {
    if (!available) {
      return const NativePandasResult(
        executed: false,
        correctOnSample: false,
        feedback: 'The local Python companion is not configured.',
        rows: [],
      );
    }
    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': code,
          'rows': task.rows,
        }),
      ).timeout(const Duration(seconds: 18));
      if (response.statusCode != 200) {
        return NativePandasResult(
          executed: false, correctOnSample: false,
          feedback: 'Companion returned HTTP ' + response.statusCode.toString(),
          rows: const [],
        );
      }
      final payload = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );
      if (payload['error'] != null) {
        return NativePandasResult(
          executed: false, correctOnSample: false,
          feedback: 'Actual Python error: ' + payload['error'].toString(),
          rows: const [],
        );
      }
      final rows = <Map<String, Object?>>[
        for (final row in (payload['rows'] as List))
          Map<String, Object?>.from(row as Map),
      ];
      final grade = SqlResultGrader.grade(
        actualRows: rows,
        expectedRows: task.expectedRows,
      );
      return NativePandasResult(
        executed: true,
        correctOnSample: grade.isCorrect,
        feedback: grade.isCorrect
            ? 'Real Pandas ran and matched this synthetic sample. '
                'Unseen-data skill transfer has not been established.'
            : 'Real Pandas executed, but the resulting rows do not match '
                'this exercise. ' + grade.feedback,
        rows: rows,
      );
    } catch (error) {
      return NativePandasResult(
        executed: false, correctOnSample: false,
        feedback: 'Local Python execution unavailable: ' + error.toString(),
        rows: const [],
      );
    }
  }
}

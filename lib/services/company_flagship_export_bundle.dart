// ignore_for_file: prefer_interpolation_to_compose_strings
import 'dart:convert';

import '../data/app_database.dart';
import '../models/flagship_attempt.dart';
import '../models/job_ready_v15.dart';
import 'company_flagship_case_service.dart';
import 'sql_result_grader.dart';
import 'sql_runner.dart';

/// Portable replay pack for SaaS, banking, hospital and logistics cases.
/// Unlike previews, exported CSVs include every versioned source event.
class CompanyFlagshipExportBundle {
  const CompanyFlagshipExportBundle(this._database);
  final AppDatabase _database;

  Future<Map<String, String>> build({
    required FlagshipWorkday workday,
    required FlagshipAttempt attempt,
  }) async {
    final service = CompanyFlagshipCaseService(_database);
    final caseInfo = await service.definition(workday.companyKey);
    final events = await service.rows(workday.companyKey);
    final latest = await service.cleanedRows(workday.companyKey);
    final query = attempt.analysisText.trim();
    final credible = attempt.tool == 'SQL' &&
        CompanyFlagshipCaseService.integrityWarning(query, workday.companyKey) == null;
    final execution = credible ? await SqlRunner(_database).runReadOnly(query) : null;
    final baseline = execution != null && execution.isSuccess
        ? SqlResultGrader.grade(
            actualRows: execution.rows,
            expectedRows: workday.sqlExpectedRows,
            truncated: execution.truncated,
          )
        : null;
    final holdout = (baseline?.isCorrect ?? false)
        ? await service.verifyChangedData(workday.companyKey, query)
        : null;
    final verified = baseline?.isCorrect == true && holdout?.isCorrect == true;
    final manifest = <String, Object?>{
      'source': 'DataQuest synthetic training data',
      'case_id': workday.companyKey,
      'dataset_version': 1,
      'source_event_rows': events.length,
      'latest_business_records': latest.length,
      'metric_definition': caseInfo['metricMeaning'],
      'denominator_definition': caseInfo['denominatorMeaning'],
      'tool': attempt.tool,
      'sql_executed': execution?.isSuccess ?? false,
      'baseline_result_matched': baseline?.isCorrect ?? false,
      'changed_data_result_matched': holdout?.isCorrect ?? false,
      'verified_independent_sql': verified,
      'note': 'These are synthetic one-period records. This check does not '
          'prove causal impact, real employment competence or broad SQL generalization.',
    };
    return {
      'data/events.csv': _csv(events),
      'data/latest_events.csv': _csv(latest),
      'reference_query.sql': (caseInfo['referenceQuery'] as String) + ';\n',
      'schema.sql': CompanyFlagshipCaseService.portableSchema,
      'submitted_query.sql': query.isEmpty ? '-- Not submitted\n' : query + ';\n',
      'verification.json': const JsonEncoder.withIndent('  ').convert(manifest) + '\n',
      'verified_result.csv': execution?.isSuccess == true ? _csv(execution!.rows) : '',
      'REPRODUCE.md': '# Reproduce the synthetic flagship project\n\n'
          'Company case: ' + workday.companyKey + '\n\n'
          'SQLite 3.32+ (from this directory):\n\n'
          '    sqlite3 case.db < schema.sql\n'
          '    sqlite3 case.db ".mode csv" ".import --skip 1 data/events.csv dq_case_events"\n'
          '    sqlite3 -header -csv case.db < reference_query.sql\n'
          '    sqlite3 -header -csv case.db < submitted_query.sql\n\n'
          'All original event versions are in data/events.csv. '
          'The dq_case_latest view resolves late arrivals by case_id and business_id. '
          'This case is a single-period synthetic exercise and should not be '
          'presented as employment history.\n',
    };
  }

  static String _csv(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) return '';
    final keys = rows.first.keys.toList();
    String escape(Object? value) =>
        '"' + (value?.toString() ?? '').replaceAll('"', '""') + '"';
    return ([
      keys.map(escape).join(','),
      for (final row in rows) keys.map((key) => escape(row[key])).join(','),
    ]).join('\n');
  }
}

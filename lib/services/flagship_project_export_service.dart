import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:archive/archive_io.dart';

import '../data/app_database.dart';
import '../models/flagship_attempt.dart';
import '../models/job_ready_v15.dart';
import 'ecommerce_flagship_export_bundle.dart';
import 'company_flagship_export_bundle.dart';
import 'company_flagship_case_service.dart';

class FlagshipProjectExportResult {
  const FlagshipProjectExportResult({
    required this.directoryPath,
    required this.fileCount,
    required this.archivePath,
  });

  final String directoryPath;
  final int fileCount;
  final String archivePath;
}

class FlagshipProjectExportService {
  const FlagshipProjectExportService(this._database);

  final AppDatabase _database;

  Future<FlagshipProjectExportResult> export({
    required FlagshipWorkday workday,
    required FlagshipAttempt attempt,
  }) async {
    final base = await _database.storageDirectoryPath;
    final safeId = workday.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final dir = Directory(p.join(base, 'exports', 'github_$safeId'));
    await dir.create(recursive: true);

    final files = <String, String>{
      'README.md': _readme(workday, attempt),
      'analysis.${_extension(attempt.tool)}': attempt.analysisText.trim(),
      'data_quality.md': _quality(workday, attempt),
      'executive_summary.md': attempt.managerText.trim(),
      'sample_data.csv': _csv(workday.previewRows),
      'statistics_review.md': '# Statistical reasoning\n\n${attempt.statisticsAnswer}\n',
      'dashboard_plan.md': '# Dashboard decision and justification\n\n${attempt.chartAnswer}\n',
      'limitations.md': _limitations(workday),
    };

    if (workday.companyKey == 'ecommerce') {
      files.addAll(
        await EcommerceFlagshipExportBundle(_database).build(
          workday: workday,
          attempt: attempt,
        ),
      );
    }
    if (CompanyFlagshipCaseService.validCases.contains(workday.companyKey)) {
      files.addAll(
        await CompanyFlagshipExportBundle(_database).build(
          workday: workday,
          attempt: attempt,
        ),
      );
    }

    for (final entry in files.entries) {
      await Directory(p.dirname(p.join(dir.path, entry.key)))
          .create(recursive: true);
      await File(p.join(dir.path, entry.key)).writeAsString(
        entry.value.endsWith('\n') ? entry.value : '${entry.value}\n',
        flush: true,
      );
    }

    final archivePath = p.join(base, 'exports', 'github_$safeId.zip');
    final zip = ZipFileEncoder();
    zip.create(archivePath);
    try {
      await zip.addDirectory(dir, includeDirName: true, followLinks: false);
    } finally {
      await zip.close();
    }

    return FlagshipProjectExportResult(
      directoryPath: dir.path,
      fileCount: files.length,
      archivePath: archivePath,
    );
  }

  static String _extension(String tool) {
    switch (tool) {
      case 'SQL':
        return 'sql';
      case 'Pandas':
        return 'py';
      case 'Power BI':
        return 'dax';
      case 'Excel':
        return 'txt';
      default:
        return 'txt';
    }
  }

  static String _readme(
    FlagshipWorkday workday,
    FlagshipAttempt attempt,
  ) => '''
# ${workday.title}

**Company simulation:** ${workday.companyName}  
**Role:** ${workday.role}  
**DataQuest score:** ${attempt.totalScore}/100  
**Primary tool chosen:** ${attempt.tool}

## Business problem
${workday.briefing}

## Dataset
${workday.datasetName}

## Workflow
1. Data-quality triage
2. Tool selection
3. Open-ended analysis
4. Statistical interpretation
5. Dashboard decision
6. Executive/manager communication

## Final recommendation
${attempt.managerText}

## Statistical reasoning
See `statistics_review.md` for the submitted interpretation.

## Dashboard specification
See `dashboard_plan.md` for the proposed decision view.

## Limitations
See `limitations.md` for dataset completeness, execution and assessment limitations.

## Training disclosure
This is a synthetic DataQuest learning project, not real employer work.
''';

  static String _quality(
    FlagshipWorkday workday,
    FlagshipAttempt attempt,
  ) => '''
# Data-quality review

Selected controls/issues:
${attempt.selectedIssues.map((item) => '- $item').join('\n')}

Reference issues:
${workday.correctIssues.map((item) => '- $item').join('\n')}
''';

  static String _limitations(FlagshipWorkday workday) => '''
# Dataset and assessment limitations
${workday.companyKey == 'ecommerce' ? '- The e-commerce flagship additionally exports the complete synthetic source dataset under data/ and the executable SQLite schema. Refer to REPRODUCE.md for verified execution status.' : ''}

- The sample_data.csv file supplied here contains only the ${workday.previewRows.length} preview rows embedded in the learning case. It is **not** a complete export of the underlying SQLite company tables.
- SQL work is executed against the local synthetic SQLite company database when SQL is chosen.
- Pandas, Excel and Power BI answers are assessed with deterministic offline patterns/rubrics. They are **not** executed by CPython, Microsoft Excel or the Power BI engine.
- Reproduce conclusions using the complete company dataset and real tools before publishing outside a training portfolio.
- Document your cleaning decisions, test your denominator and record assumptions before claiming real-world impact.

This is synthetic coursework, not employment history.
''';

  static String _csv(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return '';
    final columns = rows.first.keys.toList();
    final lines = <String>[columns.map(_escape).join(',')];
    for (final row in rows) {
      lines.add(
        columns.map((column) => _escape(row[column]?.toString() ?? '')).join(','),
      );
    }
    return lines.join('\n');
  }

  static String _escape(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}

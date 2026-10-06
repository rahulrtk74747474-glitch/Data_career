import 'dart:io';

import 'package:path/path.dart' as p;

import '../data/app_database.dart';

class CertificateExportResult {
  const CertificateExportResult({
    required this.path,
    required this.bytes,
  });

  final String path;
  final int bytes;
}

class CertificateExportService {
  const CertificateExportService(this._database);

  final AppDatabase _database;

  Future<CertificateExportResult> exportHtml({
    required String learnerName,
    required int readinessScore,
    required int capstoneScore,
  }) async {
    final base = await _database.storageDirectoryPath;
    final directory = Directory(p.join(base, 'exports'));
    await directory.create(recursive: true);

    final now = DateTime.now().toUtc();
    final stamp = now
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File(
      p.join(directory.path, 'dataquest_certificate_$stamp.html'),
    );

    final html = buildHtml(
      learnerName: learnerName,
      readinessScore: readinessScore,
      capstoneScore: capstoneScore,
      generatedAt: now,
    );
    await file.writeAsString(html, flush: true);

    return CertificateExportResult(
      path: file.path,
      bytes: await file.length(),
    );
  }

  static String buildHtml({
    required String learnerName,
    required int readinessScore,
    required int capstoneScore,
    required DateTime generatedAt,
  }) {
    String e(String value) => value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');

    return '''<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>DataQuest Completion Certificate</title>
<style>
body{font-family:Georgia,serif;background:#f6f7f9;margin:0;padding:28px;color:#1f2937}
.cert{max-width:900px;margin:auto;background:white;border:10px double #374151;padding:56px;text-align:center}
h1{font-size:42px;margin:0 0 10px}
h2{font-size:30px;margin:18px 0}
p{font-size:18px;line-height:1.6}
.metrics{display:flex;justify-content:center;gap:36px;margin:28px 0;font-family:Arial,sans-serif}
.metric{border:1px solid #d1d5db;padding:12px 18px;border-radius:8px}
.small{font-size:13px;color:#6b7280;font-family:Arial,sans-serif}
@media print{body{background:white;padding:0}.cert{border:8px double #374151;page-break-inside:avoid}}
</style>
</head>
<body>
<div class="cert">
<p class="small">DATAQUEST: ANALYST CAREER</p>
<h1>Certificate of Completion</h1>
<p>This certifies that</p>
<h2>${e(learnerName.trim())}</h2>
<p>completed the five-company DataQuest analyst career journey and satisfied the evidence-based graduation requirements, including the final cross-company analytics capstone and Interview Gauntlet.</p>
<div class="metrics">
<div class="metric"><strong>Job Readiness</strong><br>$readinessScore/100</div>
<div class="metric"><strong>Final Capstone</strong><br>$capstoneScore/100</div>
</div>
<p>Training domains: spreadsheets, data cleaning, SQL, statistics, Python/Pandas, dashboards, business analytics and professional communication.</p>
<p class="small">Generated ${e(generatedAt.toIso8601String())}. This is a DataQuest training completion certificate based on in-app synthetic exercises and is not an accredited academic credential.</p>
</div>
</body>
</html>''';
  }
}

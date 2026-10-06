import 'dart:io';

import 'package:path/path.dart' as p;

import '../data/app_database.dart';
import '../models/portfolio_snapshot.dart';
import '../models/skill_mastery.dart';

class PortfolioExportResult {
  const PortfolioExportResult({
    required this.path,
    required this.bytes,
  });

  final String path;
  final int bytes;
}

class PortfolioExportService {
  const PortfolioExportService(this._database);

  final AppDatabase _database;

  Future<PortfolioExportResult> exportHtml({
    required PortfolioSnapshot snapshot,
    required String role,
    required String companyName,
    required int xp,
    required List<SkillMastery> skills,
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
      p.join(directory.path, 'dataquest_portfolio_$stamp.html'),
    );

    final html = buildHtml(
      snapshot: snapshot,
      role: role,
      companyName: companyName,
      xp: xp,
      skills: skills,
      generatedAt: now,
    );
    await file.writeAsString(html, flush: true);
    return PortfolioExportResult(
      path: file.path,
      bytes: await file.length(),
    );
  }

  static String buildHtml({
    required PortfolioSnapshot snapshot,
    required String role,
    required String companyName,
    required int xp,
    required List<SkillMastery> skills,
    required DateTime generatedAt,
  }) {
    final sortedSkills = [...skills]
      ..sort((a, b) => b.mastery.compareTo(a.mastery));

    String e(String value) => value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');

    final skillRows = sortedSkills
        .map(
          (skill) =>
              '<tr><td>${e(skill.displayName)}</td><td>${skill.mastery.toStringAsFixed(0)}%</td><td>${skill.attempts}</td></tr>',
        )
        .join();

    final taskRows = snapshot.taskPerformances
        .take(12)
        .map(
          (task) =>
              '<tr><td>${e(task.title)}</td><td>${e(task.skillKey)}</td><td>${e(task.difficulty)}</td><td>${task.bestScore}/100</td><td>${task.attempts}</td></tr>',
        )
        .join();

    final bossRows = snapshot.bossCases
        .map(
          (boss) =>
              '<tr><td>${e(boss.caseId)}</td><td>${boss.totalScore}/100</td><td>${boss.sqlScore}</td><td>${boss.recommendationScore}</td></tr>',
        )
        .join();

    final historyRows = snapshot.attempts
        .take(40)
        .map(
          (attempt) =>
              '<tr><td>${e(attempt.completedAt.toLocal().toString().split('.').first)}</td><td>${e(attempt.sourceType)}</td><td>${e(attempt.title)}</td><td>${attempt.score}/100</td><td>${e(attempt.mode)}</td><td>${e(attempt.companyKey)}</td></tr>',
        )
        .join();

    return '''<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>DataQuest Analyst Portfolio</title>
<style>
body{font-family:Arial,sans-serif;margin:36px;color:#202124;line-height:1.45}
h1,h2{margin-bottom:8px}
.meta{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:8px 24px;margin-bottom:24px}
table{width:100%;border-collapse:collapse;margin:10px 0 24px}
th,td{border:1px solid #ccc;padding:8px;text-align:left;font-size:13px}
th{background:#f3f4f6}
.small{font-size:12px;color:#555}
@media print{body{margin:16mm}table{page-break-inside:auto}tr{page-break-inside:avoid}}
</style>
</head>
<body>
<h1>DataQuest Analyst Portfolio</h1>
<p class="small">Generated ${e(generatedAt.toIso8601String())}. Open this file in a browser and use Print → Save as PDF for a PDF-ready copy.</p>
<div class="meta">
<div><strong>Role</strong><br>${e(role)}</div>
<div><strong>Company</strong><br>${e(companyName)}</div>
<div><strong>Career XP</strong><br>$xp</div>
<div><strong>Recorded attempts</strong><br>${snapshot.attemptCount}</div>
</div>

<h2>Skill profile</h2>
<table><tr><th>Skill</th><th>Mastery</th><th>Attempts</th></tr>$skillRows</table>

<h2>Strongest ticket and lab evidence</h2>
<table><tr><th>Evidence</th><th>Skill</th><th>Difficulty</th><th>Best score</th><th>Attempts</th></tr>$taskRows</table>

<h2>Boss Cases</h2>
<table><tr><th>Case</th><th>Total</th><th>SQL</th><th>Recommendation</th></tr>$bossRows</table>

<h2>Immutable attempt history</h2>
<table><tr><th>Completed</th><th>Type</th><th>Evidence</th><th>Score</th><th>Mode</th><th>Company</th></tr>$historyRows</table>
</body>
</html>''';
  }
}

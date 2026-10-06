import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/app_database.dart';
import '../models/portfolio_snapshot.dart';
import '../models/skill_mastery.dart';
import 'career_artifact_service.dart';
import 'portfolio_export_service.dart';

class PortfolioPdfExportService {
  const PortfolioPdfExportService(this._database);

  final AppDatabase _database;

  Future<PortfolioExportResult> exportPdf({
    required PortfolioSnapshot snapshot,
    required String role,
    required String companyName,
    required int xp,
    required List<SkillMastery> skills,
  }) async {
    final bytes = await buildPdf(
      snapshot: snapshot,
      role: role,
      companyName: companyName,
      xp: xp,
      skills: skills,
      generatedAt: DateTime.now().toUtc(),
    );

    final base = await _database.storageDirectoryPath;
    final directory = Directory(p.join(base, 'exports'));
    await directory.create(recursive: true);
    final stamp = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File(
      p.join(directory.path, 'dataquest_portfolio_$stamp.pdf'),
    );
    await file.writeAsBytes(bytes, flush: true);

    return PortfolioExportResult(
      path: file.path,
      bytes: bytes.length,
    );
  }

  static Future<Uint8List> buildPdf({
    required PortfolioSnapshot snapshot,
    required String role,
    required String companyName,
    required int xp,
    required List<SkillMastery> skills,
    required DateTime generatedAt,
  }) async {
    final document = pw.Document(
      title: 'DataQuest Analyst Portfolio',
      author: 'DataQuest',
      subject: 'Synthetic analyst training evidence',
    );
    final projects = CareerArtifactService.buildProjectCards(snapshot);
    final sortedSkills = [...skills]
      ..sort((a, b) => b.mastery.compareTo(a.mastery));

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(34),
        build: (context) => [
          pw.Text(
            'DataQuest Analyst Portfolio',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            _safe(
              'Generated ${generatedAt.toIso8601String()} | '
              'Synthetic training evidence - not employer experience.',
            ),
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 14),
          _section('Career snapshot'),
          _keyValue('Role', role),
          _keyValue('Company', companyName),
          _keyValue('Career XP', '$xp'),
          _keyValue('Recorded attempts', '${snapshot.attemptCount}'),
          pw.SizedBox(height: 14),
          _section('Skill profile'),
          for (final skill in sortedSkills)
            _keyValue(
              skill.displayName,
              '${skill.mastery.toStringAsFixed(0)}% | '
              '${skill.attempts} attempts',
            ),
          pw.SizedBox(height: 14),
          _section('Portfolio projects'),
          if (projects.isEmpty)
            pw.Text('No Boss Case or capstone project evidence yet.')
          else
            for (final project in projects.take(12))
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      _safe(project.title),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      _safe(
                        '${project.company} | ${project.score}/100 | '
                        '${project.attempts} attempts',
                      ),
                    ),
                    pw.Text(_safe(project.skills.join(', '))),
                  ],
                ),
              ),
          pw.SizedBox(height: 12),
          _section('Strongest task and lab evidence'),
          if (snapshot.taskPerformances.isEmpty)
            pw.Text('No task evidence yet.')
          else
            for (final task in snapshot.taskPerformances.take(15))
              _keyValue(
                task.title,
                '${task.skillKey} | ${task.difficulty} | '
                '${task.bestScore}/100 | ${task.attempts} attempts',
              ),
          pw.SizedBox(height: 12),
          _section('Boss Cases'),
          if (snapshot.bossCases.isEmpty)
            pw.Text('No Boss Case evidence yet.')
          else
            for (final item in snapshot.bossCases)
              _keyValue(
                item.caseId,
                '${item.totalScore}/100 | SQL ${item.sqlScore} | '
                'Recommendation ${item.recommendationScore}',
              ),
          pw.SizedBox(height: 12),
          _section('Recent immutable attempts'),
          for (final attempt in snapshot.attempts.take(30))
            _keyValue(
              attempt.title,
              '${attempt.score}/100 | ${attempt.mode} | '
              '${attempt.companyKey} | '
              '${attempt.completedAt.toLocal().toString().split('.').first}',
            ),
          pw.SizedBox(height: 14),
          pw.Text(
            'DataQuest uses synthetic learning datasets. Scores and projects '
            'shown here represent in-app training evidence and should not be '
            'presented as real employer outcomes.',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _section(String title) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 15,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );

  static pw.Widget _keyValue(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 145,
              child: pw.Text(
                _safe(label),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Expanded(child: pw.Text(_safe(value))),
          ],
        ),
      );

  static String _safe(String value) => value
      .replaceAll('₹', 'INR ')
      .replaceAll('•', '|')
      .replaceAll('→', '->')
      .replaceAll('–', '-')
      .replaceAll('—', '-')
      .replaceAll('’', "'")
      .replaceAll('“', '"')
      .replaceAll('”', '"');
}

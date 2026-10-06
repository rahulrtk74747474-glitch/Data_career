import 'package:dataquest_analyst_career/services/certificate_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('certificate HTML contains evidence scores and credential disclaimer', () {
    final html = CertificateExportService.buildHtml(
      learnerName: 'Rahul Analyst',
      readinessScore: 84,
      capstoneScore: 88,
      generatedAt: DateTime.utc(2026, 10, 6),
    );

    expect(html, contains('Rahul Analyst'));
    expect(html, contains('84/100'));
    expect(html, contains('88/100'));
    expect(html, contains('not an accredited academic credential'));
  });

  test('certificate escapes learner supplied HTML', () {
    final html = CertificateExportService.buildHtml(
      learnerName: '<script>alert(1)</script>',
      readinessScore: 80,
      capstoneScore: 80,
      generatedAt: DateTime.utc(2026, 10, 6),
    );

    expect(html, isNot(contains('<script>alert(1)</script>')));
    expect(html, contains('&lt;script&gt;'));
  });
}

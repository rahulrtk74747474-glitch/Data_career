import 'dart:convert';

import 'package:dataquest_analyst_career/models/portfolio_snapshot.dart';
import 'package:dataquest_analyst_career/services/portfolio_pdf_export_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('portfolio PDF starts with a valid PDF signature', () async {
    const snapshot = PortfolioSnapshot(
      taskPerformances: [],
      bossCases: [],
      attempts: [],
    );

    final bytes = await PortfolioPdfExportService.buildPdf(
      snapshot: snapshot,
      role: 'Data Analyst',
      companyName: 'E-commerce Co.',
      xp: 500,
      skills: const [],
      generatedAt: DateTime.utc(2026, 10, 6),
    );

    expect(bytes.length, greaterThan(500));
    expect(
      ascii.decode(bytes.take(4).toList()),
      '%PDF',
    );
  });
}

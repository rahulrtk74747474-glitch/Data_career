import 'dart:convert';

import 'package:dataquest_analyst_career/models/job_ready_v15.dart';
import 'package:dataquest_analyst_career/services/flagship_workday_scoring_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('flagship scoring rewards quality controls and credible tool work',
      () async {
    final raw =
        await rootBundle.loadString('assets/content/job_ready_v1_5.json');
    final pack = jsonDecode(raw) as Map<String, dynamic>;
    final item = FlagshipWorkday.fromJson(
      Map<String, dynamic>.from(
        (pack['workdays'] as List<dynamic>).first as Map,
      ),
    );

    expect(
      FlagshipWorkdayScoringService.issueScore(
        item,
        item.correctIssues.toSet(),
      ),
      100,
    );
    expect(FlagshipWorkdayScoringService.toolScore(item, 'SQL'), 100);

    final weakPandas = FlagshipWorkdayScoringService.tokenAnalysisScore(
      item,
      'Pandas',
      'merge customer_id status completed groupby segment sum',
    );
    expect(weakPandas, lessThan(70));

    final strongPandas = FlagshipWorkdayScoringService.tokenAnalysisScore(
      item,
      'Pandas',
      "df.merge(customers, on='customer_id')"
      "[lambda x: x['status']=='completed']"
      ".groupby('segment')['revenue'].sum()",
    );
    expect(strongPandas, greaterThanOrEqualTo(70));
  });
}

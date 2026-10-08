import 'dart:convert';

import 'package:dataquest_analyst_career/services/learning_telemetry_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('learning telemetry records opens workdays and local feedback', () async {
    SharedPreferences.setMockInitialValues({});
    const service = LearningTelemetryService();

    await service.recordAppOpen();
    await service.recordEvent('workday_start');
    await service.recordEvent('workday_complete');
    await service.saveFeedback(
      realism: 5,
      usefulness: 4,
      confusion: 'None',
      wouldPay: 'Maybe',
      freeText: 'More open projects',
    );

    final report = await service.report();
    expect(report.appOpens, 1);
    expect(report.activeDays, 1);
    expect(report.workdayStarts, 1);
    expect(report.workdayCompletions, 1);
    expect(report.firstFlagshipCompletedAt, isNotNull);
    expect(report.feedbackCount, 1);

    final exported = await service.exportJson();
    expect(jsonEncode(exported), contains('More open projects'));
  });
}

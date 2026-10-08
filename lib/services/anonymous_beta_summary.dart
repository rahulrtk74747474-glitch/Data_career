// ignore_for_file: prefer_interpolation_to_compose_strings
/// Privacy-minimized summary of on-device beta learning metrics.
///
/// No identifiers, dates, raw responses, accounts, or free-text answers are
/// exported. The tester must explicitly opt in before copying this data.
class AnonymousBetaSummary {
  const AnonymousBetaSummary._();

  static Map<String, Object?> fromTelemetry(
    Map<String, dynamic> state, {
    required bool consent,
    bool independentSqlPassed = false,
  }) {
    if (!consent) throw StateError('Explicit beta export consent required.');
    final feedback = <Map<String, dynamic>>[
      for (final row in (state['feedback'] as List<dynamic>? ?? []))
        if (row is Map) Map<String, dynamic>.from(row),
    ];
    final pay = <String, int>{'Yes': 0, 'Maybe': 0, 'No': 0};
    var ratingCount = 0;
    var totalRealism = 0;
    var totalUsefulness = 0;
    for (final row in feedback) {
      final value = row['wouldPay']?.toString();
      if (pay.containsKey(value)) pay[value!] = pay[value]! + 1;
      final realism = row['realism'];
      final useful = row['usefulness'];
      if (realism is num && useful is num &&
          realism >= 1 && realism <= 5 && useful >= 1 && useful <= 5) {
        ratingCount++;
        totalRealism += realism.toInt();
        totalUsefulness += useful.toInt();
      }
    }
    int counter(String key) {
      final value = state[key];
      return value is num ? value.toInt().clamp(0, 1000000) : 0;
    }
    final opens = counter('appOpens');
    final activeDates = state['activeDates'];
    final activeDays = activeDates is List ? activeDates.length : 0;
    final stages = <String, int>{
      for (final key in [
        'quality', 'tool', 'analysis', 'statistics', 'chart', 'manager',
      ])
        key: counter('event_stage_' + key + '_complete'),
    };
    return <String, Object?>{
      'schemaVersion': 1,
      'source': 'DataQuest consented on-device beta summary',
      'appOpens': opens,
      'activeDayCount': activeDays,
      'startedWorkdays': counter('workdayStarts'),
      'completedWorkdays': counter('workdayCompletions'),
      'stageCompletionEvents': stages,
      'independentSqlPassed': independentSqlPassed,
      'feedbackCount': feedback.length,
      'wouldPayCounts': pay,
      'meanRealism': ratingCount == 0
          ? null : totalRealism / ratingCount,
      'meanUsefulness': ratingCount == 0
          ? null : totalUsefulness / ratingCount,
      'privacy': 'No identifying metadata, raw dates or free text.',
    };
  }
}

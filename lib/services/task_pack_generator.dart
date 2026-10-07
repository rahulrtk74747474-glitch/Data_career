import '../models/content_pack.dart';

class TaskPackGenerator {
  const TaskPackGenerator._();

  static Map<String, dynamic> generate({
    required String skill,
    required String level,
    int count = 25,
  }) {
    final cleanSkill = skill.trim();
    final cleanLevel = level.trim();
    if (cleanSkill.isEmpty) {
      throw const FormatException('Skill cannot be empty.');
    }
    if (cleanLevel.isEmpty) {
      throw const FormatException('Level cannot be empty.');
    }
    if (count < 1 || count > 100) {
      throw const RangeError.range(count, 1, 100, 'count');
    }

    final skillSlug = _slug(cleanSkill);
    final levelSlug = _slug(cleanLevel);
    const companies = [
      'ecommerce',
      'saas',
      'bank',
      'hospital',
      'logistics',
    ];

    final datasets = <Map<String, dynamic>>[
      for (var index = 0; index < companies.length; index++)
        {
          'id': 'generated-$skillSlug-${companies[index]}-dataset',
          'name': 'generated_${skillSlug}_${companies[index]}',
          'columns': ['segment', 'baseline', 'current', 'volume'],
          'rows': [
            {
              'segment': 'A',
              'baseline': 100 + index * 10,
              'current': 108 + index * 12,
              'volume': 1000 + index * 250,
            },
            {
              'segment': 'B',
              'baseline': 90 + index * 8,
              'current': 93 + index * 9,
              'volume': 800 + index * 200,
            },
          ],
        },
    ];

    final rubricId = 'generated-$skillSlug-reasoning-v1';
    final expected =
        'Validate the metric definition and data grain, quantify the evidence, then make a bounded recommendation.';

    final tasks = <Map<String, dynamic>>[
      for (var index = 0; index < count; index++)
        {
          'id':
              'generated-$skillSlug-$levelSlug-${(index + 1).toString().padLeft(2, '0')}',
          'title': '$cleanSkill $cleanLevel Scenario ${index + 1}',
          'skillKey': skillSlug,
          'difficulty': cleanLevel,
          'companyKey': companies[index % companies.length],
          'answerType': 'choice',
          'datasetId':
              'generated-$skillSlug-${companies[index % companies.length]}-dataset',
          'rubricId': rubricId,
          'context':
              'A ${companies[index % companies.length]} team needs a $cleanSkill decision from a small synthetic dataset. The current metric differs from baseline and the decision must remain evidence-bounded.',
          'prompt':
              'For this $cleanLevel $cleanSkill exercise, which response is the most defensible analytical next step?',
          'options': [
            expected,
            'Act immediately on the largest number without checking definitions or data grain.',
            'Ignore the evidence because small synthetic datasets can never support useful analysis.',
          ],
          'expectedAnswer': expected,
          'hints': [
            'Start by confirming what one row and one metric represent.',
            'Use the observed values as evidence, not as proof of causation.',
            'End with a bounded next action that can be validated.',
          ],
        },
    ];

    final pack = <String, dynamic>{
      'packId': 'generated-$skillSlug-$levelSlug-${count}pack',
      'schemaVersion': 2,
      'contentVersion': 1,
      'datasets': datasets,
      'rubrics': [
        {
          'id': rubricId,
          'kind': 'analytical_reasoning',
          'criteria': [
            {'key': 'definitionAndGrain', 'weight': 25},
            {'key': 'evidence', 'weight': 35},
            {'key': 'boundedRecommendation', 'weight': 25},
            {'key': 'clarity', 'weight': 15},
          ],
        },
      ],
      'dialogues': [
        {
          'id': 'generated-$skillSlug-manager-feedback',
          'triggerKey': 'generated_task_complete',
          'speaker': 'Manager',
          'text':
              'Good work. Keep the evidence separate from assumptions and make the next action testable.',
        },
      ],
      'events': [
        {
          'id': 'generated-$skillSlug-quality-check',
          'eventType': 'data_quality',
          'title': 'Definition check',
          'description':
              'Two reports use different definitions for the same business metric.',
          'decision':
              'Reconcile grain, filters and metric definitions before comparing results.',
        },
      ],
      'achievements': [
        {
          'id': 'generated-$skillSlug-first-completion',
          'title': '$cleanSkill Starter',
          'description':
              'Complete one generated $cleanSkill learning task.',
          'rule': {
            'type': 'skill_attempts',
            'skillKey': skillSlug,
            'minimum': 1,
          },
        },
      ],
      'tasks': tasks,
    };

    ContentPack.fromJson(pack);
    return pack;
  }

  static String _slug(String value) {
    final slug = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (slug.isEmpty) {
      throw const FormatException(
        'Skill and level must contain letters or numbers.',
      );
    }
    return slug;
  }
}

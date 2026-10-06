import 'package:dataquest_analyst_career/models/analyst_task.dart';
import 'package:dataquest_analyst_career/models/skill_mastery.dart';
import 'package:dataquest_analyst_career/services/adaptive_review_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AnalystTask task(String id, String skillKey) {
    return AnalystTask(
      id: id,
      title: id,
      department: 'Test',
      skill: skillKey,
      skillKey: skillKey,
      context: '',
      goal: '',
      deliverable: '',
      answerType: 'choice',
      prompt: '',
      expectedAnswer: 'A',
      requiredTokens: const [],
      expectedRows: const [],
      expectedSelections: const [],
      hints: const ['1', '2', '3'],
      explanation: '',
      xp: 10,
      datasetName: '',
      rows: const [],
      options: const ['A', 'B'],
    );
  }

  test('review queue puts due lower-mastery skill first', () {
    final now = DateTime.utc(2026, 10, 6);
    final skills = [
      SkillMastery(
        skillKey: 'sql',
        mastery: 40,
        attempts: 3,
        correct: 1,
        nextReviewAt: now.subtract(const Duration(days: 1)),
      ),
      SkillMastery(
        skillKey: 'business',
        mastery: 80,
        attempts: 3,
        correct: 3,
        nextReviewAt: now.subtract(const Duration(days: 1)),
      ),
      SkillMastery(
        skillKey: 'cleaning',
        mastery: 30,
        attempts: 2,
        correct: 0,
        nextReviewAt: now.add(const Duration(days: 2)),
      ),
    ];

    final queue = AdaptiveReviewService.buildQueue(
      skills: skills,
      tasks: [
        task('sql-task', 'sql'),
        task('business-task', 'business'),
        task('clean-task', 'cleaning'),
      ],
      now: now,
    );

    expect(queue.first.skill.skillKey, 'sql');
    expect(queue[1].skill.skillKey, 'business');
    expect(queue[2].skill.skillKey, 'cleaning');
  });

  test('recommendations prefer weakest unfinished skill', () {
    final recommendations = AdaptiveReviewService.recommendTasks(
      skills: const [
        SkillMastery(
          skillKey: 'sql',
          mastery: 25,
          attempts: 1,
          correct: 0,
          nextReviewAt: null,
        ),
        SkillMastery(
          skillKey: 'business',
          mastery: 80,
          attempts: 2,
          correct: 2,
          nextReviewAt: null,
        ),
      ],
      tasks: [
        task('sql-task', 'sql'),
        task('business-task', 'business'),
      ],
      completedTaskIds: const {},
      limit: 1,
    );

    expect(recommendations.single.id, 'sql-task');
  });
}

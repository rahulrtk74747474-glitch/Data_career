import 'package:dataquest_analyst_career/features/game/game_progress.dart';
import 'package:dataquest_analyst_career/models/foundation_lesson.dart';
import 'package:dataquest_analyst_career/services/learning_note_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('completed lessons and manual notes become revision notes', () {
    const lesson = FoundationLesson(
      id: 'lesson-1',
      skillKey: 'statistics',
      trackKey: 'statistics',
      trackTitle: 'Statistics',
      order: 1,
      title: 'Median',
      companyKey: 'ecommerce',
      concept: 'Median',
      explanation: 'Median is robust to extreme values.',
      scenario: 'Orders contain one extreme value.',
      workedExample: '600, 650, 700, 720, 7500 → median 700.',
      question: 'Which metric?',
      options: ['Median', 'Mean'],
      correctAnswer: 'Median',
      hints: ['1', '2', '3'],
      solution: 'Use the median for a typical value in this skewed sample.',
      xp: 25,
    );

    final progress = GameProgress.initial().copyWith(
      rewardedLearningIds: {'academy:lesson-1'},
      manualNotes: ['p-value is not the probability the null is true'],
    );

    final notes = LearningNoteService.build(
      progress: progress,
      foundation: const [lesson],
      tasks: const [],
      spreadsheets: const [],
      pandas: const [],
      analytics: const [],
      dashboards: const [],
      insights: const [],
      inboxMessages: const [],
      metricCases: const [],
      reviewCases: const [],
    );

    expect(notes, hasLength(2));
    expect(notes.any((note) => note.title == 'Median'), isTrue);
    expect(notes.any((note) => note.source == 'My notes'), isTrue);
  });
}

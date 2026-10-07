import '../features/game/game_progress.dart';
import '../models/analyst_task.dart';
import '../models/analytics_challenge.dart';
import '../models/dashboard_challenge.dart';
import '../models/foundation_lesson.dart';
import '../models/learning_note.dart';
import '../models/narrative_content.dart';
import '../models/pandas_challenge.dart';
import '../models/spreadsheet_challenge.dart';

class LearningNoteService {
  const LearningNoteService._();

  static List<LearningNote> build({
    required GameProgress progress,
    required List<FoundationLesson> foundation,
    required List<AnalystTask> tasks,
    required List<SpreadsheetChallenge> spreadsheets,
    required List<PandasChallenge> pandas,
    required List<AnalyticsChallenge> analytics,
    required List<DashboardChallenge> dashboards,
    required List<InsightScenario> insights,
  }) {
    final notes = <LearningNote>[];

    for (final item in foundation) {
      if (!progress.rewardedLearningIds.contains('academy:${item.id}')) {
        continue;
      }
      notes.add(
        LearningNote(
          id: 'academy:${item.id}',
          title: item.title,
          skillKey: item.skillKey,
          shortcut: _short(item.solution),
          detail: '${item.explanation}\n\nWorked example:\n${item.workedExample}',
          source: 'Academy',
        ),
      );
    }

    for (final item in tasks) {
      if (!progress.completedTaskIds.contains(item.id)) continue;
      notes.add(
        LearningNote(
          id: 'task:${item.id}',
          title: item.title,
          skillKey: item.skillKey,
          shortcut: _firstSentence(item.explanation),
          detail: item.solutionText,
          source: 'Company ticket',
        ),
      );
    }

    for (final item in spreadsheets) {
      if (!progress.rewardedLearningIds
          .contains('spreadsheet:${item.id}')) {
        continue;
      }
      notes.add(
        LearningNote(
          id: 'spreadsheet:${item.id}',
          title: item.title,
          skillKey: item.skillKey,
          shortcut: item.expectedCommand,
          detail: item.explanation,
          source: 'Spreadsheet lab',
        ),
      );
    }

    for (final item in pandas) {
      if (!progress.rewardedLearningIds.contains('pandas:${item.id}')) {
        continue;
      }
      notes.add(
        LearningNote(
          id: 'pandas:${item.id}',
          title: item.title,
          skillKey: 'python',
          shortcut: item.solutionText.split('\n').first,
          detail: item.explanation,
          source: 'Pandas lab',
        ),
      );
    }

    for (final item in analytics) {
      if (!progress.rewardedLearningIds
          .contains('analytics:${item.id}')) {
        continue;
      }
      final shortcut = item.isDashboard
          ? 'Chart: ${item.expectedChart} • KPIs: ${item.expectedKpis.join(', ')}'
          : item.expectedAnswer;
      notes.add(
        LearningNote(
          id: 'analytics:${item.id}',
          title: item.title,
          skillKey: item.skillKey,
          shortcut: _short(shortcut),
          detail: item.explanation,
          source: 'Analytics Studio',
        ),
      );
    }

    for (final item in dashboards) {
      if (!progress.rewardedLearningIds
          .contains('dashboard:${item.id}')) {
        continue;
      }
      notes.add(
        LearningNote(
          id: 'dashboard:${item.id}',
          title: item.title,
          skillKey: item.skillKey,
          shortcut: _short(item.correctOption),
          detail: item.explanation,
          source: 'BI & Dashboard Lab',
        ),
      );
    }

    for (final item in insights) {
      if (!progress.rewardedLearningIds.contains('insight:${item.id}')) {
        continue;
      }
      notes.add(
        LearningNote(
          id: 'insight:${item.id}',
          title: item.title,
          skillKey: 'business',
          shortcut: _firstSentence(item.solutionText),
          detail: item.solutionText,
          source: 'Insight Coach',
        ),
      );
    }

    for (var index = 0; index < progress.manualNotes.length; index++) {
      final text = progress.manualNotes[index];
      notes.add(
        LearningNote(
          id: 'manual:$index',
          title: 'My note ${index + 1}',
          skillKey: 'manual',
          shortcut: _short(text),
          detail: text,
          source: 'My notes',
          manualIndex: index,
        ),
      );
    }

    return notes.reversed.toList();
  }

  static String _firstSentence(String value) {
    final clean = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.isEmpty) return '';
    final match = RegExp(r'^(.+?[.!?])(?:\s|$)').firstMatch(clean);
    return _short(match?.group(1) ?? clean);
  }

  static String _short(String value, {int max = 180}) {
    final clean = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.length <= max) return clean;
    return '${clean.substring(0, max - 1)}…';
  }
}

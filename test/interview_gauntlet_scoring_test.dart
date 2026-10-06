import 'package:dataquest_analyst_career/data/app_database.dart';
import 'package:dataquest_analyst_career/repositories/content_repository.dart';
import 'package:dataquest_analyst_career/services/interview_scoring_service.dart';
import 'package:dataquest_analyst_career/services/sql_result_grader.dart';
import 'package:dataquest_analyst_career/services/sql_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;

  setUp(() {
    sqfliteFfiInit();
    database = AppDatabase(
      factory: databaseFactoryFfi,
      overridePath: inMemoryDatabasePath,
    );
  });

  tearDown(() => database.close());

  test('gauntlet SQL question grades against real local data', () async {
    final rounds = await const ContentRepository().loadInterviewRounds();
    final gauntlet = rounds.singleWhere(
      (round) => round.key == 'job_readiness_gauntlet',
    );
    final question = gauntlet.questions.firstWhere(
      (item) => item.answerType == 'sql_result',
    );

    final run = await SqlRunner(database).runReadOnly(
      "SELECT company_key, exception_rate "
      "FROM capstone_company_kpis "
      "WHERE period = 'Current' "
      "ORDER BY exception_rate DESC",
    );

    expect(run.isSuccess, isTrue);
    expect(
      SqlResultGrader.grade(
        actualRows: run.rows,
        expectedRows: question.expectedRows,
      ).isCorrect,
      isTrue,
    );
  });

  test('gauntlet choice and rubric use existing interview graders', () async {
    final rounds = await const ContentRepository().loadInterviewRounds();
    final gauntlet = rounds.singleWhere(
      (round) => round.key == 'job_readiness_gauntlet',
    );
    final choice = gauntlet.questions.firstWhere(
      (item) => item.answerType == 'choice',
    );
    final rubric = gauntlet.questions.firstWhere(
      (item) => item.answerType == 'rubric',
    );

    expect(
      InterviewScoringService.scoreChoice(
        choice,
        choice.expectedAnswer,
      ).score,
      100,
    );

    final rubricScore = InterviewScoringService.scoreRubric(
      rubric,
      'Validate the metric definition and data quality, segment by cohort, '
      'compare a baseline trend, test driver hypotheses, then recommend a '
      'pilot and monitor the next result.',
    );
    expect(rubricScore.score, greaterThanOrEqualTo(80));
  });
}

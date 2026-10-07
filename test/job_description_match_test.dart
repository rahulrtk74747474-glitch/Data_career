import 'package:dataquest_analyst_career/models/skill_mastery.dart';
import 'package:dataquest_analyst_career/services/job_match_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pasted job description detects skills and exposes weak gaps', () {
    final result = JobDescriptionMatcher.calculateDescription(
      description:
          'Need strong SQL, Excel, Power BI/DAX, stakeholder communication and Python/Pandas.',
      skills: [
        _skill('sql', 85),
        _skill('spreadsheets', 82),
        _skill('powerbi', 52),
        _skill('business', 78),
        _skill('python', 68),
      ],
    );

    expect(result.detectedSkills, contains('SQL'));
    expect(result.detectedSkills, contains('Power BI'));
    expect(result.score, greaterThan(0));
    expect(result.gaps.any((gap) => gap.startsWith('Power BI')), isTrue);
  });
}

SkillMastery _skill(String key, double mastery) => SkillMastery(
      skillKey: key,
      mastery: mastery,
      attempts: 3,
      correct: 2,
      nextReviewAt: null,
    );

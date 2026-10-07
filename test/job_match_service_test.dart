import 'package:dataquest_analyst_career/models/skill_mastery.dart';
import 'package:dataquest_analyst_career/models/workday_content.dart';
import 'package:dataquest_analyst_career/services/job_match_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('job match rewards demonstrated mastery and project breadth', () {
    const role = JobRoleProfile(
      id: 'bi',
      title: 'BI Analyst',
      description: '',
      weights: {
        'sql': 0.2,
        'spreadsheets': 0.1,
        'cleaning': 0.1,
        'statistics': 0.1,
        'python': 0.05,
        'powerbi': 0.3,
        'business': 0.15,
      },
      minProjects: 3,
      minEvidence: 10,
    );

    final strong = JobMatchService.calculate(
      role: role,
      skills: _skills(85),
      projectCount: 3,
      evidenceCount: 12,
    );
    final weak = JobMatchService.calculate(
      role: role,
      skills: _skills(55),
      projectCount: 0,
      evidenceCount: 2,
    );

    expect(strong.score, greaterThan(weak.score));
    expect(strong.score, greaterThanOrEqualTo(80));
    expect(weak.gaps, isNotEmpty);
  });
}

List<SkillMastery> _skills(double score) => [
      for (final key in const [
        'sql',
        'spreadsheets',
        'cleaning',
        'statistics',
        'python',
        'powerbi',
        'business',
      ])
        SkillMastery(
          skillKey: key,
          mastery: score,
          attempts: 4,
          correct: 3,
          nextReviewAt: null,
        ),
    ];

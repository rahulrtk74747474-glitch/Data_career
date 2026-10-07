import '../models/skill_mastery.dart';
import '../models/workday_content.dart';

class JobMatchResult {
  const JobMatchResult({
    required this.role,
    required this.score,
    required this.gaps,
  });

  final JobRoleProfile role;
  final int score;
  final List<String> gaps;
}

class JobMatchService {
  const JobMatchService._();

  static JobMatchResult calculate({
    required JobRoleProfile role,
    required List<SkillMastery> skills,
    required int projectCount,
    required int evidenceCount,
  }) {
    final byKey = {
      for (final skill in skills) skill.skillKey: skill.mastery.clamp(0, 100),
    };

    var weighted = 0.0;
    var totalWeight = 0.0;
    final gaps = <String>[];

    for (final entry in role.weights.entries) {
      final mastery = (byKey[entry.key] ?? 0).toDouble();
      weighted += mastery * entry.value;
      totalWeight += entry.value;
      if (entry.value >= 0.12 && mastery < 70) {
        gaps.add('${_label(entry.key)} ${mastery.toStringAsFixed(0)}%');
      }
    }

    final skillScore = totalWeight == 0 ? 0.0 : weighted / totalWeight;
    final projectScore = role.minProjects == 0
        ? 100.0
        : (projectCount / role.minProjects * 100).clamp(0, 100).toDouble();
    final evidenceScore = role.minEvidence == 0
        ? 100.0
        : (evidenceCount / role.minEvidence * 100).clamp(0, 100).toDouble();

    if (projectCount < role.minProjects) {
      gaps.add('${role.minProjects - projectCount} more project(s)');
    }
    if (evidenceCount < role.minEvidence) {
      gaps.add('${role.minEvidence - evidenceCount} more evidence item(s)');
    }

    final score =
        (skillScore * 0.78 + projectScore * 0.12 + evidenceScore * 0.10)
            .round()
            .clamp(0, 100)
            .toInt();

    return JobMatchResult(
      role: role,
      score: score,
      gaps: gaps.take(4).toList(),
    );
  }

  static String _label(String key) {
    switch (key) {
      case 'spreadsheets':
        return 'Excel';
      case 'cleaning':
        return 'Data Cleaning';
      case 'statistics':
        return 'Statistics';
      case 'python':
        return 'Python/Pandas';
      case 'powerbi':
        return 'Power BI';
      case 'business':
        return 'Business Analytics';
      default:
        return key.toUpperCase();
    }
  }
}

class JobDescriptionMatchResult {
  const JobDescriptionMatchResult({
    required this.score,
    required this.detectedSkills,
    required this.gaps,
  });

  final int score;
  final List<String> detectedSkills;
  final List<String> gaps;
}

class JobDescriptionMatcher {
  const JobDescriptionMatcher._();

  static JobDescriptionMatchResult calculateDescription({
    required String description,
    required List<SkillMastery> skills,
  }) {
    final text = description.toLowerCase();
    final keywordMap = <String, List<String>>{
      'sql': ['sql', 'query', 'database', 'joins'],
      'spreadsheets': ['excel', 'spreadsheet', 'pivot', 'xlookup', 'vlookup'],
      'cleaning': ['data cleaning', 'data quality', 'etl', 'wrangling'],
      'statistics': [
        'statistics',
        'statistical',
        'hypothesis',
        'a/b',
        'experiment',
        'regression',
      ],
      'python': ['python', 'pandas', 'numpy'],
      'powerbi': ['power bi', 'powerbi', 'dax', 'power query', 'tableau', 'bi tool'],
      'business': [
        'stakeholder',
        'business analysis',
        'kpi',
        'communication',
        'insight',
        'presentation',
      ],
    };

    final mastery = {
      for (final skill in skills) skill.skillKey: skill.mastery.clamp(0, 100),
    };
    final detected = <String>[];
    final gaps = <String>[];
    var total = 0.0;

    for (final entry in keywordMap.entries) {
      final found = entry.value.any(text.contains);
      if (!found) continue;
      detected.add(_label(entry.key));
      final score = (mastery[entry.key] ?? 0).toDouble();
      total += score;
      if (score < 70) {
        gaps.add('${_label(entry.key)} ${score.toStringAsFixed(0)}%');
      }
    }

    if (detected.isEmpty) {
      return const JobDescriptionMatchResult(
        score: 0,
        detectedSkills: [],
        gaps: ['No supported analyst-skill keywords detected.'],
      );
    }

    return JobDescriptionMatchResult(
      score: (total / detected.length).round().clamp(0, 100).toInt(),
      detectedSkills: detected,
      gaps: gaps,
    );
  }
}

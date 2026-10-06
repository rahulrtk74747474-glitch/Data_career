class ReadinessDomain {
  const ReadinessDomain({
    required this.key,
    required this.label,
    required this.score,
    required this.recommendation,
  });

  final String key;
  final String label;
  final double score;
  final String recommendation;
}

class JobReadinessReport {
  const JobReadinessReport({
    required this.totalScore,
    required this.domains,
    required this.skillFoundationScore,
    required this.interviewScore,
    required this.bossCaseScore,
    required this.evidenceScore,
    required this.completionScore,
    required this.capstoneScore,
    required this.remediation,
  });

  final int totalScore;
  final List<ReadinessDomain> domains;
  final double skillFoundationScore;
  final double interviewScore;
  final double bossCaseScore;
  final double evidenceScore;
  final double completionScore;
  final double capstoneScore;
  final List<String> remediation;

  ReadinessDomain? domain(String key) {
    for (final item in domains) {
      if (item.key == key) return item;
    }
    return null;
  }
}

class GraduationCriterion {
  const GraduationCriterion({
    required this.label,
    required this.met,
    required this.detail,
  });

  final String label;
  final bool met;
  final String detail;
}

class GraduationEligibility {
  const GraduationEligibility({
    required this.criteria,
  });

  final List<GraduationCriterion> criteria;

  bool get eligible => criteria.every((item) => item.met);
}

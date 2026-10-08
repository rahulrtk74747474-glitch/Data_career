import '../features/game/game_progress.dart';
import '../models/achievement_badge.dart';
import '../models/interview_result.dart';
import '../models/portfolio_snapshot.dart';
import '../models/skill_mastery.dart';

class AchievementService {
  const AchievementService._();

  static List<AchievementBadge> evaluate({
    required GameProgress progress,
    required List<SkillMastery> skills,
    required PortfolioSnapshot portfolio,
    required List<InterviewResult> interviews,
    required bool graduated,
  }) {
    double mastery(String key) {
      for (final skill in skills) {
        if (skill.skillKey == key) return skill.mastery;
      }
      return 0;
    }

    bool hasSkillEvidence(String key) => portfolio.taskPerformances.any(
          (item) => item.skillKey == key && item.bestScore >= 70,
        );
    final bestInterview = interviews.isEmpty
        ? 0
        : interviews
            .map((item) => item.bestScore)
            .reduce((a, b) => a > b ? a : b);
    final careerProjects = progress.rewardedLearningIds
        .where((id) => id.startsWith('mission:'))
        .length;
    final flagshipProjects = progress.rewardedLearningIds
        .where((id) => id.startsWith('flagship:'))
        .length;
    final independentPasses = portfolio.taskPerformances
        .where(
          (item) =>
              item.difficulty == 'Independent' &&
              item.bestScore >= 70,
        )
        .length;

    return [
      AchievementBadge(
        id: 'first-query',
        title: 'First Query',
        description: 'Complete a SQL task with a passing score.',
        unlocked: hasSkillEvidence('sql'),
      ),
      AchievementBadge(
        id: 'spreadsheet-operator',
        title: 'Spreadsheet Operator',
        description: 'Reach 70% spreadsheet mastery.',
        unlocked: mastery('spreadsheets') >= 70,
      ),
      AchievementBadge(
        id: 'data-cleaner',
        title: 'Data Cleaner',
        description: 'Reach 70% data-cleaning mastery.',
        unlocked: mastery('cleaning') >= 70,
      ),
      AchievementBadge(
        id: 'pandas-practitioner',
        title: 'Pandas Practitioner',
        description: 'Reach 70% Python/Pandas mastery.',
        unlocked: mastery('python') >= 70,
      ),
      AchievementBadge(
        id: 'power-bi-builder',
        title: 'Power BI Builder',
        description:
            'Reach 70% Power BI mastery and complete a passing BI task.',
        unlocked:
            mastery('powerbi') >= 70 && hasSkillEvidence('powerbi'),
      ),
      AchievementBadge(
        id: 'independent-analyst',
        title: 'Independent Analyst',
        description:
            'Pass five Independent-stage foundation tasks without relying only on guided work.',
        unlocked: independentPasses >= 5,
      ),
      AchievementBadge(
        id: 'project-analyst',
        title: 'Project Analyst',
        description:
            'Complete three connected Career Campaign projects.',
        unlocked: careerProjects >= 3,
      ),
      AchievementBadge(
        id: 'flagship-analyst',
        title: 'Flagship Analyst',
        description:
            'Complete all five end-to-end Day-at-Work portfolio projects.',
        unlocked: flagshipProjects >= 5,
      ),
      AchievementBadge(
        id: 'evidence-driven',
        title: 'Evidence Driven',
        description: 'Reach 75% business-communication mastery.',
        unlocked: mastery('business') >= 75,
      ),
      AchievementBadge(
        id: 'seven-day-streak',
        title: 'Seven-Day Streak',
        description: 'Complete Daily Challenge seven consecutive days.',
        unlocked: progress.dailyStreak >= 7,
      ),
      AchievementBadge(
        id: 'boss-ready',
        title: 'Boss Case Ready',
        description: 'Score at least 80 on a Boss Case.',
        unlocked: portfolio.bossCases.any(
          (item) => item.totalScore >= 80,
        ),
      ),
      AchievementBadge(
        id: 'interview-ready',
        title: 'Interview Ready',
        description: 'Score at least 75 in an interview round.',
        unlocked: bestInterview >= 75,
      ),
      AchievementBadge(
        id: 'five-industries',
        title: 'Five Industries',
        description: 'Complete the five-company career journey.',
        unlocked: progress.companyJourneyCompleted,
      ),
      AchievementBadge(
        id: 'dataquest-graduate',
        title: 'DataQuest Graduate',
        description: 'Meet all graduation evidence gates.',
        unlocked: graduated,
      ),
    ];
  }
}

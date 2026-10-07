import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/career_mission.dart';
import '../../models/workday_content.dart';
import '../campaign/career_campaign_screen.dart';
import '../interview/interview_mode_screen.dart';
import '../insight/insight_coach_screen.dart';
import '../portfolio/portfolio_screen.dart';
import '../game/game_progress.dart';
import '../game/game_providers.dart';
import 'analyst_handbook_screen.dart';
import 'analyst_stories_screen.dart';
import 'analyst_workflow_screen.dart';
import 'job_match_screen.dart';
import 'learning_notebook_screen.dart';
import 'metric_relationship_lab_screen.dart';
import 'recruiter_view_screen.dart';
import 'review_desk_screen.dart';
import 'work_inbox_screen.dart';

class AnalystDesktopLoginScreen extends ConsumerWidget {
  const AnalystDesktopLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(gameProgressProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('DataQuest Workstation')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 34,
                        child: Icon(Icons.desktop_windows_outlined, size: 34),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Analyst Desktop',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        progress.companyName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(progress.role),
                      const SizedBox(height: 20),
                      const Text(
                        'Log in to begin your simulated workday. Once signed in, your presence shows Online and you can handle messages, projects, notes, references and career work like a real analyst workstation.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const AnalystDesktopScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.login),
                          label: const Text('Log in to work'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AnalystDesktopScreen extends ConsumerWidget {
  const AnalystDesktopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(gameProgressProvider);
    final messages = ref.watch(workInboxMessagesProvider).valueOrNull ??
        const <WorkInboxMessage>[];
    final missions = ref.watch(careerMissionsProvider).valueOrNull ??
        const <CareerMission>[];

    final visibleMessages = messages.where((item) {
      final company =
          item.companyKey == 'general' || item.companyKey == progress.companyKey;
      return company && item.minCareerLevel <= progress.careerLevel;
    }).toList();
    final unread = visibleMessages.where(
      (item) => !progress.rewardedLearningIds
          .contains('decision:inbox:${item.id}'),
    ).length;

    final completedProjects = missions.where(
      (mission) => progress.rewardedLearningIds.contains(mission.rewardId),
    ).length;
    CareerMission? nextMission;
    for (var index = 0; index < missions.length; index++) {
      final mission = missions[index];
      if (progress.rewardedLearningIds.contains(mission.rewardId)) {
        continue;
      }
      final previousComplete = index == 0 ||
          progress.rewardedLearningIds.contains(missions[index - 1].rewardId);
      if (previousComplete &&
          progress.resolvedCompanyChapter >= mission.companyChapter) {
        nextMission = mission;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyst Desktop'),
        actions: [
          const _OnlinePill(),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Log out',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _WorkdayHeader(
              company: progress.companyName,
              role: progress.role,
              unread: unread,
              completedProjects: completedProjects,
              totalProjects: missions.length,
              nextMissionTitle: nextMission?.title,
            ),
            const SizedBox(height: 14),
            _CompanyImpactCard(progress: progress),
            const SizedBox(height: 14),
            _ResponsibilityCard(careerLevel: progress.careerLevel),
            const SizedBox(height: 18),
            Text(
              'Desktop apps',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.95,
              children: [
                _DesktopApp(
                  icon: Icons.mail_outline,
                  label: 'Inbox',
                  badge: unread == 0 ? null : '$unread',
                  onTap: () => _open(context, const WorkInboxScreen()),
                ),
                _DesktopApp(
                  icon: Icons.work_history_outlined,
                  label: 'Workday',
                  onTap: () =>
                      _open(context, const CareerCampaignScreen()),
                ),
                _DesktopApp(
                  icon: Icons.menu_book_outlined,
                  label: 'Notebook',
                  onTap: () =>
                      _open(context, const LearningNotebookScreen()),
                ),
                _DesktopApp(
                  icon: Icons.library_books_outlined,
                  label: 'Handbook',
                  onTap: () =>
                      _open(context, const AnalystHandbookScreen()),
                ),
                _DesktopApp(
                  icon: Icons.hub_outlined,
                  label: 'Metric Lab',
                  onTap: () =>
                      _open(context, const MetricRelationshipLabScreen()),
                ),
                _DesktopApp(
                  icon: Icons.chat_outlined,
                  label: 'Manager Coach',
                  onTap: () =>
                      _open(context, const InsightCoachScreen()),
                ),
                _DesktopApp(
                  icon: Icons.rate_review_outlined,
                  label: 'Review Desk',
                  onTap: () => _open(context, const ReviewDeskScreen()),
                ),
                _DesktopApp(
                  icon: Icons.account_tree_outlined,
                  label: 'Workflow',
                  onTap: () =>
                      _open(context, const AnalystWorkflowScreen()),
                ),
                _DesktopApp(
                  icon: Icons.badge_outlined,
                  label: 'Recruiter',
                  onTap: () =>
                      _open(context, const RecruiterViewScreen()),
                ),
                _DesktopApp(
                  icon: Icons.work_outline,
                  label: 'Job Match',
                  onTap: () => _open(context, const JobMatchScreen()),
                ),
                _DesktopApp(
                  icon: Icons.auto_stories_outlined,
                  label: 'Stories',
                  onTap: () =>
                      _open(context, const AnalystStoriesScreen()),
                ),
                _DesktopApp(
                  icon: Icons.folder_special_outlined,
                  label: 'Portfolio',
                  onTap: () => _open(context, const PortfolioScreen()),
                ),
                _DesktopApp(
                  icon: Icons.record_voice_over_outlined,
                  label: 'Interviews',
                  onTap: () =>
                      _open(context, const InterviewModeScreen()),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'You are Online while this desktop is open. Logging out ends the simulated work session; your progress and company consequences remain saved offline.',
            ),
          ],
        ),
      ),
    );
  }

  static void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }
}

class _OnlinePill extends StatelessWidget {
  const _OnlinePill();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 10),
            SizedBox(width: 6),
            Text('Online'),
          ],
        ),
      ),
    );
  }
}

class _WorkdayHeader extends StatelessWidget {
  const _WorkdayHeader({
    required this.company,
    required this.role,
    required this.unread,
    required this.completedProjects,
    required this.totalProjects,
    required this.nextMissionTitle,
  });

  final String company;
  final String role;
  final int unread;
  final int completedProjects;
  final int totalProjects;
  final String? nextMissionTitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(company, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              'Good morning, $role',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              unread == 0
                  ? 'Inbox clear.'
                  : '$unread decision message${unread == 1 ? '' : 's'} waiting.',
            ),
            const SizedBox(height: 4),
            Text(
              nextMissionTitle == null
                  ? 'Career projects: $completedProjects/$totalProjects complete.'
                  : 'Today’s main project: $nextMissionTitle',
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyImpactCard extends StatelessWidget {
  const _CompanyImpactCard({required this.progress});
  final GameProgress progress;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      ('Revenue', progress.revenueIndex.toStringAsFixed(1)),
      ('Churn', '${progress.churnRate.toStringAsFixed(1)}%'),
      ('Cost', progress.costIndex.toStringAsFixed(1)),
      ('Satisfaction', '${progress.satisfaction.toStringAsFixed(0)}%'),
      ('Manager trust', '${progress.managerTrust.toStringAsFixed(0)}%'),
      ('Data quality', '${progress.dataQuality.toStringAsFixed(0)}%'),
      ('Risk', progress.riskIndex.toStringAsFixed(0)),
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Company consequences',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your technical work and business decisions change these values.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in metrics)
                  Chip(label: Text('${item.$1}: ${item.$2}')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponsibilityCard extends StatelessWidget {
  const _ResponsibilityCard({required this.careerLevel});
  final int careerLevel;

  @override
  Widget build(BuildContext context) {
    final responsibility = switch (careerLevel) {
      0 => 'Intern: follow the workflow, validate data and explain what you learned.',
      1 => 'Junior: own routine analysis, metric definitions and data-quality checks.',
      2 => 'Analyst: solve ambiguous requests independently and own business recommendations.',
      3 => 'Senior: review junior work, challenge assumptions and protect analytical quality.',
      4 => 'Lead: prioritize competing requests, coach analysts and connect analysis to company outcomes.',
      _ => 'Head of Analytics: manage decision risk, executive trade-offs, governance and the analytics portfolio.',
    };
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.military_tech_outlined),
        ),
        title: const Text(
          'Responsibility at your level',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(responsibility),
      ),
    );
  }
}

class _DesktopApp extends StatelessWidget {
  const _DesktopApp({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                right: 8,
                top: 8,
                child: Badge(label: Text(badge!)),
              ),
          ],
        ),
      ),
    );
  }
}

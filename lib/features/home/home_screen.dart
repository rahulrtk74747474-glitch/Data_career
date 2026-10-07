import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/analyst_task.dart';
import '../../models/skill_mastery.dart';
import '../achievements/achievements_screen.dart';
import '../analytics/analytics_studio_screen.dart';
import '../boss_case/boss_case_screen.dart';
import '../career/company_chapter_review_screen.dart';
import '../career/performance_review_screen.dart';
import '../continuity/data_continuity_screen.dart';
import '../dashboard/dashboard_lab_screen.dart';
import '../daily/daily_challenge_screen.dart';
import '../events/random_events_screen.dart';
import '../game/game_progress.dart';
import '../game/game_providers.dart';
import '../graduation/job_readiness_screen.dart';
import '../insight/insight_coach_screen.dart';
import '../interview/interview_mode_screen.dart';
import '../online/weekly_case_screen.dart';
import '../pandas/pandas_lab_screen.dart';
import '../placement/placement_screen.dart';
import '../portfolio/portfolio_screen.dart';
import '../practice/practice_gym_screen.dart';
import '../reminders/reminder_settings_screen.dart';
import '../review/monthly_performance_review_screen.dart';
import '../review/review_queue_screen.dart';
import '../skills/skills_screen.dart';
import '../spreadsheet/spreadsheet_lab_screen.dart';
import '../sql_workspace/sql_workspace_screen.dart';
import '../task/task_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(gameProgressProvider);
    final tasks = ref.watch(careerTasksProvider);
    final placementComplete = ref.watch(placementCompletedProvider);
    final skillProfile = ref.watch(skillProfileProvider);
    final recommendations = ref.watch(adaptiveRecommendationsProvider);
    final reviewQueue = ref.watch(reviewQueueProvider);
    final cloudConfig = ref.watch(cloudRuntimeConfigProvider);
    final reviewCount = reviewQueue.valueOrNull?.length ?? 0;

    final nextStep = _buildNextStep(
      context: context,
      placementComplete: placementComplete,
      recommendations: recommendations,
      reviewCount: reviewCount,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('DataQuest'),
        actions: [
          IconButton(
            tooltip: 'Skills and mastery',
            onPressed: () => _open(context, const SkillsScreen()),
            icon: const Icon(Icons.radar),
          ),
          PopupMenuButton<String>(
            tooltip: 'More options',
            onSelected: (value) {
              switch (value) {
                case 'data':
                  _open(context, const DataContinuityScreen());
                case 'reminders':
                  _open(context, const ReminderSettingsScreen());
                case 'reset':
                  _confirmReset(context, ref);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'data',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.cloud_sync_outlined),
                  title: Text('Data & Cloud'),
                ),
              ),
              PopupMenuItem(
                value: 'reminders',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.notifications_active_outlined),
                  title: Text('Reminders'),
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'reset',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.restart_alt),
                  title: Text('Reset progress'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(tasksProvider);
            ref.invalidate(careerTasksProvider);
            ref.invalidate(dailyChallengeProvider);
            ref.invalidate(interviewResultsProvider);
            ref.invalidate(promotionReviewProvider);
            ref.invalidate(companyChapterReviewProvider);
            ref.invalidate(jobReadinessProvider);
            ref.invalidate(graduationEligibilityProvider);
            ref.invalidate(capstoneResultProvider);
            ref.invalidate(skillProfileProvider);
            ref.invalidate(placementCompletedProvider);
            ref.invalidate(reviewQueueProvider);
            ref.invalidate(adaptiveRecommendationsProvider);
            ref.invalidate(portfolioSnapshotProvider);
            await Future.wait([
              ref.read(tasksProvider.future),
              ref.read(skillProfileProvider.future),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _CareerCard(
                progress: progress,
                onlineFeaturesConfigured:
                    cloudConfig.cloudConfigured ||
                    cloudConfig.weeklyCasesConfigured,
              ),
              const SizedBox(height: 12),
              skillProfile.when(
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
                data: (skills) => _FocusStrip(skills: skills),
              ),
              const SizedBox(height: 16),
              nextStep,
              const SizedBox(height: 20),
              const _SectionHeading(
                title: 'Today',
                subtitle: 'Do these first. Everything else can wait.',
              ),
              const SizedBox(height: 8),
              _TodayCard(
                reviewCount: reviewCount,
                onDaily: () => _open(context, const DailyChallengeScreen()),
                onReview: () => _open(context, const ReviewQueueScreen()),
                onGym: () => _open(context, const PracticeGymScreen()),
              ),
              const SizedBox(height: 20),
              const _SectionHeading(
                title: 'Learning labs',
                subtitle:
                    'Open a lab when you want to practise a specific skill.',
              ),
              const SizedBox(height: 8),
              _MenuSection(
                icon: Icons.school_outlined,
                title: 'Core analyst labs',
                subtitle:
                    'SQL, spreadsheets, Pandas, dashboards and statistics',
                items: [
                  _MenuItem(
                    title: 'SQL Workstation',
                    subtitle: 'Write queries and inspect company data',
                    icon: Icons.storage_outlined,
                    onTap: () => _open(context, const SqlWorkspaceScreen()),
                  ),
                  _MenuItem(
                    title: 'Spreadsheet & Cleaning Lab',
                    subtitle:
                        'Formulas, lookups, filters, pivots and cleaning',
                    icon: Icons.table_chart_outlined,
                    onTap: () => _open(context, const SpreadsheetLabScreen()),
                  ),
                  _MenuItem(
                    title: 'Pandas Lab',
                    subtitle: 'Guided dataframe transformations',
                    icon: Icons.code,
                    onTap: () => _open(context, const PandasLabScreen()),
                  ),
                  _MenuItem(
                    title: 'Dashboard Lab',
                    subtitle: 'Choose useful KPIs and visualisations',
                    icon: Icons.dashboard_outlined,
                    onTap: () => _open(context, const DashboardLabScreen()),
                  ),
                  _MenuItem(
                    title: 'Analytics Studio',
                    subtitle: 'Statistics, analysis and insight grading',
                    icon: Icons.query_stats_outlined,
                    onTap: () => _open(context, const AnalyticsStudioScreen()),
                  ),
                  _MenuItem(
                    title: 'Insight Coach',
                    subtitle: 'Turn analysis into manager-ready writing',
                    icon: Icons.edit_note_outlined,
                    onTap: () => _open(context, const InsightCoachScreen()),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _MenuSection(
                icon: Icons.emoji_events_outlined,
                title: 'Challenges & career',
                subtitle:
                    'Cases, interviews, reviews and promotion progress',
                items: [
                  _MenuItem(
                    title: 'Weekly Case',
                    subtitle: 'Solve one larger analyst case',
                    icon: Icons.calendar_month_outlined,
                    onTap: () => _open(context, const WeeklyCaseScreen()),
                  ),
                  _MenuItem(
                    title: 'Weekly Boss Case',
                    subtitle: 'End-to-end business problem',
                    icon: Icons.emoji_events_outlined,
                    onTap: () => _open(context, const BossCaseScreen()),
                  ),
                  _MenuItem(
                    title: 'Interview Mode',
                    subtitle: 'Practise SQL, behavioural and case questions',
                    icon: Icons.record_voice_over_outlined,
                    onTap: () => _open(context, const InterviewModeScreen()),
                  ),
                  _MenuItem(
                    title: 'Job Readiness',
                    subtitle: 'See what is still blocking graduation',
                    icon: Icons.school_outlined,
                    onTap: () => _open(context, const JobReadinessScreen()),
                  ),
                  _MenuItem(
                    title: 'Performance Review',
                    subtitle: 'Check promotion requirements',
                    icon: Icons.workspace_premium_outlined,
                    onTap: () =>
                        _open(context, const PerformanceReviewScreen()),
                  ),
                  _MenuItem(
                    title: 'Monthly Review',
                    subtitle: 'Manager scorecard and learning feedback',
                    icon: Icons.calendar_view_month_outlined,
                    onTap: () => _open(
                      context,
                      const MonthlyPerformanceReviewScreen(),
                    ),
                  ),
                  _MenuItem(
                    title: 'Company Chapter',
                    subtitle: 'Track industry chapter unlocks',
                    icon: Icons.business_center_outlined,
                    onTap: () => _open(
                      context,
                      const CompanyChapterReviewScreen(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _MenuSection(
                icon: Icons.person_outline,
                title: 'Progress & profile',
                subtitle: 'Evidence, achievements and career records',
                items: [
                  _MenuItem(
                    title: 'Portfolio',
                    subtitle: 'View your strongest completed evidence',
                    icon: Icons.work_outline,
                    onTap: () => _open(context, const PortfolioScreen()),
                  ),
                  _MenuItem(
                    title: 'Badges',
                    subtitle: 'Review earned achievement evidence',
                    icon: Icons.military_tech_outlined,
                    onTap: () => _open(context, const AchievementsScreen()),
                  ),
                  _MenuItem(
                    title: 'Random Events',
                    subtitle: 'Practise professional judgement',
                    icon: Icons.bolt_outlined,
                    onTap: () => _open(context, const RandomEventsScreen()),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _CompanyPulseSection(progress: progress),
              const SizedBox(height: 10),
              _TicketsSection(
                progress: progress,
                tasks: tasks,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextStep({
    required BuildContext context,
    required AsyncValue<bool> placementComplete,
    required AsyncValue<List<AnalystTask>> recommendations,
    required int reviewCount,
  }) {
    return placementComplete.when(
      loading: () => const _NextStepCard.loading(),
      error: (error, stackTrace) => _NextStepCard(
        icon: Icons.today_outlined,
        eyebrow: 'WHAT TO DO NEXT',
        title: 'Complete today’s challenge',
        description:
            'Start with one short task while DataQuest refreshes your learning plan.',
        buttonLabel: 'Start daily challenge',
        onPressed: () => _open(context, const DailyChallengeScreen()),
      ),
      data: (complete) {
        if (!complete) {
          return _NextStepCard(
            icon: Icons.fact_check_outlined,
            eyebrow: 'START HERE',
            title: 'Take the 3-minute placement test',
            description:
                'This sets your starting skill levels so DataQuest can recommend the right difficulty.',
            buttonLabel: 'Take placement test',
            onPressed: () => _open(context, const PlacementScreen()),
          );
        }

        return recommendations.when(
          loading: () => const _NextStepCard.loading(),
          error: (error, stackTrace) =>
              _fallbackNextStep(context, reviewCount),
          data: (items) {
            if (items.isNotEmpty) {
              final task = items.first;
              return _NextStepCard(
                icon: Icons.play_circle_outline,
                eyebrow: 'RECOMMENDED NEXT',
                title: task.title,
                description:
                    '${task.skill} • ${task.difficulty}. This task is selected from your weaker unfinished skills.',
                buttonLabel: 'Continue learning',
                onPressed: () => _open(context, TaskScreen(task: task)),
              );
            }
            return _fallbackNextStep(context, reviewCount);
          },
        );
      },
    );
  }

  Widget _fallbackNextStep(BuildContext context, int reviewCount) {
    if (reviewCount > 0) {
      return _NextStepCard(
        icon: Icons.replay_outlined,
        eyebrow: 'REVIEW DUE',
        title:
            'Strengthen ${reviewCount == 1 ? '1 weak area' : '$reviewCount weak areas'}',
        description:
            'Review older material before it fades. These items have the highest learning priority.',
        buttonLabel: 'Open review queue',
        onPressed: () => _open(context, const ReviewQueueScreen()),
      );
    }
    return _NextStepCard(
      icon: Icons.today_outlined,
      eyebrow: 'TODAY',
      title: 'Complete the daily challenge',
      description:
          'Keep your streak moving with one short analyst exercise.',
      buttonLabel: 'Start daily challenge',
      onPressed: () => _open(context, const DailyChallengeScreen()),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset career progress?'),
          content: const Text(
            'This removes completed tickets, XP, placement results, skill mastery, portfolio evidence and Boss Case scores stored on this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (shouldReset == true) {
      await ref.read(gameProgressProvider.notifier).reset();
      await ref.read(masteryRepositoryProvider).resetAll();
      await ref.read(bossCaseResultRepositoryProvider).resetAll();
      await ref.read(taskPerformanceRepositoryProvider).resetAll();
      await ref.read(interviewResultRepositoryProvider).resetAll();
      await ref.read(capstoneResultRepositoryProvider).resetAll();
      await ref.read(evidenceRepositoryProvider).resetAll();
      ref.invalidate(skillProfileProvider);
      ref.invalidate(placementCompletedProvider);
      ref.invalidate(reviewQueueProvider);
      ref.invalidate(adaptiveRecommendationsProvider);
      ref.invalidate(portfolioSnapshotProvider);
      ref.invalidate(interviewResultsProvider);
      ref.invalidate(promotionReviewProvider);
      ref.invalidate(companyChapterReviewProvider);
      ref.invalidate(capstoneResultProvider);
      ref.invalidate(jobReadinessProvider);
      ref.invalidate(graduationEligibilityProvider);
      ref.invalidate(careerTasksProvider);
      ref.invalidate(dailyChallengeProvider);
    }
  }
}

class _NextStepCard extends StatelessWidget {
  const _NextStepCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  }) : loading = false;

  const _NextStepCard.loading()
      : icon = Icons.hourglass_top,
        eyebrow = 'BUILDING YOUR PLAN',
        title = 'Finding the best next task…',
        description =
            'DataQuest is checking your progress and unfinished skills.',
        buttonLabel = '',
        onPressed = null,
        loading = true;

  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: scheme.onPrimaryContainer),
                const SizedBox(width: 10),
                Text(
                  eyebrow,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: 16),
            if (loading)
              const LinearProgressIndicator()
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onPressed,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(buttonLabel),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.reviewCount,
    required this.onDaily,
    required this.onReview,
    required this.onGym,
  });

  final int reviewCount;
  final VoidCallback onDaily;
  final VoidCallback onReview;
  final VoidCallback onGym;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          _ActionRow(
            icon: Icons.today_outlined,
            title: 'Daily challenge',
            subtitle: 'One short task • build your streak',
            onTap: onDaily,
          ),
          const Divider(height: 1),
          _ActionRow(
            icon: Icons.replay_outlined,
            title: 'Review queue',
            subtitle: reviewCount == 0
                ? 'Nothing urgent to review'
                : '$reviewCount priority ${reviewCount == 1 ? 'review' : 'reviews'}',
            onTap: onReview,
          ),
          const Divider(height: 1),
          _ActionRow(
            icon: Icons.fitness_center,
            title: 'Practice gym',
            subtitle: 'Choose a skill and difficulty yourself',
            onTap: onGym,
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        children: [
          const Divider(height: 1),
          for (var index = 0; index < items.length; index++) ...[
            _ActionRow(
              icon: items[index].icon,
              title: items[index].title,
              subtitle: items[index].subtitle,
              onTap: items[index].onTap,
            ),
            if (index != items.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 12,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      leading: Icon(icon),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _FocusStrip extends StatelessWidget {
  const _FocusStrip({required this.skills});

  final List<SkillMastery> skills;

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) return const SizedBox.shrink();

    final sorted = [...skills]
      ..sort((a, b) => a.mastery.compareTo(b.mastery));
    final weakest = sorted.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology_alt_outlined, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Current focus: ${weakest.displayName} • ${weakest.mastery.toStringAsFixed(0)}% mastery',
            ),
          ),
        ],
      ),
    );
  }
}

class _CareerCard extends StatelessWidget {
  const _CareerCard({
    required this.progress,
    required this.onlineFeaturesConfigured,
  });

  final GameProgress progress;
  final bool onlineFeaturesConfigured;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    progress.companyStageLabel,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                _StatusPill(
                  icon: onlineFeaturesConfigured
                      ? Icons.cloud_done_outlined
                      : Icons.offline_bolt_outlined,
                  label: onlineFeaturesConfigured
                      ? 'Offline + optional online'
                      : 'Saved offline',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              progress.role,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              progress.companyJourneyCompleted
                  ? 'Five-company journey complete'
                  : 'Company chapter ${progress.resolvedCompanyChapter + 1}',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: progress.roleProgress),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    progress.isTopRole
                        ? '${progress.xp} XP • Top career level'
                        : '${progress.xp} / ${progress.nextRoleXp} XP before review',
                  ),
                ),
                Text(
                  '${progress.dailyStreak} day streak',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _CompanyPulseSection extends StatelessWidget {
  const _CompanyPulseSection({required this.progress});

  final GameProgress progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(Icons.monitor_heart_outlined),
        title: const Text(
          'Company pulse',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('See how your decisions affect the business'),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: _MetricGrid(progress: progress),
          ),
        ],
      ),
    );
  }
}

class _TicketsSection extends StatelessWidget {
  const _TicketsSection({
    required this.progress,
    required this.tasks,
  });

  final GameProgress progress;
  final AsyncValue<List<AnalystTask>> tasks;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(Icons.assignment_outlined),
        title: const Text(
          'Current company tickets',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${progress.completedTaskIds.length} completed • open when you want to browse all work',
        ),
        children: [
          const Divider(height: 1),
          tasks.when(
            data: (items) => Column(
              children: [
                for (final task in items)
                  _TaskCard(
                    task: task,
                    completed: progress.completedTaskIds.contains(task.id),
                  ),
              ],
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Could not load the offline task packs.\n$error',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.progress});

  final GameProgress progress;

  @override
  Widget build(BuildContext context) {
    final metrics = <({String label, String value, IconData icon})>[
      (
        label: 'Revenue',
        value: progress.revenueIndex.toStringAsFixed(1),
        icon: Icons.trending_up,
      ),
      (
        label: 'Churn',
        value: '${progress.churnRate.toStringAsFixed(1)}%',
        icon: Icons.person_remove_alt_1,
      ),
      (
        label: 'Cost',
        value: progress.costIndex.toStringAsFixed(1),
        icon: Icons.payments_outlined,
      ),
      (
        label: 'Satisfaction',
        value: '${progress.satisfaction.toStringAsFixed(0)}%',
        icon: Icons.sentiment_satisfied_alt,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.9,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(metric.icon, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.label,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                      metric.value,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.completed,
  });

  final AnalystTask task;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: completed
            ? const Icon(Icons.check)
            : Text(task.department.substring(0, 1)),
      ),
      title: Text(task.title),
      subtitle: Text(
        '${task.department} • ${task.skill} • ${task.difficulty} • ${task.xp} XP',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TaskScreen(task: task),
          ),
        );
      },
    );
  }
}

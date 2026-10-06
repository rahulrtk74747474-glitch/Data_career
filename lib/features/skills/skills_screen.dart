import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/skill_mastery.dart';
import '../game/game_providers.dart';

class SkillsScreen extends ConsumerWidget {
  const SkillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(skillProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Skill Radar')),
      body: SafeArea(
        child: profile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load your skill profile.\n$error'),
            ),
          ),
          data: (skills) {
            final now = DateTime.now().toUtc();
            final weak = skills.where((skill) => skill.isWeak).toList();
            final due = skills.where((skill) => skill.isDue(now)).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Your analyst profile',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text('${weak.length} weak topics • ${due.length} due for review'),
                const SizedBox(height: 16),
                SizedBox(
                  height: 330,
                  child: _SkillRadar(skills: skills),
                ),
                const SizedBox(height: 16),
                for (final skill in skills)
                  Card(
                    child: ListTile(
                      title: Text(skill.displayName),
                      subtitle: Text(
                        skill.nextReviewAt == null
                            ? 'No review scheduled yet'
                            : 'Next review: ${_formatDate(skill.nextReviewAt!)}',
                      ),
                      trailing: Text(
                        '${skill.mastery.toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                if (weak.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Focus next',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(weak.map((skill) => skill.displayName).join(' • ')),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}

class _SkillRadar extends StatelessWidget {
  const _SkillRadar({required this.skills});

  final List<SkillMastery> skills;

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) {
      return const Center(child: Text('No skill data yet.'));
    }

    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final actual = RadarDataSet(
      dataEntries: [
        for (final skill in skills)
          RadarEntry(value: skill.mastery.clamp(1, 100).toDouble()),
      ],
      fillColor: primary.withAlpha(45),
      borderColor: primary,
      borderWidth: 2,
      entryRadius: 3,
    );

    final ceiling = RadarDataSet(
      dataEntries: [
        for (var index = 0; index < skills.length; index++)
          const RadarEntry(value: 100),
      ],
      fillColor: Colors.transparent,
      borderColor: Colors.transparent,
      borderWidth: 0,
      entryRadius: 0,
    );

    return RadarChart(
      RadarChartData(
        dataSets: [actual, ceiling],
        radarShape: RadarShape.polygon,
        tickCount: 4,
        ticksTextStyle: TextStyle(
          fontSize: 10,
          color: onSurface.withAlpha(150),
        ),
        titleTextStyle: TextStyle(
          fontSize: 12,
          color: onSurface,
        ),
        getTitle: (index, angle) => RadarChartTitle(
          text: skills[index].shortName,
          angle: angle,
        ),
      ),
    );
  }
}

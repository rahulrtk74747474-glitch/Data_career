import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/reminder_settings.dart';
import '../game/game_providers.dart';

class ReminderSettingsScreen extends ConsumerWidget {
  const ReminderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(reminderSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Learning Reminders')),
      body: SafeArea(
        child: settings.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Could not load reminder settings.\n$error'),
          ),
          data: (value) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'You control every reminder',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              const Text(
                'Reminders are local to this device. DataQuest uses inexact scheduling so it does not request exact-alarm access.',
              ),
              const SizedBox(height: 16),
              _ReminderCard(
                title: 'Daily Challenge',
                description:
                    'A daily prompt to complete the rotating analyst challenge.',
                enabled: value.dailyEnabled,
                time: TimeOfDay(
                  hour: value.dailyHour,
                  minute: value.dailyMinute,
                ),
                onToggle: (enabled) => _persist(
                  context,
                  ref,
                  value.copyWith(dailyEnabled: enabled),
                ),
                onTime: () => _pickTime(
                  context,
                  initial: TimeOfDay(
                    hour: value.dailyHour,
                    minute: value.dailyMinute,
                  ),
                  onSelected: (time) => _persist(
                    context,
                    ref,
                    value.copyWith(
                      dailyHour: time.hour,
                      dailyMinute: time.minute,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _ReminderCard(
                title: 'Review Queue',
                description:
                    'A spaced-review prompt for weak or due analyst skills.',
                enabled: value.reviewEnabled,
                time: TimeOfDay(
                  hour: value.reviewHour,
                  minute: value.reviewMinute,
                ),
                onToggle: (enabled) => _persist(
                  context,
                  ref,
                  value.copyWith(reviewEnabled: enabled),
                ),
                onTime: () => _pickTime(
                  context,
                  initial: TimeOfDay(
                    hour: value.reviewHour,
                    minute: value.reviewMinute,
                  ),
                  onSelected: (time) => _persist(
                    context,
                    ref,
                    value.copyWith(
                      reviewHour: time.hour,
                      reviewMinute: time.minute,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'Android may deliver inexact reminders a little before or after the selected time depending on battery and device background restrictions.',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context, {
    required TimeOfDay initial,
    required ValueChanged<TimeOfDay> onSelected,
  }) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (selected != null) onSelected(selected);
  }

  Future<void> _persist(
    BuildContext context,
    WidgetRef ref,
    ReminderSettings settings,
  ) async {
    await ref.read(reminderSettingsRepositoryProvider).save(settings);
    final result = await ref.read(reminderSchedulerProvider).apply(settings);
    ref.invalidate(reminderSettingsProvider);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.permissionGranted
              ? '${result.scheduledCount} reminder schedule(s) active.'
              : 'Notification permission was not granted. Settings are saved, but reminders are not active.',
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.title,
    required this.description,
    required this.enabled,
    required this.time,
    required this.onToggle,
    required this.onTime,
  });

  final String title;
  final String description;
  final bool enabled;
  final TimeOfDay time;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTime;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(title),
              subtitle: Text(description),
              value: enabled,
              onChanged: onToggle,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule_outlined),
              title: const Text('Reminder time'),
              subtitle: Text(time.format(context)),
              trailing: const Icon(Icons.edit_outlined),
              enabled: enabled,
              onTap: enabled ? onTime : null,
            ),
          ],
        ),
      ),
    );
  }
}

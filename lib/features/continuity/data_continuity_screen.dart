import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/game/game_progress.dart';
import '../../models/backup_snapshot.dart';
import '../../models/reminder_settings.dart';
import '../../services/cloud_sync_service.dart';
import '../../services/release_diagnostics_service.dart';
import 'release_diagnostics_screen.dart';
import '../game/game_providers.dart';

class DataContinuityScreen extends ConsumerStatefulWidget {
  const DataContinuityScreen({super.key});

  @override
  ConsumerState<DataContinuityScreen> createState() =>
      _DataContinuityScreenState();
}

class _DataContinuityScreenState
    extends ConsumerState<DataContinuityScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _aliasController = TextEditingController();
  CloudSession? _session;
  List<LeaderboardEntry> _leaderboard = const [];
  bool _busy = false;
  String? _status;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _aliasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(cloudRuntimeConfigProvider);
    final diagnostics = ref.watch(releaseDiagnosticsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Data, Backup & Cloud')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Portable backup',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            const Text(
              'Backups contain player progress, mastery, results, immutable evidence and reminder settings. Synthetic curriculum datasets are rebuilt by the app and are not copied.',
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (buttonContext) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _createAndShareBackup(buttonContext),
                    icon: const Icon(Icons.backup_outlined),
                    label: const Text('Create & share backup'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _restoreBackup,
                    icon: const Icon(Icons.restore_outlined),
                    label: const Text('Restore backup'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Optional cloud continuity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              config.cloudConfigured
                  ? 'This build has a cloud endpoint configured. Sign-in is explicit and session-only; DataQuest does not store your email password.'
                  : 'Cloud sync is not configured in this build. The entire career game, backups, learning and graduation remain fully offline.',
            ),
            if (!config.cloudConfigured) ...[
              const SizedBox(height: 8),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Optional setup uses DATAQUEST_SUPABASE_URL and DATAQUEST_SUPABASE_ANON_KEY via --dart-define. The required database/RLS script is docs/supabase_phase10.sql.',
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                enabled: _session == null && !_busy,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Cloud account email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                enabled: _session == null && !_busy,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              if (_session == null)
                FilledButton.icon(
                  onPressed: _busy ? null : _signIn,
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in for this session'),
                )
              else ...[
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.cloud_done_outlined),
                    title: const Text('Cloud session active'),
                    subtitle: Text(_session!.email),
                    trailing: TextButton(
                      onPressed: _busy
                          ? null
                          : () {
                              setState(() {
                                _session = null;
                                _leaderboard = const [];
                                _passwordController.clear();
                              });
                            },
                      child: const Text('Sign out'),
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _busy ? null : _syncCloud,
                  icon: const Icon(Icons.sync),
                  label: const Text('Merge local + cloud progress'),
                ),
                const SizedBox(height: 16),
                Text(
                  'Privacy-safe leaderboard',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Only your chosen alias, readiness score, graduation flag and update time are published. Evidence, email and company history are not leaderboard fields.',
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _aliasController,
                  enabled: !_busy,
                  maxLength: 20,
                  decoration: const InputDecoration(
                    labelText: 'Display alias (3–20 letters/numbers/_)',
                    border: OutlineInputBorder(),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _busy ? null : _publishLeaderboard,
                      icon: const Icon(Icons.leaderboard_outlined),
                      label: const Text('Publish my score'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _refreshLeaderboard,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh leaderboard'),
                    ),
                  ],
                ),
                if (_leaderboard.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  for (var index = 0;
                      index < _leaderboard.length;
                      index++)
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${index + 1}'),
                        ),
                        title: Text(_leaderboard[index].alias),
                        subtitle: Text(
                          _leaderboard[index].graduated
                              ? 'Graduated'
                              : 'In progress',
                        ),
                        trailing: Text(
                          '${_leaderboard[index].readinessScore}/100',
                        ),
                      ),
                    ),
                ],
              ],
            ],
            if (_status != null) ...[
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_status!),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'Release diagnostics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            diagnostics.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Text(
                'Diagnostics unavailable: $error',
              ),
              data: _DiagnosticsCard.new,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ReleaseDiagnosticsScreen(),
                ),
              ),
              icon: const Icon(Icons.health_and_safety_outlined),
              label: const Text('Open full diagnostics'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createAndShareBackup(BuildContext buttonContext) async {
    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    await _runBusy(() async {
      final reminders =
          await ref.read(reminderSettingsRepositoryProvider).load();
      final snapshot = await ref.read(backupServiceProvider).createSnapshot(
            progress: ref.read(gameProgressProvider),
            reminders: reminders,
          );
      final exported =
          await ref.read(backupServiceProvider).exportToFile(snapshot);
      final share = await ref.read(portfolioDeliveryServiceProvider).share(
            exported.path,
            sharePositionOrigin: origin,
            title: 'DataQuest Portable Backup',
            text:
                'DataQuest portable career backup. Keep this JSON file private because it contains your local learning history.',
          );
      ref.invalidate(releaseDiagnosticsProvider);
      _setStatus(
        'Backup created (${exported.bytes} bytes). Share result: ${share.status.name}.',
      );
    });
  }

  Future<void> _restoreBackup() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final bytes = picked.files.single.bytes;
    if (bytes == null) {
      _setStatus('Could not read the selected backup file.');
      return;
    }

    BackupSnapshot snapshot;
    try {
      snapshot = ref.read(backupServiceProvider).decode(utf8.decode(bytes));
    } catch (error) {
      _setStatus('Backup rejected before restore: $error');
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore this DataQuest backup?'),
        content: Text(
          'Created ${snapshot.createdAt.toLocal()} with app ${snapshot.appVersion}. '
          'Current local player-state tables will be replaced by this validated backup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _runBusy(() => _applySnapshot(snapshot));
  }

  Future<void> _signIn() async {
    await _runBusy(() async {
      final session = await ref.read(cloudSyncServiceProvider).signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (!mounted) return;
      setState(() {
        _session = session;
        _passwordController.clear();
      });
      await _refreshLeaderboard();
      _setStatus(
        'Signed in for this app session. Credentials were not saved.',
      );
    });
  }

  Future<void> _syncCloud() async {
    final session = _session;
    if (session == null) return;

    await _runBusy(() async {
      final reminders =
          await ref.read(reminderSettingsRepositoryProvider).load();
      final local = await ref.read(backupServiceProvider).createSnapshot(
            progress: ref.read(gameProgressProvider),
            reminders: reminders,
          );
      final result = await ref.read(cloudSyncServiceProvider).sync(
            session: session,
            local: local,
          );
      await _applySnapshot(result.snapshot, announce: false);
      _setStatus(
        result.hadRemoteCopy
            ? 'Cloud sync complete. Local and cloud progress were merged deterministically and the merged snapshot was saved to both.'
            : 'Cloud sync complete. No remote save existed, so the current local snapshot became the cloud save.',
      );
    });
  }

  Future<void> _publishLeaderboard() async {
    final session = _session;
    if (session == null) return;

    await _runBusy(() async {
      final readiness = await ref.read(jobReadinessProvider.future);
      final graduation =
          await ref.read(graduationEligibilityProvider.future);
      await ref.read(cloudSyncServiceProvider).publishLeaderboard(
            session: session,
            alias: _aliasController.text,
            readinessScore: readiness.totalScore,
            graduated: graduation.eligible,
          );
      await _refreshLeaderboard();
      _setStatus('Leaderboard entry published using alias-only fields.');
    });
  }

  Future<void> _refreshLeaderboard() async {
    final session = _session;
    if (session == null) return;
    final items = await ref.read(cloudSyncServiceProvider).loadLeaderboard(
          session: session,
        );
    if (!mounted) return;
    setState(() => _leaderboard = items);
  }

  Future<void> _applySnapshot(
    BackupSnapshot snapshot, {
    bool announce = true,
  }) async {
    final reminderRepository =
        ref.read(reminderSettingsRepositoryProvider);
    final currentReminders = await reminderRepository.load();
    final currentProgress = ref.read(gameProgressProvider);

    await ref.read(backupServiceProvider).restoreWithRollback(
          snapshot: snapshot,
          currentProgress: currentProgress,
          currentReminders: currentReminders,
          persistExternalState: (
            GameProgress progress,
            ReminderSettings reminders,
          ) async {
            await ref
                .read(gameProgressProvider.notifier)
                .restoreFromBackup(progress);
            await reminderRepository.save(reminders);
          },
        );

    final restoredReminders = ReminderSettings.fromJson(
      snapshot.reminderSettings,
    );
    try {
      await ref.read(reminderSchedulerProvider).apply(restoredReminders);
    } catch (_) {
      // Notification support is best-effort and never invalidates restored data.
    }

    _invalidatePlayerState();
    if (announce) {
      _setStatus(
        'Backup restored successfully. Player state was validated and applied atomically.',
      );
    }
  }

  void _invalidatePlayerState() {
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
    ref.invalidate(reminderSettingsProvider);
    ref.invalidate(releaseDiagnosticsProvider);
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await action();
    } catch (error) {
      _setStatus('Operation failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _setStatus(String message) {
    if (!mounted) return;
    setState(() => _status = message);
  }
}

class _DiagnosticsCard extends StatelessWidget {
  const _DiagnosticsCard(this.diagnostics);

  final ReleaseDiagnostics diagnostics;

  @override
  Widget build(BuildContext context) {
    final backup = diagnostics.lastBackupAt == null
        ? 'Never'
        : diagnostics.lastBackupAt!.toLocal().toString();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('App: ${diagnostics.appVersion}'),
            Text('SQLite schema: v${diagnostics.databaseSchema}'),
            Text('Backup schema: v${diagnostics.backupSchema}'),
            Text(
              'Weekly case schema: v${diagnostics.weeklyCaseSchema}',
            ),
            Text(
              'Cloud save: ${diagnostics.cloudConfigured ? 'configured' : 'offline-only'}',
            ),
            Text(
              'Weekly online feed: ${diagnostics.weeklyCasesConfigured ? 'configured' : 'bundled/cache only'}',
            ),
            Text('Last backup/restore: $backup'),
          ],
        ),
      ),
    );
  }
}

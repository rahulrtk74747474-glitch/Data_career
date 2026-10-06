import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_providers.dart';

class ReleaseDiagnosticsScreen extends ConsumerWidget {
  const ReleaseDiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnostics = ref.watch(releaseDiagnosticsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Release Diagnostics')),
      body: SafeArea(
        child: diagnostics.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Could not load diagnostics.\n$error'),
          ),
          data: (value) {
            final backup = value.lastBackupAt == null
                ? 'No backup recorded'
                : value.lastBackupAt!.toLocal().toString();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Safe support information',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                const Text(
                  'This page shows build and schema status only. It never displays cloud keys, passwords, access tokens or evidence contents.',
                ),
                const SizedBox(height: 16),
                _DiagnosticTile(
                  label: 'App version',
                  value: value.appVersion,
                ),
                _DiagnosticTile(
                  label: 'SQLite schema',
                  value: 'v${value.databaseSchema}',
                ),
                _DiagnosticTile(
                  label: 'Backup schema',
                  value: 'v${value.backupSchema}',
                ),
                _DiagnosticTile(
                  label: 'Weekly case schema',
                  value: 'v${value.weeklyCaseSchema}',
                ),
                _DiagnosticTile(
                  label: 'Cloud save',
                  value: value.cloudConfigured
                      ? 'Configured for this build'
                      : 'Not configured — offline mode',
                ),
                _DiagnosticTile(
                  label: 'Weekly online feed',
                  value: value.weeklyCasesConfigured
                      ? 'Configured'
                      : 'Bundled/cache fallback only',
                ),
                _DiagnosticTile(
                  label: 'Last backup/restore',
                  value: backup,
                ),
                const SizedBox(height: 16),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      'Troubleshooting order: verify this version/schema page, create a portable backup, then reproduce the issue. Core learning data is local and does not depend on cloud availability.',
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DiagnosticTile extends StatelessWidget {
  const _DiagnosticTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}

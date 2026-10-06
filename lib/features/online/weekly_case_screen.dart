import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/weekly_case.dart';
import '../game/game_providers.dart';

class WeeklyCaseScreen extends ConsumerStatefulWidget {
  const WeeklyCaseScreen({super.key});

  @override
  ConsumerState<WeeklyCaseScreen> createState() => _WeeklyCaseScreenState();
}

class _WeeklyCaseScreenState extends ConsumerState<WeeklyCaseScreen> {
  late Future<WeeklyCaseLoadResult> _future;
  String _choice = '';
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _future = ref.read(weeklyCaseServiceProvider).load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Analyst Case'),
        actions: [
          IconButton(
            tooltip: 'Refresh case',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<WeeklyCaseLoadResult>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Could not load a valid weekly case.\n${snapshot.error ?? ''}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final result = snapshot.data!;
            final item = result.pack;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    Chip(label: Text(result.source)),
                  ],
                ),
                if (result.message != null) ...[
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(result.message!),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(item.context),
                const SizedBox(height: 16),
                Text(
                  item.prompt,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final option in item.options)
                  Card(
                    child: ListTile(
                      leading: Icon(
                        _choice == option
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                      ),
                      title: Text(option),
                      selected: _choice == option,
                      onTap: _feedback == null
                          ? () => setState(() => _choice = option)
                          : null,
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _choice.isEmpty || _feedback != null
                      ? null
                      : () {
                          final correct = _choice == item.expectedAnswer;
                          setState(() {
                            _feedback = correct
                                ? 'Correct. ${item.explanation}'
                                : 'Not yet. ${item.explanation}';
                          });
                        },
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Check answer'),
                ),
                if (_feedback != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(_feedback!),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  'Pack: ${item.caseId} • week ${item.weekKey} • schema v${item.schemaVersion}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _refresh() {
    setState(() {
      _choice = '';
      _feedback = null;
      _future = ref.read(weeklyCaseServiceProvider).load(refresh: true);
    });
  }
}

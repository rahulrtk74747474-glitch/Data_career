import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'job_ready_providers.dart';

class DomainPlaybooksScreen extends ConsumerWidget {
  const DomainPlaybooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbooks = ref.watch(domainPlaybooksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Business Playbooks')),
      body: SafeArea(
        child: playbooks.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('$error')),
          data: (items) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Text(
                'Understand the business behind the data',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              const Text(
                'A strong analyst understands how the company operates, which levers matter, how metrics connect and which common traps can mislead decisions.',
              ),
              const SizedBox(height: 16),
              for (final item in items)
                Card(
                  child: ExpansionTile(
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(item.operatingModel),
                    childrenPadding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Business levers',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final lever in item.levers)
                            Chip(label: Text(lever)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      for (final metric in item.metrics)
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  metric.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                SelectableText('Formula: ${metric.formula}'),
                                const SizedBox(height: 4),
                                Text('Use: ${metric.use}'),
                                const SizedBox(height: 4),
                                Text('Watch-out: ${metric.trap}'),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

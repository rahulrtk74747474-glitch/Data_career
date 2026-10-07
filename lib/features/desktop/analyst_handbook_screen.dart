import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/workday_content.dart';
import '../game/game_providers.dart';

class AnalystHandbookScreen extends ConsumerStatefulWidget {
  const AnalystHandbookScreen({super.key});

  @override
  ConsumerState<AnalystHandbookScreen> createState() =>
      _AnalystHandbookScreenState();
}

class _AnalystHandbookScreenState
    extends ConsumerState<AnalystHandbookScreen> {
  String _query = '';
  String _skill = 'All';

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(handbookEntriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Analyst Handbook')),
      body: SafeArea(
        child: entries.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('$error')),
          data: (items) {
            final skills = <String>{'All', ...items.map((item) => item.skill)};
            final query = _query.trim().toLowerCase();
            final filtered = items.where((item) {
              final skillOk = _skill == 'All' || item.skill == _skill;
              final text = [
                item.title,
                item.shortcut,
                item.formula,
                item.example,
                ...item.tags,
              ].join(' ').toLowerCase();
              return skillOk && (query.isEmpty || text.contains(query));
            }).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Text(
                  'Your shortcut reference',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Formula → example → when to use → when not to use → real business scenario.',
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Search formula, concept or command',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final skill in skills) ...[
                        ChoiceChip(
                          label: Text(skill),
                          selected: _skill == skill,
                          onSelected: (_) => setState(() => _skill = skill),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                for (final item in filtered) _HandbookCard(item: item),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HandbookCard extends StatelessWidget {
  const _HandbookCard({required this.item});
  final HandbookEntry item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${item.skill} • ${item.shortcut}'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _Row(label: 'Formula / syntax', value: item.formula),
          _Row(label: 'Example', value: item.example),
          _Row(label: 'Use when', value: item.whenUse),
          _Row(label: 'Avoid when', value: item.whenNotUse),
          _Row(label: 'Company scenario', value: item.scenario),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

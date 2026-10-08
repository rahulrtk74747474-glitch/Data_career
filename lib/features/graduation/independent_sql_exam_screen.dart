import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/independent_sql_exam_service.dart';
import '../game/game_providers.dart';

class IndependentSqlExamScreen extends ConsumerStatefulWidget {
  const IndependentSqlExamScreen({super.key});

  @override
  ConsumerState<IndependentSqlExamScreen> createState() =>
      _IndependentSqlExamScreenState();
}

class _IndependentSqlExamScreenState
    extends ConsumerState<IndependentSqlExamScreen> {
  final controller = TextEditingController();
  bool loading = true;
  bool running = false;
  bool passed = false;
  String? feedback;
  List<Map<String, Object?>> events = const [];
  IndependentSqlExamService get service =>
      IndependentSqlExamService(ref.read(appDatabaseProvider));

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final source = await service.preview();
      final completed = await service.hasPassed();
      if (!mounted) return;
      setState(() {
        events = source;
        passed = completed;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        feedback = error.toString();
        loading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (controller.text.trim().isEmpty || running) return;
    setState(() => running = true);
    try {
      final result = await service.assess(controller.text);
      if (!mounted) return;
      setState(() {
        feedback = result.feedback;
        passed = passed || result.correct;
        running = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        feedback = error.toString();
        running = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Independent SQL Exam')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Unseen SQL transfer challenge',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  const Text(
                    'No guided solution or SQL hints. Your query must execute '
                    'against this local dataset, return the expected result '
                    'and remain correct when an amount changes. This is a '
                    'synthetic training assessment, not an accredited exam.',
                  ),
                  const SizedBox(height: 14),
                  const Text(IndependentSqlExamService.instructions),
                  const SizedBox(height: 10),
                  const Text(
                    'Available table columns: dq_exam_event '
                    '(event_id, order_id, region, status, gross_amount, '
                    'refunded_amount, ingested_at). '
                    'View dq_exam_latest: order_id, region, status, net_revenue.',
                  ),
                  const SizedBox(height: 8),
                  if (events.isNotEmpty)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          for (final name in events.first.keys)
                            DataColumn(label: Text(name)),
                        ],
                        rows: [
                          for (final row in events)
                            DataRow(cells: [
                              for (final key in events.first.keys)
                                DataCell(Text((row[key] ?? '').toString())),
                            ]),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    maxLines: 10,
                    minLines: 6,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Your independent SQL query',
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: running ? null : _submit,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Execute and assess SQL'),
                  ),
                  if (feedback != null) ...[
                    const SizedBox(height: 10),
                    Text(feedback!),
                  ],
                  if (passed) ...[
                    const SizedBox(height: 10),
                    const Card(
                      child: ListTile(
                        leading: Icon(Icons.verified_outlined),
                        title: Text('Independent SQL training assessment passed'),
                        subtitle: Text('Execution and changed-data verification; '
                            'not equivalent to professional work experience.'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

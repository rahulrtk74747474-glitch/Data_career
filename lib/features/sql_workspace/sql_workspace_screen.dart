import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/sql_table_schema.dart';
import '../../services/sql_runner.dart';
import '../game/game_providers.dart';

class SqlWorkspaceScreen extends ConsumerStatefulWidget {
  const SqlWorkspaceScreen({super.key});

  @override
  ConsumerState<SqlWorkspaceScreen> createState() =>
      _SqlWorkspaceScreenState();
}

class _SqlWorkspaceScreenState extends ConsumerState<SqlWorkspaceScreen> {
  final _queryController = TextEditingController(
    text: 'SELECT * FROM orders LIMIT 10;',
  );
  String? _selectedTable;
  SqlRunResult? _runResult;
  bool _running = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final schemas = ref.watch(sqlSchemasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('SQL Workstation')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Schema browser',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            const Text(
              'Inspect the offline learning database, preview rows, then experiment in the read-only scratchpad.',
            ),
            const SizedBox(height: 14),
            schemas.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) =>
                  Text('Could not load schemas.\n$error'),
              data: (items) => _SchemaBrowser(
                schemas: items,
                selectedTable: _selectedTable,
                onChanged: (value) {
                  setState(() => _selectedTable = value);
                },
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'SQL scratchpad',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Keyword shortcuts',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final keyword in const [
                    'SELECT ',
                    'FROM ',
                    'WHERE ',
                    'JOIN ',
                    'ON ',
                    'GROUP BY ',
                    'HAVING ',
                    'ORDER BY ',
                    'WITH ',
                    'CASE ',
                    'OVER (',
                    'PARTITION BY ',
                    'LIMIT ',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(keyword.trim()),
                        onPressed: () => _insertKeyword(keyword),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _queryController,
              minLines: 6,
              maxLines: 14,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                hintText: 'SELECT ...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _running ? null : _runQuery,
              icon: _running
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: const Text('Run read-only query'),
            ),
            if (_runResult != null) ...[
              const SizedBox(height: 14),
              if (!_runResult!.isSuccess)
                Text(_runResult!.error ?? 'Unknown SQL error')
              else
                _ResultTable(result: _runResult!),
            ],
          ],
        ),
      ),
    );
  }

  void _insertKeyword(String keyword) {
    final value = _queryController.value;
    final start = value.selection.start < 0
        ? value.text.length
        : value.selection.start;
    final end = value.selection.end < 0
        ? start
        : value.selection.end;
    final nextText = value.text.replaceRange(start, end, keyword);
    _queryController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(
        offset: start + keyword.length,
      ),
    );
  }

  Future<void> _runQuery() async {
    setState(() => _running = true);
    final result =
        await ref.read(sqlRunnerProvider).runReadOnly(_queryController.text);
    if (!mounted) return;
    setState(() {
      _running = false;
      _runResult = result;
    });
  }
}

class _SchemaBrowser extends ConsumerWidget {
  const _SchemaBrowser({
    required this.schemas,
    required this.selectedTable,
    required this.onChanged,
  });

  final List<SqlTableSchema> schemas;
  final String? selectedTable;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (schemas.isEmpty) {
      return const Text('No learning tables found.');
    }

    final effectiveTable = schemas.any(
      (schema) => schema.name == selectedTable,
    )
        ? selectedTable!
        : schemas.first.name;
    final schema =
        schemas.firstWhere((item) => item.name == effectiveTable);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: effectiveTable,
          decoration: const InputDecoration(labelText: 'Table'),
          items: [
            for (final item in schemas)
              DropdownMenuItem(
                value: item.name,
                child: Text(item.name),
              ),
          ],
          onChanged: onChanged,
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                for (final column in schema.columns)
                  Chip(
                    label: Text(
                      '${column.name}${column.type.isEmpty ? '' : ' • ${column.type}'}${column.primaryKey ? ' • PK' : ''}',
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<Map<String, Object?>>>(
          future: ref
              .read(sqlWorkspaceRepositoryProvider)
              .previewTable(effectiveTable),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LinearProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text('Preview error: ${snapshot.error}');
            }
            final rows = snapshot.data ?? const [];
            if (rows.isEmpty) return const Text('No rows.');
            return _GenericRowsTable(rows: rows);
          },
        ),
      ],
    );
  }
}

class _ResultTable extends StatelessWidget {
  const _ResultTable({required this.result});

  final SqlRunResult result;

  @override
  Widget build(BuildContext context) {
    if (result.rows.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Text('Query returned 0 rows.'),
        ),
      );
    }
    return _GenericRowsTable(rows: result.rows);
  }
}

class _GenericRowsTable extends StatelessWidget {
  const _GenericRowsTable({required this.rows});

  final List<Map<String, Object?>> rows;

  @override
  Widget build(BuildContext context) {
    final columns = rows.first.keys.toList();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            for (final column in columns) DataColumn(label: Text(column)),
          ],
          rows: [
            for (final row in rows)
              DataRow(
                cells: [
                  for (final column in columns)
                    DataCell(Text((row[column] ?? 'NULL').toString())),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

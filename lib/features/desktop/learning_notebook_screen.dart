import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/learning_note.dart';
import '../game/game_providers.dart';

class LearningNotebookScreen extends ConsumerStatefulWidget {
  const LearningNotebookScreen({super.key});

  @override
  ConsumerState<LearningNotebookScreen> createState() =>
      _LearningNotebookScreenState();
}

class _LearningNotebookScreenState
    extends ConsumerState<LearningNotebookScreen> {
  String _query = '';
  String _skill = 'All';

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(learningNotesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Notebook'),
        actions: [
          IconButton(
            tooltip: 'Add my note',
            onPressed: _addNote,
            icon: const Icon(Icons.note_add_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: notes.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('$error')),
          data: (items) {
            final skills = <String>{'All', ...items.map((item) => item.skillKey)};
            final q = _query.trim().toLowerCase();
            final filtered = items.where((item) {
              final skillOk = _skill == 'All' || item.skillKey == _skill;
              final text =
                  '${item.title} ${item.shortcut} ${item.detail}'.toLowerCase();
              return skillOk && (q.isEmpty || text.contains(q));
            }).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Text(
                  'Everything you learn, in shortcut form',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Completed lessons and labs are captured automatically. Add your own notes too, then revise them later.',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          labelText: 'Search notes',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => setState(() => _query = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Quick revision',
                      onPressed: filtered.isEmpty
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => _RevisionDeck(
                                    notes: filtered.take(10).toList(),
                                  ),
                                ),
                              ),
                      icon: const Icon(Icons.style_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final skill in skills) ...[
                        ChoiceChip(
                          label: Text(_label(skill)),
                          selected: _skill == skill,
                          onSelected: (_) => setState(() => _skill = skill),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No notes yet. Complete a lesson or add your first manual note.',
                      ),
                    ),
                  ),
                for (final note in filtered)
                  _NoteCard(
                    note: note,
                    onDelete: note.manualIndex == null
                        ? null
                        : () => ref
                            .read(gameProgressProvider.notifier)
                            .deleteManualNoteAt(note.manualIndex!),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNote,
        icon: const Icon(Icons.edit_note),
        label: const Text('Write note'),
      ),
    );
  }

  Future<void> _addNote() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Write a note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 3,
          maxLines: 7,
          decoration: const InputDecoration(
            hintText: 'Write the shortcut, formula, mistake or insight you want to remember…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) {
      await ref.read(gameProgressProvider.notifier).addManualNote(value);
    }
  }

  static String _label(String key) {
    switch (key) {
      case 'spreadsheets':
        return 'Excel';
      case 'cleaning':
        return 'Cleaning';
      case 'statistics':
        return 'Statistics';
      case 'python':
        return 'Python/Pandas';
      case 'powerbi':
        return 'Power BI';
      case 'business':
        return 'Business';
      case 'manual':
        return 'My notes';
      case 'All':
        return 'All';
      default:
        return key.toUpperCase();
    }
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, this.onDelete});
  final LearningNote note;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Text(
          note.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${note.source} • ${note.shortcut}'),
        trailing: onDelete == null
            ? null
            : IconButton(
                tooltip: 'Delete my note',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SelectableText(note.detail),
          ),
        ],
      ),
    );
  }
}

class _RevisionDeck extends StatefulWidget {
  const _RevisionDeck({required this.notes});
  final List<LearningNote> notes;

  @override
  State<_RevisionDeck> createState() => _RevisionDeckState();
}

class _RevisionDeckState extends State<_RevisionDeck> {
  int _index = 0;
  bool _showDetail = false;

  @override
  Widget build(BuildContext context) {
    final note = widget.notes[_index];
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Revision')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${_index + 1} / ${widget.notes.length} • ${note.source}',
              ),
              const SizedBox(height: 18),
              Text(
                note.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    note.shortcut,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => setState(() => _showDetail = !_showDetail),
                icon: Icon(
                  _showDetail ? Icons.visibility_off : Icons.visibility,
                ),
                label: Text(_showDetail ? 'Hide explanation' : 'Reveal explanation'),
              ),
              if (_showDetail) ...[
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(note.detail),
                  ),
                ),
              ] else
                const Spacer(),
              FilledButton(
                onPressed: _index >= widget.notes.length - 1
                    ? () => Navigator.pop(context)
                    : () => setState(() {
                          _index++;
                          _showDetail = false;
                        }),
                child: Text(
                  _index >= widget.notes.length - 1 ? 'Finish revision' : 'Next note',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

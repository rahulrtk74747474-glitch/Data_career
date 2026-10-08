import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/job_ready_v15.dart';
import '../../services/adaptive_manager_service.dart';
import 'job_ready_providers.dart';

class AdaptiveManagerScreen extends ConsumerWidget {
  const AdaptiveManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenarios = ref.watch(adaptiveCoachScenariosProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Adaptive Manager')),
      body: SafeArea(
        child: scenarios.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('$error')),
          data: (items) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Text(
                'Defend your analysis in a conversation',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              const Text(
                'This offline coach adapts its next question to what your answer is missing: evidence, uncertainty, business impact or action. It does not require an AI API.',
              ),
              const SizedBox(height: 16),
              for (final scenario in items)
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.psychology_alt_outlined),
                    ),
                    title: Text(scenario.title),
                    subtitle: Text(scenario.companyKey.toUpperCase()),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            _AdaptiveConversationScreen(scenario: scenario),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdaptiveConversationScreen extends StatefulWidget {
  const _AdaptiveConversationScreen({required this.scenario});
  final AdaptiveCoachScenario scenario;

  @override
  State<_AdaptiveConversationScreen> createState() =>
      _AdaptiveConversationScreenState();
}

class _AdaptiveConversationScreenState
    extends State<_AdaptiveConversationScreen> {
  final _controller = TextEditingController();
  final _history = <_CoachMessage>[];
  int _turn = 0;
  String? _prompt;

  @override
  void initState() {
    super.initState();
    _prompt = widget.scenario.prompt;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.scenario.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final message in _history)
              Align(
                alignment: message.manager
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '${message.manager ? 'Manager' : 'You'}\n${message.text}',
                    ),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('Manager\n$_prompt'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Your answer',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _controller.text.trim().isEmpty ? null : _reply,
              icon: const Icon(Icons.send_outlined),
              label: Text(_turn >= 3 ? 'Finish conversation' : 'Reply'),
            ),
          ],
        ),
      ),
    );
  }

  void _reply() {
    final answer = _controller.text.trim();
    final result = AdaptiveManagerService.respond(
      scenario: widget.scenario,
      answer: answer,
      turn: _turn,
    );

    setState(() {
      _history.add(_CoachMessage(manager: false, text: answer));
      _history.add(
        _CoachMessage(
          manager: true,
          text: 'Score ${result.score}/100. ${result.feedback}',
        ),
      );
      _prompt = result.nextQuestion;
      _turn++;
      _controller.clear();
    });

    if (_turn >= 4) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Manager conversation complete'),
          content: const Text(
            'You completed four adaptive follow-ups. Re-run the scenario later and try to answer with stronger evidence and fewer prompts.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }
}

class _CoachMessage {
  const _CoachMessage({
    required this.manager,
    required this.text,
  });

  final bool manager;
  final String text;
}

// ignore_for_file: prefer_interpolation_to_compose_strings
import 'package:flutter/material.dart';

import '../../services/company_next_day_simulation.dart';

/// A fictional, persistent workday-two response to a learner's intervention.
/// It deliberately separates external shocks from chosen-policy assumptions.
class NextDayConsequenceScreen extends StatefulWidget {
  const NextDayConsequenceScreen({
    super.key, required this.caseKey, required this.companyName,
  });
  final String caseKey;
  final String companyName;

  @override
  State<NextDayConsequenceScreen> createState() =>
      _NextDayConsequenceScreenState();
}

class _NextDayConsequenceScreenState
    extends State<NextDayConsequenceScreen> {
  final _repository = const CompanyNextDayRepository();
  CompanyNextDayResult? _result;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final saved = await _repository.load(widget.caseKey);
      if (!mounted) return;
      setState(() {
        _result = saved;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _choose(String action) async {
    if (_saving || _result != null) return;
    setState(() => _saving = true);
    try {
      final result = CompanyNextDaySimulation.evaluate(widget.caseKey, action);
      await _repository.save(result);
      if (!mounted) return;
      setState(() {
        _result = result;
        _saving = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Next Day: Consequences')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    widget.companyName + ' — 9:15 AM follow-up',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your manager requests an intervention decision. '
                    'Choose carefully: costs, service quality and operational '
                    'risk may move in different directions. This is a '
                    'deterministic synthetic business scenario, not a forecast.',
                  ),
                  const SizedBox(height: 12),
                  if (_error != null) Text(_error!),
                  if (_result == null) ...[
                    for (final option in CompanyNextDaySimulation.choices.entries)
                      Card(
                        child: ListTile(
                          title: Text(option.value),
                          subtitle: Text(option.key == 'validate'
                              ? 'Smaller immediate effect, lower risk, '
                                  'and evidence before broad rollout.'
                              : option.key == 'scale'
                                  ? 'Higher upfront cost and potential '
                                      'capacity improvement; uncertainty remains.'
                                  : 'Immediate cost relief, but possible '
                                      'service deterioration and higher risk.'),
                          trailing: const Icon(Icons.chevron_right),
                          enabled: !_saving,
                          onTap: () => _choose(option.key),
                        ),
                      ),
                  ] else ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Policy: ' +
                                CompanyNextDaySimulation.choices[_result!.action]!),
                            const SizedBox(height: 12),
                            Text('Remaining budget: ' + _result!.budget.toString() +
                                ' synthetic units'),
                            Text('Service-quality index: ' + _result!.service.toString() + '/100'),
                            Text('Operating-cost index: ' + _result!.cost.toString() + '/100'),
                            Text('Operational-risk index: ' + _result!.risk.toString() + '/100'),
                            const SizedBox(height: 12),
                            Text(_result!.explanation),
                          ],
                        ),
                      ),
                    ),
                    const Text(
                      'Your decision is saved locally. A different policy '
                      'could have produced a different modeled result, but '
                      'neither scenario is proof of real-world causation.',
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

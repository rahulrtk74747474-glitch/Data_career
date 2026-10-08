// ignore_for_file: prefer_interpolation_to_compose_strings
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/filter_context_dax_lab.dart';
import '../game/game_providers.dart';

class FilterContextDaxScreen extends ConsumerStatefulWidget {
  const FilterContextDaxScreen({super.key});

  @override
  ConsumerState<FilterContextDaxScreen> createState() =>
      _FilterContextDaxScreenState();
}

class _FilterContextDaxScreenState
    extends ConsumerState<FilterContextDaxScreen> {
  final controller = TextEditingController();
  String region = 'North';
  int? value;
  String? message;
  bool accepted = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    try {
      final calculated = FilterContextDaxLab.evaluate(
        controller.text, slicerRegion: region,
      );
      final correct = FilterContextDaxLab.passesAllRegionIndependentTask(
        controller.text,
      );
      if (correct && !accepted) {
        await ref.read(masteryRepositoryProvider).recordAttempt('powerbi', 90);
        ref.invalidate(skillProfileProvider);
      }
      if (!mounted) return;
      setState(() {
        value = calculated;
        accepted = accepted || correct;
        message = correct
            ? 'Correct: the measure deliberately removes the Customer '
                'region slicer and returns 4200 in all tested contexts.'
            : 'The measure ran, but a hidden North/South slicer test failed. '
                'Check CALCULATE and ALL(Customers).';
      });
    } on FormatException catch (error) {
      setState(() {
        value = null;
        message = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BI Filter Context Lab')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Model measures, not just charts',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text(
              'This is an offline teaching subset of DAX. It evaluates '
              'actual Customer → Sales relationship filtering, not '
              'Microsoft Power BI or a full DAX runtime.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Customer table: C01 North, C02 South, C03 North. '
              'Sales table: five records connected by customer_id. '
              'Gross sales are 4200 across all regions.',
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: region,
              decoration: const InputDecoration(
                labelText: 'Current report region slicer',
              ),
              items: const [
                DropdownMenuItem(value: 'North', child: Text('North')),
                DropdownMenuItem(value: 'South', child: Text('South')),
              ],
              onChanged: (next) {
                if (next != null) setState(() => region = next);
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Challenge: write one measure that returns total sales '
              'across every region, even when a region slicer is active. '
              'Use SUM, CALCULATE and ALL on the Customer table.',
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              minLines: 3,
              maxLines: 5,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Your DAX-like measure',
                hintText: 'All Sales = CALCULATE(...)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _run,
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Evaluate all filter contexts'),
            ),
            if (value != null) ...[
              const SizedBox(height: 12),
              Text('Current slicer output: ' + value.toString()),
            ],
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message!),
            ],
            if (accepted)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.verified_outlined),
                  title: Text('Filter-context practice passed'),
                  subtitle: Text('Verified on North and South slicers in the '
                      'in-app subset; not a native Power BI certificate.'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

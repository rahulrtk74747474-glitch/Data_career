import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_providers.dart';

class CertificateScreen extends ConsumerStatefulWidget {
  const CertificateScreen({super.key});

  @override
  ConsumerState<CertificateScreen> createState() =>
      _CertificateScreenState();
}

class _CertificateScreenState extends ConsumerState<CertificateScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eligibility = ref.watch(graduationEligibilityProvider);
    final readiness = ref.watch(jobReadinessProvider);
    final capstone = ref.watch(capstoneResultProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Graduation Certificate')),
      body: SafeArea(
        child: eligibility.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Text('Could not calculate graduation status.\n$error'),
          ),
          data: (status) {
            final ready = readiness.valueOrNull;
            final capstoneResult = capstone.valueOrNull;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Icon(
                  status.eligible
                      ? Icons.workspace_premium_outlined
                      : Icons.lock_outline,
                  size: 64,
                ),
                const SizedBox(height: 12),
                Text(
                  status.eligible
                      ? 'Graduation unlocked'
                      : 'Certificate locked',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                for (final criterion in status.criteria)
                  Card(
                    child: ListTile(
                      leading: Icon(
                        criterion.met
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                      ),
                      title: Text(criterion.label),
                      subtitle: Text(criterion.detail),
                    ),
                  ),
                if (status.eligible &&
                    ready != null &&
                    capstoneResult != null) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Name to print on certificate',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (buttonContext) => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _openCertificate(
                            context,
                            ready.totalScore,
                            capstoneResult.totalScore,
                          ),
                          icon: const Icon(Icons.open_in_new_outlined),
                          label: const Text('Open certificate'),
                        ),
                        FilledButton.icon(
                          onPressed: () {
                            final box = buttonContext.findRenderObject()
                                as RenderBox?;
                            final origin = box == null
                                ? null
                                : box.localToGlobal(Offset.zero) & box.size;
                            _shareCertificate(
                              context,
                              ready.totalScore,
                              capstoneResult.totalScore,
                              origin,
                            );
                          },
                          icon: const Icon(Icons.share_outlined),
                          label: const Text('Share certificate'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'The certificate is generated locally as lightweight HTML and can be printed or saved as PDF by the device browser. It is a DataQuest training completion certificate, not an accredited academic credential.',
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<String?> _export(
    BuildContext context,
    int readinessScore,
    int capstoneScore,
  ) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the certificate name first.')),
      );
      return null;
    }

    final result = await ref.read(certificateExportServiceProvider).exportHtml(
          learnerName: name,
          readinessScore: readinessScore,
          capstoneScore: capstoneScore,
        );
    return result.path;
  }

  Future<void> _openCertificate(
    BuildContext context,
    int readinessScore,
    int capstoneScore,
  ) async {
    final path = await _export(context, readinessScore, capstoneScore);
    if (path == null || !context.mounted) return;

    final result = await ref.read(portfolioDeliveryServiceProvider).open(path);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.opened
              ? 'Certificate opened.'
              : 'Could not open certificate: ${result.message}',
        ),
      ),
    );
  }

  Future<void> _shareCertificate(
    BuildContext context,
    int readinessScore,
    int capstoneScore,
    Rect? origin,
  ) async {
    final path = await _export(context, readinessScore, capstoneScore);
    if (path == null || !context.mounted) return;

    await ref.read(portfolioDeliveryServiceProvider).share(
          path,
          sharePositionOrigin: origin,
          title: 'DataQuest Completion Certificate',
          text:
              'DataQuest Analyst Career completion certificate. Open in a browser to print or save as PDF.',
        );
  }
}

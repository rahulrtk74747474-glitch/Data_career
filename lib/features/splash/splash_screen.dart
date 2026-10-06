import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_routes.dart';
import '../game/game_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String _status = 'Opening offline workspace...';
  Object? _error;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_initialize);
  }

  Future<void> _initialize() async {
    if (mounted) {
      setState(() {
        _error = null;
        _status = 'Opening offline workspace...';
      });
    }

    try {
      await ref.read(appDatabaseProvider).database;
      if (mounted) {
        setState(() => _status = 'Installing content packs...');
      }
      await ref.read(contentPackLoaderProvider).installBundledPacks();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _status = 'Startup could not finish safely.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(
                      Icons.analytics_outlined,
                      size: 42,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'DataQuest',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Analyst Career',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 26),
                  if (_error == null) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 14),
                    Text(_status, textAlign: TextAlign.center),
                    const SizedBox(height: 6),
                    const Text(
                      'Core learning works fully offline.',
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    const Icon(Icons.error_outline, size: 38),
                    const SizedBox(height: 10),
                    Text(
                      _status,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_error',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _initialize,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry startup'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

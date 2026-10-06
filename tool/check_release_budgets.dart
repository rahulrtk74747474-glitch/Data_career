import 'dart:io';

const maxDebugApkBytes = 200 * 1024 * 1024;
const maxReleaseAabBytes = 70 * 1024 * 1024;
const maxReleaseSplitApkBytes = 45 * 1024 * 1024;
const maxContentBytes = 5 * 1024 * 1024;

void main() {
  final checks = <_BudgetCheck>[
    const _BudgetCheck(
      path: 'build/app/outputs/flutter-apk/app-debug.apk',
      maxBytes: maxDebugApkBytes,
      label: 'debug APK',
    ),
    const _BudgetCheck(
      path: 'build/app/outputs/bundle/release/app-release.aab',
      maxBytes: maxReleaseAabBytes,
      label: 'release AAB',
    ),
    const _BudgetCheck(
      path: 'build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk',
      maxBytes: maxReleaseSplitApkBytes,
      label: 'ARM32 release APK',
    ),
    const _BudgetCheck(
      path: 'build/app/outputs/flutter-apk/app-arm64-v8a-release.apk',
      maxBytes: maxReleaseSplitApkBytes,
      label: 'ARM64 release APK',
    ),
    const _BudgetCheck(
      path: 'build/app/outputs/flutter-apk/app-x86_64-release.apk',
      maxBytes: maxReleaseSplitApkBytes,
      label: 'x86_64 release APK',
    ),
  ];

  var failed = false;
  for (final check in checks) {
    final file = File(check.path);
    if (!file.existsSync()) {
      stderr.writeln('Missing ${check.label}: ${check.path}');
      failed = true;
      continue;
    }
    final bytes = file.lengthSync();
    stdout.writeln(
      '${check.label}: ${_mb(bytes)} MB / ${_mb(check.maxBytes)} MB budget',
    );
    if (bytes > check.maxBytes) {
      stderr.writeln('${check.label} exceeds its release budget.');
      failed = true;
    }
  }

  final contentDirectory = Directory('assets/content');
  if (!contentDirectory.existsSync()) {
    stderr.writeln('Missing assets/content directory.');
    failed = true;
  } else {
    final contentBytes = contentDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .fold<int>(0, (sum, file) => sum + file.lengthSync());
    stdout.writeln(
      'content assets: ${_mb(contentBytes)} MB / ${_mb(maxContentBytes)} MB budget',
    );
    if (contentBytes > maxContentBytes) {
      stderr.writeln('Content assets exceed the low-memory budget.');
      failed = true;
    }
  }

  if (failed) exitCode = 1;
}

String _mb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(2);

class _BudgetCheck {
  const _BudgetCheck({
    required this.path,
    required this.maxBytes,
    required this.label,
  });

  final String path;
  final int maxBytes;
  final String label;
}

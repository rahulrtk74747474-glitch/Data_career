import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bundled content stays within low-memory asset budget', () {
    const maxBytes = 5 * 1024 * 1024;
    final directory = Directory('assets/content');

    expect(directory.existsSync(), isTrue);
    final files = directory
        .listSync(recursive: true)
        .whereType<File>()
        .toList();
    final bytes = files.fold<int>(
      0,
      (sum, file) => sum + file.lengthSync(),
    );

    expect(files, isNotEmpty);
    expect(
      bytes,
      lessThanOrEqualTo(maxBytes),
      reason:
          'Offline content exceeded the 5 MB source-asset budget for low-memory devices.',
    );
  });
}

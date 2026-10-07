import 'dart:convert';
import 'dart:io';

import 'package:dataquest_analyst_career/services/task_pack_generator.dart';

void main(List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(
      'Usage: dart run tool/generate_task_pack.dart '
      '--skill "Statistics" --level "Advanced" '
      '[--count 25] [--output generated_tasks.json]',
    );
    return;
  }

  String value(String name, {String? fallback}) {
    final index = args.indexOf(name);
    if (index == -1) {
      if (fallback != null) return fallback;
      throw FormatException('Missing required argument $name.');
    }
    if (index + 1 >= args.length) {
      throw FormatException('Missing value after $name.');
    }
    return args[index + 1];
  }

  try {
    final skill = value('--skill');
    final level = value('--level');
    final count = int.parse(value('--count', fallback: '25'));
    final output = value(
      '--output',
      fallback:
          'generated_${skill.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}_${level.toLowerCase()}_25.json',
    );

    final pack = TaskPackGenerator.generate(
      skill: skill,
      level: level,
      count: count,
    );
    final file = File(output);
    file.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(pack),
    );
    stdout.writeln(
      'Generated ${(pack['tasks'] as List).length} validated tasks at ${file.path}',
    );
  } on Object catch (error) {
    stderr.writeln('Task generation failed: $error');
    exitCode = 64;
  }
}

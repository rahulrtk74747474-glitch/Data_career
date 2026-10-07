import 'package:flutter/services.dart';

class SqlEditorHelper {
  const SqlEditorHelper._();

  static const keywords = <String>[
    'SELECT ', 'FROM ', 'WHERE ', 'JOIN ', 'LEFT JOIN ', 'ON ',
    'GROUP BY ', 'HAVING ', 'ORDER BY ', 'WITH ', 'CASE ', 'WHEN ',
    'OVER (', 'PARTITION BY ', 'ROWS BETWEEN ', 'LIMIT ',
  ];

  static TextEditingValue insertKeyword(
    TextEditingValue current,
    String keyword,
  ) {
    final selection = current.selection;
    final start = selection.start < 0 ? current.text.length : selection.start;
    final end = selection.end < 0 ? start : selection.end;
    final safeStart = start.clamp(0, current.text.length);
    final safeEnd = end.clamp(safeStart, current.text.length);
    final nextText = current.text.replaceRange(safeStart, safeEnd, keyword);
    return TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: safeStart + keyword.length),
    );
  }
}

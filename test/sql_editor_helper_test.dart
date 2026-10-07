import 'package:dataquest_analyst_career/services/sql_editor_helper.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keyword shortcut inserts at cursor and advances caret', () {
    const current = TextEditingValue(
      text: 'SELECT  FROM orders',
      selection: TextSelection.collapsed(offset: 7),
    );
    final next = SqlEditorHelper.insertKeyword(current, 'revenue');
    expect(next.text, 'SELECT revenue FROM orders');
    expect(next.selection.baseOffset, 14);
  });

  test('keyword shortcut replaces selected text', () {
    const current = TextEditingValue(
      text: 'SELECT wrong FROM orders',
      selection: TextSelection(baseOffset: 7, extentOffset: 12),
    );
    expect(
      SqlEditorHelper.insertKeyword(current, 'order_id').text,
      'SELECT order_id FROM orders',
    );
  });

  test('shortcut catalog covers beginner through window SQL', () {
    expect(SqlEditorHelper.keywords, containsAll([
      'SELECT ', 'WHERE ', 'JOIN ', 'GROUP BY ', 'WITH ',
      'OVER (', 'PARTITION BY ', 'ROWS BETWEEN ',
    ]));
  });
}

import 'package:dashboard_shakhsi/core/money/money_input_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const formatter = MoneyInputFormatter(maxFractionDigits: 8);

  TextEditingValue edit(String text, {int? offset}) {
    return formatter.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: offset ?? text.length),
      ),
    );
  }

  test('groups the integer part live and renders Persian digits', () {
    final result = edit('123456789');

    expect(result.text, '۱۲۳٬۴۵۶٬۷۸۹');
    expect(result.selection.baseOffset, result.text.length);
  });

  test('accepts Arabic digits and preserves a trailing decimal separator', () {
    expect(edit('١٢٣٤.').text, '۱٬۲۳۴٫');
    expect(edit('١٢٣٤.٥٠').text, '۱٬۲۳۴٫۵۰');
  });

  test('limits fractional input to eight digits without rounding', () {
    expect(edit('1234.123456789').text, '۱٬۲۳۴٫۱۲۳۴۵۶۷۸');
  });

  test('keeps the caret at the same logical digit position', () {
    final result = edit('12345', offset: 3);

    expect(result.text, '۱۲٬۳۴۵');
    expect(result.selection.baseOffset, 4);
  });

  test('allows clearing the field', () {
    final result = formatter.formatEditUpdate(
      const TextEditingValue(
        text: '۱۲۳',
        selection: TextSelection.collapsed(offset: 3),
      ),
      TextEditingValue.empty,
    );

    expect(result, TextEditingValue.empty);
  });
}

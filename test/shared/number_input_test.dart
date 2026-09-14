import 'package:flutter_test/flutter_test.dart';
import 'package:route_mint_app/shared/utils/number_input.dart';

void main() {
  test('accepts decimals from dot, comma and Persian/Arabic keyboards', () {
    for (final input in ['12.50', '12,50', ' 12,50 ', '۱۲٫۵۰', '١٢٫٥٠']) {
      expect(parseDecimalInput(input), 12.5, reason: input);
    }
    expect(parseDecimalInput(',5'), 0.5);
    expect(parseDecimalInput('-1,25'), -1.25);
    expect(parseDecimalInput('0'), 0);
  });

  test('rejects ambiguous, malformed and non-finite input', () {
    for (final input in [
      '',
      ' ',
      'NaN',
      'Infinity',
      '-Infinity',
      '1e309',
      '1,234.50',
      '1.234,50',
      '1,2,3',
      '12 dollars',
      List.filled(400, '9').join(),
    ]) {
      expect(parseDecimalInput(input), isNull, reason: input);
    }
  });
}
